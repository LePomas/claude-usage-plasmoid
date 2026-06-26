import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    property var limits: []
    property string errorText: ""
    property bool loaded: false
    property int tick: 0   // bumped each minute so countdowns re-evaluate

    readonly property bool useSystemTheme: Plasmoid.configuration.useSystemTheme
    readonly property color bgColor: Plasmoid.configuration.bgColor
    readonly property int cornerRadius: Plasmoid.configuration.cornerRadius
    readonly property bool enableShadow: Plasmoid.configuration.enableShadow
    readonly property int barStyle: Plasmoid.configuration.barStyle
    readonly property bool showCountdown: Plasmoid.configuration.showCountdown
    readonly property color claudeColor: "#D97757"

    // text legible on the chosen solid background (or theme default)
    readonly property color fgColor: useSystemTheme ? Kirigami.Theme.textColor
        : ((0.299 * bgColor.r + 0.587 * bgColor.g + 0.114 * bgColor.b) > 0.5 ? "#000000" : "#ffffff")

    Plasmoid.busy: !loaded && errorText === ""
    Plasmoid.backgroundHints: useSystemTheme ? PlasmaCore.Types.DefaultBackground
                                             : PlasmaCore.Types.NoBackground
    toolTipMainText: i18n("Claude usage")
    toolTipSubText: errorText !== "" ? i18n("Error: %1", errorText)
                                     : limits.map(function (l) {
                                           return root.kindLabel(l.kind) + ": " + (100 - l.percent) + "% left";
                                       }).join("\n")

    function kindLabel(kind) {
        switch (kind) {
        case "session": return i18n("Session (5h)");
        case "weekly_all": return i18n("Weekly");
        case "weekly_opus": return i18n("Weekly · Opus");
        case "weekly_sonnet": return i18n("Weekly · Sonnet");
        default: return kind;
        }
    }

    function shortLabel(kind) {
        return kind === "session" ? "5h" : "7d";
    }

    function fmtReset(iso) {
        var d = new Date(iso);
        if (isNaN(d.getTime())) return "";
        var now = new Date();
        var t = d.toLocaleTimeString(Qt.locale(), "hh:mm");
        if (d.toDateString() === now.toDateString())
            return i18n("resets %1", t);
        return i18n("resets %1 %2", d.toLocaleDateString(Qt.locale(), "ddd"), t);
    }

    function fmtCountdown(iso) {
        var ms = new Date(iso).getTime() - Date.now();
        if (isNaN(ms)) return "";
        if (ms <= 0) return i18n("resetting…");
        var m = Math.floor(ms / 60000);
        var h = Math.floor(m / 60);
        m = m % 60;
        return h > 0 ? i18n("%1h %2m left", h, m) : i18n("%1m left", m);
    }

    function resetText(iso) {
        var base = fmtReset(iso);
        if (!showCountdown) return base;
        var c = fmtCountdown(iso);
        return c ? base + " · " + c : base;
    }

    function colorFor(severity) {
        return severity === "normal" ? fgColor : Kirigami.Theme.negativeTextColor;
    }

    function barColor(severity) {
        if (severity !== "normal") return Kirigami.Theme.negativeTextColor;
        return barStyle === 1 ? claudeColor : Kirigami.Theme.highlightColor;
    }

    P5Support.DataSource {
        id: usage
        engine: "executable"
        connectedSources: []
        onNewData: function (source, data) {
            disconnectSource(source);
            var out = ((data["stdout"] || "") + "").trim();
            try {
                var j = JSON.parse(out);
                if (j.error) {
                    root.errorText = j.error;
                    root.limits = [];
                } else {
                    root.errorText = "";
                    root.limits = j.limits || [];
                }
            } catch (e) {
                root.errorText = i18n("bad output");
                root.limits = [];
            }
            root.loaded = true;
        }
        // bundled script — self-contained so it works when installed from the KDE Store.
        // Call via bash (script uses bashisms) and don't rely on the exec bit (zip drops it).
        function refresh() {
            var p = Qt.resolvedUrl("../scripts/claude-usage").toString().replace("file://", "");
            connectSource('bash "' + p + '"');
        }
    }

    Timer {
        interval: Math.max(1, Plasmoid.configuration.refreshMinutes) * 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: usage.refresh()
    }

    Timer {
        interval: 60000
        running: root.showCountdown
        repeat: true
        onTriggered: root.tick++
    }

    compactRepresentation: MouseArea {
        Layout.minimumWidth: compactRow.implicitWidth + Kirigami.Units.smallSpacing * 2
        onClicked: root.expanded = !root.expanded

        RowLayout {
            id: compactRow
            anchors.centerIn: parent
            spacing: Kirigami.Units.largeSpacing

            Repeater {
                model: root.limits
                PlasmaComponents.Label {
                    text: root.shortLabel(modelData.kind) + " " + (100 - modelData.percent) + "%"
                    color: modelData.severity === "normal" ? Kirigami.Theme.textColor
                                                           : Kirigami.Theme.negativeTextColor
                }
            }
            PlasmaComponents.Label {
                visible: root.errorText !== "" || (root.loaded && root.limits.length === 0)
                text: root.errorText !== "" ? "!" : "—"
                color: Kirigami.Theme.negativeTextColor
            }
        }
    }

    fullRepresentation: Item {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 15
        Layout.minimumHeight: Kirigami.Units.gridUnit * 8

        // stock-monitor-style card: solid color + rounded corners + shadow
        Kirigami.ShadowedRectangle {
            anchors.fill: parent
            visible: !root.useSystemTheme
            color: root.bgColor
            radius: root.cornerRadius
            shadow.size: root.enableShadow ? Kirigami.Units.gridUnit : 0
            shadow.yOffset: root.enableShadow ? 3 : 0
            shadow.color: Qt.rgba(0, 0, 0, 0.45)
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Heading {
                text: i18n("Claude usage")
                level: 3
                color: root.fgColor
            }

            PlasmaComponents.Label {
                visible: root.errorText !== ""
                text: i18n("Error: %1", root.errorText)
                color: Kirigami.Theme.negativeTextColor
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            Repeater {
                model: root.limits
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    RowLayout {
                        Layout.fillWidth: true
                        PlasmaComponents.Label {
                            text: root.kindLabel(modelData.kind)
                            color: root.fgColor
                            Layout.fillWidth: true
                        }
                        PlasmaComponents.Label {
                            text: i18n("%1% left", 100 - modelData.percent)
                            font.bold: true
                            color: root.barColor(modelData.severity)
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.topMargin: Kirigami.Units.smallSpacing / 2
                        Layout.bottomMargin: Kirigami.Units.smallSpacing / 2
                        implicitHeight: Kirigami.Units.gridUnit * 0.4
                        radius: height / 2
                        color: Qt.rgba(root.fgColor.r, root.fgColor.g, root.fgColor.b, 0.15)

                        Rectangle {
                            width: parent.width * Math.max(0, 100 - modelData.percent) / 100
                            height: parent.height
                            radius: height / 2
                            color: root.barColor(modelData.severity)
                        }
                    }

                    PlasmaComponents.Label {
                        text: (root.tick, root.resetText(modelData.resets_at))
                        color: root.fgColor
                        opacity: 0.7
                        font: Kirigami.Theme.smallFont
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }
    }
}
