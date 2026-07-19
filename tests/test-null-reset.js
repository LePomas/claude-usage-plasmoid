#!/usr/bin/env node
// Regression test: weekly_scoped buckets for an unused model (e.g. Fable)
// come back with resets_at: null and is_active: false. `new Date(null)`
// is NOT NaN -- it's the epoch, always in the past -- so fmtCountdown's
// `ms <= 0` check fired every tick and the widget showed "resetting..."
// forever for a bucket that never even started.
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

const mainQml = fs.readFileSync(
  path.join(__dirname, "..", "contents", "ui", "main.qml"), "utf8"
);

const fmtReset = mainQml.match(/function fmtReset\(iso\) \{([\s\S]*?)\n    \}/);
check("fmtReset found", !!fmtReset, "couldn't locate fmtReset()");
check("fmtReset guards a falsy iso before constructing Date",
  !!fmtReset && /if\s*\(!iso\)\s*return/.test(fmtReset[1]),
  `fmtReset body: ${fmtReset && fmtReset[1]}`);

const fmtCountdown = mainQml.match(/function fmtCountdown\(iso\) \{([\s\S]*?)\n    \}/);
check("fmtCountdown found", !!fmtCountdown, "couldn't locate fmtCountdown()");
check("fmtCountdown guards a falsy iso before constructing Date",
  !!fmtCountdown && /if\s*\(!iso\)\s*return/.test(fmtCountdown[1]),
  `fmtCountdown body: ${fmtCountdown && fmtCountdown[1]}`);

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail === 0 ? 0 : 1);
