# i3status configuration file.
It is important that this file is edited as UTF-8.
The following line should contain a sharp s:
ß
If the above line is not correctly displayed, fix your editor first!

[:tangle i3status.symlink]

```
general {
        colors = true
        interval = 1
        output_format = i3bar
        color_good = "#80BEED"
        color_bad = "#777777"
    #separator = " ]|[ "
}

#order += "mpd"
#order += "ipv6"
order += "disk /"
order += "run_watch DHCP"
#order += "run_watch VPN"
order += "wireless _first_"
order += "ethernet _first_"
#order += "battery 0"
#order += "load"
order += "volume master"
order += "battery 1"
order += "tztime local"

wireless _first_ {
        format_up = " W: (%quality at %essid) %ip "
        format_down = " W: down "
}

ethernet _first_ {
        # if you use %speed, i3status requires root privileges
        format_up = " E: %ip (%speed) "
        format_down = " E: down "
}

battery 1 {
        format = " %status %percentage %remaining "
}

run_watch DHCP {
        pidfile = "/var/run/dhclient*.pid"
}

run_watch VPN {
        pidfile = "/var/run/vpnc/pid"
}

tztime local {
        format = " %a %d/%m %H:%M "
}

load {
        format = "%5min"
}

disk "/" {
        #format = "%avail"
        #format = "%free (or: %percentage_used used, %percentage_used_of_avail used of avail, %percentage_free free, %percentage_avail avail)"
        format = " Disk: %avail %percentage_avail "
}

#mpd {
#        format_up = "%title - %album - %artist"
#        format_down = " - "
#        host = "127.0.0.1"
#        port = 6600
#}

volume master {
        format = " ♪ %volume "
        device = "default"
        mixer = "Master"
        mixer_idx = 0
}
```

