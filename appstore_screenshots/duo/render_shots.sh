#!/bin/bash
# Line Puzzle — iPhone (Duo) mağaza ekran görüntülerini üretir (Chrome headless).
# Ham ekranlar: screens/{en,tr}/*.png  (bkz. screens_render_test.dart.txt)
set -e
cd "$(dirname "$0")"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
# cihaz:boyut:ham-ekran-klasörü:island
TARGETS=${TARGETS:-"duo:2007x2853:screens:0 duo:1398x2034:screens:0 phone:1206x2622:screens_phone:1 phone:1179x2556:screens_phone:1 ipad:2048x2732:screens_ipad:0"}
for lang in ${LANGS:-en tr}; do
  prefix=$([ $lang = tr ] && echo "cizgi_bulmaca" || echo "line_puzzle")
  for target in $TARGETS; do
    IFS=: read device size dir island <<< "$target"
    w=${size%x*}; h=${size#*x}
    mkdir -p "output/$device/$lang/$size"
    for i in 1 2 3 4 5; do
      out="output/$device/$lang/$size/${prefix}_0${i}_${w}x${h}.png"
      "$CHROME" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 \
        --allow-file-access-from-files --virtual-time-budget=8000 \
        --window-size=$w,$h --screenshot="$PWD/$out" \
        "file://$PWD/shot_template.html?w=$w&h=$h&i=$i&lang=$lang&dir=$dir&island=$island" >/dev/null 2>&1
      python3 -c "from PIL import Image; im=Image.open('$out').convert('RGB'); im.save('$out')"
    done
  done
done
find output -name "*.png" | wc -l
