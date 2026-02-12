/*
module: tools.repoLinter
purpose: Validate module headers (presence + module/path convention) using docs/ai/module-map.yml.
exports:
  - command: RepoLinter (dotnet run --project tools/RepoLinter -- [--staged|--diff <base> <head>|--all|<paths...>])
patterns:
  - repo_linter
  - module_header_validation
notes:
  - Intended to run quickly in Husky.Net pre-commit and in CI on changed files.
*/

using System.Diagnostics;
using System.Text;
using System.Text.RegularExpressions;

return RepoLinterApp.Run(args);

internal static class RepoLinterApp
{
    private const string DefaultModuleMapRelativePath = "docs/ai/module-map.yml";

    public static int Run(string[] args)
    {
        var options = Options.Parse(args);
        if (options.ShowHelp)
        {
            PrintHelp();
            return 0;
        }

        if (options.Errors.Count > 0)
        {
            foreach (var error in options.Errors)
            {
                Console.Error.WriteLine($"ERROR: {error}");
            }

            Console.Error.WriteLine();
            PrintHelp();
            return 2;
        }

        var repoRoot = ResolveRepoRoot(options.RepoRoot);
        if (repoRoot is null)
        {
            Console.Error.WriteLine("ERROR: Could not determine repo root. Run inside a git repo, or pass --repo-root <path>.");
            return 2;
        }

        var moduleMapPath = ResolveModuleMapPath(repoRoot, options.ModuleMapPath);
        if (!File.Exists(moduleMapPath))
        {
            Console.Error.WriteLine($"ERROR: Module map not found at '{moduleMapPath}'.");
            return 2;
        }

        ModuleMap moduleMap;
        try
        {
            moduleMap = ModuleMap.Load(moduleMapPath);
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine($"ERROR: Failed to parse module map '{moduleMapPath}': {ex.Message}");
            return 2;
        }

        IReadOnlyCollection<string> candidatePaths;
        try
        {
            candidatePaths = ResolveCandidatePaths(options, repoRoot);
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine($"ERROR: Failed to resolve target paths: {ex.Message}");
            return 2;
        }

        var lintableFiles = new List<LintFile>(capacity: candidatePaths.Count);
        foreach (var inputPath in candidatePaths)
        {
            var rel = PathUtil.NormalizeRelativePath(inputPath, repoRoot);
            if (rel is null)
            {
                continue;
            }

            if (!LintScope.IsLintable(rel))
            {
                continue;
            }

            if (moduleMap.IsExcluded(rel))
            {
                continue;
            }

            var abs = Path.GetFullPath(Path.Combine(repoRoot, rel));
            if (!File.Exists(abs))
            {
                // Deleted/renamed files may appear in diffs; ignore.
                continue;
            }

            lintableFiles.Add(new LintFile(rel, abs));
        }

        var errors = new List<string>();

        if (lintableFiles.Count > 0)
        {
            foreach (var file in lintableFiles.OrderBy(f => f.RelativePath, StringComparer.OrdinalIgnoreCase))
            {
                var expectedPrefix = moduleMap.TryGetExpectedModulePrefix(file.RelativePath);
                if (expectedPrefix is null)
                {
                    errors.Add($"{file.RelativePath}: No modulePrefix mapping found for this path. Add it to '{moduleMapPath}'.");
                    continue;
                }

                var headerResult = HeaderReader.TryReadHeaderYaml(file.AbsolutePath, file.RelativePath);
                if (!headerResult.Success)
                {
                    errors.Add($"{file.RelativePath}: {headerResult.Error}");
                    continue;
                }

                var fields = HeaderFields.Parse(headerResult.Yaml);

                if (string.IsNullOrWhiteSpace(fields.Module))
                {
                    errors.Add($"{file.RelativePath}: Module header is missing required key 'module'.");
                    continue;
                }

                if (string.IsNullOrWhiteSpace(fields.Purpose))
                {
                    errors.Add($"{file.RelativePath}: Module header is missing required key 'purpose'.");
                }

                if (!fields.HasExports)
                {
                    errors.Add($"{file.RelativePath}: Module header is missing required key 'exports'.");
                }

                if (!fields.HasPatterns)
                {
                    errors.Add($"{file.RelativePath}: Module header is missing required key 'patterns'.");
                }

                if (!ModuleConventions.MatchesExpectedPrefix(fields.Module, expectedPrefix))
                {
                    errors.Add(
                      $"{file.RelativePath}: Module header 'module: {fields.Module}' does not match expected modulePrefix '{expectedPrefix}' (must equal it or start with '{expectedPrefix}.')."
                    );
                }
            }
        }

        if (options.SecretsScan)
        {
            try
            {
                errors.AddRange(SecretsScanner.Scan(options, repoRoot));
            }
            catch (Exception ex)
            {
                errors.Add($"(secrets scan): {ex.Message}");
            }
        }

        try
        {
            errors.AddRange(InfraValidator.Validate(options, repoRoot, candidatePaths));
        }
        catch (Exception ex)
        {
            errors.Add($"(infra): {ex.Message}");
        }

        if (errors.Count == 0)
        {
            return 0;
        }

        foreach (var error in errors)
        {
            Console.Error.WriteLine($"ERROR: {error}");
        }

        return 1;
    }

    private static string? ResolveRepoRoot(string? repoRootArg)
    {
        if (!string.IsNullOrWhiteSpace(repoRootArg))
        {
            return Path.GetFullPath(repoRootArg);
        }

        return Git.TryGetRepoRoot();
    }

