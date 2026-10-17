import {
  parseSha256,
  selectLatestAdminAppRelease,
} from "@/lib/admin-app-release";

export const revalidate = 300;

const RELEASES_URL =
  "https://api.github.com/repos/smrutiprakashrout/slice_and_serve/releases?per_page=30";
const HEADERS = {
  Accept: "application/vnd.github+json",
  "User-Agent": "slice-and-serve-admin-release-page",
};

export async function GET() {
  try {
    const response = await fetch(RELEASES_URL, {
      headers: HEADERS,
      next: { revalidate: 300 },
    });
    if (!response.ok) {
      return Response.json({ error: "GitHub release lookup failed." }, { status: 502 });
    }

    let releases: unknown;
    try {
      releases = await response.json();
    } catch {
      return Response.json({ error: "GitHub returned invalid release data." }, { status: 502 });
    }

    const release = selectLatestAdminAppRelease(releases);
    if (!release) {
      return Response.json({ error: "No admin app release was found." }, { status: 404 });
    }

    let sha256: string | null = null;
    if (release.checksumUrl) {
      try {
        const checksumResponse = await fetch(release.checksumUrl, {
          headers: HEADERS,
          next: { revalidate: 300 },
        });
        if (checksumResponse.ok) {
          sha256 = parseSha256(await checksumResponse.text());
        }
      } catch {
        // The checksum is optional; the release details remain useful without it.
      }
    }

    return Response.json({
      tag: release.tag,
      versionName: release.versionName,
      buildNumber: release.buildNumber,
      publishedAt: release.publishedAt,
      releaseUrl: release.releaseUrl,
      apk: release.apk,
      sha256,
    });
  } catch {
    return Response.json({ error: "GitHub release lookup failed." }, { status: 502 });
  }
}
