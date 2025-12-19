import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes
import QtQuick.Controls.Basic
import QtQuick.Effects
import ELE_Sti 1.0
import "../components" as Components

Page {
    id: monitorPage
    background: null

    // ==========================================
    // 1. 核心数据绑定
    // ==========================================
    property int remainingSeconds: treatmentManager.remainingTime

    // 状态绑定
    property string statusText: {
        if (realTimeError !== 0) return "硬件故障 (ERR:" + realTimeError + ")"
        switch(treatmentManager.currentState) {
            case TreatmentManager.Idle: return "设备待机 (Standby)"
            case TreatmentManager.Running: return "治疗输出中 (Firing)"
            case TreatmentManager.Paused: return "已暂停 (Paused)"
            default: return "--"
        }
    }

    property color statusColor: {
        if (realTimeError !== 0) return "#ff1744" // 故障红
        switch(treatmentManager.currentState) {
            case TreatmentManager.Running: return "#00e676" // 运行绿
            case TreatmentManager.Paused: return "#ff9100"  // 暂停橙
            default: return "#9e9e9e"                       // 待机灰
        }
    }

    // --- 实时计算参数 ---
    property real realTimeCurrent: 0.0      // 电流 (mA)
    property real realTimeVoltage: 0.0      // 电压 (V)
    property int  realTimeImpedance: 0      // 阻抗 (Ω)
    property real realTimePower: 0.0        // 功率 (mW)
    property real totalEnergy: 0.0          // 累计能量 (mJ)

    property int  batteryLevel: 100         // 电池 (%)
    property int  realTimeError: 0          // 错误码

    // ==========================================
    // 2. 增强型数据监听器
    // ==========================================
    Connections {
        target: treatmentManager

        // A. 波形与峰值监听 (频率快: ~20ms一次)
        function onWaveformReceived(data) {
            // 1. 刷新波形
            waveCanvas.points = data
            waveCanvas.requestPaint()

            // 2. 计算实时峰值电流 (取绝对值最大)
            let maxVal = 0.0
            if (data.length > 0) {
                for(let i=0; i<data.length; i++) {
                    if(Math.abs(data[i]) > maxVal) maxVal = Math.abs(data[i])
                }
            }
            monitorPage.realTimeCurrent = maxVal

            // 3. 联动计算：电压 = 电流 * 阻抗
            // 注意单位：mA * Ω = mV -> /1000 = V
            if (monitorPage.realTimeImpedance > 0 && monitorPage.realTimeImpedance < 10000) {
                monitorPage.realTimeVoltage = (monitorPage.realTimeCurrent * monitorPage.realTimeImpedance) / 1000.0
            } else {
                monitorPage.realTimeVoltage = 0.0
            }

            // 4. 联动计算：瞬时功率 P = I * V (单位 mW)
            monitorPage.realTimePower = monitorPage.realTimeCurrent * monitorPage.realTimeVoltage

            // 5. 联动计算：累计能量 (积分)
            // 假设每次数据包间隔 50ms (0.05s)
            // Energy (mJ) += Power (mW) * time (s)
            if (treatmentManager.currentState === TreatmentManager.Running) {
                monitorPage.totalEnergy += monitorPage.realTimePower * 0.05
            }
        }

        // B. 状态数据监听 (频率慢: ~1s一次)
        function onMonitorDataUpdated(impedance, battery, error) {
            monitorPage.realTimeImpedance = impedance
            monitorPage.batteryLevel = battery
            monitorPage.realTimeError = error

            // 如果是在待机状态，重置能量统计
            if (treatmentManager.currentState === TreatmentManager.Idle) {
                monitorPage.totalEnergy = 0.0
            }
        }
    }

    // 格式化时间
    function formatTime(seconds) {
        var m = Math.floor(seconds / 60)
        var s = seconds % 60
        return (m < 10 ? "0" + m : m) + ":" + (s < 10 ? "0" + s : s)
    }

    // ================= 主布局 =================
    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        // ----------------- 左侧：波形显示 -----------------
        Components.EBlurCard {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: 7

            // 顶部栏：标题 + 电池电量
            RowLayout {
                anchors { top: parent.top; left: parent.left; right: parent.right; margins: 16 }
                z: 1
                Text {
                    text: "实时输出监控 (Real-time Output)"
                    color: "#88ffffff"; font.pixelSize: 18 ; font.bold: true;
                }
                Item { Layout.fillWidth: true }
            }

            // Canvas 波形绘制 (保持你之前的逻辑，增加了根据 Current 动态计算 Y 轴)
            // Canvas 波形绘制
            Canvas {
                id: waveCanvas
                anchors.fill: parent
                // 调整边距，给文字留出一点点空间，防止被切掉
                anchors.margins: 16
                anchors.topMargin: 40
                property var points: []

                onPaint: {
                    var ctx = getContext("2d")
                    var w = width
                    var h = height
                    ctx.clearRect(0, 0, w, h)

                    // ==========================================
                    // 0. 定义量程 (将此变量移到最前方)
                    // ==========================================
                    var rangeMax = 50.0 // 假设最大量程 50mA

                    // ==========================================
                    // 1. 绘制网格与纵坐标
                    // ==========================================
                    ctx.lineWidth = 1

                    // --- 设置文字样式 ---
                    ctx.font = "10px sans-serif"
                    ctx.fillStyle = "#aaFFFFFF" // 淡白色文字
                    ctx.textAlign = "left"      // 文字靠左对齐

                    // --- 绘制横线 (Y轴刻度) ---
                    // i=0:顶端(+50), i=1:(+25), i=2:中线(0), i=3:(-25), i=4:底端(-50)
                    for(var i=0; i<5; i++) {
                        var y = h/4 * i

                        // A. 画线
                        ctx.strokeStyle = (i === 2) ? "#40ffffff" : "#20ffffff" // 中线稍微亮一点
                        ctx.beginPath()
                        ctx.moveTo(0, y)
                        ctx.lineTo(w, y)
                        ctx.stroke()

                        // B. 画纵坐标数值
                        var val = rangeMax - (i * (rangeMax / 2)) // 计算当前线的数值

                        // 处理文字垂直对齐，防止顶部和底部文字被切掉
                        if (i === 0) ctx.textBaseline = "top"          // 顶部文字向下挂
                        else if (i === 4) ctx.textBaseline = "bottom"  // 底部文字向上挂
                        else ctx.textBaseline = "middle"               // 中间文字居中

                        // 绘制文字 (x=2 留一点左边距)
                        ctx.fillText(val.toFixed(0) + ((i===0)?" mA":""), 2, y)
                    }

                    // --- 绘制竖线 (X轴网格) ---
                    ctx.strokeStyle = "#20ffffff"
                    ctx.beginPath()
                    for(var j=0; j<10; j++) {
                        var x = w/10 * j
                        ctx.moveTo(x, 0)
                        ctx.lineTo(x, h)
                    }
                    ctx.stroke()

                    // ==========================================
                    // 2. 绘制波形曲线
                    // ==========================================
                    ctx.strokeStyle = "#651fff"
                    ctx.lineWidth = 2
                    ctx.beginPath()

                    var centerY = h / 2
                    var scaleY = (h / 2) / rangeMax
                    var stepX = w / (points.length > 0 ? points.length : 1)

                    if (points.length > 0) {
                        for (var k = 0; k < points.length; k++) {
                            // 限制绘图范围，防止超出画布
                            var val = points[k]
                            if (val > rangeMax) val = rangeMax
                            if (val < -rangeMax) val = -rangeMax

                            var py = centerY - (val * scaleY)
                            var px = k * stepX
                            if (k === 0) ctx.moveTo(px, py); else ctx.lineTo(px, py)
                        }
                    } else {
                        ctx.moveTo(0, centerY); ctx.lineTo(w, centerY)
                    }
                    ctx.stroke()

                    // ==========================================
                    // 3. 填充阴影
                    // ==========================================
                    if (points.length > 0) {
                        ctx.lineTo(points.length * stepX, centerY) // 回到中线
                        ctx.lineTo(0, centerY)                     // 闭合路径
                        ctx.closePath()
                        var gradient = ctx.createLinearGradient(0, 0, 0, h)
                        gradient.addColorStop(0, "#20651fff")
                        gradient.addColorStop(1, "transparent")
                        ctx.fillStyle = gradient
                        ctx.fill()
                    }
                }
            }
        }

        // ----------------- 右侧：详细参数面板 -----------------
        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: 3
            spacing: 16

            // 1. 状态与倒计时
            Components.EBlurCard {
                Layout.fillWidth: true; Layout.preferredHeight: parent.height * 0.35
                layer.enabled: true; blurSource: bgImage; blurAmount: 0.7; borderRadius: 24
                borderWidth: 1
                borderColor: "#30FFFFFF"

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 5

                    // 状态指示
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 80; height: 24; radius: 12
                        color: Qt.rgba(statusColor.r, statusColor.g, statusColor.b, 0.2)
                        border.color: statusColor
                        Row {
                            anchors.centerIn: parent; spacing: 6
                            Rectangle { width: 8; height: 8; radius: 4; color: statusColor }
                            Text { text: treatmentManager.currentState === TreatmentManager.Running ? "RUNNING" : "STANDBY"; color: statusColor; font.bold: true; font.pixelSize: 10 }
                        }
                    }

                    // 倒计时
                    Text {
                        text: formatTime(remainingSeconds)
                        color: "white"; font.pixelSize: 56; font.bold: true; font.family: "Roboto Mono"
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Text { text: statusText; color: "#88ffffff"; font.pixelSize: 12; Layout.alignment: Qt.AlignHCenter }
                }
            }

            // 2. 六维参数矩阵
            Components.EBlurCard {
                Layout.fillWidth: true; Layout.fillHeight: true
                layer.enabled: true; blurSource: bgImage; blurAmount: 0.7; borderRadius: 24
                borderWidth: 1
                borderColor: "#30FFFFFF"

                GridLayout {
                    anchors.centerIn: parent
                    width: parent.width * 0.85
                    columns: 2
                    rowSpacing: 25; columnSpacing: 15

                    // 组件：参数显示项
                    component MonitorItem : Column {
                        property string name: ""; property string value: ""; property string unit: ""; property color valColor: "white"
                        Text { text: name; color: "#66ffffff"; font.pixelSize: 11 }
                        Row { spacing: 2; baselineOffset: 0
                            Text { text: value; color: valColor; font.pixelSize: 20; font.bold: true }
                            Text { text: unit; color: "#66ffffff"; font.pixelSize: 12; anchors.baseline: parent.children[0].baseline }
                        }
                    }

                    // --- 第一行 ---
                    MonitorItem {
                        name: "电压 (Voltage)"
                        value: realTimeVoltage.toFixed(1)
                        unit: "V"
                        valColor: "#2979ff"
                    }
                    MonitorItem {
                        name: "电流 (Current)"
                        value: realTimeCurrent.toFixed(2)
                        unit: "mA"
                        valColor: "#00e676"
                    }

                    // --- 第二行 ---
                    MonitorItem {
                        name: "瞬时功率 (Power)"
                        value: realTimePower.toFixed(0)
                        unit: "mW"
                        valColor: "#ffca28"
                    }
                    MonitorItem {
                        name: "负载阻抗 (Imp)"
                        value: realTimeImpedance > 2000 ? "OPEN" : realTimeImpedance
                        unit: realTimeImpedance > 2000 ? "" : "Ω"
                        valColor: realTimeImpedance > 2000 ? "#ff1744" : "white"
                    }

                    // --- 第三行 ---
                    MonitorItem {
                        name: "累计能量 (Energy)"
                        // 显示为焦耳 J (mJ / 1000)
                        value: (totalEnergy / 1000.0).toFixed(2)
                        unit: "J"
                    }
                    MonitorItem {
                        name: "错误代码 (Error)"
                        value: realTimeError
                        unit: ""
                        valColor: realTimeError === 0 ? "white" : "#ff1744"
                    }
                }
            }
        }
    }
}
