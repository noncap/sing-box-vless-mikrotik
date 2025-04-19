#!/bin/sh
exec 2>&1
sing-box check -c /singbox.json --disable-color || exit 1
exec sing-box run -c /singbox.json --disable-color
