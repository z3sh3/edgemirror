import { readdir } from "node:fs/promises";
import { dirname, join, relative } from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const ROOT = dirname(dirname(fileURLToPath(import.meta.url)));
const INCLUDE_DIRS = ["src", "scripts"];

const files = (
  await Promise.all(INCLUDE_DIRS.map((dir) => collectJavaScriptFiles(join(ROOT, dir))))
)
  .flat()
  .sort();

let failed = false;

for (const file of files) {
  const result = spawnSync(process.execPath, ["--check", file], {
    cwd: ROOT,
    encoding: "utf8",
  });

  if (result.status !== 0) {
    failed = true;
    process.stderr.write(result.stderr || result.stdout);
  } else {
    process.stdout.write(`ok ${relative(ROOT, file)}\n`);
  }
}

if (failed) {
  process.exit(1);
}

async function collectJavaScriptFiles(dir) {
  const entries = await readdir(dir, { withFileTypes: true });
  const files = await Promise.all(
    entries.map(async (entry) => {
      const path = join(dir, entry.name);
      if (entry.isDirectory()) {
        return collectJavaScriptFiles(path);
      }
      return entry.isFile() && /\.(?:mjs|js)$/.test(entry.name) ? [path] : [];
    }),
  );
  return files.flat();
}
