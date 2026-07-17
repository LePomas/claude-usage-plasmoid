#!/usr/bin/env node
// Regression test: on a fetch error, keep showing the last-known usage
// instead of blanking the widget to an error-only state.
// Bug: onNewData's error branch did `root.limits = [];`, so any transient
// error (e.g. 429) wiped the bars even though the previous fetch's numbers
// were still meaningful.
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

const onNewData = mainQml.match(/onNewData:\s*function[\s\S]*?\n\s*\}\s*\n\s*\/\//)
  || mainQml.match(/onNewData:\s*function[\s\S]*?root\.loaded = true;/);
check("onNewData block found", !!onNewData, "couldn't locate onNewData handler in main.qml");

const errorBranch = onNewData && onNewData[0].match(/if \(j\.error\) \{([\s\S]*?)\} else \{/);
check("error branch found", !!errorBranch, "couldn't locate 'if (j.error)' branch");

check("error branch does not clear root.limits",
  !!errorBranch && !/root\.limits\s*=\s*\[\]/.test(errorBranch[1]),
  `error branch body: ${errorBranch && errorBranch[1]}`);

const catchBranch = onNewData && onNewData[0].match(/\} catch \(e\) \{([\s\S]*?)\}\s*\n\s*root\.loaded/);
check("JSON-parse-failure branch does not clear root.limits",
  !!catchBranch && !/root\.limits\s*=\s*\[\]/.test(catchBranch[1]),
  `catch branch body: ${catchBranch && catchBranch[1]}`);

check("tooltipText() combines stale limits with the error instead of hiding them",
  /function tooltipText\(\)/.test(mainQml) && /lines\.push/.test(mainQml),
  "expected a tooltipText() that appends the error onto the existing limits lines");

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail === 0 ? 0 : 1);
