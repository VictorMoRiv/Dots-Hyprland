import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

ShellRoot {
    Calculator { id: calcWindow }
    Translator { id: trWindow }
    Calendar { id: calWindow }
    Weather { id: weatherWindow }

    TimeWidget {
        id: timeWindow
        visible: {
            let activeWs = ToplevelManager.activeToplevel?.workspace
            if (!activeWs) return true
            let windowsInWs = ToplevelManager.toplevels.values
                .filter(t => t.workspace === activeWs && !t.minimized)
            return windowsInWs.length === 0
        }
    }

    IpcHandler {
        target: "calculator"
        function toggle(): void { calcWindow.visible = !calcWindow.visible }
        function open(): void   { calcWindow.visible = true  }
        function close(): void  { calcWindow.visible = false }
    }

    IpcHandler {
        target: "translator"
        function toggle(): void { trWindow.visible = !trWindow.visible }
        function open(): void   { trWindow.visible = true  }
        function close(): void  { trWindow.visible = false }
    }

    IpcHandler {
        target: "timewidget"
        function toggle(): void { timeWindow.visible = !timeWindow.visible }
        function open(): void   { timeWindow.visible = true  }
        function close(): void  { timeWindow.visible = false }
    }

    IpcHandler {
    target: "calendar"
    function toggle(): void { calWindow.visible = !calWindow.visible }
    function open(): void   { calWindow.visible = true  }
    function close(): void  { calWindow.visible = false }
    }


    IpcHandler {
        target: "weather"
        function toggle(): void { weatherWindow.visible = !weatherWindow.visible }
        function open(): void   { weatherWindow.visible = true  }
        function close(): void  { weatherWindow.visible = false }
}
}