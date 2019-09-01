/* Copyright (C) 2018 Casper Meijn <casper@meijn.net>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
#include "onvifdevice.h"
#include "onvifdevicemanager.h"
#include "onvifdeviceservice.h"
#include "onvifmediaservice.h"

#include <KAboutApplicationDialog>
#include <KAboutData>
#include <QPointer>
#include <QSettings>
#include <QQmlContext>

OnvifDeviceManager::OnvifDeviceManager(QObject* parent) :
    QObject(parent)
{
    qRegisterMetaType<QList<OnvifDevice*>> ("QList<OnvifDevice*>");
}

void OnvifDeviceManager::loadDevices()
{
    Q_ASSERT(m_deviceList.isEmpty());

    QSettings settings;
    int size = settings.beginReadArray("devices");
    for (int i = 0; i < size; i++) {
        settings.setArrayIndex(i);
        OnvifDevice* device = createNewDevice();
        device->setDeviceName(settings.value("deviceName").toString());
        device->setHostName(settings.value("hostName").toString());
        device->setUserName(settings.value("userName").toString());
        device->setPassword(settings.value("password").toString());
        device->setPreferContinuousMove(settings.value("preferContinuousMove").toBool());
        device->setPreferredVideoStreamProtocol(settings.value("preferredVideoStreamProtocol").toString());

        device->connectToDevice();
    }
    settings.endArray();
}

void OnvifDeviceManager::saveDevices()
{
    QSettings settings;
    settings.beginWriteArray("devices");
    for (int i = 0; i < m_deviceList.count(); i++) {
        auto device = m_deviceList.at(i);
        settings.setArrayIndex(i);
        settings.setValue("deviceName", device->deviceName());
        settings.setValue("hostName", device->hostName());
        settings.setValue("userName", device->userName());
        settings.setValue("password", device->password());
        settings.setValue("preferContinuousMove", device->preferContinuousMove());
        settings.setValue("preferredVideoStreamProtocol", device->preferredVideoStreamProtocol());
    }
    settings.endArray();
}

OnvifDevice* OnvifDeviceManager::createNewDevice()
{
    auto* device = new OnvifDevice(this);

    m_deviceList.append(device);
    emit deviceListChanged(m_deviceList);
    return device;
}

QList<OnvifDevice*> OnvifDeviceManager::deviceList() const
{
    return m_deviceList;
}

OnvifDevice* OnvifDeviceManager::at(int i)
{
    return m_deviceList.at(i);
}

int OnvifDeviceManager::appendDevice()
{
    createNewDevice();
    return m_deviceList.count() - 1;
}

void OnvifDeviceManager::removeDevice(int i)
{
    OnvifDevice* device = m_deviceList.takeAt(i);
    emit deviceListChanged(m_deviceList);
    device->deleteLater();
}

int OnvifDeviceManager::indexOf(OnvifDevice* device)
{
    return m_deviceList.indexOf(device);
}

int OnvifDeviceManager::size()
{
    return m_deviceList.size();
}

void OnvifDeviceManager::aboutApplication()
{
    new KAboutApplicationDialog(KAboutData::applicationData(), nullptr);
}
