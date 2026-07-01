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
    default: return humanize(kind);
    }
}

function shortLabel(kind) {
    return kind === "session" ? "5h" : "7d";
}

if (typeof module !== "undefined") {
    module.exports = { kindLabel: kindLabel, shortLabel: shortLabel, humanize: humanize };
}
