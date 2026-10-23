// Merges the master copy's hooks into a project's .claude/settings.json (scripts/sync.sh runs it).
// Usage: SYNCED="<synced paths, one per line>" node scripts/sync-settings.mjs <master settings> <project settings>
// SYNCED holds the current synced paths and those of the last sync, so a hook the master copy dropped goes too.
// Keeps every project key and every project hook; a hook whose command runs a synced file is replaced by the
// master copy's hooks, which come first in each event.
import fs from "node:fs";

const [src, dst] = process.argv.slice(2);
const synced = new Set((process.env.SYNCED || "").split("\n").filter(Boolean));
const master = JSON.parse(fs.readFileSync(src, "utf8"));
let proj = {};
if (fs.existsSync(dst)) proj = JSON.parse(fs.readFileSync(dst, "utf8"));

const runsSynced = (h) => {
  const m = (h.command || "").match(/\$\{?CLAUDE_PROJECT_DIR\}?"?\/([^"\s]+)/);
  return Boolean(m && synced.has(m[1]));
};

const hooks = {};
for (const [event, groups] of Object.entries(master.hooks || {})) hooks[event] = [...groups];
for (const [event, groups] of Object.entries(proj.hooks || {})) {
  const kept = groups
    .map((g) => ({ ...g, hooks: (g.hooks || []).filter((h) => !runsSynced(h)) }))
    .filter((g) => g.hooks.length);
  if (kept.length) hooks[event] = [...(hooks[event] || []), ...kept];
}
proj.hooks = hooks;
fs.writeFileSync(dst, JSON.stringify(proj, null, 2) + "\n");
