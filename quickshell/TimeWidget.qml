import Quickshell
import Quickshell.Wayland
import QtQuick
import "."

PanelWindow {
    anchors {
        right: true
        bottom: true
    }
    margins.right: 40
    margins.bottom: 500

    width: 300
    height: 480
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Bottom



    FontLoader {
    id: retroFloral
    source: "/home/victor/.fonts/IBM_Plex_Sans/retro-floral.regular.ttf"
    }
    Rectangle {
    anchors.fill: parent
    radius: 20
    color:  Theme.bg0
    border.color: Theme.bg1
    border.width: 1

    Column {
        anchors.centerIn: parent
        spacing: -10

        Text {
            id: hoursText
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(new Date(), "hh")
            font.pixelSize: 200
            font.family: retroFloral.name
            font.weight: Font.Bold
            color: Theme.green  // más tenue
        }

        Text {
            id: minsText
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(new Date(), "mm")
            font.pixelSize: 200
            font.family: "Retro Floral"
            font.weight: Font.Normal
            color: Theme.fg  // más fuerte
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            hoursText.text = Qt.formatTime(new Date(), "hh")
            minsText.text  = Qt.formatTime(new Date(), "mm")
        }
    }
}
}