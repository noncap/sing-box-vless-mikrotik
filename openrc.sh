#!/sbin/openrc-run

name=$RC_SVCNAME
description="sing-box service"
supervisor="supervise-daemon"
command="/bin/sing-box"
command_args="run -c /singbox.json --disable-color"
extra_started_commands="reload"
respawn_max=0

depend() {
	after net dns
}

reload() {
	ebegin "Reloading $RC_SVCNAME"
	$supervisor "$RC_SVCNAME" --signal HUP
	eend $?
}