    private static string ResolveModuleMapPath(string repoRoot, string? moduleMapArg)
    {
        var relative = string.IsNullOrWhiteSpace(moduleMapArg) ? DefaultModuleMapRelativePath : moduleMapArg;
        return Path.GetFullPath(Path.Combine(repoRoot, relative));
    }

    private static IReadOnlyCollection<string> ResolveCandidatePaths(Options options, string repoRoot)
    {
        if (options.Mode == TargetMode.Staged)
        {
            return Git.GetStagedFiles(repoRoot);
        }

        if (options.Mode == TargetMode.Diff)
        {
            return Git.GetDiffFiles(repoRoot, options.DiffBase!, options.DiffHead!);
        }

        if (options.Mode == TargetMode.All)
        {
            return DirectoryFileSource.GetAllFiles(repoRoot);
        }

        return options.Paths;
    }

    private static void PrintHelp()
    {
        Console.WriteLine(
          """
RepoLinter — validate module headers + module/path convention

Usage:
  dotnet run --project tools/RepoLinter/RepoLinter.csproj -- --staged
  dotnet run --project tools/RepoLinter/RepoLinter.csproj -- --diff <baseSha> <headSha>
  dotnet run --project tools/RepoLinter/RepoLinter.csproj -- --all
  dotnet run --project tools/RepoLinter/RepoLinter.csproj -- <paths...>

Options:
  --staged                 Lint staged files (git diff --cached).
  --diff <base> <head>     Lint files changed between base and head (git diff base...head).
  --all                    Lint all lintable files in the repo.
  --secrets                Scan diffs for likely secrets (added lines only).
  --infra                  Force infra validation (bicep build + build-params).
  --repo-root <path>       Repo root override (default: git rev-parse --show-toplevel).
  --module-map <path>      Module map relative path (default: docs/ai/module-map.yml).
  -h, --help               Show help.

Exit codes:
  0  Success
  1  Validation failed
  2  Usage/config error
"""
        );
    }
}

internal enum TargetMode
{
    Paths = 0,
    Staged = 1,
    Diff = 2,
    All = 3,
}

internal sealed record Options(
  TargetMode Mode,
  string? RepoRoot,
  string? ModuleMapPath,
  string? DiffBase,
  string? DiffHead,
  bool InfraCheck,
  bool SecretsScan,
  List<string> Paths,
  bool ShowHelp,
  List<string> Errors
)
{
    public static Options Parse(string[] args)
    {
        var mode = TargetMode.Paths;
        var repoRoot = (string?)null;
        var moduleMapPath = (string?)null;
        var diffBase = (string?)null;
        var diffHead = (string?)null;
        var infraCheck = false;
        var secretsScan = false;
        var paths = new List<string>();
        var showHelp = false;
        var errors = new List<string>();

        var i = 0;
        while (i < args.Length)
        {
            var a = args[i];

            if (a is "-h" or "--help" or "/?")
            {
                showHelp = true;
                i++;
                continue;
            }

            if (a == "--staged")
            {
                mode = EnsureMode(mode, TargetMode.Staged, errors, a);
                i++;
                continue;
            }

            if (a == "--all")
            {
                mode = EnsureMode(mode, TargetMode.All, errors, a);
                i++;
                continue;
            }

            if (a == "--secrets")
            {
                secretsScan = true;
                i++;
                continue;
            }

            if (a == "--infra")
            {
                infraCheck = true;
                i++;
                continue;
            }

            if (a == "--diff")
            {
                mode = EnsureMode(mode, TargetMode.Diff, errors, a);

                if (i + 2 >= args.Length)
                {
                    errors.Add("Option '--diff' requires two arguments: <baseSha> <headSha>.");
                    break;
                }

                diffBase = args[i + 1];
                diffHead = args[i + 2];
                i += 3;
                continue;
            }

            if (a == "--repo-root")
            {
                if (i + 1 >= args.Length)
                {
                    errors.Add("Option '--repo-root' requires an argument.");
                    break;
                }

                repoRoot = args[i + 1];
                i += 2;
                continue;
            }

            if (a == "--module-map")
            {
                if (i + 1 >= args.Length)
                {
                    errors.Add("Option '--module-map' requires an argument.");
                    break;
                }

                moduleMapPath = args[i + 1];
                i += 2;
                continue;
            }

            if (a.StartsWith("-", StringComparison.Ordinal))
            {
                errors.Add($"Unknown option '{a}'.");
                i++;
                continue;
            }

            paths.Add(a);
            i++;
        }

        if (!showHelp)
        {
            if (mode == TargetMode.Paths && paths.Count == 0)
            {
                errors.Add("No target specified. Use --staged, --diff, --all, or provide <paths...>.");
            }

            if (mode == TargetMode.Diff)
            {
                if (string.IsNullOrWhiteSpace(diffBase) || string.IsNullOrWhiteSpace(diffHead))
                {
                    errors.Add("Option '--diff' requires two arguments: <baseSha> <headSha>.");
                }
            }
        }

        return new Options(mode, repoRoot, moduleMapPath, diffBase, diffHead, infraCheck, secretsScan, paths, showHelp, errors);
    }

    private static TargetMode EnsureMode(TargetMode current, TargetMode requested, List<string> errors, string option)
    {
        if (current == TargetMode.Paths)
        {
            return requested;
        }

        if (current == requested)
        {
            return requested;
        }

        errors.Add($"Conflicting options: '{option}' cannot be combined with another target selection.");
        return requested;
    }
}

internal sealed record LintFile(string RelativePath, string AbsolutePath);

internal static class LintScope
{
    private static readonly HashSet<string> Extensions = new(StringComparer.OrdinalIgnoreCase)
  {
    ".bicep",
    ".bicepparam",
    ".ps1",
    ".psm1",
    ".cs",
    ".ts",
    ".tsx",
    ".vue",
    ".sql",
    ".md",
    ".mdc",
    ".yml",
    ".yaml",
  };

