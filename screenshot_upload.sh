#! /bin/bash

# Config
source "$HOME/.config/screenshot_upload"
SAVE_DIR="$HOME/Pictures/Screenshots"

mkdir -p "$SAVE_DIR"

# Take a screenshot and save to temp file
TMPFILE=$(mktemp /tmp/screenshot-XXXXXX.png)
case "${1:-region}" in
	monitor)
		hyprcap shot monitor -r -N > "$TMPFILE"
		;;
	window)
		hyprcap shot window -z -r -N > "$TMPFILE"
		;;
	region)
		hyprcap shot region -z -r -N > "$TMPFILE"
		;;
esac

while true; do
	SIZE1=$(stat -c%s "$TMPFILE")
	sleep 0.2
	SIZE2=$(stat -c%s "$TMPFILE")
	[ "$SIZE1" -eq "$SIZE2" ] && break
done

# Name screenshot
HASH=$(cat /dev/urandom | tr -dc 'a-zA-Z' | head -c 10)
FILENAME="${HASH}.png"

cp "$TMPFILE" "$SAVE_DIR/$FILENAME"
rm "$TMPFILE"

# Upload
CURL_OUTPUT=$(curl -s --ftp-create-dirs \
	-u "$FTP_USER:$FTP_PASS" \
	-T "$SAVE_DIR/$FILENAME" \
	"ftp://$FTP_HOST/$FTP_DIR/$FILENAME" 2>&1)

if [ $? -ne 0]; then
	notify-send "Screenshot upload failed" "$CURL_OUTPUT"
fi

# Copy URL to clipboard
echo -n "$BASE_URL/$FILENAME" | wl-copy

notify-send "Screenshot uploaded" "$BASE_URL/$FILENAME"
