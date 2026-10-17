import { describe, expect, it } from "vitest";
import {
  parseSha256,
  selectLatestAdminAppRelease,
} from "@/lib/admin-app-release";

function release(overrides: Record<string, unknown> = {}) {
  return {
    tag_name: "admin-v1.2.3-b10",
    draft: false,
    prerelease: false,
    published_at: "2026-01-02T00:00:00Z",
    html_url: "https://github.com/example/release",
    assets: [
      {
        name: "admin.apk",
        size: 1234,
        browser_download_url: "https://example.com/admin.apk",
      },
      {
        name: "admin.apk.sha256",
        size: 80,
        browser_download_url: "https://example.com/admin.apk.sha256",
      },
    ],
    ...overrides,
  };
}

describe("admin app release selection", () => {
  it("selects the newest valid admin-v release and finds APK and checksum assets", () => {
    const selected = selectLatestAdminAppRelease([
      release({ tag_name: "admin-v1.2.2-b9", published_at: "2025-12-01T00:00:00Z" }),
      release({ tag_name: "admin-v1.2.4-b11", published_at: "2026-02-01T00:00:00Z" }),
      release({ tag_name: "admin-v9.0.0-b1", draft: true }),
      release({ tag_name: "admin-v8.0.0-b1", prerelease: true }),
      release({ tag_name: "web-v99.0.0-b1" }),
    ]);

    expect(selected).toMatchObject({
      tag: "admin-v1.2.4-b11",
      versionName: "1.2.4",
      buildNumber: 11,
      apk: {
        name: "admin.apk",
        sizeBytes: 1234,
        downloadUrl: "https://example.com/admin.apk",
      },
      checksumUrl: "https://example.com/admin.apk.sha256",
    });
  });

  it("returns null when there is no matching release", () => {
    expect(selectLatestAdminAppRelease([
      release({ tag_name: "web-v1.2.3-b10" }),
      release({ draft: true }),
      release({ prerelease: true }),
    ])).toBeNull();
  });

  it("allows a matching release without a checksum asset", () => {
    const selected = selectLatestAdminAppRelease([
      release({ assets: [release().assets[0]] }),
    ]);
    expect(selected?.checksumUrl).toBeNull();
    expect(parseSha256("checksum unavailable")).toBeNull();
  });

  it("extracts the first 64-character SHA-256 token", () => {
    const hash = "a".repeat(64);
    expect(parseSha256(`file  ${hash}  admin.apk`)).toBe(hash);
  });
});
