SYS=$(hostname)
NOW=$(date +%Y-%m%d-%H%M)
FN="/tmp/bootfile-${SYS}-${NOW}"

hostname > ${FN}
echo ${NOW} >> ${FN}
