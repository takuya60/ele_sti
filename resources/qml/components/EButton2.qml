import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

Item { // [修改1] 根节点改为 Item，不要有颜色
    id: root

    // ==== 外部接口 ====
    property string text: "Button"
    property string iconCharacter: ""
    property string iconFontFamily: iconFont.name
    signal clicked()

    // ==== 样式配置 ====
    property bool backgroundVisible: true
    property real radius: 16

    // 颜色逻辑
    property color buttonColor: "transparent"
    property color hoverColor: "#15FFFFFF"
    property color textColor: theme.textColor
    property color iconColor: theme.textColor

    // 阴影配置
    property bool shadowEnabled: false
    property color shadowColor: theme.shadowColor
    property real pressedScale: 0.8
    property bool iconRotateOnClick: false

    // ==== 尺寸 ====
    implicitHeight: 85
    implicitWidth: 100

    property int iconSize: 26
    property int fontSize: 13
    property int spacing: 6

    // [修改2] 缩放移到根节点，整体缩放
    transform: Scale {
        id: scale
        origin.x: root.width / 2
        origin.y: root.height / 2
    }

    // ==== 1. 阴影层 (放在背景下面) ====
    MultiEffect {
        source: backgroundMask
        anchors.fill: backgroundRect // 跟随背景大小
        visible: root.backgroundVisible && root.shadowEnabled

        // 关键设置：只画阴影，不画 source 本身，防止黑色叠加
        // 或者因为我们把它放在了 backgroundRect 下面，即使画了 source 也会被下面的 backgroundRect 盖住
        // 但最好是分离清楚
        shadowEnabled: true
        shadowColor: root.shadowColor
        shadowBlur: 10
        shadowVerticalOffset: 4
    }

    // 辅助遮罩 (用于生成阴影形状，颜色不重要，形状重要)
    Item {
        id: backgroundMask
        anchors.fill: parent
        visible: false
        Rectangle {
            anchors.fill: parent
            radius: root.radius
            color: "black"
        }
    }

    // ==== 2. 实体背景层 (真正的按钮颜色) ====
    Rectangle {
        id: backgroundRect
        anchors.fill: parent
        radius: root.radius

        // [关键] 颜色逻辑移到这里
        color: root.backgroundVisible ? (mouseArea.containsMouse ? root.hoverColor : root.buttonColor) : "transparent"

        Behavior on color { ColorAnimation { duration: 150 } }
    }

    // ==== 3. 内容层 ====
    ColumnLayout {
        anchors.centerIn: parent
        spacing: root.spacing

        // 图标
        Text {
            id: iconLabel
            text: root.iconCharacter
            color: root.iconColor
            font.family: root.iconFontFamily
            font.pixelSize: root.iconSize

            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter

            transform: Rotation {
                id: iconRotation
                origin.x: iconLabel.width / 2
                origin.y: iconLabel.height / 2
                angle: 0
            }

            PropertyAnimation { id: rotateAnimation; target: iconRotation; property: "angle"; from: 0; to: 360; duration: 250; easing.type: Easing.InOutQuad }

        }

        // 文字
        Text {
            text: root.text
            color: root.textColor
            font.pixelSize: root.fontSize
            font.bold: true

            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
            Layout.maximumWidth: root.width - 10
            elide: Text.ElideRight
        }
    }

    // ==== 交互 ====
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onPressed: {
            scale.xScale = root.pressedScale
            scale.yScale = root.pressedScale
            if (root.iconRotateOnClick) rotateAnimation.start()
        }

        onReleased: {
            restoreAnimation.restart()
            root.clicked()
            if (root.iconRotateOnClick) restoreRotation.start()
        }

        onCanceled: {
            restoreAnimation.restart()
            if (root.iconRotateOnClick) restoreRotation.start()
        }
    }

    ParallelAnimation {
        id: restoreAnimation
        SpringAnimation { target: scale; property: "xScale"; to: 1.0; spring: 2.5; damping: 0.25 }
        SpringAnimation { target: scale; property: "yScale"; to: 1.0; spring: 2.5; damping: 0.25 }
    }
}
