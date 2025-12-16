import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes
import QtQuick.Controls.Basic
import QtQuick.Effects // 必须引入特效模块
import "../components" as Components

Item {
    id: pageRoot
    anchors.fill: parent

    property int viewportWidth: 1200
    property var theme
    property var toastRef

    // ==========================================
    // 1. 定义核心数据模型 (State)
    // ==========================================
    property real paramPosWidth: 200  // 正向脉宽 (ms)
    property real paramNegWidth: 200  // 反向脉宽 (ms)
    property real paramDeadTime: 200   // 死区时间 (ms)
    property real paramPeriod: 1000   // 刺激周期 (ms)

    property real paramPosAmp: 50     // 正向幅值 (mA)
    property real paramNegAmp: 50     // 反向幅值 (mA)

    property string selectedWaveform: "方波"

    // 全局点击拦截器 (用于退出输入框)
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: pageRoot.forceActiveFocus()
    }

    // --- 内部复用组件：专用参数滑块 ---
    component ParamSlider: ColumnLayout {
        property string title: "参数名称"
        property string unit: "ms"
        property var unitOptions: ["ms", "us"]
        property real value: 0
        property bool showInfinityWhenDisabled: false
        property alias from: sliderControl.from
        property alias to: sliderControl.to
        property color accentColor: typeof theme !== "undefined" ? theme.focusColor : "#2979ff"

        spacing: 5
        Layout.fillWidth: true

        // 顶部文字行
        RowLayout {
            Layout.fillWidth: true
            Text {
                text: title
                color: "#dedede"
                font.bold: true
                font.pixelSize: 18
            }
            Item { Layout.fillWidth: true }
            // --- 输入框 ---
            TextField {
                id: valueInput
                text: (parent.parent.showInfinityWhenDisabled && !parent.parent.enabled)
                                      ? "∞"
                                      : Math.round(sliderControl.value).toString()
                color: accentColor
                font.pixelSize: (text === "∞") ? 30 : 22
                font.bold: true
                Layout.preferredWidth: 80
                horizontalAlignment: Text.AlignRight
                validator: IntValidator {
                    bottom: Math.round(sliderControl.from)
                    top: Math.round(sliderControl.to)
                }
                enabled: parent.parent.enabled
                background: Rectangle {
                    color: "transparent"
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width; height: 2; color: accentColor
                        visible: valueInput.activeFocus
                    }
                }
                onEditingFinished: {
                    var val = parseFloat(text)
                    if (!isNaN(val)) {
                        if (val < sliderControl.from) val = sliderControl.from
                        if (val > sliderControl.to) val = sliderControl.to
                        parent.parent.value = val
                        text = val.toString()
                    } else {
                        text = Math.round(sliderControl.value).toString()
                    }
                }
            }
            // 单位菜单
            Components.EMenuButton {
                text: unit
                menuModel: unitOptions
                backgroundVisible: false
                Layout.alignment: Qt.AlignBaseline
                onItemClicked: (index, text) => { unit = text }
            }
        }

        // --- 滑块 ---
        Slider {
            id: sliderControl
            Layout.fillWidth: true
            from: 0; to: 500
            value: parent.value
            enabled: parent.enabled
            onValueChanged: {
                parent.value = value
                if (!valueInput.activeFocus) {
                    valueInput.text = Math.round(value).toString()
                }
            }

            // 1. 【核心修改】背景条：增加柔和光晕
            background: Rectangle {
                x: sliderControl.leftPadding
                y: sliderControl.topPadding + sliderControl.availableHeight / 2 - height / 2
                implicitWidth: 200
                implicitHeight: 12 // 把轨道稍微调细一点，显得光晕更明显
                width: sliderControl.availableWidth
                height: implicitHeight
                radius: 4
                // 轨道底色（深灰）
                color: sliderControl.enabled ? "#333333" : "#222222"

                // --- 进度条容器 ---
                Item {
                    width: sliderControl.visualPosition * parent.width
                    height: parent.height

                    // (A) 光晕层：位于实心条下方，向四周发散
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -4 // 【关键】让光晕比实体条大一圈
                        radius: 6
                        color: accentColor // 跟随主题色
                        opacity: 0.3       // 透明度低一点，营造“氛围感”

                        // 只有启用时才发光
                        visible: sliderControl.enabled

                        layer.enabled: true
                        layer.effect: MultiEffect {
                            blurEnabled: true
                            blurMax: 60   // 模糊范围大一点，光就越柔
                            blur: 1.5
                            brightness: 0.20
                        }
                    }

                    // (B) 实体层：清晰的进度条
                    Rectangle {
                        anchors.fill: parent
                        radius: 4
                        color: sliderControl.enabled ? accentColor : "#555555"
                    }
                }
            }

            // 2. 【回归】手柄：恢复为无特效的简约白点
            handle: Rectangle {
                x: sliderControl.leftPadding + sliderControl.visualPosition * (sliderControl.availableWidth - width)
                y: sliderControl.topPadding + sliderControl.availableHeight / 2 - height / 2
                implicitWidth: 24
                implicitHeight: 24
                radius: 12
                color: "white" // 纯白手柄，无光晕

                // 加一点点普通的物理投影，增加立体感，但不是“发光”
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: "#80000000" // 黑色半透明阴影
                    shadowBlur: 0.5
                    shadowVerticalOffset: 1
                }
            }
        }
    }

    // --- 主布局 ---
    RowLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        // ================= 左侧：参数设置区 =================
        ColumnLayout {
            Layout.fillHeight: true
            Layout.preferredWidth: 2
            Layout.fillWidth: true
            spacing: 20

            // 1. 顶部通道选择条
            RowLayout {
                spacing: 10
                Rectangle {
                    width: 120; height: 40; radius: 6; color: "#333333"; border.color: "#555555"; border.width: 1
                    Row { anchors.centerIn: parent; spacing: 8
                        Rectangle { width: 8; height: 8; radius: 4; color: theme.focusColor }
                        Text { text: "通道 01"; color: "white"; font.bold: true }
                    }
                }
                Rectangle {
                    width: 120; height: 40; radius: 6; color: "transparent"; border.color: "#333333"; border.width: 1
                    Text { text: "通道 02"; color: "#666666"; anchors.centerIn: parent }
                }
                Components.EMenuButton {
                    text: selectedWaveform
                    menuModel: ["方波", "三角波", "正弦波", "梯形波"]
                    backgroundVisible: true
                    height: 40
                    Layout.preferredWidth: 120
                    onItemClicked: (index, text) => { selectedWaveform = text }
                }
                Item { Layout.fillWidth: true }
                Components.EButton { text: "应用至所有通道"; backgroundVisible: true; height: 36 }
            }

            // 2. 时域参数设置卡片 (Timing)
            Components.EBlurCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 300
                layer.enabled: true
                blurSource: bgImage
                blurAmount: 0.7
                borderRadius: 24
                borderWidth: 1
                borderColor: "#30FFFFFF"

                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 20; spacing: 20
                    RowLayout {
                        Text { text: "\uf1fe"; font.family: iconFont.name; color: theme.focusColor; font.pixelSize: 25 }
                        Text { text: "时域参数设置 (TIMING)"; color: "#dddddd"; font.bold: true; font.pixelSize: 18 }
                    }
                    GridLayout {
                        columns: 2; columnSpacing: 40; rowSpacing: 30; Layout.fillWidth: true
                        ParamSlider { title: "正向脉宽"; value: paramPosWidth; onValueChanged: paramPosWidth = value; to: 1000; unit: "ms"; accentColor: "#2979ff" }
                        ParamSlider { title: "反向脉宽"; value: paramNegWidth; onValueChanged: paramNegWidth = value; to: 1000; unit: "ms"; accentColor: "#2979ff" }
                        ParamSlider { title: "死区时间"; value: paramDeadTime; onValueChanged: paramDeadTime = value; to: 1000; unit: "ms"; accentColor: "#2979ff" }
                        ParamSlider { title: "刺激周期"; value: paramPeriod;   onValueChanged: paramPeriod = value;   to: 2000; unit: "ms"; accentColor: "#00e676" }
                    }
                }
            }

            // 3. 输出强度设置卡片 (Intensity)
            Components.EBlurCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                layer.enabled: true
                blurSource: bgImage
                blurAmount: 0.7
                borderRadius: 24
                borderWidth: 1
                borderColor: "#30FFFFFF"

                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 20; spacing: 30
                    RowLayout {
                        Text { text: "\uf0e7"; font.family: iconFont.name; color: theme.focusColor; font.pixelSize: 18 }
                        Text { text: "输出强度设置 (INTENSITY)"; color: "#dddddd"; font.bold: true; font.pixelSize: 18 }
                    }
                    GridLayout {
                        columns: 2; columnSpacing: 40; Layout.fillWidth: true
                        ParamSlider { title: "正向幅值"; value: paramPosAmp; onValueChanged: paramPosAmp = value; to: 100; unit: "mA"; unitOptions: ["mA"]; accentColor: "#ff9100" }
                        ParamSlider { title: "反向幅值"; value: paramNegAmp; onValueChanged: paramNegAmp = value; to: 100; unit: "mA"; unitOptions: ["mA"]; accentColor: "#ff9100" }
                    }
                    Rectangle { Layout.fillWidth: true; height: 1; color: "#333333" }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 20
                        Text { text: "治疗时长"; color: "#cccccc"; font.bold: true; font.pixelSize: 18; transform: Translate { x: 4 ;y:-4} }

                        Switch {
                            id: timerSwitch
                            text: checked ? "定时结束" : "手动结束"
                            checked: true
                            Layout.alignment: Qt.AlignBottom
                            Layout.bottomMargin: 30
                            indicator: Rectangle {
                                implicitWidth: 40; implicitHeight: 20
                                x: timerSwitch.leftPadding
                                y: parent.height / 2 - height / 2
                                radius: 10
                                color: timerSwitch.checked ? "#00e676" : "#333333"
                                border.color: "#333333"
                                Rectangle {
                                    x: timerSwitch.checked ? parent.width - width : 0
                                    width: 20; height: 20; radius: 10
                                    color: "white"; border.color: "#999999"
                                    Behavior on x { NumberAnimation { duration: 200 } }
                                }
                            }
                            contentItem: Text {
                                text: timerSwitch.text; color: "#888888"; font.pixelSize: 14
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: timerSwitch.indicator.width + timerSwitch.spacing
                            }
                            transform: Translate { x: 8}
                        }
                        Item { Layout.fillWidth: true }
                        ParamSlider {
                            Layout.preferredWidth: 300
                            title: ""
                            value: 20
                            unit: "min"; unitOptions: ["min"]
                            accentColor: "#00e676"
                            transform: Translate { y: -12 }
                            enabled: timerSwitch.checked
                            opacity: enabled ? 1.0 : 0.5
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                            showInfinityWhenDisabled: true
                        }
                        transform: Translate { x: 8}
                    }
                }
            }
        }

        // ================= 右侧：动态波形预览 =================
        ColumnLayout {
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            Layout.fillWidth: true
            spacing: 20

            Components.EBlurCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                layer.enabled: true
                blurSource: bgImage
                blurAmount: 0.4
                borderRadius: 24
                borderWidth: 1
                borderColor: "#30FFFFFF"

                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 15; spacing: 10
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "波形预览 (PREVIEW)"; color: "white"; font.pixelSize: 12; font.bold: true }
                        Item { Layout.fillWidth: true }
                        Rectangle {
                            width: 70; height: 24; color: "#333333"; radius: 4;
                            Text { text: "Auto Scale"; anchors.centerIn: parent; color: "#888888"; font.pixelSize: 10 }
                        }
                    }
                    Text { text: "CHANNEL 1"; color: theme.focusColor; font.bold: true; font.pixelSize: 14 }

                    // --- 动态绘图区域 (已集成发光特效) ---
                    Item {
                        id: waveContainer
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumHeight: 200
                        clip: true

                        // 计算缩放比例
                        property real timeRange: Math.max(1000, paramPosWidth + paramNegWidth + paramDeadTime + 200)
                        property real ampRange: 120
                        property real pxPerMs: width / timeRange
                        property real pxPermA: (height / 2) / ampRange
                        property real zeroY: height / 2

                        // 1. 网格背景
                        Canvas {
                            anchors.fill: parent
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.clearRect(0, 0, width, height);
                                // 网格
                                ctx.strokeStyle = "#222222"; ctx.lineWidth = 1; ctx.beginPath();
                                for(var i=0; i<height; i+=30) { ctx.moveTo(0, i); ctx.lineTo(width, i); }
                                for(var j=0; j<width; j+=30) { ctx.moveTo(j, 0); ctx.lineTo(j, height); }
                                ctx.stroke();
                                // 参考线 (+/- 50mA)
                                ctx.strokeStyle = "#40ffffff"; ctx.lineWidth = 1;
                                ctx.setLineDash([4, 4]); ctx.beginPath();
                                var yPos50 = parent.zeroY - (100 * parent.pxPermA);
                                ctx.moveTo(0, yPos50); ctx.lineTo(width, yPos50);
                                var yNeg50 = parent.zeroY + (100 * parent.pxPermA);
                                ctx.moveTo(0, yNeg50); ctx.lineTo(width, yNeg50);
                                ctx.stroke();
                                // 中心轴
                                ctx.strokeStyle = "#444444"; ctx.lineWidth = 2; ctx.setLineDash([]); ctx.beginPath();
                                ctx.moveTo(0, parent.zeroY); ctx.lineTo(width, parent.zeroY);
                                ctx.stroke();
                            }
                        }

                        // 2. 【核心修改】柔和发光波形 (Repeater 实现)
                        Repeater {
                            model: 2 // 0: 光晕层, 1: 核心层
                            delegate: Shape {
                                id: waveShape
                                anchors.fill: parent
                                z: 0 // 确保在文字层下方

                                property bool isGlowLayer: index === 0

                                // 光晕特效配置
                                layer.enabled: isGlowLayer
                                layer.effect: MultiEffect {
                                    blurEnabled: true
                                    blurMax: 10    // 柔和的大范围光晕
                                    blur: 2.0
                                    brightness: 0.3  // 降低亮度避免刺眼
                                    saturation: 0.2  // 降低饱和度增加高级感
                                }
                                opacity: isGlowLayer ? 0.4 : 1.0

                                ShapePath {
                                    // 样式区分：光晕粗，核心细且亮
                                    strokeWidth: waveShape.isGlowLayer ? 8.5 : 4.5
                                    strokeColor: waveShape.isGlowLayer ? theme.focusColor : Qt.lighter(theme.focusColor, 1.3)
                                    fillColor: "transparent"

                                    startX: 20
                                    startY: waveContainer.zeroY
                                    // 绘制路径
                                    PathLine { x: 20 + 20; y: waveContainer.zeroY }
                                    PathLine { relativeX: 0; y: waveContainer.zeroY - (paramPosAmp * waveContainer.pxPermA) }
                                    PathLine { relativeX: paramPosWidth * waveContainer.pxPerMs; relativeY: 0 }
                                    PathLine { relativeX: 0; y: waveContainer.zeroY }
                                    PathLine { relativeX: paramDeadTime * waveContainer.pxPerMs; relativeY: 0 }
                                    PathLine { relativeX: 0; y: waveContainer.zeroY + (paramNegAmp * waveContainer.pxPermA) }
                                    PathLine { relativeX: paramNegWidth * waveContainer.pxPerMs; relativeY: 0 }
                                    PathLine { relativeX: 0; y: waveContainer.zeroY }
                                    PathLine { x: waveContainer.width; y: waveContainer.zeroY }
                                }
                            }
                        }

                        // 3. 【核心修改】文字层 (z:10 确保不被光晕覆盖)
                        Item {
                            anchors.fill: parent
                            z: 10
                            // +100mA 标尺
                            Text {
                                text: "+100mA"; color: "#80ffffff"
                                font.pixelSize: 10
                                x: 5; y: waveContainer.zeroY - (100 * waveContainer.pxPermA) - 12
                            }
                            // -100mA 标尺
                            Text {
                                text: "-100mA"; color: "#80ffffff"
                                font.pixelSize: 10
                                x: 5; y: waveContainer.zeroY + (100 * waveContainer.pxPermA) - 12
                            }
                            // 正向脉宽数值
                            Text {
                                text: Math.round(paramPosWidth) + "ms"
                                color: "#2979ff"; font.pixelSize: 12; font.bold: true
                                x: 40 + (paramPosWidth * waveContainer.pxPerMs) / 2 - width/2
                                y: waveContainer.zeroY - (paramPosAmp * waveContainer.pxPermA) - 15
                            }
                            // 死区数值
                            Text {
                                text: Math.round(paramDeadTime) + "ms"
                                color: "#ffaa00"; font.pixelSize: 12; font.bold: true
                                x: 40 + (paramPosWidth * waveContainer.pxPerMs) + (paramDeadTime * waveContainer.pxPerMs) / 2 - width/2
                                y: waveContainer.zeroY - 15
                            }
                            // 反向脉宽数值
                            Text {
                                text: Math.round(paramNegWidth) + "ms"
                                color: "#ff9100"; font.pixelSize: 12; font.bold: true
                                x: 40 + ((paramPosWidth + paramDeadTime) * waveContainer.pxPerMs) + (paramNegWidth * waveContainer.pxPerMs)/2 - width/2
                                y: waveContainer.zeroY + (paramNegAmp * waveContainer.pxPermA) + 5
                            }
                        }
                    }

                    // 底部数据统计
                    RowLayout {
                        Layout.fillWidth: true; Layout.preferredHeight: 60; spacing: 10
                        Rectangle {
                            Layout.fillWidth: true; Layout.fillHeight: true; radius: 8; color: "#1e1e1e"
                            Column {
                                anchors.centerIn: parent
                                Text { text: "FREQUENCY (F)"; color: "#666666"; font.pixelSize: 10; font.bold: true }
                                Text { text: (1000/paramPeriod).toFixed(1) + " Hz"; color: "white"; font.pixelSize: 16; font.bold: true }
                            }
                        }
                        Rectangle {
                            Layout.fillWidth: true; Layout.fillHeight: true; radius: 8; color: "#1e1e1e"
                            Column {
                                anchors.centerIn: parent
                                Text { text: "CHARGE"; color: "#666666"; font.pixelSize: 10; font.bold: true }
                                Text { text: "2000.0 uC"; color: "#ff9100"; font.pixelSize: 16; font.bold: true }
                            }
                        }
                    }
                }
            }

            // 2. 启动/停止按钮
            Rectangle {
                id: actionButton
                Layout.fillWidth: true; Layout.preferredHeight: 80; radius: 12
                property bool isRunning: false
                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: actionButton.isRunning ? "#ff5252" : "#2979ff"
                        Behavior on color { ColorAnimation { duration: 300 } }
                    }
                    GradientStop {
                        position: 1.0
                        color: actionButton.isRunning ? "#c62828" : "#1565c0"
                        Behavior on color { ColorAnimation { duration: 300 } }
                    }
                }
                Column {
                    anchors.centerIn: parent; spacing: 4
                    Row {
                        spacing: 8; anchors.horizontalCenter: parent.horizontalCenter
                        Text {
                            text: actionButton.isRunning ? "\uf04d" : "\uf04b"
                            font.family: iconFont.name; color: "white"; font.pixelSize: 24
                        }
                        Text {
                            text: actionButton.isRunning ? "停止输出" : "启动输出"
                            color: "white"; font.pixelSize: 22; font.bold: true
                        }
                    }
                    Text {
                        text: actionButton.isRunning ? "OUTPUTTING..." : "READY TO FIRE"
                        color: Qt.rgba(1,1,1,0.6)
                        font.pixelSize: 10; anchors.horizontalCenter: parent.horizontalCenter; font.letterSpacing: 2
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    onPressed: parent.scale = 0.98
                    onReleased: parent.scale = 1.0
                    onClicked: {
                        actionButton.isRunning = !actionButton.isRunning
                        console.log(actionButton.isRunning ? "Started!" : "Stopped!")
                        if (toastRef) {
                            toastRef.show(actionButton.isRunning ? "输出已启动 ⚡" : "输出已停止 🛑")
                        }
                    }
                }
            }
        }
    }
}
