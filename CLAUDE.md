# CLAUDE.md — Project Context & Conventions

**Project**: Cloud-native SaaS template (Azure/.NET) — Multi-tenant Inventory Management System  
**Developer**: Solo  
**Status**: Actively building  
**Last updated**: 2026-02-14

---

## What This Project Is

A production-grade **SaaS template** for building multi-tenant inventory management systems. Emphasizes Clean Architecture, DDD, security, observability, and LLM-forward conventions.

**Core capabilities**:
- Multi-tenant inventory tracking (items, categories, suppliers)
- Inventory movement audit trail (stock_in, stock_out, adjustment, sale, return, loss)
- Negative stock prevention with reorder triggers
- Admin backoffice (manage customers, feature flags, audit reports, tiers, pricing)
- Product app (authenticated users managing their org's inventory)
- Sales marketing site (public, unauthenticated)

**Tech stack**:
- **Backend**: .NET 10, Clean Architecture (Domain/Application/Infrastructure/Hosts)
- **Frontend**: Vue 3 + Vite + TypeScript (Naive UI components)
- **Database**: PostgreSQL with Row-Level Security (RLS) for tenant isolation
- **Messaging**: Azure Storage Queues + outbox pattern
- **Infrastructure**: Azure Container Apps, Front Door, Key Vault, Redis, Monitor
- **Auth**: Entra ID (admin staff), OIDC (product users, provider TBD)

---

## Critical Business Logic — Protect These

### 1. **Inventory Movements** (Core domain)

**What it is**: Every change to item quantity is recorded as an immutable movement record.

**Rules**:
- **No negative stock**: CHECK constraint on `items.quantity >= 0`
- **Audit trail**: Every movement (stock_in, stock_out, adjustment, sale, return, loss) is logged with:
  - quantity_before, quantity_after (captures state at time of change)
  - user_id, timestamp (who/when)
  - reference_id (PO number, invoice, etc.)
- **Reorder triggers**: When quantity drops below `reorder_level`, background job should flag for reorder
- **Automatic PO generation**: Planned — when low-stock threshold hit, create a purchase order

**Never**:
- Query inventory without checking org_id context
- Update item quantity directly without creating a movement record
- Bypass the movement audit trail (e.g., raw SQL UPDATE on items.quantity)
- Allow movements to be deleted or modified after creation (append-only log)

### 2. **Tenant Isolation** (Security boundary)

**What it is**: Multi-tenant data isolation at three layers: (1) subdomain resolution, (2) application context, (3) PostgreSQL RLS.

**Rules**:
- **Tenant resolution**: Identified by subdomain (`<tenantSlug>.<rootDomain>`)
- **org_id in every query**: Every table with tenant data has `org_id` column. **Every SELECT/INSERT/UPDATE/DELETE must filter by org_id.**
- **Never trust client org_id**: Always validate org_id from the authenticated session context
- **RLS enforcement**: PostgreSQL RLS policies bind to `app.tenant_id` setting. Connection pool must set/reset correctly.
- **Catalog DB** (control plane): stores tenant registry, routing, tier metadata
- **Tenant DB** (data plane): shared DB with RLS, or dedicated DB per isolated-tier tenant

**Never**:
- Query without org_id validation (infrastructure layer must enforce this)
- Bypass RLS by disabling it locally or in migrations
- Return tenant-scoped data without checking org_id context
- Store hard-coded org_ids in code; always resolve from request context

### 3. **Audit Reporting** (Compliance)

**What it is**: Immutable, tamper-evident records of all inventory movements and admin actions for audit compliance.

**Rules**:
- Movement records are append-only (no deletes after creation)
- Audit reports must include user, timestamp, action, before/after state
- Super-admin can view audit reports across all customers
- Product users can view movement history for their own org

**Never**:
- Allow tenants to see other orgs' movement history
- Expose audit logs in the product UI without filtering by org_id

### 4. **Authentication & Authorization** (Separate schemes)

**What it is**: Two distinct auth boundaries to prevent token confusion.

**Admin auth (Entra ID)**:
- Super-admin staff logs in via corporate Entra ID
- Can access admin.yourdomain.com, manage all customers/features/audits
- Must have super_admin role (super_admin_only policy)

**Product auth (OIDC, not yet implemented)**:
- Tenant users log in via OIDC (provider TBD: Auth0, Okta, etc.)
- Can access app.yourdomain.com, manage their org's inventory
- Scoped to their org_id (enforced by RLS and application context)

**Never**:
- Accept admin tokens (Entra ID) on product routes
- Accept product tokens on admin routes
- Confuse product user role (viewer, member, admin, owner) with super_admin role

---

## Current Implementation Status

### ✅ Complete/Stable
- `.NET API skeleton` (endpoints, DI, health checks)
- `Database schema` (items, movements, categories, suppliers, org_members, feature_flags)
- `Clean Architecture layers` (Domain/Application/Infrastructure)
- `Flyway migrations` (schema versioning, repeatable functions)
- `Azure IaC` (Bicep, Container Apps, Front Door, monitoring)
- `AdminUi scaffold` (Vue/Vite, routing, basic state management)

### 🔄 In Progress
- **Entra ID integration** (admin auth, ABAC policy evaluation, token validation)
- **AdminUi feature screens** (users, items, categories, feature flags, pricing tiers, audit reports)
- **Inventory movement endpoints** (create, list, filter by date range)

### 📋 Not Yet Started
- **OIDC provider selection** and integration (Auth0, Okta, etc.)
- **Product app UI** (Vite app for authenticated users)
- **Sales marketing site** (public Vite app, pricing, signup flow)
- **Worker background jobs** (reorder triggers, invoice generation, payment processing)
- **Comprehensive test coverage** (unit, integration, E2E)
- **Deployment automation** (blue/green, migrations, rollback)

---

## Architecture Patterns (Clean Architecture)

### Boundaries (dependencies flow inward)
```
Domain (pure, no infra)
  ↑
Application (use cases, validators, DTOs)
  ↑
Infrastructure (EF/Dapper, Azure SDK, HTTP clients)
  ↑
Hosts (Api/Worker/AdminUi composition roots)
```

### Rules
- **Domain** stays pure: no Entity Framework, no Azure SDK, no HTTP
- **Application** orchestrates domain + infrastructure
- **Infrastructure** adapts external services to application interfaces
- **Hosts** are thin: DI setup, middleware, endpoint routing

### Module organization
Every authored file must start with a module header (YAML comment). Example:

```csharp
// <--
// module: src.api.features.inventory.createMovement
// purpose: Handle creation of inventory movements with audit trail
// exports:
//   - handler: CreateMovementHandler
//   - dto: CreateMovementRequest
// --
```

See `docs/ai/module-headers.md` for full spec.

---

## Key Conventions

### 1. **org_id Validation**

**In the API**:
```csharp
// ✅ GOOD: Validate org_id from context
var orgId = httpContext.GetOrgId(); // from auth claims
var item = await db.Items
  .Where(i => i.OrgId == orgId && i.Id == itemId)
  .FirstOrDefaultAsync();

// ❌ BAD: Trust client org_id without validation
var item = await db.Items
  .Where(i => i.OrgId == request.OrgId) // request.OrgId is user-supplied!
  .FirstOrDefaultAsync();
```

**In the database**:
- RLS policy enforces `app.tenant_id` at the row level
- Always set `app.tenant_id` before tenant-scoped queries
- Connection pooling must reset `app.tenant_id` between requests

### 2. **Inventory Movement Audit Trail**

**Always create a movement record**, never update item quantity directly:
```csharp
// ✅ GOOD: Create movement record first
var movement = new InventoryMovement {
  OrgId = orgId,
  ItemId = itemId,
  UserId = userId,
  MovementType = "stock_out",
  Quantity = -5,
  QuantityBefore = item.Quantity,
  QuantityAfter = item.Quantity - 5,
  ReferenceId = salesOrderId,
  CreatedAt = DateTime.UtcNow,
};
await db.InventoryMovements.AddAsync(movement);

// Then update item quantity via domain logic
item.ReduceQuantity(5);
await db.SaveChangesAsync();

// ❌ BAD: Update quantity directly without movement record
item.Quantity -= 5;
await db.SaveChangesAsync();
```

### 3. **Feature Flags** (for beta features)

- Check feature flag in Application layer
- Feature flag is org-scoped (OrgFeatureFlag table)
- If flag not enabled, return 403 Forbidden or hide UI

### 4. **Tenancy Resolution**

Tenant is resolved early in the middleware pipeline:
1. Extract subdomain from Host header (`tenantSlug.yourdomain.com`)
2. Look up tenant in catalog DB
3. Validate tenant is active
4. Set `httpContext.Items["OrgId"]` for downstream use
5. Set RLS `app.tenant_id` before any tenant-scoped queries

### 5. **Background Jobs** (Worker service)

- Queue messages via Azure Storage Queues
- Use outbox pattern: write message + domain event in same transaction
- Idempotency key ensures safe retries
- Poison queue handling for dead-letter messages
- Worker runs in same Container App with API (separate replica)

---

## What You're Building Right Now (Priority Order)

### 1. **Admin UI Feature Screens** (HIGH PRIORITY)
- Users: list, add, edit, delete team members and super-admins
- Items: CRUD for inventory items, bulk import
- Categories: manage item categories
- Suppliers: manage supplier info
- Feature Flags: toggle features per org
- Pricing Tiers: manage subscription tiers and pricing
- Audit Reports: view movement history with filters (date, user, item, type)

**Implementation**:
- Use Naive UI components (already integrated in AdminUi)
- Fetch data from API endpoints (CRUD endpoints already scaffolded)
- Forms with validation on client + server
- Table views with sorting/filtering/pagination

### 2. **Entra ID Admin Auth** (HIGH PRIORITY)
- ✅ Graph API integration for super-admin user lookup
- 🔄 Token validation on API endpoints
- 🔄 ABAC policy evaluation (user → roles → permissions)
- 📋 AdminUi login flow (redirect to Entra ID, handle callback)

**Implementation**:
- Middleware to validate Entra ID bearer token
- Policy-based authorization on endpoints
- AdminUi: redirect to /login, handle callback, store token in secure cookie/storage

### 3. **Product App UI** (MEDIUM PRIORITY)
- New Vite app for authenticated product users
- Inventory dashboard (low stock alerts, recent movements)
- Item management (list, create, edit, adjust stock)
- Movement history
- Categories, suppliers

**Implementation**:
- Clone AdminUi structure, remove admin-specific features
- OIDC login flow (once provider selected)
- Share types/utils with AdminUi via monorepo

### 4. **Sales Marketing Site** (MEDIUM PRIORITY)
- Public landing page
- Pricing page
- Feature highlights
- Signup flow (collect email, plan choice)

**Implementation**:
- Separate Vite app
- No auth required
- Links to admin signup or login

### 5. **Inventory Movement Endpoints** (MEDIUM PRIORITY)
- `POST /api/movements` — create movement (stock_in, stock_out, adjustment, etc.)
- `GET /api/movements` — list with filters (date range, item, type, user)
- `GET /api/movements/{id}` — single movement detail
- Validate negative stock prevention at API level

### 6. **Testing Coverage** (HIGH PRIORITY, ongoing)
- Unit tests for domain logic (inventory calculations, reorder thresholds)
- Integration tests for endpoints (auth + org_id validation)
- E2E tests for critical paths (login, adjust stock, view audit trail)

### 7. **Deployment & CI/CD** (MEDIUM PRIORITY)
- Blue/green deployments for zero-downtime updates
- Database migrations as part of deployment
- Rollback strategy
- Secrets management (Key Vault integration)

---

## Anti-Patterns & Rules

### ❌ Never Do This

1. **Query without org_id validation**
   ```csharp
   // ❌ BAD
   var item = await db.Items.Where(i => i.Id == itemId).FirstOrDefaultAsync();
   ```

2. **Disable RLS or bypass row-level security**
   ```sql
   -- ❌ BAD
   ALTER TABLE items DISABLE ROW LEVEL SECURITY;
   ```

3. **Trust client-supplied org_id**
   ```csharp
   // ❌ BAD
   var orgId = request.OrgId; // from user input
   ```

4. **Update inventory quantity without movement record**
   ```csharp
   // ❌ BAD
   item.Quantity = newQuantity;
   await db.SaveChangesAsync();
   ```

5. **Delete or modify movement records after creation**
   ```csharp
   // ❌ BAD
   db.InventoryMovements.Remove(movement);
   await db.SaveChangesAsync();
   ```

6. **Mix admin and product auth schemes**
   ```csharp
   // ❌ BAD
   if (user.HasRole("admin")) { /* allow on product route */ }
   // ❌ BAD
   if (user.HasRole("super_admin")) { /* allow on product route */ }
   ```

7. **Hardcode org_ids or tenant assumptions**
   ```csharp
   // ❌ BAD
   var orgId = new Guid("00000000-0000-0000-0000-000000000001");
   ```

### ✅ Do This Instead

1. **Always validate org_id from context**
   ```csharp
   // ✅ GOOD
   var orgId = httpContext.GetOrgId(); // from claims
   var item = await db.Items.Where(i => i.OrgId == orgId && i.Id == itemId).FirstOrDefaultAsync();
   ```

2. **Ensure RLS is enabled and policies are correct**
   ```sql
   -- ✅ GOOD
   ALTER TABLE items ENABLE ROW LEVEL SECURITY;
   ALTER TABLE items FORCE ROW LEVEL SECURITY;
   ```

3. **Validate org_id from authenticated session**
   ```csharp
   // ✅ GOOD
   var orgId = httpContext.GetOrgIdFromClaims(); // from JWT/session
   var item = await db.Items.Where(i => i.OrgId == orgId && i.Id == itemId).FirstOrDefaultAsync();
   ```

4. **Always create movement record for inventory changes**
   ```csharp
   // ✅ GOOD
   var movement = InventoryMovement.Create(orgId, itemId, userId, "stock_out", -5, refId);
   await db.InventoryMovements.AddAsync(movement);
   item.ReduceQuantity(5);
   await db.SaveChangesAsync();
   ```

5. **Treat movement records as append-only**
   ```csharp
   // ✅ GOOD: Read-only after creation
   var movement = await db.InventoryMovements.Where(m => m.Id == id && m.OrgId == orgId).FirstOrDefaultAsync();
   // Never delete or modify
   ```

6. **Keep auth schemes separate**
   ```csharp
   // ✅ GOOD: Separate policies
   app.MapAdminEndpoints().RequirePolicy("AdminOnly"); // Entra ID
   app.MapProductEndpoints().RequirePolicy("ProductUser"); // OIDC
   ```

7. **Always resolve org_id from context**
   ```csharp
   // ✅ GOOD
   var orgId = httpContext.Items["OrgId"]; // from middleware
   ```

---

## Where to Find Documentation

- **Architecture overview**: `docs/architecture/README.md`
- **Key decisions (ADRs)**: `docs/adr/` (0001–0005 cover database, tenancy, auth, messaging, routing)
- **Repo orientation**: `docs/ai/repo-map.md`
- **Module header spec**: `docs/ai/module-headers.md`
- **Data access conventions**: `docs/architecture/data-access-dapper.md`
- **Tenant safety guardrails**: `docs/architecture/tenant-safety-guardrails.md`

---

## When to Ask for Help

### Ask me to decide:
- Architecture or design questions (should this be sync or async? cache strategy?)
- Trade-off decisions (simplicity vs performance? cost vs features?)
- Direction on features not yet started (how should signup flow work?)
- Breaking changes (rename module? restructure directory?)
- Multi-file refactoring or major rebuilds

### You can decide independently:
- Adding features within existing domains (new movement type, new item field)
- UI improvements and bug fixes
- Implementing endpoints that follow the established pattern
- Test coverage and quality improvements
- Documentation and comments
- Performance optimizations within the architecture

### Red flags (always ask before coding):
- Any change to auth boundaries or tenant isolation logic
- Modifying inventory movement audit trail logic
- Changes to RLS policies or tenant resolution
- Adding new authentication schemes
- Major schema changes

---

## Technical Debt & Known Gaps

- [ ] OIDC provider not yet selected (Auth0 vs Okta vs others?)
- [ ] Worker background jobs not yet implemented
- [ ] Product app UI not yet started
- [ ] Sales marketing site not yet started
- [ ] Comprehensive E2E test coverage missing
- [ ] Deployment automation (blue/green, rollback) TBD
- [ ] AdminUi feature screens ~70% complete

---

## Useful Commands

```bash
# Run tests (unit + integration)
dotnet test

# Run specific test class
dotnet test --filter "ClassName=MyClass"

# Database migrations (Flyway)
./scripts/infra/migrate.sh

# Local development (Aspire)
dotnet run --project tools/AppHost

# Docker build (API)
docker build -f src/Api/Dockerfile -t myapp:latest .

# Deploy to Azure (requires bicep + logged-in Azure CLI)
./scripts/infra/deploy.sh
```

---

## Summary for Claude

This is an **actively-built SaaS template** with real business logic around inventory movements, tenant isolation, and audit trails. You're helping expand the Admin UI, integrate Entra ID auth, build two new product UIs, and improve test coverage.

**Core guardrails**:
- ✅ Validate org_id from authenticated context in every query
- ✅ Never bypass RLS or tenant isolation
- ✅ Create movement records for all inventory changes (audit trail)
- ✅ Keep admin and product auth schemes separate
- ✅ Treat movement records as immutable (append-only)

**Current focus**: AdminUi completion → product app → sales site → testing/deployment.

Ask me about design decisions, architectural direction, or breaking changes. Implement features, bug fixes, and test coverage independently.

