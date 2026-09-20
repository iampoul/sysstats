#!/bin/bash
# System stats collector for the sysstats Omarchy plugin.
# Outputs key-value pairs (tab-separated) and JSON arrays for complex data.

# --- CPU usage (delta-based) ---
read -r _ user1 nice1 system1 idle1 iowait1 irq1 softirq1 steal1 _ < /proc/stat
total1=$((user1 + nice1 + system1 + idle1 + iowait1 + irq1 + softirq1 + steal1))
idle_d1=$((idle1 + iowait1))

sleep 0.3

read -r _ user2 nice2 system2 idle2 iowait2 irq2 softirq2 steal2 _ < /proc/stat
total2=$((user2 + nice2 + system2 + idle2 + iowait2 + irq2 + softirq2 + steal2))
idle_d2=$((idle2 + iowait2))

total_d=$((total2 - total1))
idle_d=$((idle_d2 - idle_d1))
if [ "$total_d" -gt 0 ]; then
  cpu_pct=$(( (total_d - idle_d) * 100 / total_d ))
else
  cpu_pct=0
fi
echo -e "cpu\t${cpu_pct}"

# --- Memory ---
awk '
  /^MemTotal:/ { total = $2 }
  /^MemAvailable:/ { avail = $2 }
  /^MemFree:/ { free = $2 }
  /^Buffers:/ { buffers = $2 }
  /^Cached:/ { cached = $2 }
  /^SwapTotal:/ { swapTotal = $2 }
  /^SwapFree:/ { swapFree = $2 }
  END {
    used = total - avail
    printf "memoryTotal\t%.1f\n", total / 1024 / 1024
    printf "memoryUsed\t%.1f\n", used / 1024 / 1024
    printf "memoryFree\t%.1f\n", free / 1024 / 1024
    printf "memoryBuffers\t%.1f\n", buffers / 1024 / 1024
    printf "memoryCached\t%.1f\n", cached / 1024 / 1024
    if (total > 0) printf "memoryPct\t%.0f\n", (used / total) * 100
    if (swapTotal > 0) {
      swapUsed = swapTotal - swapFree
      printf "swapTotal\t%.1f\n", swapTotal / 1024 / 1024
      printf "swapUsed\t%.1f\n", swapUsed / 1024 / 1024
      printf "swapPct\t%.0f\n", (swapUsed / swapTotal) * 100
    } else {
      printf "swapTotal\t0\n"
      printf "swapUsed\t0\n"
      printf "swapPct\t0\n"
    }
  }
' /proc/meminfo

# --- Load average ---
awk '{ print "load1\t" $1; print "load5\t" $2; print "load15\t" $3 }' /proc/loadavg

# --- Uptime ---
awk '{
  total = int($1)
  days = int(total / 86400)
  hours = int((total % 86400) / 3600)
  mins = int((total % 3600) / 60)
  printf "uptime\t%d.%02d:%02d\n", days, hours, mins
}' /proc/uptime

# --- Disk usage ---
disks="["
first=true
while IFS= read -r line; do
  mount=$(echo "$line" | awk '{print $6}')
  [ "$mount" = "/" ] || continue
  size=$(echo "$line" | awk '{print $2}')
  used=$(echo "$line" | awk '{print $3}')
  avail=$(echo "$line" | awk '{print $4}')
  pct=$(echo "$line" | awk '{print $5}' | tr -d '%')
  [ "$first" = true ] || disks="${disks},"
  first=false
  disks="${disks}{\"mount\":\"${mount}\",\"size\":\"${size}\",\"used\":\"${used}\",\"avail\":\"${avail}\",\"pct\":${pct}}"
done < <(df -h --output=source,size,used,avail,pcent,target -x tmpfs -x devtmpfs -x efivarfs 2>/dev/null | tail -n +2)
disks="${disks}]"
echo -e "disks\t${disks}"

# --- Temperatures ---
temps="["
first=true
for hwmon in /sys/class/hwmon/hwmon*; do
  [ -d "$hwmon" ] || continue
  hwmon_name=""
  [ -f "$hwmon/name" ] && hwmon_name=$(cat "$hwmon/name")
  for temp_file in "$hwmon"/temp*_input; do
    [ -f "$temp_file" ] || continue
    val=$(cat "$temp_file" 2>/dev/null)
    [ -z "$val" ] && continue
    temp_c=$((val / 1000))
    [ "$temp_c" -le 0 ] && continue
    [ "$temp_c" -gt 200 ] && continue
    idx=$(echo "$temp_file" | grep -oP 'temp\K[0-9]+')
    label_file="${hwmon}/temp${idx}_label"
    label=""
    [ -f "$label_file" ] && label=$(cat "$label_file")
    [ -z "$label" ] && label="Sensor ${idx}"
    source="${hwmon_name}"
    [ -z "$source" ] && source="hwmon"
    [ "$first" = true ] || temps="${temps},"
    first=false
    temps="${temps}{\"source\":\"${source}\",\"label\":\"${label}\",\"temp\":${temp_c}}"
  done
done
temps="${temps}]"
echo -e "temps\t${temps}"

# --- Fans ---
fans="["
first=true
for hwmon in /sys/class/hwmon/hwmon*; do
  [ -d "$hwmon" ] || continue
  hwmon_name=""
  [ -f "$hwmon/name" ] && hwmon_name=$(cat "$hwmon/name")
  for fan_file in "$hwmon"/fan*_input; do
    [ -f "$fan_file" ] || continue
    val=$(cat "$fan_file" 2>/dev/null)
    [ -z "$val" ] && continue
    [ "$val" -eq 0 ] && continue
    idx=$(echo "$fan_file" | grep -oP 'fan\K[0-9]+')
    label_file="${hwmon}/fan${idx}_label"
    label=""
    [ -f "$label_file" ] && label=$(cat "$label_file")
    [ -z "$label" ] && label="Fan ${idx}"
    source="${hwmon_name}"
    [ -z "$source" ] && source="hwmon"
    [ "$first" = true ] || fans="${fans},"
    first=false
    fans="${fans}{\"source\":\"${source}\",\"label\":\"${label}\",\"rpm\":${val}}"
  done
done
fans="${fans}]"
echo -e "fans\t${fans}"

# --- Network ---
net="["
first=true
while IFS= read -r line; do
  iface=$(echo "$line" | awk -F: '{print $1}' | tr -d ' ')
  [ "$iface" = "lo" ] && continue
  [[ "$iface" == e* || "$iface" == w* || "$iface" == en* || "$iface" == wl* || "$iface" == eth* || "$iface" == wlan* ]] || continue
  rx=$(echo "$line" | awk '{print $2}')
  tx=$(echo "$line" | awk '{print $10}')
  [ "$first" = true ] || net="${net},"
  first=false
  rx_mb=$(awk "BEGIN { printf \"%.1f\", ${rx} / 1048576 }")
  tx_mb=$(awk "BEGIN { printf \"%.1f\", ${tx} / 1048576 }")
  net="${net}{\"iface\":\"${iface}\",\"rx\":${rx_mb},\"tx\":${tx_mb},\"rxBytes\":${rx},\"txBytes\":${tx}}"
done < <(tail -n +3 /proc/net/dev)
net="${net}]"
echo -e "net\t${net}"

# --- Kernel / hostname ---
echo -e "hostname\t$(hostname)"
echo -e "kernel\t$(uname -r)"
