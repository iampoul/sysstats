import QtQuick
import QtQuick.Controls
import qs.Ui
import qs.Commons
import "SystemStatsModel.js" as Model

Panel {
    id: root

    moduleName: "io.github.iampoul.sysstats"
    manageIpc: false
    property var anchorItem: null
    property var hostWidget: null
    property var stats: ({})
    property var netHistory: []
    readonly property var liveRates: Model.currentNetRates(netHistory)
    readonly property real currentRxRate: liveRates.rx
    readonly property real currentTxRate: liveRates.tx

    function open() { root.controller.show() }
    function close() { root.controller.hide() }
    function toggle() { root.opened ? root.close() : root.open() }

    KeyboardPanel {
        id: panel
        anchorItem: root.anchorItem
        owner: root.hostWidget || root
        bar: root.bar
        open: root.opened
        contentWidth: panel.fittedContentWidth(Style.space(460))
        contentHeight: panel.fittedContentHeight(body.implicitHeight)

        Flickable {
            id: scroll
            anchors.fill: parent
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            interactive: contentHeight > height || contentWidth > width
            contentWidth: body.width
            contentHeight: body.implicitHeight

            Column {
                id: body
                width: scroll.width
                spacing: 16

                // Header
                Text {
                    text: "System Stats"
                    color: "white"
                    font.bold: true
                    font.pixelSize: 20
                    font.family: root.bar ? root.bar.fontFamily : "monospace"
                }

                // CPU Section
                Column {
                    width: parent.width
                    spacing: 6

                    PanelSectionHeader {
                        text: "CPU"
                        foreground: root.bar ? root.bar.foreground : Color.foreground
                        fontFamily: root.bar ? root.bar.fontFamily : "monospace"
                    }

                    Row {
                        width: parent.width
                        spacing: 20

                        Column {
                            width: (parent.width - parent.spacing) / 2
                            spacing: 4
                            InfoPair { label: "Usage"; value: root.stats.cpu + "%" }
                            InfoPair { label: "Load (1m)"; value: root.stats.load1 }
                            InfoPair { label: "Load (5m)"; value: root.stats.load5 }
                            InfoPair { label: "Load (15m)"; value: root.stats.load15 }
                        }

                        Column {
                            width: (parent.width - parent.spacing) / 2
                            spacing: 4

                            Rectangle {
                                width: parent.width
                                height: 6
                                radius: 3
                                color: Qt.rgba(1, 1, 1, 0.1)

                                Rectangle {
                                    width: Math.max(parent.height, parent.width * (root.stats.cpu / 100))
                                    height: parent.height
                                    radius: parent.radius
                                    color: Model.cpuColor(root.stats.cpu)
                                }
                            }
                        }
                    }
                }

                PanelSeparator { foreground: root.bar ? root.bar.foreground : Color.foreground }

                // Memory Section
                Column {
                    width: parent.width
                    spacing: 6

                    PanelSectionHeader {
                        text: "MEMORY"
                        foreground: root.bar ? root.bar.foreground : Color.foreground
                        fontFamily: root.bar ? root.bar.fontFamily : "monospace"
                    }

                    Row {
                        width: parent.width
                        spacing: 20

                        Column {
                            width: (parent.width - parent.spacing) / 2
                            spacing: 4
                            InfoPair { label: "Used"; value: root.stats.memoryUsed + " GB / " + root.stats.memoryTotal + " GB" }
                            InfoPair { label: "Free"; value: root.stats.memoryFree + " GB" }
                            InfoPair { label: "Buffers"; value: root.stats.memoryBuffers + " GB" }
                            InfoPair { label: "Cached"; value: root.stats.memoryCached + " GB" }
                        }

                        Column {
                            width: (parent.width - parent.spacing) / 2
                            spacing: 4
                            InfoPair { label: "Usage"; value: root.stats.memoryPct + "%" }
                            InfoPair { label: "Swap"; value: root.stats.swapUsed + " GB / " + root.stats.swapTotal + " GB" }

                            Rectangle {
                                width: parent.width
                                height: 6
                                radius: 3
                                color: Qt.rgba(1, 1, 1, 0.1)

                                Rectangle {
                                    width: Math.max(parent.height, parent.width * (root.stats.memoryPct / 100))
                                    height: parent.height
                                    radius: parent.radius
                                    color: Model.memColor(root.stats.memoryPct)
                                }
                            }
                        }
                    }
                }

                PanelSeparator { foreground: root.bar ? root.bar.foreground : Color.foreground }

                // Temperature Section
                Column {
                    width: parent.width
                    spacing: 6
                    visible: root.stats.temps && root.stats.temps.length > 0

                    PanelSectionHeader {
                        text: "TEMPERATURE"
                        foreground: root.bar ? root.bar.foreground : Color.foreground
                        fontFamily: root.bar ? root.bar.fontFamily : "monospace"
                    }

                    Grid {
                        columns: 3
                        columnSpacing: 16
                        rowSpacing: 4
                        width: parent.width

                        Repeater {
                            model: root.stats.temps || []
                            delegate: Row {
                                required property var modelData
                                spacing: 8

                                InfoLabel { text: modelData.label }
                                InfoValue {
                                    text: modelData.temp + "°C"
                                    color: Model.tempColor(modelData.temp)
                                }
                            }
                        }
                    }
                }

                PanelSeparator {
                    foreground: root.bar ? root.bar.foreground : Color.foreground
                    visible: root.stats.temps && root.stats.temps.length > 0
                }

                // Fan Section
                Column {
                    width: parent.width
                    spacing: 6
                    visible: root.stats.fans && root.stats.fans.length > 0

                    PanelSectionHeader {
                        text: "FANS"
                        foreground: root.bar ? root.bar.foreground : Color.foreground
                        fontFamily: root.bar ? root.bar.fontFamily : "monospace"
                    }

                    Grid {
                        columns: 2
                        columnSpacing: 20
                        rowSpacing: 4
                        width: parent.width

                        Repeater {
                            model: root.stats.fans || []
                            delegate: Row {
                                required property var modelData
                                spacing: 8

                                InfoLabel { text: modelData.label }
                                InfoValue { text: modelData.rpm + " RPM" }
                            }
                        }
                    }
                }

                PanelSeparator {
                    foreground: root.bar ? root.bar.foreground : Color.foreground
                    visible: root.stats.fans && root.stats.fans.length > 0
                }

                // Disk Section
                Column {
                    width: parent.width
                    spacing: 6
                    visible: root.stats.disks && root.stats.disks.length > 0

                    PanelSectionHeader {
                        text: "DISK"
                        foreground: root.bar ? root.bar.foreground : Color.foreground
                        fontFamily: root.bar ? root.bar.fontFamily : "monospace"
                    }

                    Repeater {
                        model: root.stats.disks || []
                        delegate: Column {
                            required property var modelData
                            width: parent.width
                            spacing: 4

                            Row {
                                width: parent.width
                                spacing: 8
                                InfoLabel { text: modelData.mount }
                                Item { width: parent.width - 150; height: 1 }
                                InfoValue { text: modelData.used + " / " + modelData.size + " (" + modelData.pct + "%)" }
                            }

                            Rectangle {
                                width: parent.width
                                height: 6
                                radius: 3
                                color: Qt.rgba(1, 1, 1, 0.1)

                                Rectangle {
                                    width: Math.max(parent.height, parent.width * (modelData.pct / 100))
                                    height: parent.height
                                    radius: parent.radius
                                    color: Model.diskColor(modelData.pct)
                                }
                            }
                        }
                    }
                }

                PanelSeparator {
                    foreground: root.bar ? root.bar.foreground : Color.foreground
                    visible: root.stats.disks && root.stats.disks.length > 0
                }

                // Network Section
                Column {
                    width: parent.width
                    spacing: 6
                    visible: root.stats.net && root.stats.net.length > 0

                    PanelSectionHeader {
                        text: "NETWORK"
                        foreground: root.bar ? root.bar.foreground : Color.foreground
                        fontFamily: root.bar ? root.bar.fontFamily : "monospace"
                    }

                    // Live throughput
                    Row {
                        width: parent.width
                        spacing: 8

                        Text {
                            text: "↓ " + Model.rateLabel(root.currentRxRate)
                            color: "#a6e3a1"
                            font.family: root.bar ? root.bar.fontFamily : "monospace"
                            font.pixelSize: Style.font.bodySmall
                        }
                        Text {
                            text: "↑ " + Model.rateLabel(root.currentTxRate)
                            color: "#89b4fa"
                            font.family: root.bar ? root.bar.fontFamily : "monospace"
                            font.pixelSize: Style.font.bodySmall
                        }
                        Item { width: parent.width - parent.children[0].width - parent.children[1].width; height: 1 }
                        Text {
                            text: "LIVE"
                            color: "#a6e3a1"
                            font.family: root.bar ? root.bar.fontFamily : "monospace"
                            font.pixelSize: Style.font.caption
                            font.bold: true
                        }
                    }

                    // Throughput graph
                    Rectangle {
                        width: parent.width
                        height: 90
                        radius: 6
                        color: Qt.rgba(1, 1, 1, 0.05)
                        clip: true

                        Canvas {
                            id: netGraph
                            anchors.fill: parent
                            antialiasing: true
                            onPaint: Model.drawNetGraph(getContext("2d"), root.netHistory, width, height)
                            Connections {
                                target: root
                                function onNetHistoryChanged() { netGraph.requestPaint() }
                            }
                        }
                    }

                    Repeater {
                        model: root.stats.net || []
                        delegate: Row {
                            required property var modelData
                            width: parent.width
                            spacing: 20

                            InfoLabel { text: modelData.iface; width: 80 }
                            Row {
                                spacing: 8
                                Text {
                                    text: "↓ " + modelData.rx + " MB"
                                    color: "#a6e3a1"
                                    font.family: root.bar ? root.bar.fontFamily : "monospace"
                                    font.pixelSize: Style.font.bodySmall
                                }
                                Text {
                                    text: "↑ " + modelData.tx + " MB"
                                    color: "#89b4fa"
                                    font.family: root.bar ? root.bar.fontFamily : "monospace"
                                    font.pixelSize: Style.font.bodySmall
                                }
                            }
                        }
                    }
                }

                PanelSeparator {
                    foreground: root.bar ? root.bar.foreground : Color.foreground
                    visible: root.stats.net && root.stats.net.length > 0
                }

                // System Info
                Column {
                    width: parent.width
                    spacing: 4

                    PanelSectionHeader {
                        text: "SYSTEM"
                        foreground: root.bar ? root.bar.foreground : Color.foreground
                        fontFamily: root.bar ? root.bar.fontFamily : "monospace"
                    }

                    InfoPair { label: "Hostname"; value: root.stats.hostname || "—" }
                    InfoPair { label: "Kernel"; value: root.stats.kernel || "—" }
                    InfoPair { label: "Uptime"; value: root.stats.uptime || "—" }
                }

                Item { width: 1; height: 1 }
            }
        }
    }

    component InfoPair: Row {
        property string label: ""
        property string value: ""

        width: parent.width
        spacing: 8

        InfoLabel { text: label }
        Item { width: Math.max(0, parent.width - parent.children[0].implicitWidth - parent.children[2].implicitWidth - parent.spacing * 2); height: 1 }
        InfoValue { text: value }
    }

    component InfoLabel: Text {
        color: root.bar ? Qt.darker(root.bar.foreground, 1.4) : "#bac2de"
        font.family: root.bar ? root.bar.fontFamily : "monospace"
        font.pixelSize: Style.font.bodySmall
    }

    component InfoValue: Text {
        color: root.bar ? root.bar.foreground : "white"
        font.family: root.bar ? root.bar.fontFamily : "monospace"
        font.pixelSize: Style.font.bodySmall
    }
}