    public static bool IsLintable(string relativePath)
    {
        var ext = Path.GetExtension(relativePath);
        return Extensions.Contains(ext);
    }
}

internal static class DirectoryFileSource
{
    public static IReadOnlyCollection<string> GetAllFiles(string repoRoot)
    {
        var results = new List<string>();

        foreach (var abs in Directory.EnumerateFiles(repoRoot, "*", SearchOption.AllDirectories))
        {
            // Avoid touching .git internals (and any nested .git dirs).
            if (abs.Contains($"{Path.DirectorySeparatorChar}.git{Path.DirectorySeparatorChar}", StringComparison.OrdinalIgnoreCase))
            {
                continue;
            }

            results.Add(Path.GetRelativePath(repoRoot, abs));
        }

        return results;
    }
}

internal static class PathUtil
{
    public static string? NormalizeRelativePath(string inputPath, string repoRoot)
    {
        if (string.IsNullOrWhiteSpace(inputPath))
        {
            return null;
        }

        var p = inputPath.Trim();

        // Git typically returns /-separated paths even on Windows; allow both.
        p = p.Replace('\\', '/');

        if (Path.IsPathRooted(p))
        {
            var abs = Path.GetFullPath(p);
            p = Path.GetRelativePath(repoRoot, abs);
        }

        p = p.Replace('\\', '/');
        p = p.TrimStart('.', '/');

        return p;
    }
}

internal static class Git
{
    public static string? TryGetRepoRoot()
    {
        var result = Run("git", "rev-parse --show-toplevel");
        if (result.ExitCode != 0)
        {
            return null;
        }

        var root = result.StdOut.Trim();
        return string.IsNullOrWhiteSpace(root) ? null : root;
    }

    public static IReadOnlyCollection<string> GetStagedFiles(string repoRoot)
    {
        var result = Run("git", "diff --cached --name-only --diff-filter=ACMR", repoRoot);
        if (result.ExitCode != 0)
        {
            throw new InvalidOperationException(result.StdErr.Trim());
        }

        return SplitLines(result.StdOut);
    }

    public static IReadOnlyCollection<string> GetDiffFiles(string repoRoot, string baseSha, string headSha)
    {
        var cmd = $"diff --name-only --diff-filter=ACMR {baseSha}...{headSha}";
        var result = Run("git", cmd, repoRoot);
        if (result.ExitCode != 0)
        {
            throw new InvalidOperationException(result.StdErr.Trim());
        }

        return SplitLines(result.StdOut);
    }

    public static string GetStagedPatch(string repoRoot)
    {
        var result = Run("git", "diff --cached --unified=0 --diff-filter=ACMR", repoRoot);
        if (result.ExitCode != 0)
        {
            throw new InvalidOperationException(result.StdErr.Trim());
        }

        return result.StdOut;
    }

    public static string GetDiffPatch(string repoRoot, string baseSha, string headSha)
    {
        var cmd = $"diff --unified=0 --diff-filter=ACMR {baseSha}...{headSha}";
        var result = Run("git", cmd, repoRoot);
        if (result.ExitCode != 0)
        {
            throw new InvalidOperationException(result.StdErr.Trim());
        }

        return result.StdOut;
    }

    private static IReadOnlyCollection<string> SplitLines(string text)
    {
        return text.Split(['\r', '\n'], StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
    }

    private static ProcessResult Run(string fileName, string arguments, string? workingDirectory = null)
    {
        var psi = new ProcessStartInfo
        {
            FileName = fileName,
            Arguments = arguments,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
            CreateNoWindow = true,
        };

        if (!string.IsNullOrWhiteSpace(workingDirectory))
        {
            psi.WorkingDirectory = workingDirectory;
        }

        using var p = Process.Start(psi);
        if (p is null)
        {
            throw new InvalidOperationException($"Failed to start process '{fileName}'.");
        }

        var stdout = p.StandardOutput.ReadToEnd();
        var stderr = p.StandardError.ReadToEnd();

        p.WaitForExit();

        return new ProcessResult(p.ExitCode, stdout, stderr);
    }

    private sealed record ProcessResult(int ExitCode, string StdOut, string StdErr);
}

internal static class InfraValidator
{
    private const string InfraRootRelativePath = "infra/bicep";

    public static IReadOnlyCollection<string> Validate(
        Options options,
        string repoRoot,
        IReadOnlyCollection<string> candidatePaths)
    {
        if (!ShouldRun(options, repoRoot, candidatePaths))
        {
            return Array.Empty<string>();
        }

        var infraRoot = Path.Combine(repoRoot, "infra", "bicep");
        if (!Directory.Exists(infraRoot))
        {
            return [$"infra: expected folder '{InfraRootRelativePath}' not found."];
        }

        var errors = new List<string>();

        var versionResult = TryRun("bicep", "--version", infraRoot);
        if (versionResult is null)
        {
            Console.Error.WriteLine("WARNING: infra: 'bicep' CLI not found; skipping bicep build/build-params. Install Bicep CLI to validate infra.");
            return Array.Empty<string>();
        }

        if (versionResult.ExitCode != 0)
        {
            errors.Add($"infra: bicep --version failed: {versionResult.StdErr.Trim()}");
            return errors;
        }

        var bicepFiles = Directory.EnumerateFiles(infraRoot, "*.bicep", SearchOption.AllDirectories)
            .OrderBy(path => path, StringComparer.OrdinalIgnoreCase)
            .ToList();
        var paramFiles = Directory.EnumerateFiles(infraRoot, "*.bicepparam", SearchOption.AllDirectories)
            .OrderBy(path => path, StringComparer.OrdinalIgnoreCase)
            .ToList();

        foreach (var file in bicepFiles)
        {
            var result = Run("bicep", $"build \"{file}\"", infraRoot);
            if (result.ExitCode != 0)
            {
                errors.Add($"infra: bicep build failed for '{Path.GetRelativePath(repoRoot, file)}': {Trim(result.StdErr)}");
            }
        }

        foreach (var file in paramFiles)
        {
            var result = Run("bicep", $"build-params \"{file}\"", infraRoot);
            if (result.ExitCode != 0)
            {
                errors.Add($"infra: bicep build-params failed for '{Path.GetRelativePath(repoRoot, file)}': {Trim(result.StdErr)}");
            }
        }

        return errors;
    }

