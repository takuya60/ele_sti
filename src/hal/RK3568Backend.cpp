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
