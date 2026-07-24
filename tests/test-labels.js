#!/usr/bin/env node
// Regression tests for contents/ui/labels.js.
// Bug: API added kind "weekly_scoped" (a per-model weekly bucket, e.g. scope.model.display_name)
// which had no switch case, so the raw enum leaked into the widget as-is.
const path = require("path");
const { kindLabel, shortLabel, fmtCredits, fmtCreditsShort } = require(path.join(__dirname, "..", "contents", "ui", "labels.js"));

let pass = 0, fail = 0;
function check(name, got, want) {
  if (got === want) {
    console.log(`PASS: ${name}`); pass++;
  } else {
    console.log(`FAIL: ${name}\n  want: ${want}\n  got:  ${got}`); fail++;
  }
}

check("session", kindLabel("session"), "Session (5h)");
check("weekly_all", kindLabel("weekly_all"), "Weekly");
check("weekly_opus", kindLabel("weekly_opus"), "Weekly · Opus");
check("weekly_sonnet", kindLabel("weekly_sonnet"), "Weekly · Sonnet");
check("weekly_scoped with model name", kindLabel("weekly_scoped", { model: { display_name: "Fable" } }), "Weekly · Fable");
check("weekly_scoped without scope", kindLabel("weekly_scoped", null), "Weekly (scoped)");
check("weekly_scoped with empty scope", kindLabel("weekly_scoped", { model: { display_name: null } }), "Weekly (scoped)");
check("unrecognized kind is humanized, not leaked raw", kindLabel("some_new_kind"), "Some New Kind");
check("shortLabel session", shortLabel("session"), "5h");
check("shortLabel weekly kinds", shortLabel("weekly_all"), "7d");
check("shortLabel weekly_scoped", shortLabel("weekly_scoped"), "7d");
check("credits label", kindLabel("credits"), "Usage Credits");
check("fmtCredits cents", fmtCredits(219, 10000, 2), "$2.19 / $100.00");
check("fmtCredits default exponent", fmtCredits(500, 1000), "$5.00 / $10.00");
check("fmtCreditsShort cents", fmtCreditsShort(219, 2), "$2.19");

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail === 0 ? 0 : 1);
