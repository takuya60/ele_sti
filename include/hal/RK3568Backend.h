#pragma once
#include "IBackend.h"
#include <QMutex>
#include <QThread>
#include <QTimer>

class RK3568Backend : public IBackend
{
    Q_OBJECT

public:
    explicit RK3568Backend(QObject *parent = nullptr);
            ~RK3568Backend() override;

    bool init(const QString &devicePath = "/dev/spidev1.0");

    // 开始/停止刺激
    void startStimulation(const StimulationParam &param)override;
    void stopStimulation()override;
    // PID 参数设置
    void setPIDParameters(const PIDParam &pid) override;

private slots:
    void readData();

private:
    int m_fd;
    QTimer* m_readTimer;
    QMutex m_mutex;
    bool spiTransfer(const void *tx, void *rx, int len);

};

