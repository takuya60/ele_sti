import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtQuick.Effects
import "../components" as Components

ColumnLayout {
    id: root

    // ========================================
    // 1. 全局/调试配置
    // ========================================
    // 【关键修改】从这里控制模式。
    // 在实际项目中，建议绑定到全局单例，例如: visible: true, property bool isDebug: GlobalConfig.debugMode
    property bool isDebug: true

    // ========================================
    // 2. 公共属性 (保持不变)
    // ========================================
    property string title: "参数名称"
    property string unit: "us"
    property var unitOptions: ["us", "ms"]

    property real value: 0
    property real fromValue: 0
    property real toValue: (unit === "ms" ? 200 : 2000)
    property real stepSize: (unit === "ms" ? 0.01 : 1.0)

    property bool showInfinityWhenDisabled: false
    property color accentColor: "#2979ff"

    // 信号
    signal modified()

    spacing: 5
    Layout.fillWidth: true
    z: 10

    // ========================================
    // 3. 旋钮逻辑处理 (新增)
    // ========================================

    // 当这个组件获得焦点时，它将接收按键事件
    // 请确保你的 C++ 后端或驱动层将旋钮旋转映射为 Qt 的 Key_Left / Key_Right 事件
    Keys.onPressed: (event) => {
        if (root.isDebug) return; // Debug模式下通常不需要按键控制，或者两者共存

        var change = 0;
        // 假设旋钮左转是减，右转是加
        // 如果你的旋钮发送的是 Up/Down，请修改这里
        if (event.key === Qt.Key_Left || event.key === Qt.Key_Down) {
            change = -root.stepSize;
        } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Up) {
            change = root.stepSize;
        }

        if (change !== 0) {
            var newVal = root.value + change;
            // 手动做边界检查
            if (newVal < sliderControl.from) newVal = sliderControl.from;
            if (newVal > sliderControl.to) newVal = sliderControl.to;

            if (root.value !== newVal) {
                sliderControl.value = newVal; // 更新 Slider UI
                event.accepted = true;
            }
        }
    }

    // 顶部标题栏和输入框 (逻辑保持不变，为了节省篇幅略有折叠，实际使用请保留完整逻辑)
    RowLayout {
        Layout.fillWidth: true
        z: 10

        Text {
            text: root.title
            color: "#dedede"
            font.bold: true
            font.pixelSize: 18
        }

        Item { Layout.fillWidth: true }

        // --- 输入框 ---
        TextField {
            id: valueInput
            // 只要不是 debug 模式下的拖动，就显示当前值
            text: (root.showInfinityWhenDisabled && !root.enabled)
                  ? "∞"
                  : (root.unit === "ms" ? sliderControl.value.toFixed(2) : Math.round(sliderControl.value).toString())

            color: root.accentColor
            font.pixelSize: (text === "∞") ? 30 : 22
            font.bold: true
            Layout.preferredWidth: 100
            horizontalAlignment: Text.AlignRight

            // 【关键修改】医疗模式下，如果不想让用户点输入框弹软键盘，可以将 enabled 设为 false，
            // 或者只允许 focus 作为一个整体。这里暂时保留输入功能以便微调。
            enabled: root.enabled

            validator: DoubleValidator {
                bottom: sliderControl.from; top: sliderControl.to
                decimals: root.unit === "ms" ? 2 : 0
                notation: DoubleValidator.StandardNotation
            }
            background: Rectangle {
                color: "transparent"
                Rectangle {
                    anchors.bottom: parent.bottom; width: parent.width; height: 2; color: root.accentColor
                    visible: valueInput.activeFocus
                }
            }
            onEditingFinished: {
                var val = parseFloat(text)
                if (!isNaN(val)) {
                    if (val < sliderControl.from) val = sliderControl.from
                    if (val > sliderControl.to) val = sliderControl.to
                    if (root.value !== val) {
                        root.value = val
                        root.modified()
                    }
                    text = (root.unit === "ms" ? val.toFixed(2) : Math.round(val).toString())
                }
            }
        }

        Components.EDropdown {
            id: unitDropdown
            Layout.preferredWidth: 80; Layout.preferredHeight: 30; Layout.alignment: Qt.AlignBaseline
            headerColor: "transparent"; textColor: "#888888"; radius: 4; fontSize: 14; headerHeight: 30
            title: root.unit; model: root.unitOptions
            onSelectionChanged: (index, item) => { root.unit = (typeof item === 'string') ? item : item.text }
        }
    }

    // ========================================
    // 4. 滑块核心部分 (核心修改)
    // ========================================
    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 30 // 给滑块留出高度

        // --- 真正的 Slider 组件 ---
        Slider {
            id: sliderControl
            anchors.fill: parent
            z: 1

            from: root.fromValue
            to: root.toValue
            stepSize: root.stepSize
            value: root.value
            enabled: root.enabled // 整体禁用逻辑

            // 如果不是 debug 模式，Slider 自身不处理交互（由上层 MouseArea 接管）
            // 注意：直接设 interactive: false 会导致无法显示 handle 的 visualPosition 更新
            // 所以我们通过在上层盖 MouseArea 来拦截

            onValueChanged: {
                if (root.value !== value) {
                    root.value = value
                    if (!valueInput.activeFocus) {
                        valueInput.text = (root.unit === "ms" ? value.toFixed(2) : Math.round(value).toString())
                        root.modified()
                    }
                }
            }

            // 自定义背景槽
            background: Rectangle {
                x: sliderControl.leftPadding
                y: sliderControl.topPadding + sliderControl.availableHeight / 2 - height / 2
                implicitWidth: 200; implicitHeight: 12
                width: sliderControl.availableWidth; height: implicitHeight
                radius: 4
                color: sliderControl.enabled ? "#333333" : "#222222"

                Item {
                    width: sliderControl.visualPosition * parent.width
                    height: parent.height
                    Rectangle {
                        anchors.fill: parent; anchors.margins: -4; radius: 6
                        color: root.accentColor; opacity: 0.3
                        visible: sliderControl.enabled
                        layer.enabled: true
                        layer.effect: MultiEffect { blurEnabled: true; blurMax: 60; blur: 1.5; brightness: 0.20 }
                    }
                    Rectangle {
                        anchors.fill: parent; radius: 4
                        color: sliderControl.enabled ? root.accentColor : "#555555"
                    }
                }
            }

            // 自定义手柄 (Handle)
            handle: Rectangle {
                x: sliderControl.leftPadding + sliderControl.visualPosition * (sliderControl.availableWidth - width)
                y: sliderControl.topPadding + sliderControl.availableHeight / 2 - height / 2
                implicitWidth: 24; implicitHeight: 24
                radius: 12

                // 【核心逻辑】颜色变化
                // 1. Debug模式: 永远白色
                // 2. 医疗模式: 只有被选中 (root.activeFocus) 时才变色，否则白色
                color: {
                    if (root.isDebug) return "white";
                    return root.activeFocus ? root.accentColor : "white";
                }

                // 选中时的光晕效果
                border.width: (root.activeFocus && !root.isDebug) ? 2 : 0
                border.color: "white"

                Behavior on color { ColorAnimation { duration: 200 } }

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: "#80000000"
                    shadowBlur: 0.5
                    shadowVerticalOffset: 1
                }
            }
        }

        // --- 医疗模式拦截层 ---
        // 只有在 !isDebug 时启用
        MouseArea {
            id: knobInteractor
            anchors.fill: parent
            z: 10 // 盖在 Slider 上面

            // Debug 模式下隐藏/穿透，允许直接触摸 Slider
            enabled: !root.isDebug

            // 阻止鼠标事件传递给 Slider，从而禁止拖动
            preventStealing: true
            propagateComposedEvents: false

            onClicked: {
                // 点击后，强制整个组件获得焦点
                root.forceActiveFocus()
                console.log(root.title + " 选中，等待旋钮输入...")
            }
        }
    }
}
