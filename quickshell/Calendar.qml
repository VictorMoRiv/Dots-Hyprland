import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "."

PanelWindow {
    id: root
    visible: false

    WlrLayershell.keyboardFocus: visible ? 1 : 0
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:calendar"

    implicitWidth: 360
    implicitHeight: 420
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }

    onVisibleChanged: if (visible) root.forceActiveFocus()

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) root.visible = false
        if (event.key === Qt.Key_Left)   root.prevMonth()
        if (event.key === Qt.Key_Right)  root.nextMonth()
        if (event.key === Qt.Key_H)      root.goToday()
    }

    // ── Estado ──────────────────────────────
    property int viewYear:  new Date().getFullYear()
    property int viewMonth: new Date().getMonth()  // 0-11
    property int todayDay:  new Date().getDate()
    property int todayMonth: new Date().getMonth()
    property int todayYear:  new Date().getFullYear()

    function prevMonth() {
        if (viewMonth === 0) { viewMonth = 11; viewYear-- }
        else viewMonth--
    }
    function nextMonth() {
        if (viewMonth === 11) { viewMonth = 0; viewYear++ }
        else viewMonth++
    }
    function goToday() {
        viewMonth = todayMonth
        viewYear  = todayYear
    }

    function daysInMonth(y, m) {
        return new Date(y, m + 1, 0).getDate()
    }
    function firstDayOfMonth(y, m) {
        return new Date(y, m, 1).getDay()  // 0=dom
    }

    property var monthNames: [
        "Enero","Febrero","Marzo","Abril","Mayo","Junio",
        "Julio","Agosto","Septiembre","Octubre","Noviembre","Diciembre"
    ]

    // Cerrar al click fuera
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: root.visible = false
    }

    Rectangle {
        anchors.centerIn: parent
        width: 360; height: 420
        radius: 18
        color: Theme.bg1
        border.color: Theme.bg2
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 0
            spacing: 0

            // ── Header ──────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: 56
                color: Theme.bg0
                radius: 18
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width; height: parent.radius
                    color: parent.color
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20

                    Text {
                        text: "󰃭"
                        color: Theme.green
                        font.pixelSize: 20
                        font.family: "Symbols Nerd Font"
                    }

                    Text {
                        text: root.monthNames[root.viewMonth] + "  " + root.viewYear
                        color: Theme.fg
                        font { family: "IBM Plex Sans"; pixelSize: 18; weight: Font.Medium }
                        Layout.fillWidth: true
                        leftPadding: 10
                    }

                    // Prev
                    Rectangle {
                        width: 30; height: 30; radius: 8
                        color: prevHover.containsMouse ? Theme.bg2 : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: "‹"
                            color: Theme.gray
                            font.pixelSize: 22
                        }
                        MouseArea {
                            id: prevHover
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.prevMonth()
                        }
                        Behavior on color { ColorAnimation { duration: 100 } }
                    }

                    // Next
                    Rectangle {
                        width: 30; height: 30; radius: 8
                        color: nextHover.containsMouse ? Theme.bg2 : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: "›"
                            color: Theme.gray
                            font.pixelSize: 22
                        }
                        MouseArea {
                            id: nextHover
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.nextMonth()
                        }
                        Behavior on color { ColorAnimation { duration: 100 } }
                    }
                }
            }

            // ── Días de la semana ────────────────────
            Row {
                Layout.fillWidth: true
                Layout.topMargin: 14
                Layout.leftMargin: 16
                Layout.rightMargin: 16

                property real cellW: (360 - 32) / 7

                Repeater {
                    model: ["Do","Lu","Ma","Mi","Ju","Vi","Sá"]
                    Text {
                        width: parent.cellW
                        text: modelData
                        color: Theme.gray
                        font { family: "IBM Plex Sans"; pixelSize: 12; weight: Font.Bold }
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            // ── Grid de días ─────────────────────────
            Grid {
                id: calGrid
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.leftMargin: 16
                Layout.rightMargin: 16
                Layout.bottomMargin: 16
                Layout.topMargin: 6

                columns: 7
                property real cellW: (360 - 32) / 7
                property real cellH: (calGrid.height) / 6

                Repeater {
                    model: 42  // 6 semanas x 7 días

                    delegate: Rectangle {
                        width:  calGrid.cellW
                        height: calGrid.cellH
                        radius: 8
                        color:  isToday   ? Theme.orange :
                                dayHover.containsMouse ? Theme.bg2 : "transparent"

                        property int offset: index - root.firstDayOfMonth(root.viewYear, root.viewMonth)
                        property int day:    offset + 1
                        property bool valid: day >= 1 && day <= root.daysInMonth(root.viewYear, root.viewMonth)
                        property bool isToday: valid &&
                            day === root.todayDay &&
                            root.viewMonth === root.todayMonth &&
                            root.viewYear  === root.todayYear

                        Text {
                            anchors.centerIn: parent
                            text:    parent.valid ? parent.day : ""
                            color:   parent.isToday ? Theme.bg0 :
                                     (index % 7 === 0) ? Theme.red : Theme.fg
                            font { family: "IBM Plex Sans"; pixelSize: 14;
                                   weight: parent.isToday ? Font.Bold : Font.Normal }
                        }

                        MouseArea {
                            id: dayHover
                            anchors.fill: parent
                            hoverEnabled: true
                        }

                        Behavior on color { ColorAnimation { duration: 100 } }
                    }
                }
            }
        }
    }
}