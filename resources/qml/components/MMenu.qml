import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: root

    // ===========================
    // 1. 公共接口
    // ===========================
    property string text: "Select"
    property var menuModel: []

    // 信号
    signal itemClicked(int index, string text)

    // 样式属性
    property real radius: 8
    property color accentColor: "#007AFF" // 选中时的蓝色高亮
    property color textColor: "#FFFFFF"
    property color backgroundColor: "#2C2C2E" // 按钮和菜单的深灰色背景
    property color borderColor: "#3A3A3C"     // 极细的边框颜色

    // 状态
    property bool isOpen: false

    // 尺寸
    implicitWidth: 120
    implicitHeight: 36
    z: isOpen ? 1000 : 1

    // ===========================
    // 2. 按钮主体
    // ===========================
    Rectangle {
        id: buttonBg
        anchors.fill: parent
        radius: root.radius
        color: root.backgroundColor

        // 静态边框，不会因为展开而发光
        border.color: root.borderColor
        border.width: 1

        // 按钮内容
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 0

            Text {
                text: root.text
                color: root.textColor
                font.pixelSize: 14
                font.bold: true
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            // 旋转小箭头
            Text {
                text: "\uf078" // fa-chevron-down
                font.family: iconFont.name
                color: "#8E8E93" // 灰色箭头
                font.pixelSize: 10
                rotation: root.isOpen ? 180 : 0
                Behavior on rotation { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }
            }
        }

        // 点击交互
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.isOpen = !root.isOpen
        }
    }

    // ===========================
    // 3. 伪菜单层 (Loader 架构 - 修复旋转问题)
    // ===========================
    Loader {
        id: menuLoader
        active: root.isOpen
        visible: active

        y: root.height + 4
        x: 0
        width: root.width

        sourceComponent: Component {
            Item {
                id: menuContainer
                height: Math.min(listView.contentHeight + 4, 250)
                width: menuLoader.width

                // 菜单背景
                Rectangle {
                    id: menuBg
                    anchors.fill: parent
                    color: root.backgroundColor
                    radius: 8

                    border.color: root.borderColor
                    border.width: 1

                    clip: true

                    // 阴影
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowBlur: 12
                        shadowColor: "#80000000"
                        shadowVerticalOffset: 4
                    }
                }

                // 列表
                ListView {
                    id: listView
                    anchors.fill: parent
                    anchors.margins: 2 // 内部留白
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: root.menuModel

                    delegate: Item {
                        id: delegateItem
                        width: listView.width
                        height: 32 // 标准高度

                        property bool isSelected: modelData === root.text
                        property bool isHovered: false

                        // 【核心修改】选中项背景高亮
                        Rectangle {
                            anchors.fill: parent
                            radius: 6
                            // 选中显示主题色，悬停显示浅灰，否则透明
                            color: {
                                if (isSelected) return root.accentColor
                                if (isHovered) return Qt.rgba(1, 1, 1, 0.1) // 悬停时的微亮
                                return "transparent"
                            }

                            // 平滑颜色过渡
                            Behavior on color { ColorAnimation { duration: 100 } }
                        }

                        // 文字
                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData
                            // 选中文字一定变白，未选中根据主题
                            color: isSelected ? "#FFFFFF" : root.textColor
                            font.pixelSize: 13
                            // 选中加粗
                            font.bold: isSelected
                        }

                        // 【可选】右侧对勾 (如果需要加强指示，可以保留；不需要可删除)
                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: "\uf00c" // fa-check
                            font.family: iconFont.name
                            color: "#FFFFFF"
                            font.pixelSize: 10
                            visible: isSelected
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: delegateItem.isHovered = true
                            onExited: delegateItem.isHovered = false
                            onClicked: {
                                root.text = modelData
                                root.itemClicked(index, modelData)
                                root.isOpen = false
                            }
                        }
                    }
                }

                // 进场动画
                Component.onCompleted: {
                    menuOpacityAnim.start()
                    menuScaleAnim.start()
                }
                NumberAnimation { id: menuOpacityAnim; target: menuContainer; property: "opacity"; from: 0; to: 1; duration: 150 }
                NumberAnimation { id: menuScaleAnim; target: menuContainer; property: "scale"; from: 0.95; to: 1; duration: 150; easing.type: Easing.OutQuad }
            }
        }
    }
}