    private static bool ShouldRun(Options options, string repoRoot, IReadOnlyCollection<string> candidatePaths)
    {
        if (options.InfraCheck || options.Mode == TargetMode.All)
        {
            return true;
        }

        foreach (var path in candidatePaths)
        {
            var relative = PathUtil.NormalizeRelativePath(path, repoRoot);
            if (relative is null)
            {
                continue;
            }

            if (relative.StartsWith($"{InfraRootRelativePath}/", StringComparison.OrdinalIgnoreCase))
            {
                return true;
            }
        }

        return false;
    }

    private static string Trim(string value)
        => string.IsNullOrWhiteSpace(value) ? "Unknown error." : value.Trim();

    private static ProcessResult? TryRun(string fileName, string arguments, string? workingDirectory)
    {
        try
        {
            return Run(fileName, arguments, workingDirectory);
        }
        catch
        {
            return null;
        }
    }

    private static ProcessResult Run(string fileName, string arguments, string? workingDirectory)
    {
        var psi = new ProcessStartInfo
        {
            FileName = fileName,
            Arguments = arguments,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
            CreateNoWindow = true,
        };

        if (!string.IsNullOrWhiteSpace(workingDirectory))
        {
            psi.WorkingDirectory = workingDirectory;
        }

        using var p = Process.Start(psi);
        if (p is null)
        {
            throw new InvalidOperationException($"Failed to start process '{fileName}'.");
        }

        var stdout = p.StandardOutput.ReadToEnd();
        var stderr = p.StandardError.ReadToEnd();

        p.WaitForExit();

        return new ProcessResult(p.ExitCode, stdout, stderr);
    }

    private sealed record ProcessResult(int ExitCode, string StdOut, string StdErr);
}

internal static class SecretsScanner
{
    // NOTE: This scanner is intentionally conservative and never prints the secret value.
    // It inspects only added lines in git diffs (staged or PR diff) to avoid failing builds
    // due to legacy content and to reduce false positives.

    private static readonly Regex DiffHeaderRegex =
      new(
        @"^diff --git a/(?<old>.+) b/(?<new>.+)$",
        RegexOptions.Compiled | RegexOptions.CultureInvariant | RegexOptions.ExplicitCapture
      );

    private static readonly Regex HunkHeaderRegex =
      new(
        @"^@@ -(?<oldStart>\d+)(?:,\d+)? \+(?<newStart>\d+)(?:,\d+)? @@",
        RegexOptions.Compiled | RegexOptions.CultureInvariant | RegexOptions.ExplicitCapture
      );

    private static readonly Regex PrivateKeyRegex =
      new(
        @"-----BEGIN(?: [A-Z0-9]+)? PRIVATE KEY-----",
        RegexOptions.Compiled | RegexOptions.CultureInvariant | RegexOptions.ExplicitCapture
      );

    private static readonly Regex GitHubTokenRegex =
      new(
        @"\bgh[opsru]_[A-Za-z0-9]{36}\b|\bgithub_pat_[A-Za-z0-9_]{80,}\b",
        RegexOptions.Compiled | RegexOptions.CultureInvariant | RegexOptions.ExplicitCapture
      );

    private static readonly Regex AwsAccessKeyIdRegex =
      new(@"\bAKIA[0-9A-Z]{16}\b", RegexOptions.Compiled | RegexOptions.CultureInvariant | RegexOptions.ExplicitCapture);

    private static readonly Regex StripeSecretKeyRegex =
      new(
        @"\bsk_(?:live|test)_[0-9a-zA-Z]{20,}\b",
        RegexOptions.Compiled | RegexOptions.CultureInvariant | RegexOptions.ExplicitCapture
      );

    private static readonly Regex SlackTokenRegex =
      new(
        @"\bxox[baprs]-[0-9A-Za-z-]{10,}\b",
        RegexOptions.Compiled | RegexOptions.CultureInvariant | RegexOptions.ExplicitCapture
      );

    private static readonly Regex CredentialAssignmentRegex =
      new(
        @"(?i)(?<key>[A-Za-z0-9_.-]*?(?:password|pwd|passphrase|clientsecret|client_secret|api[_-]?key|token)[A-Za-z0-9_.-]*)\s*[:=]\s*(?<value>""[^""]*""|'[^']*'|[^\s;,#]+)",
        RegexOptions.Compiled | RegexOptions.CultureInvariant | RegexOptions.ExplicitCapture
      );

    private static readonly HashSet<string> PlaceholderValues = new(StringComparer.OrdinalIgnoreCase)
  {
    "changeme",
    "change-me",
    "password",
    "example",
    "examplepassword",
    "your_password_here",
    "your-password-here",
    "redacted",
  };

    /// <summary>
    /// Paths excluded from secrets scanning (e.g. generated/docs with example code like authToken).
    /// </summary>
    private static readonly string[] SecretsScanExcludedPathPrefixes = ["artifacts/"];

