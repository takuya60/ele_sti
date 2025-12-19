import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic
import QtQuick.Effects

Item {
    id: root

    // === 基础属性 ===
    property string title: "请选择"
    property bool opened: false
    property var model: [] // 期望格式: [{text: "Option A"}, {text: "Option B"}]
    property int selectedIndex: -1
    signal selectionChanged(int index, var item)

    // === 样式属性 (iOS 风格) ===
    property real radius: 10
    // 按钮（Header）背景色：稍微亮一点的深灰
    property color headerColor: "#2C2C2E"
    // 菜单（Popup）背景色：更深一点，产生层级感
    property color popupColor: "#1C1C1E"
    property color textColor: "#FFFFFF"
    property color accentColor: "#0A84FF" // iOS Blue

    property int fontSize: 14
    property int headerHeight: 40
    property int popupMaxHeight: 250
    property int popupSpacing: 6 // 菜单与按钮的间距

    // === 尺寸 ===
    implicitWidth: 140
    implicitHeight: headerHeight

    // 确保弹窗在最上层
    z: opened ? 1000 : 1

    // ========================================================
    // 1. 按钮头部 (Header)
    // ========================================================
    Rectangle {
        id: headerBackground
        anchors.fill: parent
        radius: root.radius
        color: root.headerColor

        // 极细的边框，增加精致感
        border.color: root.opened ? root.accentColor : "#33FFFFFF"
        border.width: 1

        // 点击交互
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.opened = !root.opened
        }

        // 内容布局
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 0

            // 选中的文字
            Text {
                id: headerText
                Layout.fillWidth: true
                text: root.selectedIndex >= 0 ? (root.model[root.selectedIndex].text || root.model[root.selectedIndex]) : root.title
                color: root.textColor
                font.pixelSize: root.fontSize
                font.bold: true
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }

            // 旋转箭头
            Text {
                text: "\uf078" // fa-chevron-down
                font.family: iconFont.name // 确保 main.qml 加载了 FontAwesome
                font.pixelSize: 10
                color: "#8E8E93" // iOS Gray

                // 旋转动画
                rotation: root.opened ? 180 : 0
                Behavior on rotation { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }
            }
        }
    }

    // ========================================================
    // 2. 弹出菜单 (Popup Menu)
    // ========================================================
    Item {
        id: popupContainer
        width: root.width
        // 根据内容自适应高度
        height: Math.min(contentListView.contentHeight + 10, root.popupMaxHeight)

        // 定位：在按钮正下方
        y: root.headerHeight + root.popupSpacing
        x: 0

        // 状态控制
        visible: opacity > 0
        opacity: root.opened ? 1 : 0
        scale: root.opened ? 1 : 0.95
        transformOrigin: Item.Top // 从顶部向下展开

        // 进出场动画
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack; } }

        // 菜单背景 (实体背景 + 阴影)
        Rectangle {
            id: popupBg
            anchors.fill: parent
            radius: root.radius
            color: root.popupColor // 深色背景，防止混淆

            // 边框
            border.color: "#33FFFFFF"
            border.width: 1
            clip: true

            // 阴影特效 (弥散阴影)
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowBlur: 24
                shadowColor: "#80000000" // 半透明黑影
                shadowVerticalOffset: 8
            }
        }

        // 列表内容
        ListView {
            id: contentListView
            anchors.fill: parent
            anchors.margins: 5 // 内部留白
            clip: true
            spacing: 2

            // 数据模型适配 (兼容纯字符串数组和对象数组)
            model: root.model

            delegate: Item {
                width: contentListView.width
                height: 36 // 选项高度

                // 数据解析辅助
                property string itemText: (typeof modelData === 'string') ? modelData : (modelData.text || "")
                property bool isSelected: index === root.selectedIndex
                property bool isHovered: false

                // 选中/悬停背景
                Rectangle {
                    anchors.fill: parent
                    radius: 6
                    color: {
                        if (isSelected) return root.accentColor // 选中变蓝
                        if (isHovered) return "#20FFFFFF"      // 悬停变浅灰
                        return "transparent"
                    }

                    // 颜色过渡动画
                    Behavior on color { ColorAnimation { duration: 100 } }
                }

                // 选项文字
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: itemText
                    color: isSelected ? "#FFFFFF" : root.textColor
                    font.pixelSize: root.fontSize - 1
                    font.bold: isSelected
                }

                // 选中对勾 (可选)
                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\uf00c" // fa-check
                    font.family: iconFont.name
                    visible: isSelected
                    color: "#FFFFFF"
                    font.pixelSize: 10
                }

                // 交互
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: parent.isHovered = true
                    onExited: parent.isHovered = false
                    onClicked: {
                        root.selectedIndex = index
                        root.opened = false
                        // 兼容对象和字符串回传
                        root.selectionChanged(index, (typeof modelData === 'string') ? {text: modelData} : modelData)
                    }
                }
            }
        }
    }

    // 全局点击关闭 (透明遮罩)
    // 当菜单打开时，在整个屏幕（或父级容器）覆盖一层透明区域来拦截点击
    // 注意：在旋转场景下，这个 MouseArea 只覆盖 root 的父级范围
    // 如果需要全屏关闭，最好在 pageRoot 加遮罩。这里这是一个简化的局部方案。
    Item {
        z: -1
        anchors.fill: parent
        // 扩展遮罩范围到稍微大一点，防止误触边缘
        anchors.margins: -1000
        visible: root.opened

        MouseArea {
            anchors.fill: parent
            onClicked: root.opened = false
        }
    }
}
