// Installs the cute status line: copies statusline.js into the Claude config dir and
// registers it as `statusLine` in settings.json. Usage: node install.js [--force]
const fs = require("fs");
const os = require("os");
const path = require("path");

const force = process.argv.includes("--force");

// Honour CLAUDE_CONFIG_DIR so people with a relocated config are not silently skipped.
const configDir = process.env.CLAUDE_CONFIG_DIR ?? path.join(os.homedir(), ".claude");
const settingsPath = path.join(configDir, "settings.json");
const targetScript = path.join(configDir, "statusline.js");

fs.mkdirSync(configDir, { recursive: true });

let settings = {};
if (fs.existsSync(settingsPath)) {
  try {
    settings = JSON.parse(fs.readFileSync(settingsPath, "utf8"));
  } catch (error) {
    // Never rewrite a file we could not parse: we would destroy the user's hooks and permissions.
    console.error(`Could not parse ${settingsPath}: ${error.message}. Nothing changed.`);
    process.exit(1);
  }
}

if (settings.statusLine && !force) {
  console.error(`A statusLine is already configured in ${settingsPath}. Re-run with --force to replace it.`);
  process.exit(1);
}

if (fs.existsSync(settingsPath)) {
  fs.copyFileSync(settingsPath, `${settingsPath}.bak`);
}
fs.copyFileSync(path.join(__dirname, "statusline.js"), targetScript);

// Absolute node path with forward slashes: works whether or not node is on the harness's PATH,
// and avoids backslash escaping problems inside the JSON command string.
const node = process.execPath.replace(/\\/g, "/");
const script = targetScript.replace(/\\/g, "/");
settings.statusLine = { type: "command", command: `"${node}" "${script}"` };

fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2) + "\n");
console.log(`Installed. Script: ${targetScript}\nSettings updated: ${settingsPath} (backup: settings.json.bak)`);
