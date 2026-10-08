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

            console.log("XHR status:", xhr.status);

            if (xhr.status === 200) {
                try {
                    let json = JSON.parse(xhr.responseText);
                    let raw = json.raw;
                    let found = false;

                    for (let key in raw) {
                        let region = raw[key];
                        if (region.name !== targetRegion) continue;

                        let districts = region.districts;
                        for (let dk in districts) {
                            if (districts[dk].name === targetDistrict) {
                                status = districts[dk].alert ? "alarm" : "clear";
                                found = true;
                                break;
                            }
                        }
                        if (!found) {
                            status = region.alert ? "alarm" : "clear";
                            found = true;
                        }
                        break;
                    }

                    if (!found) status = "error";
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
        xhr.open("GET", "https://ubilling.net.ua/aerialalerts/?raw=true", true);
        xhr.setRequestHeader("User-Agent", "plasma-airalert/1.5");
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
            source: root.status === "alarm" ? "state-warning"
            : root.status === "clear"  ? "state-ok"
            : root.status === "error"  ? "dialog-error"
            : "state-sync"
            active: mouseArea.containsMouse
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.expanded = !root.expanded
        }
    }

    fullRepresentation: Item {
        implicitWidth:  220
        implicitHeight: 120

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 8

            Kirigami.Icon {
                Layout.alignment: Qt.AlignHCenter
                source: root.status === "alarm" ? "state-warning"
                : root.status === "clear"  ? "state-ok"
                : root.status === "error"  ? "dialog-error"
                : "state-sync"
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
                onClicked: checkAlarm()
            }
        }
    }
}
