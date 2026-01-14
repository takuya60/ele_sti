// /*
//  * @Author: takuyasaya 1754944616@qq.com
//  * @Date: 2025-12-16 22:51:29
//  * @LastEditors: takuyasaya 1754944616@qq.com
//  * @LastEditTime: 2025-12-23 14:36:42
//  * @FilePath: \ele_sti\src\hal\RK3568Backend.cpp
//  * @Description: 硬件抽象层：负责与RK3568的SPI通信，发送控制命令，接收状态和波形数据
//  */
// #include "hal/RK3568Backend.h"
// #include <fcntl.h>
// #include <unistd.h>
// #include <QDebug>
// #include <sys/ioctl.h>
// #include <sys/types.h>
// #include <sys/stat.h>
// #include <cstring>
// #include <linux/spi/spidev.h>

// // SPI 配置参数
// static const uint32_t SPI_SPEED = 1000000; // 1MHz
// static const uint8_t  SPI_BITS  = 8;
// static const uint8_t  SPI_MODE  = 0;

// RK3568Backend::RK3568Backend(QObject *parent)
//     : IBackend(parent),m_fd(-1)
// {
//     m_readTimer = new QTimer(this);
//     m_readTimer->setInterval(20);
//     connect(m_readTimer, &QTimer::timeout, this, &RK3568Backend::readData);
// }

// RK3568Backend::~RK3568Backend()
// {
//     if (m_fd >= 0)
//     {
//         close(m_fd);
//         m_fd = -1;
//     }
// }
// /**
//  * @brief 1.初始化SPI设备
//  * @note  打开SPI设备文件，配置SPI参数
//  */
// bool RK3568Backend::init(const QString &devicePath)
// {
//     m_fd = open(devicePath.toStdString().c_str(), O_RDWR);
//     if (m_fd < 0) {
//         qCritical() << "[SPI] Failed to open device:" << devicePath;
//         return false;
//     }

//     // 配置 SPI 参数 (Mode, Bits, Speed)
//     uint8_t mode = SPI_MODE;
//     uint8_t bits = SPI_BITS;
//     uint32_t speed = SPI_SPEED;

//     if (ioctl(m_fd, SPI_IOC_WR_MODE, &mode) < 0 ||
//         ioctl(m_fd, SPI_IOC_WR_BITS_PER_WORD, &bits) < 0 ||
//         ioctl(m_fd, SPI_IOC_WR_MAX_SPEED_HZ, &speed) < 0)
//     {
//         qCritical() << "[SPI] Failed to configure SPI settings";
//         close(m_fd);
//         m_fd = -1;
//         return false;
//     }

//     qInfo() << "[SPI] Initialized success" << devicePath;
    
//     // 启动接收轮询
//     m_readTimer->start();
//     return true;
// }
// /**
//  * @brief 1.SPI 数据传输
//  * @note  使用 ioctl 进行 SPI 数据传输
//  */
// bool RK3568Backend::spiTransfer(const void *tx ,void *rx,int len)
// {
//     QMutexLocker locker (&m_mutex);
//     struct spi_ioc_transfer tr;
//     memset(&tr,0,sizeof(tr));
//     tr.tx_buf = (unsigned long)tx;
//     tr.rx_buf = (unsigned long)rx;
//     tr.len = len;
//     ssize_t ret =ioctl(m_fd,SPI_IOC_MESSAGE(1),&tr);
//     if (ret<1)
//     {
//         qDebug()<<"[SPI] Failed to transfer data";
//         return false;
//     }
//     return true;
// }
// /**
//  * @brief 2.开始刺激
//  * @note  通过ioctl发送SPI消息给M0，把prama放到packet里
//  */
// void RK3568Backend::startStimulation(const StimulationParam &param)
// {
//     ControlPacket packet={0};
//     packet.head = HEAD_CONTROL;
//     packet.cmd = CMD_START;
//     packet.freq = param.freq;
//     packet.amp_neg= param.negAmp;
//     packet.amp_pos= param.posAmp;
//     packet.positive_width= param.posW;
//     packet.negative_width= param.negW;
//     packet.dead_pulse= param.dead;
//     packet.checksum = calculateChecksum(&packet, sizeof(packet) - 1);

//     spiTransfer(&packet,nullptr,sizeof(packet));
// }

