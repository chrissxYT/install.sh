#!/bin/sh

[ $# -ne 4 ] && {
        echo 'Usage: install.sh [name] [checksum-algorithm] [checksum] [url]' >&2
        exit 1
}

name="$1"
sumalgo="$2"
sum="$3"
url="$4"

[ "$sumalgo" = "sha256" -o "$sumalgo" = "sha1" -o "$sumalgo" = "md5" ] && sumalgo="$sumalgo"sum

tmp="$(mktemp)"
curl -Lo "$tmp" "$url"

"$sumalgo" "$tmp" | grep "$sum" >/dev/null || {
        rm -f "$tmp"
        echo "Checksum doesn't match!" >&2
        exit 2
}

systemctl stop "$name.service" >/dev/null 2>/dev/null
mv -f "$tmp" "/usr/bin/$name"
chmod +x "/usr/bin/$name"

echo "[Unit]
Description=$name
[Service]
Type=simple
Restart=always
ExecStart=/usr/bin/$name
[Install]
WantedBy=multi-user.target" > "/etc/systemd/system/$name.service"

systemctl enable --now "$name.service"
