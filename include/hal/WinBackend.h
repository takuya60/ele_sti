#pragma once
#include "IBackend.h"
#include <QTimer>
#include <QObject>

class WinBackend : public IBackend
{
    Q_OBJECT
public:
    explicit WinBackend(QObject *parent = nullptr);
    ~WinBackend() override;

    // --- 接口实现 ---
    // 不需要 init 函数，因为 Windows 不需要打开 /dev/spidev
    // 但为了接口统一，你可以留一个空的 init，或者在 main 里区分调用
    bool init(const QString &path = "") { return true; }

    void startStimulation(const StimulationParam &param) override;
    void stopStimulation() override;
    void setPIDParameters(const PIDParam &pid) override;
    void updateParameters(const StimulationParam &param) override;
private slots:
    // 模拟数据生成的槽函数
    void onSimulateTimer();

private:
    QTimer *m_simTimer; // 模拟定时器
    bool m_isRunning;   // 是否处于"运行"状态
    double m_phase;     // 用于生成正弦波的相位
    StimulationParam m_cachedParam; // 缓存当前的参数
};