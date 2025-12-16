#pragma once
#include <QObject>
#include <QTimer>
#include <QList>
#include "hal/IBackend.h"

// 状态定义


class TreatmentService : public QObject
{
    Q_OBJECT
public:
    enum class Runstate {
        Idle,
        Running,
        Paused,
        Error
    };
    Q_ENUM(Runstate)
    explicit TreatmentService(IBackend *backend, QObject *parent = nullptr);

    // 纯业务接口
    void startTreatment(int duration);
    void stopTreatment();
    // 接收结构体参数
    void updateParameters(const StimulationParam &param);
    void setPIDParameters(const PIDParam &pid);

    // Getter
    Runstate currentState() const { return m_state; }
    int remainingTime() const { return m_remaining_seconds; }
    StimulationParam m_currentParam;

signals:
    // 状态变化
    void stateChanged(Runstate newState);
    // 时间更新
    void timeUpdated(int seconds);
    // 监测数据就绪
    void monitoringDataReady(float impedance, int battery, int error);
    // 波形数据就绪
    void waveformReceived(const QVector<float> &data);


private:
    IBackend *m_backend;
    QTimer *m_timer;
    Runstate m_state;
    int m_remaining_seconds;

    // 内部处理逻辑
    void onTimerTick();
    void handleStatusPacket(const StatusPacket &packet);
    void handleWaveformPacket(const WaveformPacket &packet);

};
