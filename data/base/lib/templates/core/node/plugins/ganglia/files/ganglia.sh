GMOND=`cat << EOF
globals {
  daemonize = yes
  setuid = yes
  user = ganglia
  debug_level = 0
  max_udp_msg_len = 1472
  mute = no
  deaf = no
  allow_extra_data = yes
  host_dmax = 86400
  host_tmax = 20
  cleanup_threshold = 300
  gexec = no
  send_metadata_interval = 30
}
cluster {
  name = "<%= domain.config.cluster %>"
  owner = "unspecified"
  latlong = "unspecified"
  url = "unspecified"
}
host {
  location = "unspecified"
}
udp_send_channel {
  host = <%= node.plugins.ganglia.config.ganglia_serverip %>
  port = 8649
  ttl = 1
}
udp_recv_channel {
  port = 8649
}
tcp_accept_channel {
  port = 8659
  gzip_output = no
}
modules {
  module {
    name = "core_metrics"
  }
  module {
    name = "cpu_module"
    path = "modcpu.so"
  }
  module {
    name = "disk_module"
    path = "moddisk.so"
  }
  module {
    name = "load_module"
    path = "modload.so"
  }
  module {
    name = "mem_module"
    path = "modmem.so"
  }
  module {
    name = "net_module"
    path = "modnet.so"
  }
  module {
    name = "proc_module"
    path = "modproc.so"
  }
  module {
    name = "sys_module"
    path = "modsys.so"
  }
}
collection_group {
  collect_once = yes
  time_threshold = 20
  metric {
    name = "heartbeat"
  }
}
collection_group {
  collect_every = 60
  time_threshold = 60
  metric {
    name = "cpu_num"
    title = "CPU Count"
  }
  metric {
    name = "cpu_speed"
    title = "CPU Speed"
  }
  metric {
    name = "mem_total"
    title = "Memory Total"
  }
  metric {
    name = "swap_total"
    title = "Swap Space Total"
  }
  metric {
    name = "boottime"
    title = "Last Boot Time"
  }
  metric {
    name = "machine_type"
    title = "Machine Type"
  }
  metric {
    name = "os_name"
    title = "Operating System"
  }
  metric {
    name = "os_release"
    title = "Operating System Release"
  }
  metric {
    name = "location"
    title = "Location"
  }
}
collection_group {
  collect_once = yes
  time_threshold = 300
  metric {
    name = "gexec"
    title = "Gexec Status"
  }
}
collection_group {
  collect_every = 20
  time_threshold = 90
  metric {
    name = "cpu_user"
    value_threshold = "1.0"
    title = "CPU User"
  }
  metric {
    name = "cpu_system"
    value_threshold = "1.0"
    title = "CPU System"
  }
  metric {
    name = "cpu_idle"
    value_threshold = "5.0"
    title = "CPU Idle"
  }
  metric {
    name = "cpu_nice"
    value_threshold = "1.0"
    title = "CPU Nice"
  }
  metric {
    name = "cpu_aidle"
    value_threshold = "5.0"
    title = "CPU aidle"
  }
  metric {
    name = "cpu_wio"
    value_threshold = "1.0"
    title = "CPU wio"
  }
  metric {
    name = "cpu_steal"
    value_threshold = "1.0"
    title = "CPU steal"
  }
}
collection_group {
  collect_every = 20
  time_threshold = 90
  metric {
    name = "load_one"
    value_threshold = "1.0"
    title = "One Minute Load Average"
  }
  metric {
    name = "load_five"
    value_threshold = "1.0"
    title = "Five Minute Load Average"
  }
  metric {
    name = "load_fifteen"
    value_threshold = "1.0"
    title = "Fifteen Minute Load Average"
  }
}
collection_group {
  collect_every = 80
  time_threshold = 950
  metric {
    name = "proc_run"
    value_threshold = "1.0"
    title = "Total Running Processes"
  }
  metric {
    name = "proc_total"
    value_threshold = "1.0"
    title = "Total Processes"
  }
}
collection_group {
  collect_every = 40
  time_threshold = 180
  metric {
    name = "mem_free"
    value_threshold = "1024.0"
    title = "Free Memory"
  }
  metric {
    name = "mem_shared"
    value_threshold = "1024.0"
    title = "Shared Memory"
  }
  metric {
    name = "mem_buffers"
    value_threshold = "1024.0"
    title = "Memory Buffers"
  }
  metric {
    name = "mem_cached"
    value_threshold = "1024.0"
    title = "Cached Memory"
  }
  metric {
    name = "swap_free"
    value_threshold = "1024.0"
    title = "Free Swap Space"
  }
}
collection_group {
  collect_every = 40
  time_threshold = 300
  metric {
    name = "bytes_out"
    value_threshold = 4096
    title = "Bytes Sent"
  }
  metric {
    name = "bytes_in"
    value_threshold = 4096
    title = "Bytes Received"
  }
  metric {
    name = "pkts_in"
    value_threshold = 256
    title = "Packets Received"
  }
  metric {
    name = "pkts_out"
    value_threshold = 256
    title = "Packets Sent"
  }
}
collection_group {
  collect_every = 1800
  time_threshold = 3600
  metric {
    name = "disk_total"
    value_threshold = 1.0
    title = "Total Disk Space"
  }
}
collection_group {
  collect_every = 40
  time_threshold = 180
  metric {
    name = "disk_free"
    value_threshold = 1.0
    title = "Disk Space Available"
  }
  metric {
    name = "part_max_used"
    value_threshold = 1.0
    title = "Maximum Disk Space Used"
  }
}
include ("/etc/ganglia/conf.d/*.conf")
EOF
`

yum -y install ganglia-gmond

<% if (node.plugins.ganglia.config.ganglia_isserver rescue false) then -%>
GMETAD=`cat << EOF
data_source '<%= node.name %>' localhost:8659
gridname '<%= domain.config.cluster %>'
authority "http://<%= node.plugins.ganglia.config.ganglia_serverip %>/ganglia/"
setuid_username ganglia
case_sensitive_hostnames 0
EOF
`

yum -y install ganglia ganglia-web ganglia-gmetad
sed -i -e 's/^\s*Require.*$/  Require all granted/g' /etc/httpd/conf.d/ganglia.conf
systemctl enable httpd
systemctl restart httpd
systemctl enable gmetad
systemctl restart gmetad

cat << EOF > /var/lib/firstrun/scripts/gangliafirewall.bash
firewall-cmd --add-port 8659/tcp --add-port 8649/tcp --add-port 8649/udp --add-port 8659/udp --zone <%= config.networks.pri.firewallpolicy %> --permanent
firewall-cmd --reload
EOF

echo "$GMETAD" > /etc/ganglia/gmetad.conf
<% end -%>

echo "$GMOND" > /etc/ganglia/gmond.conf

systemctl enable gmond
systemctl restart gmond
