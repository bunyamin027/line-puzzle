#!/bin/bash
# Line Puzzle — App Store header görsellerini üretir (Chrome headless).
set -e
cd "$(dirname "$0")"
python3 -c "
import json
t=open('header_template.html').read()
open('header.html','w').write(t.replace('__LEVELS__', json.dumps(json.load(open('levels.json')))))"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
mkdir -p output
# "header": ürün sayfası başlığı, "search": arama sonuçları görseli
for item in header:5244x2950 header:3840x1646 search:5244x2950 search:3840x2560 search:1920x1280; do
  kind=${item%%:*}; size=${item#*:}
  w=${size%x*}; h=${size#*x}
  for lang in en tr; do
  for text in 1 0; do
    # Yazısız görsel dilden bağımsız: yalnızca bir kez üret
    [ $lang = tr ] && [ $text = 0 ] && continue
    suffix=$([ $text = 1 ] && echo "" || echo "_notext")
    prefix=$([ $lang = tr ] && echo "cizgi_bulmaca" || echo "line_puzzle")
    out="output/${prefix}_${kind}_${w}x${h}${suffix}.png"
    "$CHROME" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 \
      --allow-file-access-from-files --virtual-time-budget=8000 \
      --window-size=$w,$h --screenshot="$PWD/$out" \
      "file://$PWD/header.html?w=$w&h=$h&text=$text&lang=$lang" >/dev/null 2>&1
    # App Store: saydamlık kanalı olmadan RGB
    python3 -c "from PIL import Image; im=Image.open('$out').convert('RGB'); im.save('$out')"
    echo "$out $(python3 -c "from PIL import Image; print(Image.open('$out').size)")"
  done
  done
done
