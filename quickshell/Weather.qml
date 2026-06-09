import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "."

PanelWindow {
    id: root
    visible: false

    WlrLayershell.keyboardFocus: visible ? 1 : 0
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:weather"

    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }

    implicitWidth: 700
    implicitHeight: 400

    onVisibleChanged: if (visible) { root.forceActiveFocus(); root.fetchWeather() }

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) root.visible = false
    }

    // ── Estado ──────────────────────────────
    property bool loading: true
    property string errorMsg: ""
    property string city: ""
    property var days: []  // array de objetos día

    // Mapeo código wttr -> emoji
    function weatherIcon(code) {
        const c = parseInt(code)
        if (c === 113) return "☀️"
        if (c === 116) return "⛅"
        if (c === 119 || c === 122) return "☁️"
        if (c === 143 || c === 248 || c === 260) return "🌫️"
        if ([176,263,266,281,284,293,296,299,302,305,308,311,314,317,320].includes(c)) return "🌧️"
        if ([179,182,185,227,230,323,326,329,332,335,338,350,368,371,374,377].includes(c)) return "❄️"
        if ([386,389,392,395].includes(c)) return "⛈️"
        return "🌡️"
    }

    function dayName(dateStr, index) {
        if (index === 0) return "Hoy"
        if (index === 1) return "Mañana"
        const days = ["Dom","Lun","Mar","Mié","Jue","Vie","Sáb"]
        const d = new Date(dateStr)
        return days[d.getDay()]
    }

    // ── Fetch ────────────────────────────────
    Process {
        id: curlProc
        property string result: ""
        stdout: StdioCollector { onStreamFinished: curlProc.result = text }
        onExited: (code) => {
            if (code !== 0) { root.errorMsg = "Error de red"; root.loading = false; return }
            try {
                const json = JSON.parse(curlProc.result)
                root.city = json.nearest_area[0].areaName[0].value +
                            ", " + json.nearest_area[0].country[0].value

                root.days = json.weather.map((w, i) => ({
                    date:    w.date,
                    label:   root.dayName(w.date, i),
                    icon:    root.weatherIcon(w.hourly[4].weatherCode),
                    desc:    w.hourly[4].weatherDesc[0].value,
                    maxC:    w.maxtempC,
                    minC:    w.mintempC,
                    humidity: w.hourly[4].humidity,
                    wind:    w.hourly[4].windspeedKmph,
                    rain:    w.hourly[4].chanceofrain
                }))
                root.loading = false
                root.errorMsg = ""
            } catch(e) {
                root.errorMsg = "Error al parsear"
                root.loading = false
            }
        }
    }

    function fetchWeather() {
        root.loading = true
        curlProc.command = ["curl", "-s", "--max-time", "10",
            "https://wttr.in/?format=j1"]
        curlProc.running = true
    }

    // ── Componente día grande ────────────────
    component BigDay: Rectangle {
        property string label:    ""
        property string icon:     ""
        property string desc:     ""
        property string maxC:     ""
        property string minC:     ""
        property string humidity: ""
        property string wind:     ""
        property string rain:     ""

        radius: 14
        color: Theme.bg0
        border.color: Theme.bg2
        border.width: 1

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 6

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: label
                color: Theme.gray
                font { family: "IBM Plex Sans"; pixelSize: 12; weight: Font.Bold }
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: icon
                font.pixelSize: 42
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: desc
                color: Theme.fg
                font { family: "IBM Plex Sans"; pixelSize: 11 }
                wrapMode: Text.WordWrap
                width: 100
                horizontalAlignment: Text.AlignHCenter
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: maxC + "° / " + minC + "°"
                color: Theme.fg
                font { family: "IBM Plex Sans"; pixelSize: 16; weight: Font.Bold }
            }
            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.bg2 }
            Row {
                Layout.alignment: Qt.AlignHCenter
                spacing: 8
                Text { text: "💧" + rain + "%";  color: Theme.gray; font { family: "IBM Plex Sans"; pixelSize: 10 } }
                Text { text: "💨" + wind + "km"; color: Theme.gray; font { family: "IBM Plex Sans"; pixelSize: 10 } }
                Text { text: "🌢" + humidity + "%"; color: Theme.gray; font { family: "IBM Plex Sans"; pixelSize: 10 } }
            }
        }
    }

    // ── Componente día pequeño ───────────────
    component SmallDay: Rectangle {
        property string label: ""
        property string icon:  ""
        property string maxC:  ""
        property string minC:  ""
        property string rain:  ""

        radius: 10
        color: Theme.bg0
        border.color: Theme.bg2
        border.width: 1

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 3

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: label
                color: Theme.gray
                font { family: "IBM Plex Sans"; pixelSize: 10; weight: Font.Bold }
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: icon
                font.pixelSize: 24
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: maxC + "°/" + minC + "°"
                color: Theme.fg
                font { family: "IBM Plex Sans"; pixelSize: 11; weight: Font.Medium }
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "💧" + rain + "%"
                color: Theme.gray
                font { family: "IBM Plex Sans"; pixelSize: 9 }
            }
        }
    }

    // ── Cerrar fuera ─────────────────────────
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: root.visible = false
    }

    // ── UI ───────────────────────────────────
    Rectangle {
        anchors.centerIn: parent
        width: 700; height: 400
        radius: 18
        color: Theme.bg1
        border.color: Theme.bg2
        border.width: 1

        // Loading
        Text {
            anchors.centerIn: parent
            visible: root.loading
            text: "Cargando clima…"
            color: Theme.gray
            font { family: "IBM Plex Sans"; pixelSize: 16 }
        }

        // Error
        Text {
            anchors.centerIn: parent
            visible: !root.loading && root.errorMsg !== ""
            text: root.errorMsg
            color: Theme.red
            font { family: "IBM Plex Sans"; pixelSize: 16 }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12
            visible: !root.loading && root.errorMsg === ""

            // Header
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "󰖐  " + root.city
                    color: Theme.fg
                    font { family: "IBM Plex Sans"; pixelSize: 16; weight: Font.Bold }
                    Layout.fillWidth: true
                }

                Rectangle {
                    width: 80; height: 28; radius: 8
                    color: refreshHover.containsMouse ? Theme.bg2 : Theme.bg0
                    border.color: Theme.bg2; border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: "↻  Actualizar"
                        color: Theme.gray
                        font { family: "IBM Plex Sans"; pixelSize: 11 }
                    }
                    MouseArea {
                        id: refreshHover
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.fetchWeather()
                    }
                    Behavior on color { ColorAnimation { duration: 100 } }
                }
            }

            // 3 días grandes
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 10
                visible: root.days.length >= 3

                Repeater {
                    model: 3
                    BigDay {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        label:    root.days.length > index ? root.days[index].label    : ""
                        icon:     root.days.length > index ? root.days[index].icon     : ""
                        desc:     root.days.length > index ? root.days[index].desc     : ""
                        maxC:     root.days.length > index ? root.days[index].maxC     : ""
                        minC:     root.days.length > index ? root.days[index].minC     : ""
                        humidity: root.days.length > index ? root.days[index].humidity : ""
                        wind:     root.days.length > index ? root.days[index].wind     : ""
                        rain:     root.days.length > index ? root.days[index].rain     : ""
                    }
                }
            }

            // 4 días pequeños
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                visible: root.days.length >= 7

                Repeater {
                    model: 4
                    SmallDay {
                        Layout.fillWidth: true
                        height: 110
                        property int idx: index + 3
                        label: root.days.length > idx ? root.days[idx].label : ""
                        icon:  root.days.length > idx ? root.days[idx].icon  : ""
                        maxC:  root.days.length > idx ? root.days[idx].maxC  : ""
                        minC:  root.days.length > idx ? root.days[idx].minC  : ""
                        rain:  root.days.length > idx ? root.days[idx].rain  : ""
                    }
                }
            }
        }
    }
}