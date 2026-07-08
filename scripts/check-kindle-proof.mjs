import { existsSync, mkdirSync, readFileSync } from "node:fs";
import { execFileSync } from "node:child_process";
import path from "node:path";

const volume = path.resolve(process.argv[2] || "/Volumes/Kindle");
const documentsDir = path.join(volume, "documents");
const proofLog = path.join(documentsDir, "kindle-dashboard-proof.log");
const nativeLog = path.join(documentsDir, "kindle-dashboard-native.log");
const diagnoseLog = path.join(documentsDir, "kindle-dashboard-diagnose.log");
const pgm = path.join(documentsDir, "kindle-dashboard-last-render.pgm");
const outDir = path.resolve("kindle/native/build");
const png = path.join(outDir, "kindle-dashboard-last-render.png");

function readIfPresent(file) {
  if (!existsSync(file)) return "";
  return readFileSync(file, "utf8");
}

function fail(message) {
  console.error(message);
  process.exit(1);
}

if (!existsSync(volume)) fail(`Kindle volume not found: ${volume}`);
if (!existsSync(pgm)) {
  fail([
    `Missing saved render: ${pgm}`,
    "Eject/unplug Kindle, run KUAL -> Kindle Dashboard -> Render Proof, then mount again."
  ].join("\n"));
}

const proofText = readIfPresent(proofLog);
const nativeText = readIfPresent(nativeLog);
const diagnoseText = readIfPresent(diagnoseLog);
const combined = [proofText, nativeText, diagnoseText].join("\n");

if (!/render=(framebuffer ok|fbink ok)/.test(combined)) {
  fail("Saved PGM exists, but logs do not prove framebuffer/fbink rendering succeeded.");
}

if (!/saved_pgm_bytes=|render=save-pgm /.test(combined)) {
  fail("Logs do not show the saved PGM was produced by the native renderer.");
}

mkdirSync(outDir, { recursive: true });
execFileSync("sips", ["-s", "format", "png", pgm, "--out", png], { stdio: "ignore" });

console.log(`Proof OK: ${pgm}`);
console.log(`Preview PNG: ${png}`);
