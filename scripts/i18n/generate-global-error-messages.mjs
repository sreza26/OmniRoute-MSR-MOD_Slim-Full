/**
 * Generates `src/i18n/global-error-messages/<locale>.json` files from the
 * locale message catalogs (`src/i18n/messages/<locale>.json`).
 *
 * The global error boundary cannot statically import the full locale catalog
 * (that would bundle every language into the initial HTML of every page), so
 * only the `publicSystem.globalError` slice is extracted and shipped per
 * locale. The dynamic loader in src/app/global-error.tsx fetches these files.
 */
import fs from "node:fs";
import path from "node:path";

function getPublicSystemGlobalError(messages, locale) {
  const publicSystem = messages?.publicSystem;
  if (!publicSystem || typeof publicSystem !== "object") {
    return null;
  }
  const globalError = publicSystem.globalError;
  if (!globalError || typeof globalError !== "object") {
    return null;
  }
  return { publicSystem: { globalError } };
}

export function generateGlobalErrorMessages(rootDir = process.cwd()) {
  const messagesDir = path.join(rootDir, "src", "i18n", "messages");
  const outDir = path.join(rootDir, "src", "i18n", "global-error-messages");

  if (!fs.existsSync(messagesDir)) {
    console.warn(`[generate-global-error-messages] messages directory not found: ${messagesDir}`);
    return { written: [], skipped: [] };
  }

  fs.mkdirSync(outDir, { recursive: true });

  const written = [];
  const skipped = [];

  for (const file of fs.readdirSync(messagesDir)) {
    if (!file.endsWith(".json")) continue;
    const locale = file.replace(/\.json$/, "");
    try {
      const raw = fs.readFileSync(path.join(messagesDir, file), "utf8");
      const messages = JSON.parse(raw);
      const slice = getPublicSystemGlobalError(messages, locale);
      if (!slice) {
        skipped.push(locale);
        continue;
      }
      fs.writeFileSync(path.join(outDir, `${locale}.json`), JSON.stringify(slice, null, 2) + "\n", "utf8");
      written.push(locale);
    } catch (err) {
      console.warn(`[generate-global-error-messages] failed for ${locale}:`, err);
      skipped.push(locale);
    }
  }

  console.log(`[generate-global-error-messages] wrote ${written.length} files${skipped.length ? `, skipped ${skipped.length}` : ""}`);
  return { written, skipped };
}

// Allow running directly: node scripts/i18n/generate-global-error-messages.mjs
if (process.argv[1] && import.meta.url === new URL(`file://${path.resolve(process.argv[1])}`).href) {
  generateGlobalErrorMessages(process.cwd());
}
