import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes
import QtQuick.Controls.Basic
import QtQuick.Effects
import ELE_Sti 1.0
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
    property real paramPosWidth: 200
    property real paramNegWidth: 200
    property real paramDeadTime: 50
    property real paramPeriod: 1000

    property string unitPosWidth: "us"
    property string unitNegWidth: "us"
    property string unitDeadTime: "us"
    property string unitPeriod: "us"

    property real paramPosAmp: 30
    property real paramNegAmp: 30

    property string selectedWaveform: "方波"

    // --- 辅助函数：统一转换为微秒 (us) ---
    function getUsValue(val, unit) {
        if (unit === "ms") {
            return Math.round(val * 1000);
        } else {
            return Math.round(val);
        }
    }

    function syncParamsToCpp() {
        let periodUs = getUsValue(paramPeriod, unitPeriod);
        let freq = (periodUs > 0) ? Math.round(1000000.0 / periodUs) : 0;

        treatmentManager.updateParameters(
            freq,
            paramPosAmp,
            paramNegAmp,
            getUsValue(paramPosWidth, unitPosWidth),
            getUsValue(paramDeadTime, unitDeadTime),
            getUsValue(paramNegWidth, unitNegWidth)
        )
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: pageRoot.forceActiveFocus()
    }

    // ==========================================
    // 组件已被移除，移至 ParamSlider.qml
    // ==========================================

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
                z: 99
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
                Components.EDropdown {
                    Layout.preferredWidth: 140; Layout.preferredHeight: 40; radius: 6
                    headerColor: "transparent"; textColor: "white"; fontSize: 14
                    model: [ { text: "方波" }, { text: "三角波" }, { text: "正弦波" }, { text: "梯形波" } ]
                    title: selectedWaveform
                    onSelectionChanged: (index, item) => { selectedWaveform = item.text }
                }
                Item { Layout.fillWidth: true }
                Components.EButton { text: "应用至所有通道"; backgroundVisible: true; height: 36 }
            }

            // 2. 时域参数设置卡片 (Timing)
            Components.EBlurCard {
                Layout.fillWidth: true; Layout.preferredHeight: 300
                layer.enabled: true
                blurSource: bgImage; blurAmount: 0.7; borderRadius: 24; borderWidth: 1; borderColor: "#30FFFFFF"

                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 20; spacing: 20
                    RowLayout {
                        Text { text: "\uf1fe"; font.family: iconFont.name; color: theme.focusColor; font.pixelSize: 25 }
                        Text { text: "时域参数设置 (TIMING)"; color: "#dddddd"; font.bold: true; font.pixelSize: 18 }
                    }
                    GridLayout {
                        columns: 2; columnSpacing: 40; rowSpacing: 30; Layout.fillWidth: true

                        Components.ParamSlider {
                            title: "正向脉宽"; value: paramPosWidth; unit: unitPosWidth;
                            accentColor: "#2979ff"
                            onValueChanged: paramPosWidth = value; onUnitChanged: unitPosWidth = unit;
                            onModified: pageRoot.syncParamsToCpp()
                        }
                        Components.ParamSlider {
                            title: "反向脉宽"; value: paramNegWidth; unit: unitNegWidth;
                            accentColor: "#2979ff"
                            onValueChanged: paramNegWidth = value; onUnitChanged: unitNegWidth = unit;
                            onModified: pageRoot.syncParamsToCpp()
                        }
                        Components.ParamSlider {
                            title: "死区时间"; value: paramDeadTime; unit: unitDeadTime;
                            accentColor: "#2979ff"
                            onValueChanged: paramDeadTime = value; onUnitChanged: unitDeadTime = unit;
                            onModified: pageRoot.syncParamsToCpp()
                        }
                        Components.ParamSlider {
                            title: "刺激周期"; value: paramPeriod; unit: unitPeriod;
                            accentColor: "#00e676"
                            onValueChanged: paramPeriod = value; onUnitChanged: unitPeriod = unit;
                            onModified: pageRoot.syncParamsToCpp()
                        }
                    }
                }
            }

            // 3. 输出强度设置卡片
            Components.EBlurCard {
                Layout.fillWidth: true; Layout.fillHeight: true; layer.enabled: true
                blurSource: bgImage; blurAmount: 0.7; borderRadius: 24; borderWidth: 1; borderColor: "#30FFFFFF"

                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 20; spacing: 30
                    RowLayout {
                        Text { text: "\uf0e7"; font.family: iconFont.name; color: theme.focusColor; font.pixelSize: 18 }
                        Text { text: "输出强度设置 (INTENSITY)"; color: "#dddddd"; font.bold: true; font.pixelSize: 18 }
                    }
                    GridLayout {
                        columns: 2; columnSpacing: 40; Layout.fillWidth: true

                        Components.ParamSlider {
                            title: "正向幅值"; value: paramPosAmp;
                            toValue: 100; unit: "mA"; unitOptions: ["mA"]; accentColor: "#ff9100"
                            onValueChanged: paramPosAmp = value
                            onModified: pageRoot.syncParamsToCpp()
                        }
                        Components.ParamSlider {
                            title: "反向幅值"; value: paramNegAmp;
                            toValue: 100; unit: "mA"; unitOptions: ["mA"]; accentColor: "#ff9100"
                            onValueChanged: paramNegAmp = value
                            onModified: pageRoot.syncParamsToCpp()
                        }
                    }
                    Rectangle { Layout.fillWidth: true; height: 1; color: "#333333" }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 20
                        Text { text: "治疗时长"; color: "#cccccc"; font.bold: true; font.pixelSize: 18; transform: Translate { x: 4 ;y:-4} }

                        Switch {
                            id: timerSwitch; text: checked ? "定时结束" : "手动结束"; checked: true
                            Layout.alignment: Qt.AlignBottom; Layout.bottomMargin: 30
                            indicator: Rectangle {
                                implicitWidth: 40; implicitHeight: 20
                                x: timerSwitch.leftPadding; y: parent.height / 2 - height / 2; radius: 10
                                color: timerSwitch.checked ? "#00e676" : "#333333"; border.color: "#333333"
                                Rectangle {
                                    x: timerSwitch.checked ? parent.width - width : 0; width: 20; height: 20; radius: 10
                                    color: "white"; border.color: "#999999"
                                    Behavior on x { NumberAnimation { duration: 200 } }
                                }
                            }
                            contentItem: Text { text: timerSwitch.text; color: "#888888"; font.pixelSize: 14; verticalAlignment: Text.AlignVCenter; leftPadding: timerSwitch.indicator.width + timerSwitch.spacing }
                            transform: Translate { x: 8}
                        }
                        Item { Layout.fillWidth: true }

                        Components.ParamSlider {
                            id: durationSlider; Layout.preferredWidth: 300;
                            toValue: 20; title: ""; value: 5
                            unit: "min"; unitOptions: ["min"]; accentColor: "#00e676"
                            transform: Translate { y: -12 } enabled: timerSwitch.checked
                            opacity: enabled ? 1.0 : 0.5; Behavior on opacity { NumberAnimation { duration: 200 } }
                            showInfinityWhenDisabled: true
                            // 只有开始治疗时才读取时长，所以这里不需要 onModified
                        }
                        transform: Translate { x: 8}
                    }
                }
            }
        }

        // ================= 右侧：动态波形预览 =================
        ColumnLayout {
            Layout.fillHeight: true; Layout.preferredWidth: 1; Layout.fillWidth: true; spacing: 20
            Components.EBlurCard {
                Layout.fillWidth: true; Layout.fillHeight: true; layer.enabled: true
                blurSource: bgImage; blurAmount: 0.4; borderRadius: 24; borderWidth: 1; borderColor: "#30FFFFFF"

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

                    Item {
                        id: waveContainer
                        Layout.fillWidth: true; Layout.fillHeight: true; Layout.minimumHeight: 200; clip: true

                        property real valPosWidthUs: pageRoot.getUsValue(paramPosWidth, unitPosWidth)
                        property real valNegWidthUs: pageRoot.getUsValue(paramNegWidth, unitNegWidth)
                        property real valDeadTimeUs: pageRoot.getUsValue(paramDeadTime, unitDeadTime)

                        property real timeRange: Math.max(2000, valPosWidthUs + valNegWidthUs + valDeadTimeUs + 500)
                        property real ampRange: 120
                        property real pxPerUs: width / timeRange
                        property real pxPermA: (height / 2) / ampRange
                        property real zeroY: height / 2

                        Canvas {
                            anchors.fill: parent
                            onPaint: {
                                var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height);
                                ctx.strokeStyle = "#222222"; ctx.lineWidth = 1; ctx.beginPath();
                                for(var i=0; i<height; i+=30) { ctx.moveTo(0, i); ctx.lineTo(width, i); }
                                for(var j=0; j<width; j+=30) { ctx.moveTo(j, 0); ctx.lineTo(j, height); }
                                ctx.stroke();
                                ctx.strokeStyle = "#40ffffff"; ctx.lineWidth = 1; ctx.setLineDash([4, 4]); ctx.beginPath();
                                var yPos50 = parent.zeroY - (100 * parent.pxPermA); ctx.moveTo(0, yPos50); ctx.lineTo(width, yPos50);
                                var yNeg50 = parent.zeroY + (100 * parent.pxPermA); ctx.moveTo(0, yNeg50); ctx.lineTo(width, yNeg50);
                                ctx.stroke();
                                ctx.strokeStyle = "#444444"; ctx.lineWidth = 2; ctx.setLineDash([]); ctx.beginPath();
                                ctx.moveTo(0, parent.zeroY); ctx.lineTo(width, parent.zeroY); ctx.stroke();
                            }
                        }

                        Repeater {
                            model: 2
                            delegate: Shape {
                                id: waveShape
                                anchors.fill: parent; z: 0
                                property bool isGlowLayer: index === 0
                                layer.enabled: isGlowLayer
                                layer.effect: MultiEffect { blurEnabled: true; blurMax: 10; blur: 2.0; brightness: 0.3; saturation: 0.2 }
                                opacity: isGlowLayer ? 0.4 : 1.0
                                ShapePath {
                                    strokeWidth: waveShape.isGlowLayer ? 8.5 : 4.5
                                    strokeColor: waveShape.isGlowLayer ? theme.focusColor : Qt.lighter(theme.focusColor, 1.3)
                                    fillColor: "transparent"
                                    startX: 20; startY: waveContainer.zeroY
                                    PathLine { x: 20 + 20; y: waveContainer.zeroY }
                                    PathLine { relativeX: 0; y: waveContainer.zeroY - (paramPosAmp * waveContainer.pxPermA) }
                                    PathLine { relativeX: waveContainer.valPosWidthUs * waveContainer.pxPerUs; relativeY: 0 }
                                    PathLine { relativeX: 0; y: waveContainer.zeroY }
                                    PathLine { relativeX: waveContainer.valDeadTimeUs * waveContainer.pxPerUs; relativeY: 0 }
                                    PathLine { relativeX: 0; y: waveContainer.zeroY + (paramNegAmp * waveContainer.pxPermA) }
                                    PathLine { relativeX: waveContainer.valNegWidthUs * waveContainer.pxPerUs; relativeY: 0 }
                                    PathLine { relativeX: 0; y: waveContainer.zeroY }
                                    PathLine { x: waveContainer.width; y: waveContainer.zeroY }
                                }
                            }
                        }

                        Item {
                            anchors.fill: parent; z: 10
                            Text { text: "+100mA"; color: "#80ffffff"; font.pixelSize: 10; x: 5; y: waveContainer.zeroY - (100 * waveContainer.pxPermA) - 12 }
                            Text { text: "-100mA"; color: "#80ffffff"; font.pixelSize: 10; x: 5; y: waveContainer.zeroY + (100 * waveContainer.pxPermA) - 12 }
                            Text {
                                text: unitPosWidth === "ms" ? paramPosWidth.toFixed(2) + "ms" : Math.round(paramPosWidth) + "us"
                                color: "#2979ff"; font.pixelSize: 12; font.bold: true
                                x: 40 + (waveContainer.valPosWidthUs * waveContainer.pxPerUs) / 2 - width/2
                                y: waveContainer.zeroY - (paramPosAmp * waveContainer.pxPermA) - 15
                            }
                            Text {
                                text: unitDeadTime === "ms" ? paramDeadTime.toFixed(2) + "ms" : Math.round(paramDeadTime) + "us"
                                color: "#ffaa00"; font.pixelSize: 12; font.bold: true
                                x: 40 + (waveContainer.valPosWidthUs * waveContainer.pxPerUs) + (waveContainer.valDeadTimeUs * waveContainer.pxPerUs) / 2 - width/2
                                y: waveContainer.zeroY - 15
                            }
                            Text {
                                text: unitNegWidth === "ms" ? paramNegWidth.toFixed(2) + "ms" : Math.round(paramNegWidth) + "us"
                                color: "#ff9100"; font.pixelSize: 12; font.bold: true
                                x: 40 + ((waveContainer.valPosWidthUs + waveContainer.valDeadTimeUs) * waveContainer.pxPerUs) + (waveContainer.valNegWidthUs * waveContainer.pxPerUs)/2 - width/2
                                y: waveContainer.zeroY + (paramNegAmp * waveContainer.pxPermA) + 5
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: updateButton
                Layout.fillWidth: true; Layout.preferredHeight: 80; radius: 12
                scale: updateMouseArea.pressed ? 0.98 : 1.0; Behavior on scale { NumberAnimation { duration: 100 } }
                gradient: Gradient { GradientStop { position: 0.0; color: "#7c4dff" } GradientStop { position: 1.0; color: "#651fff" } }
                Column {
                    anchors.centerIn: parent; spacing: 4
                    Row { spacing: 8; anchors.horizontalCenter: parent.horizontalCenter
                        Text { text: "\uf021"; font.family: iconFont.name; color: "white"; font.pixelSize: 24 }
                        Text { text: "更新参数"; color: "white"; font.pixelSize: 22; font.bold: true }
                    }
                    Text { text: "APPLY SETTINGS"; color: Qt.rgba(1,1,1,0.6); font.pixelSize: 10; anchors.horizontalCenter: parent.horizontalCenter; font.letterSpacing: 2 }
                }
                MouseArea { id: updateMouseArea; anchors.fill: parent; onClicked: confirmWindow.open(updateButton) }
            }

            Rectangle {
                id: actionButton
                Layout.fillWidth: true; Layout.preferredHeight: 80; radius: 12
                property bool isRunning: treatmentManager.currentState === TreatmentManager.Running
                gradient: Gradient {
                    GradientStop { position: 0.0; color: actionButton.isRunning ? "#ff5252" : "#2979ff"; Behavior on color { ColorAnimation { duration: 300 } } }
                    GradientStop { position: 1.0; color: actionButton.isRunning ? "#c62828" : "#1565c0"; Behavior on color { ColorAnimation { duration: 300 } } }
                }
                Column {
                    anchors.centerIn: parent; spacing: 4
                    Row { spacing: 8; anchors.horizontalCenter: parent.horizontalCenter
                        Text { text: actionButton.isRunning ? "\uf04d" : "\uf04b"; font.family: iconFont.name; color: "white"; font.pixelSize: 24 }
                        Text { text: actionButton.isRunning ? "停止输出" : "启动输出"; color: "white"; font.pixelSize: 22; font.bold: true }
                    }
                    Text { text: actionButton.isRunning ? "OUTPUTTING..." : "READY TO FIRE"; color: Qt.rgba(1,1,1,0.6); font.pixelSize: 10; anchors.horizontalCenter: parent.horizontalCenter; font.letterSpacing: 2 }
                }
                function toggleTreatment() {
                        if (actionButton.isRunning) {
                            // --- 停止逻辑 ---
                            treatmentManager.stopTreatment()
                            if (typeof toastRef !== "undefined" && toastRef) toastRef.show("停止刺激")
                        } else {
                            // --- 启动逻辑
                            var minutes = Math.round(durationSlider.value)
                            var durationSeconds = timerSwitch.checked ? (minutes * 60) : 36000

                            // 获取界面参数
                            let pUs = getUsValue(paramPeriod, unitPeriod);
                            let freq = (pUs > 0) ? Math.round(1000000.0 / pUs) : 0;

                            // 调用 C++ 开始
                            treatmentManager.startTreatment(
                                durationSeconds,
                                freq,
                                paramPosAmp,
                                paramNegAmp,
                                getUsValue(paramPosWidth, unitPosWidth),
                                getUsValue(paramDeadTime, unitDeadTime),
                                getUsValue(paramNegWidth, unitNegWidth)
                            )

                            if (typeof toastRef !== "undefined" && toastRef) toastRef.show("开始刺激")
                        }
                    }
                Connections {
                        target: treatmentManager

                        function onSerialTriggerReceived() {
                            console.log("QML: 收到串口指令，执行切换动作")

                            // 【核心修改】：去掉之前的 if 判断
                            // 直接调用切换函数。
                            // 效果：Start -> Stop, Stop -> Start
                            actionButton.toggleTreatment()
                        }
                    }
                MouseArea {
                    anchors.fill: parent
                    onPressed: parent.scale = 0.98; onReleased: parent.scale = 1.0
                    onClicked: {
                        onClicked: actionButton.toggleTreatment()
                    }
                }
            }
        }
    }

    Components.EAnimatedWindow {
        id: confirmWindow
        popupWidth: 550; popupHeight: 420; popupRadius: 24; fullscreenColor: "#222222"; dismissOnOverlay: true; animDuration: 400

        ColumnLayout {
            anchors.centerIn: parent; width: 500; spacing: 30
            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter; spacing: 10
                Text { text: "\uf071"; font.family: iconFont.name; color: "#ffab00"; font.pixelSize: 60; Layout.alignment: Qt.AlignHCenter }
                Text { text: "CONFIRM UPDATE"; color: "white"; font.bold: true; font.pixelSize: 24; Layout.alignment: Qt.AlignHCenter }
                Text { text: "即将向设备下发以下刺激参数，请确认安全。"; color: "#aaaaaa"; font.pixelSize: 14; Layout.alignment: Qt.AlignHCenter }
            }
            Rectangle { Layout.fillWidth: true; height: 1; color: "#333333" }
            GridLayout {
                Layout.fillWidth: true; columns: 2; rowSpacing: 15; columnSpacing: 20
                component ParamRow: RowLayout {
                    property string name; property string val; property color valColor: "white"; Layout.fillWidth: true
                    Text { text: name; color: "#888888"; font.pixelSize: 16; Layout.fillWidth: true }
                    Text { text: val; color: valColor; font.pixelSize: 18; font.bold: true }
                }
                ParamRow { name: "刺激周期 "; val: unitPeriod === "ms" ? paramPeriod.toFixed(2)+" ms" : paramPeriod+" us" }
                ParamRow { name: "正向幅值 "; val: paramPosAmp.toFixed(1) + " mA"; valColor: "#ff9100" }
                ParamRow { name: "反向幅值 "; val: paramNegAmp.toFixed(1) + " mA"; valColor: "#ff9100" }
                ParamRow { name: "正向脉宽 "; val: unitPosWidth === "ms" ? paramPosWidth.toFixed(2)+" ms" : paramPosWidth+" us" }
                ParamRow { name: "反向脉宽 "; val: unitNegWidth === "ms" ? paramNegWidth.toFixed(2)+" ms" : paramNegWidth+" us" }
            }
            Rectangle { Layout.fillWidth: true; height: 1; color: "#333333" }
            RowLayout {
                Layout.fillWidth: true; Layout.topMargin: 20; spacing: 20
                Components.EButton { Layout.fillWidth: true; Layout.preferredHeight: 50; radius: 25; buttonColor: "#333333"; iconCharacter: "\uf00d"; iconRotateOnClick: true; text: "取 消"; onClicked: { confirmWindow.state = "iconState" } }
                Components.EButton { Layout.fillWidth: true; Layout.preferredHeight: 50; radius: 25; buttonColor: "#651fff"; iconCharacter: "\uf021"; iconRotateOnClick: true; text: "立即更新"; onClicked: { pageRoot.syncParamsToCpp(); if (toastRef) toastRef.show("参数已下发"); confirmWindow.state = "iconState" } }
            }
        }
    }
}
