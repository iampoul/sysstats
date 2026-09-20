# System Stats

A system monitoring widget for the Omarchy bar, inspired by macOS iStat Menus. Shows CPU, memory, and temperature in the bar, and opens a details panel with memory, load, disk, temperature, fans, network, and system info.

## Install

```sh
omarchy plugin add https://github.com/iampoul/sysstats.git --enable
```

## Usage

Click the widget to open the details panel. Click again or press outside to close it. Middle-click forces an immediate refresh.

The panel's Network section shows current download/upload throughput and a live graph of the last ~2.5 minutes alongside per-interface cumulative totals.

## Configure

```sh
omarchy bar move io.github.iampoul.sysstats --section right
```

| Setting | Default | Description |
| --- | --- | --- |
| `refreshMs` | `2000` | Polling interval in milliseconds. |
| `barFormat` | `temp cpu mem` | Order of the bar widgets (`temp`, `cpu`, `mem`). |

## Remove

```sh
omarchy plugin remove io.github.iampoul.sysstats
```

## Requirements

- A Linux kernel exposing temperature sensors through `hwmon` (typical on Intel and AMD with `coretemp`, `k10temp` / NVMe). Machines without readable sensors show no temperature entry.
- Fan speeds are only shown when fan sensors (`fan*_input`) exist; many desktops have none.
- No external dependencies — data comes from `/proc`, `/sys`, and `df`, polled by a small shell script.

## License

MIT, see [LICENSE](LICENSE).