#include "hal/WinBackend.h" // 确保路径正确
#include <QDebug>
#include <QtMath>     // qSin, M_PI
#include <QDateTime>  // 用于打印精确时间戳
#include <cstdlib>    // rand()
#include <cstring>    // memset

// 辅助宏：打印带时间戳的 Log
#define LOG_SIM(msg) qDebug().noquote() << "[" << QDateTime::currentDateTime().toString("HH:mm:ss.zzz") << "][WinBackend]" << msg

WinBackend::WinBackend(QObject *parent)
    : IBackend(parent), m_isRunning(false), m_phase(0.0)
{
    // 模拟 M0 的采样频率
    // 设置为 50ms (20Hz) 刷新率，这也是 UI 图表常见的刷新频率
    m_simTimer = new QTimer(this);
    m_simTimer->setInterval(50); 
    connect(m_simTimer, &QTimer::timeout, this, &WinBackend::onSimulateTimer);
    
    // 启动模拟器
    m_simTimer->start();
    
    LOG_SIM("=========================================");
    LOG_SIM("   PC Simulation Environment Started     ");
    LOG_SIM("   Timer Interval: 50ms                  ");
    LOG_SIM("=========================================");
}

WinBackend::~WinBackend()
{
    LOG_SIM("Simulation Stopped.");
}

void WinBackend::startStimulation(const StimulationParam &param)
{
    m_isRunning = true;
    m_cachedParam = param;
    
    // 重置相位，保证每次开始波形都从 0 开始，看起来更舒服
    m_phase = 0.0; 

    LOG_SIM(">>> CMD_START RECEIVED <<<");
    LOG_SIM(QString("  Freq       : %1 Hz").arg(param.freq));
    LOG_SIM(QString("  Pos Amp    : %1 mA").arg(param.posAmp));
    LOG_SIM(QString("  Neg Amp    : %1 mA").arg(param.negAmp));
    LOG_SIM(QString("  Pos Width  : %1 us").arg(param.posW));
    LOG_SIM(QString("  Neg Width  : %1 us").arg(param.negW));
    LOG_SIM(QString("  Dead Time  : %1 us").arg(param.dead));
}

void WinBackend::stopStimulation()
{
    m_isRunning = false;
    LOG_SIM(">>> CMD_STOP RECEIVED <<<");
    LOG_SIM("  Output Disabled (Amplitude set to 0)");
}

void WinBackend::updateParameters(const StimulationParam &param)
{

    LOG_SIM(">>> CMD_UPDATE RECEIVED <<<");
    LOG_SIM(QString("  Freq       : %1 Hz").arg(param.freq));
    LOG_SIM(QString("  Pos Amp    : %1 mA").arg(param.posAmp));
    LOG_SIM(QString("  Neg Amp    : %1 mA").arg(param.negAmp));
    LOG_SIM(QString("  Pos Width  : %1 us").arg(param.posW));
    LOG_SIM(QString("  Neg Width  : %1 us").arg(param.negW));
    LOG_SIM(QString("  Dead Time  : %1 us").arg(param.dead));

}

void WinBackend::setPIDParameters(const PIDParam &pid)
{
    LOG_SIM(">>> CMD_SET_PID RECEIVED <<<");
    LOG_SIM(QString("  Kp: %1, Ki: %2, Kd: %3, Limit: %4")
            .arg(pid.kp).arg(pid.ki).arg(pid.kd).arg(pid.limit));
}

// 核心：造假数据
void WinBackend::onSimulateTimer()
{
    // ==========================================
    // 1. 造波形数据 (WaveformPacket)
    // ==========================================
    WaveformPacket wavePkt;
    
    // 安全起见，先把内存清零 (模拟真实驱动行为)
    memset(&wavePkt, 0, sizeof(wavePkt)); 
    
    // 如果是 Running，使用缓存的参数；否则输出 0
    float amplitude = m_isRunning ? m_cachedParam.posAmp : 0.0f;
    float frequency = m_isRunning ? (float)m_cachedParam.freq : 1.0f; 
    
    // 模拟生成正弦波
    // 假设 WAVEFORM_BATCH_SIZE 是 50 (根据 ProtocolData.h 定义)
    // 我们假设这 50 个点是高速采样的结果
    
    // 步进值：决定波形的疏密。频率越高，相位走得越快
    double phaseStep = (2.0 * M_PI * frequency) / 1000.0; // 简单模拟

    for (int i = 0; i < WAVEFORM_BATCH_SIZE; i++) {
        // y = A * sin(phase) + 随机噪声 (模拟真实电路底噪)
        float noise = (rand() % 100 - 50) / 1000.0f; // +/- 0.05mA 的噪声
        float val = amplitude * qSin(m_phase) + noise;
        
        wavePkt.adc_batch[i] = val;
        
        // 更新相位，让波形动起来
        m_phase += phaseStep; 
        if (m_phase > 2 * M_PI) m_phase -= 2 * M_PI;
    }
    
    // 发送波形信号
    emit waveDataReceived(wavePkt);

    // ==========================================
    // 2. 造状态数据 (StatusPacket)
    // ==========================================
    StatusPacket statusPkt;
    
    // 模拟电池电量波动 (95% - 96% 之间跳变，测试 UI 刷新)
    static int simBattery = 95;
    if (rand() % 10 == 0) { // 偶尔变一下
        simBattery = (simBattery == 95) ? 96 : 95;
    }
    statusPkt.battery_pct = simBattery; 
    
    // 模拟阻抗：
    // Running 时: 500欧 (正常人体阻抗) + 一点波动
    // Idle 时: 20000欧 (电极脱落/未接触)
    if (m_isRunning) {
        statusPkt.impedance = 500.0f + (rand() % 20); 
    } else {
        statusPkt.impedance = 200;
    }
    
    statusPkt.error_code = 0; // 无错误
    
    // 发送状态信号
    emit statusDataReceived(statusPkt);
    
    // ==========================================
    // 3. 周期性日志 (防止刷屏，每 20 次循环打印一次)
    // ==========================================
    static int logCounter = 0;
    if (++logCounter >= 20) { // 20 * 50ms = 1秒打印一次心跳
        logCounter = 0;
        LOG_SIM(QString("[Heartbeat] State: %1 | Amp: %2 mA | Bat: %3% | Imp: %4 Ohm")
                .arg(m_isRunning ? "RUNNING" : "IDLE")
                .arg(amplitude, 0, 'f', 2)
                .arg(statusPkt.battery_pct)
                .arg(statusPkt.impedance));
    }
}
