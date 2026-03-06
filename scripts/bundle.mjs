import { readFileSync, writeFileSync, mkdirSync, rmSync } from "node:fs";
import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const root = resolve(__dirname, "..");
const source = resolve(root, "_build/js/debug/build/cmd/main/main.js");
const distDir = resolve(root, "dist");
const dest = resolve(distDir, "cli.mjs");

// Clean and create dist/
rmSync(distDir, { recursive: true, force: true });
mkdirSync(distDir, { recursive: true });

// Read source, prepend shebang, write to dist/
const code = readFileSync(source, "utf-8");
writeFileSync(dest, `#!/usr/bin/env node\n${code}`, { mode: 0o755 });

console.log(`Bundled ${dest}`);
