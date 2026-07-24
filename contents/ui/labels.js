// Pure label-formatting logic for limits[].kind, kept framework-agnostic so
// it can be unit-tested with plain `node` (QML has no CI test runner).
function humanize(kind) {
    return kind.replace(/_/g, " ").replace(/\b\w/g, function (c) { return c.toUpperCase(); });
}

function kindLabel(kind, scope) {
    switch (kind) {
    case "session": return "Session (5h)";
    case "weekly_all": return "Weekly";
    case "weekly_opus": return "Weekly · Opus";
    case "weekly_sonnet": return "Weekly · Sonnet";
    case "weekly_scoped":
        var model = scope && scope.model && scope.model.display_name;
        return model ? "Weekly · " + model : "Weekly (scoped)";
    case "credits": return "Usage Credits";
    default: return humanize(kind);
    }
}

function shortLabel(kind) {
    return kind === "session" ? "5h" : "7d";
}

// spend.used/limit are { amount_minor, exponent } — exponent 2 means cents.
function fmtCredits(used_minor, limit_minor, exponent) {
    var div = Math.pow(10, exponent || 2);
    return "$" + (used_minor / div).toFixed(2) + " / $" + (limit_minor / div).toFixed(2);
}

// compact-panel chip: just the amount spent, no cap — keeps the chip short.
function fmtCreditsShort(used_minor, exponent) {
    var div = Math.pow(10, exponent || 2);
    return "$" + (used_minor / div).toFixed(2);
}

if (typeof module !== "undefined") {
    module.exports = {
        kindLabel: kindLabel, shortLabel: shortLabel, humanize: humanize,
        fmtCredits: fmtCredits, fmtCreditsShort: fmtCreditsShort
    };
}
