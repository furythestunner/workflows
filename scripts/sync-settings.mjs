// Merges the master copy's hooks and deny rules into a project's .claude/settings.json (scripts/sync.sh runs it).
// Usage: SYNCED="<synced paths, one per line>" OLD_MASTER="<master settings.json at the last sync>" \
//          node scripts/sync-settings.mjs <master settings> <project settings>
// SYNCED holds the current synced paths and those of the last sync, so a hook the master copy dropped goes too.
// Keeps every project key and every project hook; a hook whose command runs a synced file is replaced by the
// master copy's hooks, which come first in each event.
// permissions.deny: the master copy's rules come first, then the project's own. A rule the master copy had at the
// last sync (OLD_MASTER) but has no more goes too; every other project rule stays.
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

const denyOf = (s) => (Array.isArray(s?.permissions?.deny) ? s.permissions.deny : []);
let oldMaster = {};
try { oldMaster = JSON.parse(process.env.OLD_MASTER || "{}"); } catch {}  // unreadable: keep every project rule
const masterRules = new Set([...denyOf(master), ...denyOf(oldMaster)]);
const deny = [...new Set([...denyOf(master), ...denyOf(proj).filter((r) => !masterRules.has(r))])];
if (deny.length) proj.permissions = { ...(proj.permissions || {}), deny };
else if (proj.permissions) {
  delete proj.permissions.deny;
  if (!Object.keys(proj.permissions).length) delete proj.permissions;
}
fs.writeFileSync(dst, JSON.stringify(proj, null, 2) + "\n");
