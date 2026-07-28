#!/usr/bin/env node
// Regression test: boot-race login-expired retry must repeat, not one-shot.
// Bug: a single retry at t=15s wasn't enough — network/PATH can still be
// unready 15s after Plasma login, so the widget fell through to a permanent
// error until the next 5-60min poll. Fix: repeat every 10s across a wider
// window (90s) until it clears or the window elapses.
const fs = require("fs");
const path = require("path");

let pass = 0, fail = 0;
function check(name, cond, detail) {
  if (cond) {
    console.log(`PASS: ${name}`); pass++;
  } else {
    console.log(`FAIL: ${name}\n  ${detail}`); fail++;
  }
}

const root = path.join(__dirname, "..");
const mainQml = fs.readFileSync(path.join(root, "contents", "ui", "main.qml"), "utf8");

const timerBlock = mainQml.match(/id:\s*bootRetryTimer[\s\S]*?\n    \}/);
check("bootRetryTimer block found", !!timerBlock, "bootRetryTimer id not found in main.qml");

check("bootRetryTimer repeats (not one-shot)",
  !!timerBlock && /repeat:\s*true/.test(timerBlock[0]),
  `timer block: ${timerBlock && timerBlock[0]}`);

const windowMatch = mainQml.match(/bootRetryWindowMs:\s*(\d+)/);
check("boot retry window is >=60s (wide enough to cover slow network/PATH init)",
  !!windowMatch && Number(windowMatch[1]) >= 60000,
  `got window: ${windowMatch && windowMatch[1]}`);

check("no leftover one-shot bootRetried flag",
  !/bootRetried/.test(mainQml),
  "found stale 'bootRetried' one-shot boolean — should be replaced by repeating timer");

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail === 0 ? 0 : 1);
