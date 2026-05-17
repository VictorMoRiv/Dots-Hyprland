import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import "."

PanelWindow {
    id: root
    visible: false

    WlrLayershell.keyboardFocus: visible ? 1 : 0
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:translator"

    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }

    onVisibleChanged: {
        if (visible) focusTimer.start()
    }
    Timer {
        id: focusTimer
        interval: 50
        onTriggered: inputArea.forceActiveFocus()
    }

    property string srcLang:  "es"
    property string tgtLang:  "en"
    property string inputTxt: ""
    property string output:   "Escribe texto y pulsa Traducir…"
    property bool   loading:  false

    Process {
        id: curlProc
        property string result: ""
        stdout: StdioCollector { onStreamFinished: curlProc.result = text }
        onExited: (code) => {
            if (code === 0) {
                try {
                    let json = JSON.parse(curlProc.result)
                    if (json.responseStatus === 200)
                        root.output = json.responseData.translatedText
                    else
                        root.output = "Error: " + (json.responseDetails || "Fallo")
                } catch (e) { root.output = "Error al parsear respuesta" }
            } else { root.output = "Error de red (código " + code + ")" }
            root.loading = false
        }
    }

    function translate() {
        if (inputTxt.trim() === "") return
        loading = true; output = "Traduciendo…"
        let encoded = encodeURIComponent(inputTxt)
        curlProc.command = ["curl", "-s", "--max-time", "10",
            "https://api.mymemory.translated.net/get?q=" + encoded + "&langpair=" + srcLang + "|" + tgtLang]
        curlProc.running = true
    }

    function swapLangs() {
        let s = srcLang, t = tgtLang, o = output
        srcLang = t; tgtLang = s
        inputArea.text = o; output = ""
    }

    property var languages: [
        { code: "es", name: "Español"  }, { code: "en", name: "English"   },
        { code: "fr", name: "Français" }, { code: "de", name: "Deutsch"   },
        { code: "it", name: "Italiano" }, { code: "pt", name: "Português" },
    ]

    component LangRow: ColumnLayout {
        property string title:    ""
        property string selected: ""
        signal langSelected(string code)
        spacing: 4

        Text {
            text: title
            color: Theme.gray
            font { family: "Inter"; pixelSize: 11; weight: Font.Bold }
            leftPadding: 16
        }
        ScrollView {
            Layout.fillWidth: true
            implicitHeight: 38
            clip: true
            ScrollBar.vertical.policy: ScrollBar.AlwaysOff
            Row {
                spacing: 6; leftPadding: 16
                Repeater {
                    model: root.languages
                    delegate: Rectangle {
                        property bool active: modelData.code === selected
                        height: 28; width: lbl.implicitWidth + 24
                        radius: 5
                        color:  active ? Theme.orange : Theme.bg2
                        border.color: active ? Theme.blue : Theme.gray
                        border.width: 0
                        Text {
                            id: lbl; anchors.centerIn: parent
                            text: modelData.name
                            color: active ? Theme.bg0 : Theme.gray
                            font { family: "Inter"; pixelSize: 12; }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: langSelected(modelData.code)
                            onPressed:  parent.opacity = 0.75
                            onReleased: parent.opacity = 1.0
                        }
                        Behavior on color   { ColorAnimation  { duration: 120 } }
                        Behavior on opacity { NumberAnimation { duration: 80  } }
                    }
                }
            }
        }
    }

    // Cerrar al hacer click fuera
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: root.visible = false
    }

    Item {
        anchors.fill: parent

        Rectangle {
            anchors.centerIn: parent
            width: 620; height: 540
            radius: 18
            color: Theme.bg1
            border.color: Theme.bg2
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // Header
                Rectangle {
                    Layout.fillWidth: true; height: 52
                    color: Theme.bg0; radius: 0
                    border.color: Theme.bg2
                    border.width: 1

                    Text {
                        anchors { left: parent.left; leftMargin: 20; verticalCenter: parent.verticalCenter }
                        text: "󰗊  Traductor"
                        color: Theme.green
                        font { family: "Inter"; pixelSize: 18; weight: Font.Bold }
                    }
                }

                // Idioma origen
                LangRow {
                    Layout.fillWidth: true; Layout.topMargin: 10
                    title: "ORIGEN"; selected: root.srcLang
                    onLangSelected: (c) => root.srcLang = c
                }

                // Texto de entrada
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 16; Layout.rightMargin: 16; Layout.topMargin: 10
                    spacing: 6
                    Text {
                        text: "TEXTO A TRADUCIR"
                        color: Theme.gray
                        font { family: "Cantarell"; pixelSize: 11; weight: Font.Bold }
                    }
                    Rectangle {
                        Layout.fillWidth: true; height: 90
                        color: Theme.bg0; radius: 10
                        border.color: Theme.bg2; border.width: 1
                        TextArea {
                            id: inputArea
                            anchors.fill: parent
                            background: null
                            color: Theme.fg
                            font { family: "Cantarell"; pixelSize: 14 }
                            wrapMode: TextArea.Wrap; padding: 10
                            placeholderText: "Escribe aquí…"
                            placeholderTextColor: Theme.gray
                            onTextChanged: root.inputTxt = text
                        }
                    }
                }

                // Botones
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 16; Layout.rightMargin: 16
                    Layout.topMargin: 8; Layout.bottomMargin: 6
                    spacing: 8
                    Rectangle {
                        implicitWidth: swapLbl.implicitWidth + 28; implicitHeight: 36
                        radius: 10
                        color: Theme.bg2
                        border.color: Theme.gray; border.width: 0
                        Text {
                            id: swapLbl; anchors.centerIn: parent
                            text: "⇅  Intercambiar"
                            color: Theme.yellow
                            font { family: "Inter"; pixelSize: 13 }
                        }
                        MouseArea { anchors.fill: parent; onClicked: root.swapLangs() }
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        implicitWidth: trLbl.implicitWidth + 32; implicitHeight: 36
                        radius: 10
                        color: root.loading ? Theme.bg2 : Theme.red
                        Text {
                            id: trLbl; anchors.centerIn: parent
                            text: root.loading ? "Traduciendo…" : "Traducir  →"
                            color: Theme.bg0
                            font { family: "Cantarell"; pixelSize: 14; weight: Font.Normal }
                        }
                        MouseArea { anchors.fill: parent; onClicked: if (!root.loading) root.translate() }
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                }

                // Idioma destino
                LangRow {
                    Layout.fillWidth: true
                    title: "DESTINO"; selected: root.tgtLang
                    onLangSelected: (c) => root.tgtLang = c
                }

                // Resultado
                ColumnLayout {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    Layout.leftMargin: 16; Layout.rightMargin: 16
                    Layout.topMargin: 10; Layout.bottomMargin: 16
                    spacing: 6
                    Text {
                        text: "TRADUCCIÓN"
                        color: Theme.gray
                        font { family: "Cantarell"; pixelSize: 11; weight: Font.Bold }
                    }
                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        color: Theme.bg0; radius: 10
                        border.color: Theme.bg2; border.width: 1
                        TextArea {
                            anchors.fill: parent; background: null
                            readOnly: true; selectByMouse: true
                            color: Theme.fg
                            font { family: "Cantarell"; pixelSize: 14 }
                            wrapMode: TextArea.Wrap; padding: 10
                            text: root.output
                        }
                    }
                }
            }
        }
    }
}
