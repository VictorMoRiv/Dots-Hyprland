import Quickshell
import Quickshell.Io
import QtQuick

ShellRoot {
    Calculator { id: calcWindow }
    Translator  { id: trWindow  }

    IpcHandler {
        target: "calculator"

        function toggle(): void {
            calcWindow.visible = !calcWindow.visible
        }

        function open(): void {
            calcWindow.visible = true
        }

        function close(): void {
            calcWindow.visible = false
        }
    }

    IpcHandler {
        target: "translator"

        function toggle(): void {
            trWindow.visible = !trWindow.visible
        }

        function open(): void {
            trWindow.visible = true
        }

        function close(): void {
            trWindow.visible = false
        }
    }
}
