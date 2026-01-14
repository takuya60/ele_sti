// /*
//  * @Author: takuyasaya 1754944616@qq.com
//  * @Date: 2025-12-16 17:01:57
//  * @LastEditors: takuyasaya 1754944616@qq.com
//  * @LastEditTime: 2025-12-23 14:21:46
//  * @FilePath: \ele_sti\include\hal\RK3568Backend.h
//  * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
//  */
// #pragma once
// #include "IBackend.h"
// #include <QMutex>
// #include <QThread>
// #include <QTimer>
// #define GPIO_PRE  "100"
// #define GPIO_CLR  "101"

// class RK3568Backend : public IBackend
// {
//     Q_OBJECT

// public:
//     explicit RK3568Backend(QObject *parent = nullptr);
//             ~RK3568Backend() override;

//     bool init(const QString &devicePath = "/dev/spidev3.0");

//     // 开始/停止刺激
//     void startStimulation(const StimulationParam &param)override;
//     void stopStimulation()override;
//     void updateParameters(const StimulationParam &param)override;

//     // PID 参数设置
//     void setPIDParameters(const PIDParam &pid) override;
    
//     // 硬件使能电路
//     void setGpio(const char *gpio_Pin , int value);
//     void enableHardwareSwitch(bool enable);
// private slots:
//     void readData();

// private:
//     int m_fd;
//     QTimer* m_readTimer;
//     QMutex m_mutex;
//     bool spiTransfer(const void *tx, void *rx, int len);

// };

