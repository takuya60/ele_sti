import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: root

    // === 公共属性 ===
    property bool opened: false
    property int panelWidth: 300
    property color drawerColor: "#CC000000" // 默认深色半透明

    // 玻璃拟态配置
    property Item blurSource: null
    property real blurAmount: 0

    // 边框配置
    property real borderWidth: 0
    property color borderColor: "transparent"

    // 内容插槽 (关键：使用 Item 而不是 Column，允许内部填充)
    default property alias content: contentContainer.data

    // 状态控制
    function open() { root.opened = true }
    function close() { root.opened = false }
    function toggle() { root.opened = !root.opened }

    // 遮罩层 (点击空白关闭)
    anchors.fill: parent
    visible: root.opened // 只有打开时才拦截点击

    // 透明背景层用于拦截点击
    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    // === 抽屉面板 ===
    Item {
        id: panel
        width: root.panelWidth
        height: parent.height

        // 动画控制 x 坐标
        x: root.opened ? (parent.width - width) : parent.width
        Behavior on x {
            NumberAnimation {
                duration: 400
                easing.type: Easing.OutQuart
            }
        }

        // 拦截面板内的点击，防止穿透到底部
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {} // 吞掉点击事件
        }

        // --- 1. 阴影层 ---
        MultiEffect {
            source: bgRect
            anchors.fill: bgRect
            shadowEnabled: true
            shadowColor: "#80000000"
            shadowBlur: 40
            shadowHorizontalOffset: -5
            visible: root.opened
        }

        // --- 2. 玻璃拟态层 (核心) ---
        Item {
            anchors.fill: parent
            visible: root.blurSource !== null && root.blurAmount > 0

            ShaderEffectSource {
                id: effectSource
                sourceItem: root.blurSource
                anchors.fill: parent
                // 动态计算截取区域，实现透视效果
                sourceRect: Qt.rect(panel.x, 0, panel.width, panel.height)
                visible: false
            }

            MultiEffect {
                anchors.fill: parent
                source: effectSource
                blurEnabled: true
                blurMax: 64
                blur: root.blurAmount
            }
        }

        // --- 3. 背景色层 ---
        Rectangle {
            id: bgRect
            anchors.fill: parent
            color: root.drawerColor
            border.width: root.borderWidth
            border.color: root.borderColor
        }

        // --- 4. 内容容器 ---
        Item {
            id: contentContainer
            anchors.fill: parent
            clip: true // 裁剪溢出内容
        }
    }
}
