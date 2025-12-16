#include "hal/RK3568Backend.h"
#include <fcntl.h>
#include <unistd.h>
#include <QDebug>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <linux/spi/spidev.h>

RK3568Backend::RK3568Backend{

    m_fd= open("/dev/spidev1.0", O_RDWR);
    if (m_fd < 0)
    {
        qDebug() << "Failed to open SPI device!";
    }
}

RK3568Backend::~RK3568Backend()
{
    if (m_fd >= 0)
    {
        close(m_fd);
        m_fd = -1;
    }
}
/**
 * @brief 1.开始刺激
 * @note  通过ioctl发送SPI消息给M0，把prama放到packet里
 */
void RK3568Backend::startStimulation(const StimulationParam &param)
{
    ControlPacket packet={0};
    packet.head = HEAD_CONTROL;
    packet.cmd = CMD_START;
    packet.freq = param.freq;
    packet.amp_neg= param.negAmp;
    packet.amp_pos= param.posAmp;
    packet.positive_width= param.posW;
    packet.negative_width= param.negW;
    packet.dead_pulse= param.dead;
    packet.checksum = calculateChecksum(&packet, sizeof(packet) - 1);

    struct spi_ioc_transfer tr;
    memset(&tr,0,sizeof(tr));   //清洗内存
    tr.tx_buf = (unsigned long)&packet;
    tr.len = sizeof(packet);

    ssize_t ret = ioctl(m_fd, SPI_IOC_MESSAGE(1), &tr);
    if (ret < 1)
    {
        qDebug() << "[SPI]Failed to start Stimulation";
    }

}
/**
 * @brief 2..停止刺激
 * @note  通过ioctl发送SPI消息给M0，cmd设置成stop
 */
void RK3568Backend::stopStimulation()
{
    ControlPacket packet={0};
    packet.head =HEAD_CONTROL;
    packet.cmd =CMD_STOP;
    packet.checksum = calculateChecksum(&packet, sizeof(packet) - 1);

    struct spi_ioc_transfer tr;
    memset(&tr,0,sizeof(tr));
    tr.tx_buf = (unsigned long)&packet;
    tr.len = sizeof(packet);

    ssize_t ret = ioctl(m_fd, SPI_IOC_MESSAGE(1), &tr);
    if (ret < 1)
    {
        qDebug() << "[SPI]Failed to stop Stimulation";
    }
}

void RK3568Backend::setPIDParameters(const PIDParam &pid)
{
    PIDPacket packet={0};
    packet.head = HEAD_PID;
    packet.kp = pid.kp;
    packet.ki =pid.ki;
    packet.kd = pid.kd;
    packet.integ_limit = pid.limit;
    packet.checksum = calculateChecksum(&packet, sizeof(packet) - 1);

    struct spi_ioc_transfer tr;
    memset(&tr,0,sizeof(tr));
    tr.tx_buf = (unsigned long)&packet;
    tr.len = sizeof(packet);

    ssize_t ret = ioctl(m_fd, SPI_IOC_MESSAGE(1), &tr);
    if (ret < 1)
    {
        qDebug() << "[SPI]Failed to set PID Parameters";
    }
}