    public static bool IsExcludedFromSecretsScan(string? filePath)
    {
        if (string.IsNullOrWhiteSpace(filePath))
        {
            return true;
        }

        var normalized = filePath.Replace('\\', '/').TrimStart('.', '/');
        foreach (var prefix in SecretsScanExcludedPathPrefixes)
        {
            if (normalized.StartsWith(prefix, StringComparison.OrdinalIgnoreCase))
            {
                return true;
            }
        }

        return false;
    }

    public static IReadOnlyCollection<string> Scan(Options options, string repoRoot)
    {
        if (options.Mode is not (TargetMode.Staged or TargetMode.Diff))
        {
            return new[] { "Option '--secrets' is only supported with --staged or --diff." };
        }

        var patch = options.Mode == TargetMode.Staged
          ? Git.GetStagedPatch(repoRoot)
          : Git.GetDiffPatch(repoRoot, options.DiffBase!, options.DiffHead!);

        return ScanPatch(patch);
    }

    private static IReadOnlyCollection<string> ScanPatch(string patch)
    {
        var errors = new List<string>();

        string? currentFile = null;
        var inHunk = false;
        var oldLine = 0;
        var newLine = 0;

        using var sr = new StringReader(patch);
        string? line;
        while ((line = sr.ReadLine()) is not null)
        {
            var diffMatch = DiffHeaderRegex.Match(line);
            if (diffMatch.Success)
            {
                currentFile = UnquoteGitPath(diffMatch.Groups["new"].Value);
                inHunk = false;
                oldLine = 0;
                newLine = 0;
                continue;
            }

            var hunkMatch = HunkHeaderRegex.Match(line);
            if (hunkMatch.Success)
            {
                inHunk = true;
                _ = int.TryParse(hunkMatch.Groups["oldStart"].Value, out oldLine);
                _ = int.TryParse(hunkMatch.Groups["newStart"].Value, out newLine);
                continue;
            }

            if (!inHunk || currentFile is null)
            {
                continue;
            }

            // Skip file header lines within the diff.
            if (line.StartsWith("+++", StringComparison.Ordinal) || line.StartsWith("---", StringComparison.Ordinal))
            {
                continue;
            }

            if (line.StartsWith("+", StringComparison.Ordinal))
            {
                var added = line.Length > 1 ? line[1..] : string.Empty;

                // Skip secrets scan for artifacts (e.g. generated/docs HTML with example code like authToken).
                if (!SecretsScanner.IsExcludedFromSecretsScan(currentFile)
                    && TryDetectSecret(currentFile, added, out var ruleId, out var message))
                {
                    errors.Add($"{currentFile}:{newLine}: {ruleId} {message}");
                }

                newLine++;
                continue;
            }

            if (line.StartsWith("-", StringComparison.Ordinal))
            {
                oldLine++;
                continue;
            }

            if (line.StartsWith(" ", StringComparison.Ordinal))
            {
                oldLine++;
                newLine++;
            }
        }

        return errors;
    }

    private static bool TryDetectSecret(string? filePath, string line, out string ruleId, out string message)
    {
        ruleId = string.Empty;
        message = string.Empty;

        if (PrivateKeyRegex.IsMatch(line))
        {
            ruleId = "SS001";
            message = "Private key material detected (do not commit keys; use Key Vault / environment secrets).";
            return true;
        }

        if (GitHubTokenRegex.IsMatch(line))
        {
            ruleId = "SS002";
            message = "GitHub access token detected (do not commit tokens; use GitHub Secrets).";
            return true;
        }

        if (AwsAccessKeyIdRegex.IsMatch(line))
        {
            ruleId = "SS003";
            message = "AWS access key id detected (do not commit credentials).";
            return true;
        }

        if (StripeSecretKeyRegex.IsMatch(line))
        {
            ruleId = "SS004";
            message = "Stripe secret key detected (do not commit secrets).";
            return true;
        }

        if (SlackTokenRegex.IsMatch(line))
        {
            ruleId = "SS005";
            message = "Slack token detected (do not commit secrets).";
            return true;
        }

        var allowBareIdentifier = IsCodeFile(filePath);
        if (TryDetectHardcodedCredentialAssignment(line, allowBareIdentifier, out var keyName))
        {
            ruleId = "SS006";
            message = $"Hardcoded credential value detected for '{keyName}' (use Key Vault / GitHub Secrets / env vars).";
            return true;
        }

        return false;
    }

    private static bool TryDetectHardcodedCredentialAssignment(string line, bool allowBareIdentifier, out string keyName)
    {
        keyName = string.Empty;

        var match = CredentialAssignmentRegex.Match(line);
        if (!match.Success)
        {
            return false;
        }

        var key = match.Groups["key"].Value;
        var rawValue = match.Groups["value"].Value.Trim();
        var value = UnquoteValue(rawValue).Trim();
        value = value.TrimEnd(')', ']', '}', ',');

        if (string.IsNullOrWhiteSpace(value))
        {
            return false;
        }

        if (LooksLikeVariableReference(value) || LooksLikeCiSecretsExpression(line, value))
        {
            return false;
        }

        if (allowBareIdentifier && IsBareIdentifier(value))
        {
            return false;
        }

        if (IsPlaceholder(value))
        {
            return false;
        }

        // Avoid screaming about tiny values like "dev" while still catching typical secrets.
        if (value.Length < 8)
        {
            return false;
        }

        keyName = key;
        return true;
    }

