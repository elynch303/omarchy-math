import QtQuick
import qs.Ui

// Bar button that launches the Kids Math game. Mirrors the built-in
// omarchy.menu widget: a plain WidgetButton that toggles the panel through
// the shell IPC CLI, which keeps working across plugin/bar reloads.
BarWidget {
  id: root
  moduleName: "io.github.elynch303.kids-math"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "123"
    tooltipText: "Kids Math"
    onPressed: function (b) {
      if (!root.bar) return
      root.bar.run("omarchy-shell shell toggle io.github.elynch303.kids-math")
    }
  }
}
