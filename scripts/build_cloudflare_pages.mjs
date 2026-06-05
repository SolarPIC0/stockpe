import { rm, mkdir, copyFile, writeFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = dirname(fileURLToPath(import.meta.url));
const root = dirname(scriptDir);
const out = join(root, "cloudflare-pages");
const toolsOut = join(out, "tools");

await rm(out, { recursive: true, force: true });
await mkdir(toolsOut, { recursive: true });

await copyFile(join(root, "index.html"), join(out, "index.html"));
await copyFile(join(root, "tools", "index.html"), join(toolsOut, "index.html"));
await copyFile(join(root, "tools", "pe_price_slider.html"), join(toolsOut, "pe_price_slider.html"));

await writeFile(join(out, "_headers"), `/*
  X-Content-Type-Options: nosniff

/index.html
  Cache-Control: no-store

/tools/index.html
  Cache-Control: no-store

/tools/pe_price_slider.html
  Cache-Control: no-store
`, "utf8");

console.log(`Cloudflare Pages output ready: ${out}`);
