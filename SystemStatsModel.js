.pragma library

function parseStats(raw) {
    var result = {
        cpu: 0,
        memoryPct: 0,
        memoryTotal: 0,
        memoryUsed: 0,
        memoryFree: 0,
        memoryBuffers: 0,
        memoryCached: 0,
        swapTotal: 0,
        swapUsed: 0,
        swapPct: 0,
        load1: 0,
        load5: 0,
        load15: 0,
        uptime: "",
        disks: [],
        temps: [],
        fans: [],
        net: [],
        hostname: "",
        kernel: ""
    }
    var lines = String(raw || "").split("\n")
    for (var i = 0; i < lines.length; i++) {
        var idx = lines[i].indexOf("\t")
        if (idx <= 0) continue
        var key = lines[i].substring(0, idx)
        var val = lines[i].substring(idx + 1).trim()
        if (key === "cpu") result.cpu = parseInt(val) || 0
        else if (key === "memoryPct") result.memoryPct = parseInt(val) || 0
        else if (key === "memoryTotal") result.memoryTotal = parseFloat(val) || 0
        else if (key === "memoryUsed") result.memoryUsed = parseFloat(val) || 0
        else if (key === "memoryFree") result.memoryFree = parseFloat(val) || 0
        else if (key === "memoryBuffers") result.memoryBuffers = parseFloat(val) || 0
        else if (key === "memoryCached") result.memoryCached = parseFloat(val) || 0
        else if (key === "swapTotal") result.swapTotal = parseFloat(val) || 0
        else if (key === "swapUsed") result.swapUsed = parseFloat(val) || 0
        else if (key === "swapPct") result.swapPct = parseInt(val) || 0
        else if (key === "load1") result.load1 = parseFloat(val) || 0
        else if (key === "load5") result.load5 = parseFloat(val) || 0
        else if (key === "load15") result.load15 = parseFloat(val) || 0
        else if (key === "uptime") result.uptime = val
        else if (key === "hostname") result.hostname = val
        else if (key === "kernel") result.kernel = val
        else if (key === "disks") {
            try { result.disks = JSON.parse(val) } catch (e) {}
        }
        else if (key === "temps") {
            try { result.temps = JSON.parse(val) } catch (e) {}
        }
        else if (key === "fans") {
            try { result.fans = JSON.parse(val) } catch (e) {}
        }
        else if (key === "net") {
            try { result.net = JSON.parse(val) } catch (e) {}
        }
    }
    return result
}

function formatTemp(tempC) {
    return tempC + "\u00B0C"
}

function formatBytes(gb) {
    if (gb >= 1024) return (gb / 1024).toFixed(1) + " TB"
    return gb.toFixed(1) + " GB"
}

function formatRate(mb) {
    if (mb >= 1024) return (mb / 1024).toFixed(1) + " GB"
    return mb.toFixed(1) + " MB"
}

function cpuColor(pct) {
    if (pct >= 90) return "#f38ba8"
    if (pct >= 70) return "#fab387"
    if (pct >= 50) return "#f9e2af"
    return "#a6e3a1"
}

function memColor(pct) {
    if (pct >= 90) return "#f38ba8"
    if (pct >= 70) return "#fab387"
    if (pct >= 50) return "#f9e2af"
    return "#a6e3a1"
}

function tempColor(temp) {
    if (temp >= 80) return "#f38ba8"
    if (temp >= 65) return "#fab387"
    if (temp >= 50) return "#f9e2af"
    return "#a6e3a1"
}

function diskColor(pct) {
    if (pct >= 90) return "#f38ba8"
    if (pct >= 70) return "#fab387"
    if (pct >= 50) return "#f9e2af"
    return "#a6e3a1"
}

function formatUptime(raw) {
    return raw || "n/a"
}

function rateLabel(kbs) {
    if (!isFinite(kbs) || kbs < 1) return "0 KB/s"
    if (kbs >= 1024) return (kbs / 1024).toFixed(1) + " MB/s"
    if (kbs >= 100) return Math.round(kbs) + " KB/s"
    return kbs.toFixed(1) + " KB/s"
}

function drawNetGraph(ctx, hist, width, height) {
    ctx.reset()
    if (!hist || hist.length === 0) return

    var i
    var maxRate = 1
    for (i = 0; i < hist.length; i++) {
        if (hist[i].rx > maxRate) maxRate = hist[i].rx
        if (hist[i].tx > maxRate) maxRate = hist[i].tx
    }
    maxRate = Math.ceil(maxRate * 1.1)

    ctx.lineWidth = 1
    ctx.strokeStyle = "rgba(255, 255, 255, 0.12)"
    ctx.beginPath()
    ctx.moveTo(0, height - 0.5)
    ctx.lineTo(width, height - 0.5)
    ctx.stroke()

    function series(key, color) {
        var j
        var span = hist.length - 1
        ctx.strokeStyle = color
        ctx.fillStyle = color
        ctx.lineWidth = 1.5
        ctx.beginPath()
        for (j = 0; j < hist.length; j++) {
            var x = span > 0 ? (j / span) * width : width / 2
            var y = height - Math.max(0, Math.min(1, hist[j][key] / maxRate)) * height
            if (j === 0) ctx.moveTo(x, y)
            else ctx.lineTo(x, y)
        }
        ctx.stroke()

        ctx.globalAlpha = 0.18
        ctx.beginPath()
        ctx.moveTo(hist.length > 0 ? 0 : width, height)
        for (j = 0; j < hist.length; j++) {
            var fx = span > 0 ? (j / span) * width : width / 2
            var fy = height - Math.max(0, Math.min(1, hist[j][key] / maxRate)) * height
            ctx.lineTo(fx, fy)
        }
        ctx.lineTo(width, height)
        ctx.closePath()
        ctx.fill()
        ctx.globalAlpha = 1.0
    }

    series("rx", "#a6e3a1")
    series("tx", "#89b4fa")
}

function currentNetRates(hist) {
    if (!hist || hist.length === 0) return { rx: 0, tx: 0 }
    var last = hist[hist.length - 1]
    return { rx: last.rx, tx: last.tx }
}
