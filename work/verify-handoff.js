const fs = require("fs");
const path = require("path");

const root = "/Users/mac/Documents/Codex/2026-08-06/referenced-chatgpt-conversation-this-is-an";
const required = [
  "AGENTS.md",
  "CONTEXT.md",
  "docs/任务进程.md",
  "docs/决策日志.md",
  "docs/进度报告.md",
  "docs/superpowers/specs/2026-08-06-finder-quick-nav-design.md",
  "docs/superpowers/specs/2026-08-06-finder-quick-nav-interaction-design.md",
  "docs/superpowers/plans/2026-08-06-finder-quick-nav.md",
  "docs/superpowers/plans/2026-08-06-finder-quick-nav-interaction.md",
  "FinderQuickNav/docs/interaction-verification.md",
  "outputs/2026-08-06_Finder快速导航_DeepSeek交接.md",
  "outputs/finder-quicknav-prototypes/index.html",
  "outputs/finder-quicknav-prototypes/variant-c.html",
];

for (const file of required) {
  if (!fs.existsSync(path.join(root, file))) throw new Error(`missing ${file}`);
}

for (const file of ["index.html", "variant-a.html", "variant-b.html", "variant-c.html"]) {
  const work = fs.readFileSync(path.join(root, "work/prototypes", file));
  const output = fs.readFileSync(path.join(root, "outputs/finder-quicknav-prototypes", file));
  if (!work.equals(output)) throw new Error(`prototype copy differs ${file}`);
  const html = work.toString("utf8");
  for (const match of html.matchAll(/<script>([\s\S]*?)<\/script>/g)) new Function(match[1]);
}

const spec = fs.readFileSync(
  path.join(root, "docs/superpowers/specs/2026-08-06-finder-quick-nav-design.md"),
  "utf8",
);
for (const phrase of [
  "contextualMenuForContainer",
  "292 × 286 pt",
  "新建文件",
  "当前 Finder 窗口",
  "NSExtensionContext.open",
]) {
  if (!spec.includes(phrase)) throw new Error(`spec missing ${phrase}`);
}

const plan = fs.readFileSync(
  path.join(root, "docs/superpowers/plans/2026-08-06-finder-quick-nav.md"),
  "utf8",
);
for (let task = 1; task <= 9; task += 1) {
  if (!plan.includes(`### Task ${task}:`)) throw new Error(`plan missing task ${task}`);
}
if (/TBD|TODO|implement later|xcodebuild test \.\.\.|similar to/i.test(plan)) {
  throw new Error("plan contains placeholder");
}

const progress = fs.readFileSync(path.join(root, "docs/任务进程.md"), "utf8");
if (!progress.includes("直接执行：先读本文件和 `docs/interaction-verification.md`")) {
  throw new Error("missing next instruction");
}
if (!progress.includes("不要重做：A/B/C 比较")) throw new Error("missing do-not-redo");

for (const file of [
  "/Users/mac/Documents/Obsidian Vault/复盘报告/决策日志/2026-08-06_Finder快速导航/决策日志.md",
  "/Users/mac/Documents/Obsidian Vault/output/2026-08-06_Finder快速导航_进度报告.md",
]) {
  if (!fs.existsSync(file)) throw new Error(`missing Obsidian record ${file}`);
}

console.log(`VERIFY_OK files=${required.length} prototypes=4 planTasks=9`);
