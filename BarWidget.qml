import QtQuick
import Quickshell.Io
import qs.Ui
import qs.Commons
import "SystemStatsModel.js" as Model

BarWidget {
    id: root

    moduleName: "io.github.iampoul.sysstats"
    readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false

    function open() {
        if (panelLoader.item) panelLoader.item.open()
    }

    function close() {
        if (panelLoader.item) panelLoader.item.close()
    }

    readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false

    function closeForPopoutSwitch() {
        if (panelLoader.item) panelLoader.item.closeForPopoutSwitch()
    }

    property var stats: ({
        cpu: 0, memoryPct: 0, memoryTotal: 0, memoryUsed: 0,
        temps: [], disks: [], fans: [], net: [],
        load1: 0, load5: 0, load15: 0, uptime: ""
    })

    property var netHistory: []
    property var prevNet: ({})
    property int maxNetSamples: 80

    function recordNetwork() {
        if (!stats || !Array.isArray(stats.net) || stats.net.length === 0)
            return
        var rxBytes = 0
        var txBytes = 0
        for (var i = 0; i < stats.net.length; i++) {
            var iface = stats.net[i]
            if (iface && iface.rxBytes !== undefined && iface.txBytes !== undefined) {
                rxBytes += iface.rxBytes
                txBytes += iface.txBytes
            }
        }
        var now = Date.now()
        var prev = root.prevNet
        if (prev && prev.rxBytes !== undefined && now > prev.time) {
            var dt = (now - prev.time) / 1000
            if (dt > 0) {
                netHistory.push({
                    rx: Math.max(0, (rxBytes - prev.rxBytes) / 1024 / dt),
                    tx: Math.max(0, (txBytes - prev.txBytes) / 1024 / dt)
                })
                while (netHistory.length > root.maxNetSamples)
                    netHistory.shift()
            }
        }
        root.prevNet = { rxBytes: rxBytes, txBytes: txBytes, time: now }
    }

    implicitWidth: row.implicitWidth + 16
    implicitHeight: Math.max(row.implicitHeight + 8, barSize)

    function refresh() {
        if (!statsProc.running)
            statsProc.running = true
    }

    function togglePanel() {
        if (panelLoader.item)
            panelLoader.item.toggle()
    }

    function injectPanel() {
        if (!panelLoader.item)
            return
        panelLoader.item.bar = bar
        panelLoader.item.settings = settings
        panelLoader.item.anchorItem = clickArea
        panelLoader.item.hostWidget = root
        panelLoader.item.stats = stats
        panelLoader.item.netHistory = netHistory
    }

    onBarChanged: injectPanel()
    onSettingsChanged: injectPanel()
    onStatsChanged: injectPanel()
    onNetHistoryChanged: injectPanel()

    Timer {
        interval: root.setting("refreshMs", 2000)
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Process {
        id: statsProc
        command: [Qt.resolvedUrl("collect-stats.sh").toString().replace("file://", "")]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                root.stats = Model.parseStats(text)
                root.recordNetwork()
            }
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8

        Text {
            text: "󰈐 " + root.stats.cpu + "%"
            color: Model.cpuColor(root.stats.cpu)
            font.family: root.bar ? root.bar.fontFamily : "monospace"
            font.pixelSize: Style.font.caption
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: "󰍛 " + root.stats.memoryPct + "%"
            color: Model.memColor(root.stats.memoryPct)
            font.family: root.bar ? root.bar.fontFamily : "monospace"
            font.pixelSize: Style.font.caption
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: root.stats && root.stats.temps && root.stats.temps.length > 0
            text: "󰏐 " + (root.stats.temps.length > 0 ? root.stats.temps[0].temp : 0) + "°"
            color: Model.tempColor(root.stats.temps.length > 0 ? root.stats.temps[0].temp : 0)
            font.family: root.bar ? root.bar.fontFamily : "monospace"
            font.pixelSize: Style.font.caption
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: clickArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: function(mouse) {
            if (mouse.button === Qt.MiddleButton) {
                root.refresh()
            } else {
                root.togglePanel()
            }
        }
    }

    Loader {
        id: panelLoader
        source: Qt.resolvedUrl("Panel.qml")
        onLoaded: {
            root.injectPanel()
            Qt.callLater(root.injectPanel)
        }
    }
}
