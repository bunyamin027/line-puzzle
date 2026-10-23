#!/bin/bash
# Convert images to base64 and create a JS file with the data
cd "/Users/teknopark/Desktop/mobil/7-Çizgi Bulmaca/appstore_screenshots"

echo "const IMAGE_DATA = {" > images_base64.js

for img in IMG_1965.PNG IMG_1968.PNG IMG_1969.PNG IMG_1970.PNG IMG_1977.PNG; do
    if [ -f "$img" ]; then
        echo "  '$img': 'data:image/png;base64,$(base64 -i "$img")'," >> images_base64.js
        echo "Encoded: $img"
    else
        echo "NOT FOUND: $img"
    fi
done

echo "};" >> images_base64.js
echo "Done! File size: $(du -h images_base64.js | cut -f1)"
