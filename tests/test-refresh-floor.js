#!/usr/bin/env node
// Regression test: refreshMinutes floor.
// Bug: SpinBox from:1 + Timer clamp Math.max(1,...) let users set 1-minute
// polling against the undocumented usage endpoint, which then rate-limits
// the token for ~20min (429, retry-after ~1372s). Floor must stay >=5.
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
const configQml = fs.readFileSync(path.join(root, "contents", "ui", "configGeneral.qml"), "utf8");
const mainXml = fs.readFileSync(path.join(root, "contents", "config", "main.xml"), "utf8");

const timerClamp = mainQml.match(/Math\.max\((\d+),\s*Plasmoid\.configuration\.refreshMinutes\)/);
check("Timer clamps refreshMinutes to >=5", !!timerClamp && Number(timerClamp[1]) >= 5,
  `got clamp floor: ${timerClamp && timerClamp[1]}`);

const spinboxFrom = configQml.match(/QQC2\.SpinBox\s*\{\s*id:\s*refresh[\s\S]*?from:\s*(\d+)/);
check("SpinBox 'from' is >=5", !!spinboxFrom && Number(spinboxFrom[1]) >= 5,
  `got from: ${spinboxFrom && spinboxFrom[1]}`);

const kcfgMin = mainXml.match(/<entry name="refreshMinutes"[^>]*>[\s\S]*?<min>(\d+)<\/min>/);
check("kcfg refreshMinutes has min >=5", !!kcfgMin && Number(kcfgMin[1]) >= 5,
  `got min: ${kcfgMin && kcfgMin[1]}`);

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail === 0 ? 0 : 1);