    private static bool LooksLikeCiSecretsExpression(string fullLine, string value)
    {
        if (fullLine.Contains("${{", StringComparison.Ordinal))
        {
            return true;
        }

        if (value.Contains("secrets.", StringComparison.OrdinalIgnoreCase))
        {
            return true;
        }

        return false;
    }

    private static bool LooksLikeVariableReference(string value)
    {
        if (value.StartsWith("$", StringComparison.Ordinal))
        {
            return true;
        }

        if (value.Contains("$(", StringComparison.Ordinal) || value.Contains("${", StringComparison.Ordinal))
        {
            return true;
        }

        return false;
    }

    private static bool IsPlaceholder(string value)
    {
        if (value.StartsWith("<", StringComparison.Ordinal) && value.EndsWith(">", StringComparison.Ordinal))
        {
            return true;
        }

        if (PlaceholderValues.Contains(value))
        {
            return true;
        }

        if (value.Contains("your_", StringComparison.OrdinalIgnoreCase) || value.Contains("your-", StringComparison.OrdinalIgnoreCase))
        {
            return true;
        }

        if (value.Contains("example", StringComparison.OrdinalIgnoreCase))
        {
            return true;
        }

        if (value.Contains("redact", StringComparison.OrdinalIgnoreCase))
        {
            return true;
        }

        return false;
    }

    private static bool IsCodeFile(string? filePath)
    {
        if (string.IsNullOrWhiteSpace(filePath))
        {
            return false;
        }

        var ext = Path.GetExtension(filePath);
        return ext is ".cs" or ".ts" or ".tsx" or ".js" or ".jsx" or ".vue";
    }

    private static bool IsBareIdentifier(string value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return false;
        }

        for (var i = 0; i < value.Length; i++)
        {
            var c = value[i];
            var valid = c == '_' || c == '.' || char.IsLetterOrDigit(c);
            if (!valid)
            {
                return false;
            }
        }

        return char.IsLetter(value[0]) || value[0] == '_';
    }

    private static string UnquoteGitPath(string value)
    {
        var v = value.Trim();
        if (v.Length >= 2 && ((v.StartsWith('"') && v.EndsWith('"')) || (v.StartsWith('\'') && v.EndsWith('\''))))
        {
            return v[1..^1];
        }

        return v;
    }

    private static string UnquoteValue(string value)
    {
        if (value.Length >= 2 && ((value.StartsWith('"') && value.EndsWith('"')) || (value.StartsWith('\'') && value.EndsWith('\''))))
        {
            return value[1..^1];
        }

        return value;
    }
}

internal sealed record ModulePrefixEntry(string ModulePrefix, List<string> Paths);

internal sealed class ModuleMap
{
    private readonly List<ModulePrefixEntry> _modulePrefixes;
    private readonly List<string> _exclusions;

    private ModuleMap(List<ModulePrefixEntry> modulePrefixes, List<string> exclusions)
    {
        _modulePrefixes = modulePrefixes;
        _exclusions = exclusions;
    }

    public static ModuleMap Load(string moduleMapPath)
    {
        var lines = File.ReadAllLines(moduleMapPath);

        var modulePrefixes = new List<ModulePrefixEntry>();
        var exclusions = new List<string>();

        ModulePrefixEntry? current = null;
        var inModulePrefixes = false;
        var inExclusions = false;
        var inPaths = false;

        foreach (var rawLine in lines)
        {
            var line = rawLine.TrimEnd();
            if (string.IsNullOrWhiteSpace(line))
            {
                continue;
            }

            var trimmed = line.TrimStart();
            if (trimmed.StartsWith("#", StringComparison.Ordinal))
            {
                continue;
            }

            if (trimmed.StartsWith("modulePrefixes:", StringComparison.Ordinal))
            {
                inModulePrefixes = true;
                inExclusions = false;
                inPaths = false;
                continue;
            }

            if (trimmed.StartsWith("exclusions:", StringComparison.Ordinal))
            {
                inModulePrefixes = false;
                inExclusions = true;
                inPaths = false;
                current = null;
                continue;
            }

            if (inExclusions)
            {
                if (TryParseListItem(trimmed, out var item))
                {
                    exclusions.Add(item);
                }

                continue;
            }

            if (!inModulePrefixes)
            {
                continue;
            }

            if (TryParseDashKeyValue(trimmed, "modulePrefix", out var modulePrefixValue))
            {
                current = new ModulePrefixEntry(modulePrefixValue, new List<string>());
                modulePrefixes.Add(current);
                inPaths = false;
                continue;
            }

            if (trimmed.StartsWith("paths:", StringComparison.Ordinal))
            {
                if (current is null)
                {
                    throw new InvalidOperationException("Found 'paths:' before a 'modulePrefix:' entry.");
                }

                inPaths = true;
                continue;
            }

            if (inPaths && TryParseListItem(trimmed, out var pathPattern))
            {
                current!.Paths.Add(pathPattern);
            }
        }

        if (modulePrefixes.Count == 0)
        {
            throw new InvalidOperationException("No modulePrefixes found in module map.");
        }

        return new ModuleMap(modulePrefixes, exclusions);
    }

    public bool IsExcluded(string relativePath)
    {
        // Always ignore any .git folders.
        if (Glob.IsMatch(relativePath, "**/.git/**"))
        {
            return true;
        }

        foreach (var ex in _exclusions)
        {
            if (Glob.IsMatch(relativePath, ex))
            {
                return true;
            }
        }

        return false;
    }

    public string? TryGetExpectedModulePrefix(string relativePath)
    {
        foreach (var entry in _modulePrefixes)
        {
            foreach (var pattern in entry.Paths)
            {
                if (Glob.IsMatch(relativePath, pattern))
                {
                    return entry.ModulePrefix;
                }
            }
        }

        return null;
    }

