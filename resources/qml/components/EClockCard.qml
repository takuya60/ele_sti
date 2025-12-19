import QtQuick
import QtQuick.Controls
import QtQuick.Effects

Item {
    id: root
    width: 300
    height: 100

    // === 样式 ===
    property color faceColor: theme.secondaryColor
    property color textColor: theme.textColor
    property color accentColor: theme.focusColor
    property real radius: 26
    property bool backgroundVisible: true
    property bool shadowEnabled: true
    property color shadowColor: theme.shadowColor

    // === 时间与显示 ===
    property bool is24Hour: true
    property bool showSeconds: false
    property date now: new Date()

    function pad2(n) { return (n < 10 ? "0" : "") + n }
    function hourStr(d) {
        let h = d.getHours()
        if (!is24Hour) {
            h = h % 12
            if (h === 0) h = 12
        }
        return pad2(h)
    }
    function minuteStr(d) { return pad2(d.getMinutes()) }
    function secondStr(d) { return pad2(d.getSeconds()) }
    function weekdayZh(d) { return ["周日","周一","周二","周三","周四","周五","周六"][d.getDay()] }

    readonly property string dateLine: (now.getMonth()+1) + "月" + now.getDate() + "日 " + weekdayZh(now)

    // 每秒更新时间
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    // 阴影效果（只作用于背景卡片）
    MultiEffect {
        source: background
        anchors.fill: background
        visible: root.shadowEnabled && root.backgroundVisible
        shadowEnabled: true
        shadowColor: root.shadowColor
        shadowBlur: theme.shadowBlur
        shadowHorizontalOffset: theme.shadowXOffset
        shadowVerticalOffset: theme.shadowYOffset
    }

    // 背景卡片
    Rectangle {
        id: background
        anchors.fill: parent
        radius: root.radius
        color: faceColor
        visible: root.backgroundVisible
        antialiasing: true
    }

    // 内容布局
    Row {
        anchors.centerIn: parent
        spacing: 20 // 时间和日期的间距

        // 左侧：时间
        Row {
            id: timeRow
            spacing: 4
            anchors.verticalCenter: parent.verticalCenter

            Text {
                text: hourStr(now)
                color: accentColor
                font.pixelSize: 54
                font.bold: true
                verticalAlignment: Text.AlignVCenter
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: ":"
                color: theme.textColor
                font.pixelSize: 54
                font.bold: true
                verticalAlignment: Text.AlignVCenter
                anchors.verticalCenter: parent.verticalCenter
                // 让冒号微闪烁效果（可选，不喜欢可删掉 Animation）
                OpacityAnimator on opacity {
                    from: 1; to: 0.5; duration: 1000; loops: Animation.Infinite; easing.type: Easing.InOutQuad
                }
            }
            Text {
                text: minuteStr(now)
                color: theme.textColor
                font.pixelSize: 54
                font.bold: true
                verticalAlignment: Text.AlignVCenter
                anchors.verticalCenter: parent.verticalCenter
            }
            // 可选秒
            Text {
                visible: showSeconds
                text: ":" + secondStr(now)
                color: theme.textColor
                font.pixelSize: 36
                font.bold: true
                verticalAlignment: Text.AlignVCenter
                anchors.verticalCenter: parent.verticalCenter
                anchors.baseline: parent.baseline
            }
        }

        // 右侧：日期
        // 之前是Column包含天气和日期，现在只剩下日期，直接用 Text 即可
        Text {
            text: dateLine
            color: theme.textColor
            font.pixelSize: 16 // 稍微调大一点点，因为没有天气挤占空间了，视觉更平衡
            font.bold: true
            opacity: 0.8
            anchors.verticalCenter: parent.verticalCenter
            // 如果你希望日期在时间旁边作为辅助信息显示，VerticalCenter 最好
            // 如果希望日期和时间底部对齐，可以改用 anchors.bottom: parent.bottom 等
        }
    }

    // 主题变化时刷新颜色
    Connections {
        target: theme
        enabled: !!theme
        ignoreUnknownSignals: true
        function onIsDarkChanged() { background.color = faceColor }
        // 其他颜色通常通过属性绑定自动更新，无需手动处理
    }
}
