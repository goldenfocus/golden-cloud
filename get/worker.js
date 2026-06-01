/**
 * get.goldenfocus.io — the install.sh gateway.
 *
 * Proxies `curl get.goldenfocus.io | bash` to the real install script in this
 * repo. Serves plain shellscript with a short cache so edits propagate quickly.
 *
 * Future paths (reserved):
 *   /           → startup-kit/install.sh
 *   /elite      → startup-kit/install.sh (alias)
 *   /raw/<path> → raw.githubusercontent.com/goldenfocus/golden-cloud/main/<path>
 */

const REPO = "goldenfocus/golden-cloud";
const BRANCH = "main";
const BASE = `https://raw.githubusercontent.com/${REPO}/${BRANCH}`;
const DEFAULT_SCRIPT = "/startup-kit/install.sh";

export default {
  async fetch(request) {
    const url = new URL(request.url);
    let target;

    if (url.pathname === "/" || url.pathname === "/elite" || url.pathname === "/kit") {
      target = `${BASE}${DEFAULT_SCRIPT}`;
    } else if (url.pathname.startsWith("/raw/")) {
      target = `${BASE}/${url.pathname.slice(5)}`;
    } else {
      // Any other path — try to resolve it in the repo root.
      target = `${BASE}${url.pathname}`;
    }

    const upstream = await fetch(target, {
      cf: { cacheTtl: 300, cacheEverything: true },
    });

    if (!upstream.ok) {
      return new Response(
        `# get.goldenfocus.io\n# upstream ${target} returned ${upstream.status}\n`,
        { status: upstream.status, headers: { "content-type": "text/plain; charset=utf-8" } }
      );
    }

    const isScript = target.endsWith(".sh") || target.endsWith(".bash");
    const contentType = isScript
      ? "text/x-shellscript; charset=utf-8"
      : (upstream.headers.get("content-type") || "text/plain; charset=utf-8");

    return new Response(upstream.body, {
      status: 200,
      headers: {
        "content-type": contentType,
        "cache-control": "public, max-age=300",
        "x-served-by": "get.goldenfocus.io",
        "x-source": target,
      },
    });
  },
};
