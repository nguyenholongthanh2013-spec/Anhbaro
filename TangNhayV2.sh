#!/system/bin/sh
os=$(getprop ro.product.build.version.incremental)
uptime=$(uptime -p | sed 's/^up //' | awk -F', ' '
{
  out=""
  for (i=1;i<=NF;i++) {
    if ($i !~ /^0 (weeks|days)$/ && $i ~ /(weeks|days|hours|minutes)/) {
      out = (out=="" ? $i : out", "$i)
    }
  }
  print out
}')
package=$(pm list packages | wc -l)
disk=$(df -k /storage/emulated | awk 'NR==2 {printf "%.2fG / %.2fG\n", $3/1024/1024, $2/1024/1024}')
diskusage=$(df /storage/emulated | awk 'NR==2 {print $5}')
disksystem=$(df / | awk 'NR==2 {printf "%.2f MiB / %.2f MiB (%s)\n", $3/1024, $2/1024, $5}')
memory=$(free -m | awk 'NR==2 {printf "%.2f GiB / %.2f GiB (%d%%)\n", $3/1024, $2/1024, ($3*100)/$2}')
swap=$(free -m | awk '
$1=="Swap:" {
  used=$3; total=$2;
  if (total > 0)
    printf "%.2f GiB / %.2f GiB (%d%%)\n", used/1024, total/1024, (used*100)/total
  else
    print "OFF"
}')
gpu=$(dumpsys SurfaceFlinger \
| awk -F'GLES: ' '/GLES:/ {print $2}' \
| awk -F', OpenGL' '{print $1}')

soc=$(getprop ro.soc.model)
[ -z "$soc" ] && soc=$(grep -i "Hardware" /proc/cpuinfo | awk '{print $NF}')

vendor=$(getprop ro.soc.manufacturer)
[ -z "$vendor" ] && vendor="Unknown"

case "$vendor" in
  QTI|Qualcomm*) vendor="Qualcomm" ;;
  MediaTek*) vendor="MediaTek" ;;
  samsung*|Samsung*) vendor="Samsung" ;;
esac

name="Unknown"

case "$soc" in
  SM8750) name="Snapdragon 8 Elite" ;;
  SM8650) name="Snapdragon 8 Gen 3" ;;
  SM8635) name="Snapdragon 8s Gen 3" ;;
  SM8550) name="Snapdragon 8 Gen 2" ;;
  SM8475) name="Snapdragon 8+ Gen 1" ;;
  SM8450) name="Snapdragon 8 Gen 1" ;;
  SM7675) name="Snapdragon 7+ Gen 3" ;;
  SM7550) name="Snapdragon 7 Gen 3" ;;
  SM7475) name="Snapdragon 7 Gen 2" ;;
  SM7435) name="Snapdragon 7s Gen 2" ;;
  SM6450) name="Snapdragon 6 Gen 1" ;;
  SM6375) name="Snapdragon 6s Gen 3" ;;
  SM6225) name="Snapdragon 680" ;;
  SM6115) name="Snapdragon 662" ;;

  MT6989) name="Dimensity 9300" ;;
  MT6983) name="Dimensity 9000" ;;
  MT6978) name="Dimensity 9200+" ;;
  MT6897) name="Dimensity 8300 Ultra" ;;
  MT6895) name="Dimensity 8200" ;;
  MT6877) name="Dimensity 7050" ;;
  MT6873) name="Dimensity 1080" ;;
  MT6872) name="Dimensity 920" ;;
  MT6853) name="Dimensity 700" ;;
  MT6789) name="Helio G99" ;;
  MT6769) name="Helio G80" ;;
  MT6765) name="Helio G35" ;;

  S5E9945) name="Exynos 2400" ;;
  S5E9925) name="Exynos 2200" ;;
  S5E8845) name="Exynos 1480" ;;
  S5E8835) name="Exynos 1380" ;;
  S5E8825) name="Exynos 1280" ;;
  S5E8815) name="Exynos 1330" ;;
esac

[ "$name" = "Unknown" ] && name="Unknown ($soc)"

cores=$(nproc 2>/dev/null)
[ -z "$cores" ] && cores=$(grep -c ^processor /proc/cpuinfo)

freq=$(cat /sys/devices/system/cpu/cpu*/cpufreq/cpuinfo_max_freq 2>/dev/null | sort -nr | head -n1)
if [ -n "$freq" ]; then
  freq=$(awk "BEGIN{printf \"%.2f\", $freq/1000000}")
  freq="@ $freq GHz"
else
  freq=""
fi 

echo "         -o          o-             u0_a$(id -u)@localhost
          +hydNNNNdyh+              -----------------
        +mMMMMMMMMMMMMm+          OS: $os
      dMMm:NMMMMMMN:mMMd          Host: $(getprop ro.product.vendor_dlkm.manufacturer) $(getprop ro.product.marketname) ($(getprop ro.product.model))
      hMMMMMMMMMMMMMMMMMMh        Kernel: Linux $(uname -r)
  ..  yyyyyyyyyyyyyyyyyyyy  ..    Uptime: $uptime
.mMMmMMMMMMMMMMMMMMMMMMMMmMMm.    Packages: $package (pm)
:MMMM-MMMMMMMMMMMMMMMMMMMM-MMMM:  Shell: $0
:MMMM-MMMMMMMMMMMMMMMMMMMM-MMMM:  CPU: $vendor $name [$soc] ($cores) $freq
:MMMM-MMMMMMMMMMMMMMMMMMMM-MMMM:  GPU: $gpu
:MMMM-MMMMMMMMMMMMMMMMMMMM-MMMM:  Memory: $memory
-MMMM-MMMMMMMMMMMMMMMMMMMM-MMMM-  Swap: $swap
 +yy+ MMMMMMMMMMMMMMMMMMMM +yy+   Disk (/): $disksystem
      mMMMMMMMMMMMMMMMMMMm        Disk (/storage/emulated): $disk ($diskusage)
      /++MMMMh++hMMMM++/          Local IP (rmnet_data1): $(ip -o -4 addr show | awk '/rmnet_data/ {print $4}')
          MMMMo  oMMMM            Local IP (wlan0): $(ip -o -4 addr show wlan0 | awk '{print $4}')
          MMMMo  oMMMM            Locale: $(settings get system system_locales)
          oNMm-  -mMNs            
                                  
                                  
"                                  
