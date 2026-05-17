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
    WlrLayershell.namespace: "quickshell:calculator"

    implicitWidth:  340
    implicitHeight: 460
    color: "transparent"

    anchors { top: true; bottom: true; left: true; right: true }

    // Foco al abrirse
    onVisibleChanged: if (visible) calcFocusTimer.start()
    Timer {
        id: calcFocusTimer
        interval: 50
        onTriggered: calcRoot.forceActiveFocus()
    }

    // ── Estado ──────────────────────────────
    property string display:  "0"
    property string input:    ""
    property string operator: ""
    property real   prev:     0
    property bool   justEq:   false

    function evaluate(a, op, b) {
        if (op === "+") return a + b
        if (op === "-") return a - b
        if (op === "*") return a * b
        if (op === "/") return b !== 0 ? a / b : NaN
        return b
    }
    function fmtNum(n) {
        if (isNaN(n)) return "Error"
        let s = String(n)
        if (s.includes(".") && !s.includes("e"))
            s = s.replace(/\.?0+$/, "")
        return s
    }
    function pushDigit(d) {
        let ni = justEq ? d : (input === "0" || input === "") ? d : input + d
        input = ni; display = ni; justEq = false
    }
    function pushDot() {
        if (input.includes(".")) return
        let base = justEq ? "0" : (input || "0")
        input = base + "."; display = input; justEq = false
    }
    function pushOp(op) {
        let cur = parseFloat(input || display) || 0
        let res = (operator !== "" && input !== "" && !justEq)
                  ? evaluate(prev, operator, cur) : cur
        prev = res; display = fmtNum(res); input = ""; operator = op; justEq = false
    }
    function calc() {
        if (operator === "") return
        let cur = parseFloat(input || display) || 0
        let res = evaluate(prev, operator, cur)
        display = fmtNum(res); input = fmtNum(res)
        prev = isNaN(res) ? 0 : res; operator = ""; justEq = true
    }
    function clearAll() { display = "0"; input = ""; operator = ""; prev = 0; justEq = false }
    function backspace() {
        if (justEq || input === "") { input = ""; display = "0"; return }
        input = input.slice(0, -1); display = input || "0"
    }
    function toggleSign() {
        let v = parseFloat(input || display) * -1
        input = display = fmtNum(v)
    }
    function percent() {
        let v = parseFloat(input || display) / 100
        input = display = fmtNum(v)
    }

    // ── Componente botón ─────────────────────
    component CalcBtn: Rectangle {
        property string lbl:     ""
        property string bgColor: Theme.bg2
        property string fgColor: Theme.fg
        property var    action

        radius: 10
        color:  bgColor

        Text {
            anchors.centerIn: parent
            text:  lbl
            color: fgColor
            font { family: "Cantarell"; pixelSize: 20; weight: Font.Medium }
        }
        MouseArea {
            anchors.fill: parent
            onClicked:  action()
            onPressed:  parent.opacity = 0.7
            onReleased: parent.opacity = 1.0
        }
        Behavior on opacity { NumberAnimation { duration: 80 } }
    }

    // ── UI ───────────────────────────────────
    Item {
        id: calcRoot
        anchors.fill: parent
        focus: true

        Keys.onPressed: (event) => {
            const k = event.key
            if (k >= Qt.Key_0 && k <= Qt.Key_9)
                root.pushDigit(String(k - Qt.Key_0))
            else if (k === Qt.Key_Plus)     root.pushOp("+")
            else if (k === Qt.Key_Minus)    root.pushOp("-")
            else if (k === Qt.Key_Asterisk) root.pushOp("*")
            else if (k === Qt.Key_Slash)    root.pushOp("/")
            else if (k === Qt.Key_Return || k === Qt.Key_Enter) root.calc()
            else if (k === Qt.Key_Backspace) root.backspace()
            else if (k === Qt.Key_Escape)   root.visible = false
            else if (k === Qt.Key_Period || k === Qt.Key_Comma) root.pushDot()
        }

        Rectangle {
            anchors.centerIn: parent
            width: 340; height: 460
            radius: 18
            color: Theme.bg1
            border.color: Theme.bg2
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // Display
                Rectangle {
                    Layout.fillWidth: true
                    height: 110
                    color: Theme.bg0
                    radius: 18
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width; height: parent.radius
                        color: parent.color
                    }
                    Text {
                        anchors { right: parent.right; rightMargin: 20; verticalCenter: parent.verticalCenter }
                        text:  root.display
                        color: Theme.fg
                        font { family: "Cantarell"; pixelSize: 48; weight: Font.Light }
                        elide: Text.ElideLeft
                        width: parent.width - 24
                        horizontalAlignment: Text.AlignRight
                    }
                }

                // Grid 4x4
                GridLayout {
                    Layout.fillWidth:  true
                    Layout.fillHeight: true
                    Layout.margins: 12
                    columns: 4
                    rowSpacing: 8
                    columnSpacing: 8

                    // Fila 1
                    CalcBtn { Layout.fillWidth: true; Layout.fillHeight: true
                        lbl: "AC";  bgColor: Theme.red;    fgColor: Theme.bg0; action: root.clearAll }
                    CalcBtn { Layout.fillWidth: true; Layout.fillHeight: true
                        lbl: "+/-"; bgColor: Theme.green;  fgColor: Theme.bg0; action: root.toggleSign }
                    CalcBtn { Layout.fillWidth: true; Layout.fillHeight: true
                        lbl: "%";   bgColor: Theme.green;  fgColor: Theme.bg0; action: root.percent }
                    CalcBtn { Layout.fillWidth: true; Layout.fillHeight: true
                        lbl: "÷";   bgColor: Theme.blue;   fgColor: Theme.bg0; action: () => root.pushOp("/") }
                    // Fila 2
                    CalcBtn { Layout.fillWidth: true; Layout.fillHeight: true
                        lbl: "7"; action: () => root.pushDigit("7") }
                    CalcBtn { Layout.fillWidth: true; Layout.fillHeight: true
                        lbl: "8"; action: () => root.pushDigit("8") }
                    CalcBtn { Layout.fillWidth: true; Layout.fillHeight: true
                        lbl: "9"; action: () => root.pushDigit("9") }
                    CalcBtn { Layout.fillWidth: true; Layout.fillHeight: true
                        lbl: "×"; bgColor: Theme.blue; fgColor: Theme.bg0; action: () => root.pushOp("*") }
                    // Fila 3
                    CalcBtn { Layout.fillWidth: true; Layout.fillHeight: true
                        lbl: "4"; action: () => root.pushDigit("4") }
                    CalcBtn { Layout.fillWidth: true; Layout.fillHeight: true
                        lbl: "5"; action: () => root.pushDigit("5") }
                    CalcBtn { Layout.fillWidth: true; Layout.fillHeight: true
                        lbl: "6"; action: () => root.pushDigit("6") }
                    CalcBtn { Layout.fillWidth: true; Layout.fillHeight: true
                        lbl: "−"; bgColor: Theme.blue; fgColor: Theme.bg0; action: () => root.pushOp("-") }
                    // Fila 4
                    CalcBtn { Layout.fillWidth: true; Layout.fillHeight: true
                        lbl: "1"; action: () => root.pushDigit("1") }
                    CalcBtn { Layout.fillWidth: true; Layout.fillHeight: true
                        lbl: "2"; action: () => root.pushDigit("2") }
                    CalcBtn { Layout.fillWidth: true; Layout.fillHeight: true
                        lbl: "3"; action: () => root.pushDigit("3") }
                    CalcBtn { Layout.fillWidth: true; Layout.fillHeight: true
                        lbl: "+"; bgColor: Theme.blue; fgColor: Theme.bg0; action: () => root.pushOp("+") }
                }

                // Fila 5
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 12; Layout.rightMargin: 12
                    Layout.bottomMargin: 14
                    spacing: 8
                    property real btnH: 64

                    Rectangle {
                        Layout.preferredHeight: parent.btnH
                        Layout.fillWidth: true
                        radius: 10; color: Theme.bg2
                        Text {
                            anchors { left: parent.left; leftMargin: 26; verticalCenter: parent.verticalCenter }
                            text: "0"; color: Theme.fg
                            font { family: "Cantarell"; pixelSize: 20; weight: Font.Medium }
                        }
                        MouseArea { anchors.fill: parent; onClicked: root.pushDigit("0") }
                    }
                    Rectangle {
                        Layout.preferredWidth: Layout.preferredHeight
                        Layout.preferredHeight: parent.btnH
                        radius: 10; color: Theme.bg2
                        Text { anchors.centerIn: parent; text: "."
                            color: Theme.fg; font { family: "Cantarell"; pixelSize: 20 } }
                        MouseArea { anchors.fill: parent; onClicked: root.pushDot() }
                    }
                    Rectangle {
                        Layout.preferredWidth: Layout.preferredHeight
                        Layout.preferredHeight: parent.btnH
                        radius: 10; color: Theme.bg2
                        Text { anchors.centerIn: parent; text: "⌫"
                            color: Theme.gray; font { family: "Cantarell"; pixelSize: 20 } }
                        MouseArea { anchors.fill: parent; onClicked: root.backspace() }
                    }
                    Rectangle {
                        Layout.preferredWidth: Layout.preferredHeight
                        Layout.preferredHeight: parent.btnH
                        radius: 10; color: Theme.purple
                        Text { anchors.centerIn: parent; text: "="
                            color: Theme.bg0; font { family: "Cantarell"; pixelSize: 20; weight: Font.Bold } }
                        MouseArea { anchors.fill: parent; onClicked: root.calc() }
                    }
                }
            }
        }
    }

    // Cerrar al click fuera
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: root.visible = false
    }
}
