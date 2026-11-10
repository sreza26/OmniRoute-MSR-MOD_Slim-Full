// Shim for backward compatibility: postinstall expects scripts/build/sync-env.mjs
// The canonical implementation lives at scripts/dev/sync-env.mjs
export * from "../dev/sync-env.mjs";
