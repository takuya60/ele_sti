// ECarousel.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import "." as Components
Item {
    id: root

    // ==== 公共/样式属性 ====
    property real radius: 20
    property bool shadowEnabled: true

    // ==== 数据模型 ====
    // 这里现在是个纯净的数组，等待外部传入 ["url1", "url2"]
    property var model: []
    property alias currentIndex: swipeView.currentIndex

    // ==== 尺寸/布局 ====
    implicitWidth: 400
    implicitHeight: width * 9 / 16

    // ==== 背景阴影效果 ====
    MultiEffect {
        source: background
        anchors.fill: background
        visible: root.shadowEnabled
        shadowEnabled: true
        shadowColor: theme.shadowColor
        shadowBlur: theme.shadowBlur
        shadowVerticalOffset: theme.shadowYOffset
        shadowHorizontalOffset: theme.shadowXOffset
    }

    // ==== 背景容器与滑动视图 ====
    Rectangle {
        id: background
        anchors.fill: parent
        radius: root.radius
        color: theme.secondaryColor
        clip: true

        // ==== 图片滑动视图 ====
        Item {
            id: swipeContainer
            anchors.fill: parent
            anchors.margins: -1

            SwipeView {
                id: swipeView
                anchors.fill: parent
                interactive: root.model.length > 1 // 只有一张图时禁止滑动
                visible: true
                opacity: 0 // 保持可交互但不直接显示（由下面的 MultiEffect 掩模负责显示）

                // ==== 图片重复显示 ====
                Repeater {
                    model: root.model
                    delegate: Item {
                        width: swipeView.width
                        height: swipeView.height

                        // 原始图像（隐藏），用于 MultiEffect 的 source
                        Image {
                            id: sourceItem
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop
                            cache: true
                            asynchronous: true
                            visible: true

                            // --- 修改点：直接使用传入的 modelData ---
                            // 删除了原先针对 Bing 的 ?w=... 参数拼接，防止本地图片加载失败
                            source: modelData
                        }

                        // 加载占位：主题色三点加载动画

                    }
                }
            }

            // 容器级掩模，保证滑动时区域保持圆角
            MultiEffect {
                id: swipeMasked
                source: swipeView
                anchors.fill: parent
                maskEnabled: true
                maskSource: containerMask
                autoPaddingEnabled: false
                antialiasing: true
                layer.enabled: true
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1.0
                z: 1
            }

            // 整体加载占位：当没有数据时显示


            // 圆角掩模图形
            Item {
                id: containerMask
                anchors.fill: parent
                layer.enabled: true
                visible: false
                Rectangle {
                    anchors.fill: parent
                    radius: root.radius
                    color: "black"
                }
            }
        }

        // ==== 底部页码指示器 ====
        PageIndicator {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 15
            count: swipeView.count
            currentIndex: swipeView.currentIndex
            delegate: Rectangle {
                height: 8
                width: index === currentIndex ? 24 : 8
                radius: 4
                opacity: 0.85
                Behavior on width {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.InOutCubic
                    }
                }
            }
        }
    }
}
