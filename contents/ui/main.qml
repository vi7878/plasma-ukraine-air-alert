import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    property string targetRegion:   "Черкаська область"
    property string targetDistrict: "Черкаський район"
    property string status:     "loading"
    property string lastUpdate: ""

    preferredRepresentation: compactRepresentation

    function statusText() {
        if (status === "alarm") return "Повітряна тривога!";
        if (status === "clear") return "Тривоги немає";
        if (status === "error") return "Помилка оновлення";
        return "Оновлення даних...";
    }

    function statusIcon() {
        if (status === "alarm") return "state-warning";
        if (status === "clear") return "state-ok";
        if (status === "error") return "dialog-error";
        return "state-sync";
    }

    function updateMetadata() {
        Plasmoid.icon            = statusIcon();
        Plasmoid.toolTipMainText = targetDistrict;
        Plasmoid.toolTipSubText  = statusText();
    }

    function checkAlarm() {
        status = "loading";
        updateMetadata();

        let xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;

            console.log("Neptun API XHR status:", xhr.status);

            if (xhr.status === 200) {
                try {
                    let data = JSON.parse(xhr.responseText);
                    let isAlarm = false;

                    if (data.raions) {
                        for (let i = 0; i < data.raions.length; i++) {
                            let raion = data.raions[i];
                            if (raion.name === targetDistrict && raion.oblast === targetRegion) {
                                isAlarm = true;
                                break;
                            }
                        }
                    }

                    if (!isAlarm && data.oblasts) {
                        for (let i = 0; i < data.oblasts.length; i++) {
                            let oblast = data.oblasts[i];
                            if (oblast.name === targetRegion) {
                                isAlarm = true;
                                break;
                            }
                        }
                    }

                    status = isAlarm ? "alarm" : "clear";
                } catch (e) {
                    console.log("Parse error:", e);
                    status = "error";
                }
            } else {
                console.log("HTTP error, status:", xhr.status);
                status = "error";
            }

            lastUpdate = Qt.formatTime(new Date(), "hh:mm");
            updateMetadata();
        };

        xhr.open("GET", "https://neptun.in.ua/api/v1/alerts", true);
        xhr.setRequestHeader("User-Agent", "plasma-airalert/1.6");
        xhr.send();
    }

    Timer {
        interval: 30000
        repeat:   true
        running:  true
        onTriggered: checkAlarm()
    }

    Component.onCompleted: checkAlarm()

    compactRepresentation: Item {
        Kirigami.Icon {
            anchors.centerIn: parent
            width:  Math.min(parent.width, parent.height) * 0.8
            height: width
            source: root.statusIcon()
            active: compactMouseArea.containsMouse
        }

        MouseArea {
            id: compactMouseArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.expanded = !root.expanded
        }
    }

    fullRepresentation: Item {
        implicitWidth:  220
        implicitHeight: 140

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8

            Kirigami.Icon {
                Layout.alignment: Qt.AlignHCenter
                source: root.statusIcon()
                implicitWidth:  Kirigami.Units.iconSizes.large
                implicitHeight: Kirigami.Units.iconSizes.large
            }

            QQC2.Label {
                Layout.alignment: Qt.AlignHCenter
                text:     root.statusText()
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }

            QQC2.Label {
                Layout.alignment: Qt.AlignHCenter
                text:    root.lastUpdate !== "" ? ("Оновлено: " + String(root.lastUpdate)) : ""
                opacity: 0.7
                font.pixelSize: 11
            }

            QQC2.Button {
                Layout.alignment: Qt.AlignHCenter
                text: "Оновити зараз"
                onClicked: root.checkAlarm()
            }
        }
    }
}
