// EBlurCard
import QtQuick
import QtQuick.Controls
import QtQuick.Effects

Item {
    id: root

    // --- 公共属性 ---
    property Item blurSource
    property real blurAmount: 1
    property bool dragable: false

    property real blurMax: 64
    property real borderRadius: 24
    property color borderColor: "transparent"
    property real borderWidth: 0

    default property alias content: contentItem.data

    width: 300
    height: 200

    // --- 拖动功能 ---
    MouseArea {
        anchors.fill: parent
        drag.target: root
        drag.axis: Drag.XAndYAxis
        enabled: root.dragable
    }

    // --- 捕获背景内容 ---
    ShaderEffectSource {
            id: effectSource
            anchors.fill: parent
            sourceItem: root.blurSource

            // --- 核心修改开始 ---
            sourceRect: {
                if (root.blurSource) {
                    // 将卡片自身的 (0,0) 映射到 blurSource 的坐标系中
                    var point = root.mapToItem(root.blurSource, 0, 0);
                    return Qt.rect(point.x, point.y, root.width, root.height);
                }
                return Qt.rect(0, 0, root.width, root.height);
            }
            // --- 核心修改结束 ---

            visible: false
        }

    // === 创建遮罩 ===
    Item {
        id: maskItem
        anchors.fill: parent
        layer.enabled: true
        layer.smooth: true
        visible: false
        Rectangle {
            anchors.fill: parent
            radius: root.borderRadius
            color: "white"  // 必须是不透明色，否则遮罩无效
        }
    }
    // === 启用遮罩 ===
    MultiEffect {
        anchors.fill: effectSource
        source: effectSource
        autoPaddingEnabled: false
        blurEnabled: true
        blurMax: root.blurMax
        blur: root.blurAmount
        maskEnabled: true
        maskSource: maskItem
    }

    // ====叠加主题色, 避免过亮/过透明 ====
    Rectangle {
        anchors.fill: parent
        radius: root.borderRadius
        color: theme.blurOverlayColor
        z: 1
        opacity: 1.0
        border.color: root.borderColor
        border.width: root.borderWidth
    }

    // 内容容器
    Item {
        id: contentItem
        anchors.fill: parent
        clip: true
        z: 2
    }
}