// /**
//  * @brief 3.停止刺激
//  * @note  通过ioctl发送SPI消息给M0，cmd设置成stop
//  */
// void RK3568Backend::stopStimulation()
// {
//     ControlPacket packet={0};
//     packet.head =HEAD_CONTROL;
//     packet.cmd =CMD_STOP;
//     packet.checksum = calculateChecksum(&packet, sizeof(packet) - 1);

//     spiTransfer(&packet,nullptr,sizeof(packet));
// }

// void RK3568Backend::updateParameters(const StimulationParam &param)
// {
//     ControlPacket packet={0};
//     packet.head = HEAD_CONTROL;
//     packet.cmd = CMD_UPDATE;
//     packet.freq = param.freq;
//     packet.amp_neg= param.negAmp;
//     packet.amp_pos= param.posAmp;
//     packet.positive_width= param.posW;
//     packet.negative_width= param.negW;
//     packet.dead_pulse= param.dead;
//     packet.checksum = calculateChecksum(&packet, sizeof(packet) - 1);

//     spiTransfer(&packet,nullptr,sizeof(packet));
// }
// /**
//  * @brief 4.设置PID参数
//  * @note
//  */
// void RK3568Backend::setPIDParameters(const PIDParam &pid)
// {
//     PIDPacket packet={0};
//     packet.head = HEAD_PID;
//     packet.kp = pid.kp;
//     packet.ki =pid.ki;
//     packet.kd = pid.kd;
//     packet.integ_limit = pid.limit;
//     packet.checksum = calculateChecksum(&packet, sizeof(packet) - 1);

//     spiTransfer(&packet,nullptr,sizeof(packet));
// }

// /**
//  * @brief 5.读取数据
//  * @note
//  */
// void RK3568Backend::readData()
// {
//     if (m_fd<0)    return;
//     uint8_t tx_buf[sizeof(WaveformPacket)]={0};
//     uint8_t rx_buf[sizeof(WaveformPacket)]={0};
//     if (spiTransfer(tx_buf,rx_buf,sizeof(WaveformPacket)))
//     {
//        uint8_t head=rx_buf[0];
//        if (head==HEAD_WAVEFORM)
//        {
//         WaveformPacket *packet=(WaveformPacket *)rx_buf;
//         if (calculateChecksum(packet, sizeof(WaveformPacket) - 1) == packet->checksum) {
//                 emit waveDataReceived(*packet);
//             }
//        }
//        if (head==HEAD_STATUS)
//        {
//         StatusPacket *packet=(StatusPacket *)rx_buf;
//         if (calculateChecksum(packet, sizeof(StatusPacket) - 1) == packet->checksum) {
//                 emit statusDataReceived(*packet);
//             }
//        }
       
//     }
// }
// void RK3568Backend::setGpio(const char *gpinPin,int value)
// {
//     QString path = QString("/sys/class/gpio//gpio%1/value")
//     QFile file(path);
//     if (file.open(QIODevice::WriteOnly)){
//         file.write(value ? "1" : "0");
//         file.close();
//     }
// }

// void RK3568Backend::enableHardwareSwitch(bool enable)
// {
//     if (enable) {
//         // === 开启输出序列 ===
//         // 1. 确保 PRE 释放 (高)
//         setGpio(GPIO_PRE, 1);
        
//         // 2. 产生 CLR 脉冲 (高 -> 低 -> 高)
//         // 根据原理图：L=Clear(Q=L, Q#=H)。我们要 Q#=H(导通)，所以要触发 CLR。
//         setGpio(GPIO_CLR, 1); // 初始状态
//         QThread::usleep(100); // 稍作延时
//         setGpio(GPIO_CLR, 0); // 拉低：强制 Q=0, Q#=1 (导通!)
//         QThread::usleep(100);
//         setGpio(GPIO_CLR, 1); // 拉高：保持状态
        
//         qDebug() << "Hardware Switch: UNLOCKED (Output Enabled)";
//     } else {
//         // === 强制关闭序列 (急停) ===
//         // PRE = 0, CLR = 1 -> Q=1, Q#=0 (关断)
//         setGpio(GPIO_CLR, 1);
//         setGpio(GPIO_PRE, 0);
        
//         qDebug() << "Hardware Switch: LOCKED (Safe Mode)";
//     }
// }