    private static bool TryParseListItem(string trimmedLine, out string item)
    {
        item = string.Empty;

        if (!trimmedLine.StartsWith("-", StringComparison.Ordinal))
        {
            return false;
        }

        var rest = trimmedLine[1..].Trim();
        if (rest.Length == 0)
        {
            return false;
        }

        item = Unquote(rest);
        return true;
    }

    private static bool TryParseDashKeyValue(string trimmedLine, string key, out string value)
    {
        value = string.Empty;

        var prefix = $"- {key}:";
        if (!trimmedLine.StartsWith(prefix, StringComparison.Ordinal))
        {
            return false;
        }

        value = Unquote(trimmedLine[prefix.Length..].Trim());
        return true;
    }

    private static string Unquote(string value)
    {
        if (value.Length >= 2 && ((value.StartsWith('"') && value.EndsWith('"')) || (value.StartsWith('\'') && value.EndsWith('\''))))
        {
            return value[1..^1];
        }

        return value;
    }
}

internal static class Glob
{
    public static bool IsMatch(string path, string pattern)
    {
        path = Normalize(path);
        pattern = Normalize(pattern);

        // Normalize leading "./"
        if (path.StartsWith("./", StringComparison.Ordinal))
        {
            path = path[2..];
        }

        if (pattern.StartsWith("./", StringComparison.Ordinal))
        {
            pattern = pattern[2..];
        }

        var regex = GlobToRegex(pattern);
        return Regex.IsMatch(path, regex, RegexOptions.CultureInvariant | RegexOptions.ExplicitCapture);
    }

    private static string Normalize(string value) => value.Replace('\\', '/');

    private static string GlobToRegex(string pattern)
    {
        var sb = new StringBuilder();
        sb.Append('^');

        for (var i = 0; i < pattern.Length; i++)
        {
            var c = pattern[i];

            if (c == '*')
            {
                var isDoubleStar = i + 1 < pattern.Length && pattern[i + 1] == '*';
                if (isDoubleStar)
                {
                    var isDoubleStarSlash = i + 2 < pattern.Length && pattern[i + 2] == '/';
                    if (isDoubleStarSlash)
                    {
                        // Match zero or more path segments (including trailing slash).
                        sb.Append("(?:.*/)?");
                        i += 2;
                    }
                    else
                    {
                        sb.Append(".*");
                        i++;
                    }
                }
                else
                {
                    sb.Append("[^/]*");
                }

                continue;
            }

            if (c == '?')
            {
                sb.Append("[^/]");
                continue;
            }

            if (c == '/')
            {
                sb.Append('/');
                continue;
            }

            sb.Append(Regex.Escape(c.ToString()));
        }

        sb.Append('$');
        return sb.ToString();
    }
}

internal sealed record HeaderReadResult(bool Success, string Yaml, string Error)
{
    public static HeaderReadResult Ok(string yaml) => new(true, yaml, string.Empty);
    public static HeaderReadResult Fail(string error) => new(false, string.Empty, error);
}

internal static class HeaderReader
{
    public static HeaderReadResult TryReadHeaderYaml(string absolutePath, string relativePath)
    {
        var ext = Path.GetExtension(relativePath).ToLowerInvariant();
        var fileName = Path.GetFileName(relativePath);

        return ext switch
        {
            ".bicep" or ".bicepparam" or ".cs" or ".ts" or ".tsx" => ReadBlockComment(absolutePath, "/*", "*/"),
            ".ps1" or ".psm1" => ReadBlockComment(absolutePath, "<#", "#>"),
            ".sql" => ReadLineCommentBlock(absolutePath, "--"),
            ".yml" or ".yaml" => ReadLineCommentBlock(absolutePath, "#"),
            ".mdc" => ReadFrontMatter(absolutePath),
            ".md" or ".vue" => ReadMarkdownLikeHeader(absolutePath, fileName),
            _ => HeaderReadResult.Fail("File type is not supported by the repo linter."),
        };
    }

    private static HeaderReadResult ReadMarkdownLikeHeader(string absolutePath, string fileName)
    {
        if (fileName.Equals("SKILL.md", StringComparison.OrdinalIgnoreCase))
        {
            return ReadFrontMatter(absolutePath);
        }

        var prefix = ReadFilePrefix(absolutePath);
        var trimmed = SkipBomAndLeadingWhitespace(prefix);

        if (trimmed.StartsWith("<!--", StringComparison.Ordinal))
        {
            return ReadBlockComment(absolutePath, "<!--", "-->");
        }

        if (trimmed.StartsWith("---", StringComparison.Ordinal))
        {
            return ReadFrontMatter(absolutePath);
        }

        // Leniency for legacy markdown files using /* ... */ (e.g., infra/bicep/README.md).
        if (trimmed.StartsWith("/*", StringComparison.Ordinal))
        {
            return ReadBlockComment(absolutePath, "/*", "*/");
        }

        return HeaderReadResult.Fail("Missing module header at start of file.");
    }

    private static HeaderReadResult ReadFrontMatter(string absolutePath)
    {
        using var sr = new StreamReader(absolutePath, Encoding.UTF8, detectEncodingFromByteOrderMarks: true);

        string? line;
        do
        {
            line = sr.ReadLine();
            if (line is null)
            {
                return HeaderReadResult.Fail("File is empty.");
            }
        } while (string.IsNullOrWhiteSpace(line));

        if (!string.Equals(line.Trim(), "---", StringComparison.Ordinal))
        {
            return HeaderReadResult.Fail("Missing YAML frontmatter module header (expected starting '---').");
        }

        var sb = new StringBuilder();
        while ((line = sr.ReadLine()) is not null)
        {
            if (string.Equals(line.Trim(), "---", StringComparison.Ordinal))
            {
                return HeaderReadResult.Ok(sb.ToString());
            }

            sb.AppendLine(line);
        }

        return HeaderReadResult.Fail("Unterminated YAML frontmatter (missing closing '---').");
    }

