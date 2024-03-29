﻿/* Copyright (C) 2018-2019 Casper Meijn <casper@meijn.net>
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
import org.kde.kirigami 2.6 as Kirigami
import QtQml.Models 2.1
import QtQuick 2.9
import QtQuick.Controls 2.3 as Controls
import QtQuick.Layouts 1.3

Kirigami.ScrollablePage {
    id: pageOverview
    title: i18n("Overview")
    objectName: "overviewPage"

    actions {
        main: Kirigami.Action {
            text: i18nc("adds a new camera", "Add")
            iconName: "list-add"
            onTriggered: {
                bottomDrawer.open()
            }
        }
        right: Kirigami.Action {
            text: i18nc("opens the \"About\" menu", "About")
            iconName: "help-about"
            onTriggered: {
                pageStack.push(aboutComponent);
            }
        }
    }

    //Close the drawer with the back button
    onBackRequested: {
        if (bottomDrawer.drawerOpen) {
            event.accepted = true;
            bottomDrawer.close();
        }
    }

    Kirigami.OverlaySheet {
        id: bottomDrawer
        contentItem: ColumnLayout {
            Controls.Button {
                text: i18n("Automaticly discover camera")
                Layout.fillWidth: true
                onClicked: {
                    pageStack.push(discoverCameraComponent);
                    bottomDrawer.close();
                }
                visible: deviceDiscover.isAvailable
            }
            Controls.Label {
                text: i18n("Automatically find a camera in your network.");
                wrapMode: Text.WordWrap
                horizontalAlignment: "AlignHCenter"
                Layout.leftMargin: Kirigami.Units.gridUnit * 2
                Layout.rightMargin: Kirigami.Units.gridUnit * 2
                Layout.fillWidth: true
                visible: deviceDiscover.isAvailable
            }
            Controls.Button {
                text: i18n("Add demonstation camera")
                Layout.fillWidth: true
                onClicked: {
                    pageStack.push(addDemoCameraComponent);
                    bottomDrawer.close();
                }
            }
            Controls.Label {
                text: i18n("These demonstation cameras show you some on the capabilities, without owning a camera.");
                wrapMode: Text.WordWrap
                horizontalAlignment: "AlignHCenter"
                Layout.leftMargin: Kirigami.Units.gridUnit * 2
                Layout.rightMargin: Kirigami.Units.gridUnit * 2
                Layout.fillWidth: true
            }
            Controls.Button {
                text: i18n("Manually add camera")
                Layout.fillWidth: true
                onClicked: {
                    selectedIndex = deviceManager.appendDevice()
                    pageStack.push(settingsComponent);
                    pageStack.currentItem.isNewDevice = true
                    bottomDrawer.close();
                }
            }
            Controls.Label {
                text: i18n("Manually adding a camera means that you need to provide the connection parameters yourself.");
                wrapMode: Text.WordWrap
                horizontalAlignment: "AlignHCenter"
                Layout.leftMargin: Kirigami.Units.gridUnit * 2
                Layout.rightMargin: Kirigami.Units.gridUnit * 2
                Layout.fillWidth: true
            }
        }

    }

    ColumnLayout {
        visible: deviceManager.size === 0

        width: pageOverview.width
        height: pageOverview.height
        Item {
            Layout.fillHeight: true
        }
        Controls.Label {
            text: i18n("You can add a camera by clicking the \"Add\" button below.")
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
        }
        Kirigami.Icon {
            source: "go-down"
            Layout.fillWidth: true
            height: Kirigami.Units.iconSizes.enormous
        }
        Item {
            Layout.fillHeight: true
        }
    }

    Kirigami.CardsLayout {
        id: view
        maximumColumnWidth: Kirigami.Units.gridUnit * 40

        Repeater {
            model: deviceManagerModel
            delegate: Kirigami.AbstractCard {
                header: ColumnLayout {
                    Kirigami.Heading {
                        level: 2
                        text: model.deviceName || i18n("Camera %1", model.index + 1)
                        Layout.fillWidth: true
                    }
                    Kirigami.Separator {
                        Layout.fillWidth: true
                    }
                }
                //NOTE: never put a Layout as contentItem as it will cause binding loops
                //SEE: https://bugreports.qt.io/browse/QTBUG-66826
                contentItem: Item {
                    //TODO: This appears to create a binding loop
//                    implicitWidth: 0
                    implicitHeight: delegateLayout.implicitHeight
                    GridLayout {
                        id: delegateLayout
                        anchors {
                            left: parent.left
                            top: parent.top
                            right: parent.right
                        }
                        Controls.Label {
                            id: errorText
                            text: i18n("An error occurred during communication with the camera.")
                            wrapMode: Text.Wrap
                            horizontalAlignment: Text.AlignHCenter
                            visible: model.errorString
                            Layout.fillWidth: true
                        }
                        Controls.Label {
                            id: snapshotUnsupportedText
                            text: i18n("The camera doesn't support the retrieval of snapshots.")
                            wrapMode: Text.Wrap
                            horizontalAlignment: Text.AlignHCenter
                            visible: !model.errorString && !model.supportsSnapshotUri
                            Layout.fillWidth: true
                        }
                        OnvifCameraViewer {
                            id: viewerItem
                            camera: model.device
                            snapshotInterval: 5000
                            loadStream: false
                            visible: !model.errorString && model.supportsSnapshotUri
                            Layout.fillWidth: true
                            //TODO: This appears to create a binding loop
                            Layout.preferredHeight: width / viewerItem.aspectRatio
                        }
                    }
                }
                footer: Kirigami.ActionToolBar {
                    id: actionsToolBar
                    actions: [
                        Kirigami.Action {
                            iconName: "view-preview"
                            text: i18nc("Go to view a camera", "View")
                            onTriggered: {
                                selectedIndex = index
                                pageStack.pop(pageOverview);
                                pageStack.push(deviceViewerComponent);
                            }
                        },
                        Kirigami.Action {
                            iconName: "settings-configure"
                            text: i18nc("Go to settings of a camera", "Settings")
                            onTriggered: {
                                selectedIndex = index
                                pageStack.pop(pageOverview);
                                pageStack.push(settingsComponent);
                            }
                        }
                    ]
                }
            }
        }
    }
}
