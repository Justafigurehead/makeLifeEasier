// Claude Code status line: reads the session JSON on stdin, prints one cute line.
// Node (not PowerShell) so startup is fast and there is no jq dependency; this runs on every refresh.
const { execFileSync } = require("child_process");
const path = require("path");

// 256-colour codes chosen to stay readable on the light theme as well as dark ones.
const c = (code, text) => `\x1b[38;5;${code}m${text}\x1b[0m`;
const PINK = 169, PURPLE = 98, TEAL = 30, GREEN = 71, AMBER = 172, RED = 160, GREY = 244;

// Hearts instead of blocks keeps it cute; colour shifts as the context window fills up.
function bar(pct) {
  const total = 8;
  const filled = Math.min(total, Math.round((pct / 100) * total));
  const colour = pct >= 85 ? RED : pct >= 60 ? AMBER : GREEN;
  return c(colour, "♥".repeat(filled)) + c(GREY, "♡".repeat(total - filled));
}

function gitBranch(cwd) {
  try {
    // --no-optional-locks so a refresh never contends with the user's own git commands.
    return execFileSync("git", ["--no-optional-locks", "rev-parse", "--abbrev-ref", "HEAD"], {
      cwd,
      encoding: "utf8",
      stdio: ["ignore", "pipe", "ignore"],
      timeout: 1000,
    }).trim();
  } catch {
    return null; // not a repo, or git missing: just omit the segment
  }
}

let raw = "";
process.stdin.on("data", (chunk) => (raw += chunk));
process.stdin.on("end", () => {
  let input = {};
  try {
    input = JSON.parse(raw);
  } catch {
    // Malformed input should degrade to a minimal line rather than break the UI.
  }

  const cwd = input.workspace?.current_dir ?? input.cwd ?? process.cwd();
  const parts = [];

  parts.push(c(PINK, `✿ ${input.model?.display_name ?? "Claude"}`));
  parts.push(c(PURPLE, `📁 ${path.basename(cwd)}`));

  const branch = gitBranch(cwd);
  if (branch) parts.push(c(TEAL, `🌿 ${branch}`));

  const ctx = input.context_window?.used_percentage;
  if (typeof ctx === "number") parts.push(`${bar(ctx)} ${c(GREY, `${Math.round(ctx)}%`)}`);

  const fiveHour = input.rate_limits?.five_hour?.used_percentage;
  if (typeof fiveHour === "number") parts.push(c(AMBER, `⏳ ${Math.round(fiveHour)}%`));

  process.stdout.write(parts.join(c(GREY, "  ·  ")));
});
