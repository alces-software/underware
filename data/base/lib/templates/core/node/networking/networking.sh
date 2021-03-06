#!/bin/bash
#(c)2018 Alces Flight Ltd. HPC Consulting Build Suite
CONFIGDIR='/etc/sysconfig/network-scripts/'
<% config.networks.each do |name, network| %>
<% if network.defined %>
<% unless name.to_s == 'bmc' %>
cat << EOF > "${CONFIGDIR}ifcfg-<%=network.interface%>"
<% if (network.bridge rescue false) -%>
TYPE='Bridge'
STP='no'
<% elsif (network.bond rescue false) -%>
TYPE='Bond'
BONDING_OPTS='<%=network.bond.options%>'
<% elsif ! (network.interface.to_s.match(/^ib.*/).to_s.empty?) -%>
TYPE='Infiniband'
<% else -%>
TYPE='Ethernet'
<% end -%>
<% if network.dhcp -%>
BOOTPROTO=dhcp
<% else -%>
BOOTPROTO=none
<% end -%>
<% if network.primary -%>
DEFROUTE=yes
<% else -%>
DEFROUTE=no
<% end -%>
<% if network.dhcpinfo -%>
PEERDNS=yes
PEERROUTES=yes
<% else -%>
PEERDNS=no
PEERROUTES=no
<% end -%>
IPV4_FAILURE_FATAL=no
IPV6INIT=no
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_PEERDNS=yes
IPV6_PEERROUTES=yes
IPV6_FAILURE_FATAL=no
NAME=<%=network.interface%>
DEVICE=<%=network.interface%>
ONBOOT=yes
<% if ! network.dhcp -%>
IPADDR=<%=network.ip%>
NETMASK=<%=network.netmask%>
<% end -%>
ZONE=trusted
<% if (node.platform == 'aws' rescue false) -%>
MTU="9001"
<% end -%>
<% if network.interface.match(/\.\d+$/)-%>
VLAN=yes
<%end-%>
<% if ! network.dhcpinfo -%>
<% if ! (network.gateway.to_s.empty? rescue true) -%>
GATEWAY=<%=network.gateway%>
<% end -%>
<% end -%>
EOF
<% (network.bridge.slave_interfaces rescue []).each do |slaveinterface| -%>
cat << EOF > "${CONFIGDIR}ifcfg-<%=slaveinterface%>"
<% if (network.bond rescue false) -%>
TYPE='Bond'
BONDING_OPTS='<%=network.bond.options%>'
<% end -%>
BOOTPROTO=none
DEFROUTE=no
PEERDNS=no
PEERROUTES=no
IPV4_FAILURE_FATAL=no
IPV6INIT=no
IPV6_AUTOCONF=no
IPV6_DEFROUTE=no
IPV6_PEERDNS=no
IPV6_PEERROUTES=no
IPV6_FAILURE_FATAL=no
ONBOOT=yes
NAME=<%=slaveinterface%>
DEVICE=<%=slaveinterface%>
BRIDGE=<%=network.bridge.interface%>
<% if (config.platform == 'aws' rescue false) -%>
MTU="9001"
<% end -%>
<%if slaveinterface.match(/\.\d+$/)-%>
VLAN=yes
<%end-%>
EOF
<% end -%>
<% (network.bond.slave_interfaces rescue []).each do |slaveinterface| -%>
cat << EOF > "${CONFIGDIR}ifcfg-<%=slaveinterface%>
TYPE=Bond
BOOTPROTO=none
DEFROUTE=no
PEERDNS=no
PEERROUTES=no
IPV4_FAILURE_FATAL=no
IPV6INIT=no
IPV6_AUTOCONF=no
IPV6_DEFROUTE=no
IPV6_PEERDNS=no
IPV6_PEERROUTES=no
IPV6_FAILURE_FATAL=no
ONBOOT=yes
NAME=<%=slaveinterface%>
DEVICE=<%=slaveinterface%>
MASTER=<%=network.bond.interface%>
<% if (config.platform == 'aws' rescue false) -%>
MTU="9001"
<% end -%>
<%if slaveinterface.match(/\.\d+$/)-%>
VLAN=yes
<%end-%>
EOF
<% end -%>
<% else -%>
BMCPASSWORD="<%= network.bmcpassword %>"
BMCCHANNEL="<%= network.bmcchannel %>"
BMCUSER="<%= network.bmcuser %>"
BMCUSERID="<%= network.bmcuserid %>"
BMCVLAN="<%= network.bmcvlan %>"

yum -y install ipmitool

service ipmi start
sleep 1
ipmitool lan set "$BMCCHANNEL" ipsrc static
sleep 2
ipmitool lan set "$BMCCHANNEL" ipaddr "<%= network.ip %>"
sleep 2
ipmitool lan set "$BMCCHANNEL" netmask "<%= network.netmask %>"
sleep 2
ipmitool lan set "$BMCCHANNEL" defgw ipaddr "<%= network.gateway %>"
sleep 2
if ! [ -z "${BMCVLAN}" ] ; then
ipmitool lan set "$BMCCHANNEL" vlan id "${BMCVLAN}"
sleep 2
fi
ipmitool user set name "$BMCUSERID" "$BMCUSER"
sleep 2
ipmitool user set password "$BMCUSERID" "$BMCPASSWORD"
sleep 2
ipmitool lan print "$BMCCHANNEL"
ipmitool user list "$BMCUSERID"
ipmitool mc reset cold
<% end -%>
<% end -%>
<% end -%>
