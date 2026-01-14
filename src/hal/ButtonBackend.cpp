#include "hal/ButtonBackend.h"

ButtonBackend::ButtonBackend(QObject *parent):QObject(parent)
{
    serial=new QSerialPort(this);
    connect(serial, &QSerialPort::readyRead, this, &ButtonBackend::onReadyRead);
}
ButtonBackend::~ButtonBackend()
{
    serial->close();
}
bool ButtonBackend::openSerial(const QString &portName)
{
    if(serial->isOpen()){
        serial->close();
    }

    serial->setPortName(portName);
    serial->setBaudRate(115200);
    if (serial->open(QIODevice::ReadWrite)){
        return true;
    }
    else
        return false;
}

void ButtonBackend::onReadyRead()
{
    buffer.append(serial->readAll());
    if (buffer.size() > MAX_BUFFER_SIZE) {
        buffer.clear();
        return;
    }
    while (buffer.size()>=sizeof(ButtonPacket)){
        if ((uint8_t)buffer.at(0)!= FRAME_HEAD){
            int headIndex = buffer.indexOf((char)FRAME_HEAD);
            if (headIndex == -1){
                buffer.clear();
                return;
            }
            else{
                buffer.remove(0,headIndex);
                if (buffer.size()<sizeof(ButtonPacket)){
                    return;
                }
            }
        }

        const ButtonPacket *packet = reinterpret_cast<const ButtonPacket*>(buffer.constData());
        if (packet->tail==FRAME_TAIL){

            if (packet->cmd == 0xBB){
                emit startFromSerial();
                // 业务逻辑
            }
            buffer.remove(0,sizeof(ButtonPacket));
        }
        else{
            // 帧头对，帧尾不对，就删掉当前的帧头，继续找下一个帧头
            buffer.remove(0,1);
        }
    }
}
