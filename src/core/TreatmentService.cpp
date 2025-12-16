#include "core/TreatmentService.h"
#include <QDebug>
#include <QTimer>

TreatmentService::TreatmentService(IBackend *backend,QObject *parent)
:m_backend(backend),QObject(parent)
{
    // 初始化状态机
    m_state=Runstate::Idle;
    // 初始化计时器
    m_remaining_seconds=0;
    m_timer=new QTimer(this);
    m_timer->setInterval(1000);
    connect(m_timer, &QTimer::timeout, this, &TreatmentService::onTimerTick);
    connect(m_backend, &IBackend::statusDataReceived,this,&TreatmentService::handleStatusPacket);
    connect(m_backend,&IBackend::waveDataReceived,this,&TreatmentService::handleWaveformPacket);
}

/**
 * @brief 1.开始治疗
 * @param duration 治疗时长，单位秒
 */
void TreatmentService:: startTreatment(int duration)
{
    if (m_state==Runstate::Running)
    {
        qDebug() << "Treatment is already running!";
        return;
    }
    m_remaining_seconds = duration;
    m_backend->startStimulation(m_currentParam);
    m_timer->start();
    // 状态机改变并通知controller
    m_state=Runstate::Running;
    emit stateChanged(Runstate::Running);
    emit timeUpdated(m_remaining_seconds);
}

/**
 * @brief 2.停止治疗
 */
void TreatmentService::stopTreatment()
{
    if (m_state!=Runstate::Running)
    {
        return;
    }

    if (m_timer->isActive()) 
    {
        m_timer->stop();
    }
    m_backend->stopStimulation();
    // 状态机改变并通知controller
    m_state=Runstate::Idle;
    emit stateChanged(Runstate::Idle);

    m_remaining_seconds = 0;
    emit timeUpdated(0);
}

/**
 * @brief 3.更新刺激参数
 * @param param 刺激参数结构体
 */
void TreatmentService::updateParameters(const StimulationParam &param)
{
    m_currentParam = param;
}

/**
 * @brief 4.设置 PID 参数
 * @param pid PID 参数结构体
 */
void TreatmentService::setPIDParameters(const PIDParam &pid)
{
    m_backend->setPIDParameters(pid);
}

/**
 * @brief 5.处理波形包
 * @param packet 波形数据包
 */
void TreatmentService::handleWaveformPacket(const WaveformPacket &packet)
{
    QList<float> data;
    data.reserve(WAVEFORM_BATCH_SIZE);
    for (int i = 0; i < WAVEFORM_BATCH_SIZE; i++) {
        data.append(packet.adc_batch[i]);
    }
    // 转发给 UI
    emit waveformReceived(data);
} 

/**
 * @brief 6.处理状态包
 * @param packet 状态数据包
 */
void TreatmentService::handleStatusPacket(const StatusPacket &packet)
{
    if (packet.error_code != 0 && m_state == Runstate::Running) {
        stopTreatment(); // 触发急停
    }
    emit monitoringDataReady(packet.real_freq, packet.battery_pct, packet.error_code);

}

/**
 * @brief 7.定时器槽函数
 * 每秒调用一次，更新剩余时间
 */
void TreatmentService::onTimerTick()
{

    if (m_remaining_seconds > 0) {
        m_remaining_seconds--;

        emit timeUpdated(m_remaining_seconds);
    } else {
        // 停止
        stopTreatment();
    }
}
