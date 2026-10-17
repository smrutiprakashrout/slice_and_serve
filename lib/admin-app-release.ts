export interface AdminAppReleaseAsset {
  name: string;
  size: number;
  browser_download_url: string;
}

export interface AdminAppRelease {
  tag: string;
  versionName: string;
  buildNumber: number;
  publishedAt: string;
  releaseUrl: string;
  apk: {
    name: string;
    sizeBytes: number;
    downloadUrl: string;
  };
  checksumUrl: string | null;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function isAsset(value: unknown): value is AdminAppReleaseAsset {
  return (
    isRecord(value) &&
    typeof value.name === "string" &&
    typeof value.size === "number" &&
    typeof value.browser_download_url === "string"
  );
}

export function selectLatestAdminAppRelease(
  releases: unknown,
): AdminAppRelease | null {
  if (!Array.isArray(releases)) return null;

  const candidates = releases.flatMap((value): AdminAppRelease[] => {
    if (!isRecord(value) || value.draft === true || value.prerelease === true) {
      return [];
    }

    const tag = value.tag_name;
    const match = typeof tag === "string"
      ? /^admin-v([0-9]+\.[0-9]+\.[0-9]+)-b([0-9]+)$/.exec(tag)
      : null;
    const publishedAt = value.published_at;
    const releaseUrl = value.html_url;
    const timestamp = typeof publishedAt === "string" ? Date.parse(publishedAt) : NaN;

    if (
      !match ||
      !Number.isSafeInteger(Number(match[2])) ||
      typeof publishedAt !== "string" ||
      Number.isNaN(timestamp) ||
      typeof releaseUrl !== "string" ||
      !Array.isArray(value.assets)
    ) {
      return [];
    }

    const assets = value.assets.filter(isAsset);
    const apk = assets.find((asset) => asset.name.toLowerCase().endsWith(".apk"));
    if (!apk) return [];
    const checksum = assets.find((asset) => asset.name.toLowerCase().endsWith(".sha256"));

    return [{
      tag: tag as string,
      versionName: match[1],
      buildNumber: Number(match[2]),
      publishedAt,
      releaseUrl,
      apk: {
        name: apk.name,
        sizeBytes: apk.size,
        downloadUrl: apk.browser_download_url,
      },
      checksumUrl: checksum?.browser_download_url ?? null,
    }];
  });

  candidates.sort(
    (left, right) => Date.parse(right.publishedAt) - Date.parse(left.publishedAt),
  );
  return candidates[0] ?? null;
}

export function parseSha256(text: string): string | null {
  return text.match(/\b[0-9a-fA-F]{64}\b/)?.[0].toLowerCase() ?? null;
}