    private static HeaderReadResult ReadLineCommentBlock(string absolutePath, string prefix)
    {
        using var sr = new StreamReader(absolutePath, Encoding.UTF8, detectEncodingFromByteOrderMarks: true);

        string? line;
        do
        {
            line = sr.ReadLine();
            if (line is null)
            {
                return HeaderReadResult.Fail("File is empty.");
            }
        } while (string.IsNullOrWhiteSpace(line));

        var first = line.TrimStart();
        if (!first.StartsWith(prefix, StringComparison.Ordinal))
        {
            return HeaderReadResult.Fail($"Missing module header at start of file (expected '{prefix}' comment header).");
        }

        var sb = new StringBuilder();
        while (line is not null)
        {
            var trimmed = line.TrimStart();
            if (!trimmed.StartsWith(prefix, StringComparison.Ordinal))
            {
                break;
            }

            var yamlPart = trimmed[prefix.Length..];
            if (yamlPart.StartsWith(' '))
            {
                yamlPart = yamlPart[1..];
            }

            sb.AppendLine(yamlPart);
            line = sr.ReadLine();
        }

        return HeaderReadResult.Ok(sb.ToString());
    }

    private static HeaderReadResult ReadBlockComment(string absolutePath, string start, string end)
    {
        var prefix = ReadFilePrefix(absolutePath);
        var trimmed = SkipBomAndLeadingWhitespace(prefix);

        if (!trimmed.StartsWith(start, StringComparison.Ordinal))
        {
            return HeaderReadResult.Fail($"Missing module header at start of file (expected '{start} ... {end}').");
        }

        var startIndex = prefix.IndexOf(start, StringComparison.Ordinal);
        if (startIndex < 0)
        {
            return HeaderReadResult.Fail("Missing module header start.");
        }

        var endIndex = prefix.IndexOf(end, startIndex + start.Length, StringComparison.Ordinal);
        if (endIndex < 0)
        {
            return HeaderReadResult.Fail($"Unterminated module header (missing '{end}').");
        }

        var yamlStart = startIndex + start.Length;
        var yaml = prefix.Substring(yamlStart, endIndex - yamlStart);
        return HeaderReadResult.Ok(yaml);
    }

    private static string ReadFilePrefix(string path)
    {
        const int maxChars = 200_000;

        using var sr = new StreamReader(path, Encoding.UTF8, detectEncodingFromByteOrderMarks: true);
        var buffer = new char[4096];
        var sb = new StringBuilder(capacity: 8192);

        while (sb.Length < maxChars)
        {
            var read = sr.Read(buffer, 0, Math.Min(buffer.Length, maxChars - sb.Length));
            if (read <= 0)
            {
                break;
            }

            sb.Append(buffer, 0, read);

            // Quick exit: if we have both start and end tokens in the buffer, we can stop reading.
            if (sb.Length >= 256 && sb.ToString().Contains("module:", StringComparison.Ordinal))
            {
                // Still keep reading until we likely captured the whole header.
                // (MaxChars provides an upper bound.)
            }
        }

        return sb.ToString();
    }

    private static string SkipBomAndLeadingWhitespace(string text)
    {
        if (text.Length == 0)
        {
            return text;
        }

        var i = 0;

        if (text[0] == '\uFEFF')
        {
            i++;
        }

        while (i < text.Length && char.IsWhiteSpace(text[i]))
        {
            i++;
        }

        return text[i..];
    }
}

internal sealed record HeaderFields(string? Module, string? Purpose, bool HasExports, bool HasPatterns)
{
    public static HeaderFields Parse(string yaml)
    {
        string? module = null;
        string? purpose = null;
        var hasExports = false;
        var hasPatterns = false;

        foreach (var raw in yaml.Split(['\r', '\n'], StringSplitOptions.RemoveEmptyEntries))
        {
            var line = raw.Trim();
            if (line.Length == 0)
            {
                continue;
            }

            // Ignore pure comment lines within the header (rare but harmless).
            if (line.StartsWith("#", StringComparison.Ordinal))
            {
                continue;
            }

            var colonIndex = line.IndexOf(':');
            if (colonIndex <= 0)
            {
                continue;
            }

            var key = line[..colonIndex].Trim();
            var value = line[(colonIndex + 1)..].Trim();

            if (key.Equals("module", StringComparison.Ordinal))
            {
                module ??= Unquote(value);
            }
            else if (key.Equals("purpose", StringComparison.Ordinal))
            {
                purpose ??= value;
            }
            else if (key.Equals("exports", StringComparison.Ordinal))
            {
                hasExports = true;
            }
            else if (key.Equals("patterns", StringComparison.Ordinal))
            {
                hasPatterns = true;
            }
        }

        return new HeaderFields(module, purpose, hasExports, hasPatterns);
    }

    private static string Unquote(string value)
    {
        if (value.Length >= 2 && ((value.StartsWith('"') && value.EndsWith('"')) || (value.StartsWith('\'') && value.EndsWith('\''))))
        {
            return value[1..^1];
        }

        return value;
    }
}

internal static class ModuleConventions
{
    public static bool MatchesExpectedPrefix(string module, string expectedPrefix)
    {
        if (module.Equals(expectedPrefix, StringComparison.Ordinal))
        {
            return true;
        }

        return module.StartsWith($"{expectedPrefix}.", StringComparison.Ordinal);
    }
}
