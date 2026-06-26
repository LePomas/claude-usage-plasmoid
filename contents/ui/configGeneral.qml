import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kquickcontrols as KQuickControls

Kirigami.FormLayout {
    property alias cfg_refreshMinutes: refresh.value
    property alias cfg_showCountdown: countdown.checked
    property alias cfg_barStyle: barStyle.currentIndex
    property alias cfg_useSystemTheme: systemTheme.checked
    property alias cfg_bgColor: bgColor.color
    property alias cfg_cornerRadius: radius.value
    property alias cfg_enableShadow: shadow.checked

    QQC2.SpinBox {
        id: refresh
        Kirigami.FormData.label: i18n("Refresh every (minutes):")
        from: 1
        to: 120
    }

    QQC2.CheckBox {
        id: countdown
        Kirigami.FormData.label: i18n("Reset display:")
        text: i18n("Show time left until reset")
    }

    QQC2.ComboBox {
        id: barStyle
        Kirigami.FormData.label: i18n("Bar color:")
        model: [i18n("Follow system"), i18n("Claude")]
    }

    Item { Kirigami.FormData.isSection: true }

    QQC2.CheckBox {
        id: systemTheme
        Kirigami.FormData.label: i18n("Background:")
        text: i18n("Follow system theme")
    }

    KQuickControls.ColorButton {
        id: bgColor
        Kirigami.FormData.label: i18n("Solid color:")
        enabled: !systemTheme.checked
        showAlphaChannel: true
    }

    QQC2.SpinBox {
        id: radius
        Kirigami.FormData.label: i18n("Corner radius:")
        from: 0
        to: 40
        enabled: !systemTheme.checked
    }

    QQC2.CheckBox {
        id: shadow
        Kirigami.FormData.label: i18n("Shadow:")
        text: i18n("Enable shadow")
        enabled: !systemTheme.checked
    }
}
