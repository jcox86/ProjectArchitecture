/*
module: src.adminUi.tests.smoke
purpose: Verify the admin UI test runner is wired correctly.
exports:
  - test: smoke
patterns:
  - vitest
*/
import { describe, expect, it } from "vitest";

describe("smoke", () => {
  it("runs", () => {
    expect(true).toBe(true);
  });
});
