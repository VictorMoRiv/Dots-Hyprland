pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Valores por defecto Rose Piné
    property string bg0:    "#191724"
    property string bg1:    "#1f1d2e"
    property string bg2:    "#26233a"
    property string fg:     "#e0def4"
    property string gray:   "#6e6a86"
    property string red:    "#eb6f92"
    property string orange: "#f6c177"
    property string yellow: "#f6c177"
    property string blue:   "#31748f"
    property string green:  "#9ccfd8"
    property string purple: "#c4a7e7"

    property string _jsonPath: Quickshell.configDir + "/themes/current.json"

    function applyJson(raw) {
        if (!raw || raw.trim() === "") return
        try {
            let t = JSON.parse(raw)
            if (t.bg0)    root.bg0    = t.bg0
            if (t.bg1)    root.bg1    = t.bg1
            if (t.bg2)    root.bg2    = t.bg2
            if (t.fg)     root.fg     = t.fg
            if (t.gray)   root.gray   = t.gray
            if (t.red)    root.red    = t.red
            if (t.orange) root.orange = t.orange
            if (t.yellow) root.yellow = t.yellow
            if (t.blue)   root.blue   = t.blue
            if (t.green)  root.green  = t.green
            if (t.purple) root.purple = t.purple
            console.log("Theme: colores cargados OK")
        } catch(e) {
            console.log("Theme: error JSON:", e)
        }
    }

    // Leer el JSON con cat al iniciar
    Process {
        id: catProc
        command: ["cat", root._jsonPath]
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.applyJson(text)
        }
    }

    // Vigilar cambios en el archivo con inotifywait
    Process {
        id: watchProc
        command: ["inotifywait", "-m", "-e", "close_write", root._jsonPath]
        running: true
        stdout: SplitParser {
            onRead: (data) => {
                // Cuando el archivo cambia, releer con cat
                catProc.running = false
                catProc.running = true
            }
        }
    }

    Component.onCompleted: {
        // Carga inicial
        catProc.running = true
    }
}
