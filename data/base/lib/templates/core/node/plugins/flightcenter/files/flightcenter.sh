# Setup prompt
cat << "EOF" > /etc/profile.d/flightcenter.sh
#Custom PS1 with client name
[ -f /etc/flightcentersupported ] && c=32 || c=31
if [ "$PS1" ]; then
  PS1="[\u@\h\[\e[1;${c}m\] [<%=domain.config.cluster%>]\[\e[0m\] \W]\\$ "
fi
EOF

# Enable support
touch /etc/flightcentersupported

# Crontab
cat << 'EOF' > /etc/cron.d/tmpdir
SHELL=/bin/bash
PATH=/sbin:/bin:/usr/sbin:/usr/bin
MAILTO=root
* * * * * root mkdir -p -m 0777 /tmp/users
EOF

# User directories
cat << 'EOF' > /etc/profile.d/alces-fs.sh
################################################################################
##
## Alces HPC Software Stack - User helper directory creation on login
## Copyright (c) 2008-2017 Alces Software Ltd
##
################################################################################

ARCHIVE_DIR="<%= node.plugins.flightcenter.config.flightcenter_archivedir %>"
SHAREDSCRATCH_DIR="<%= node.plugins.flightcenter.config.flightcenter_sharedscratchdir %>"
LOCALSCRATCH_DIR="<%= node.plugins.flightcenter.config.flightcenter_localscratchdir %>"

USERDIR=$USER/

export SKIP_USERS="root alces"
export LOWEST_UID=500

check_user() {
  for SKIPUSER in $SKIP_USERS; do
    if [ "$USER" ==  "$SKIPUSER" ]; then
      return 1
    fi
    if [ $LOWEST_UID -gt `id -u` ]; then
      return 1
    fi
  done
  return 0
}

do_userpath() {

  TYPE=$1
  LINK=$2
  BASEDIR=$3
  MODE=$4
  if [ -z $MODE]; then
    MODE=700
  fi
  if ! [ -z $BASEDIR ]; then
    TARGET_DIR=$BASEDIR/$USERDIR
    if ! [ -d $TARGET_DIR ] && [ -w $BASEDIR ]; then
      echo "Creating user dir for '$TYPE'"
      mkdir -m $MODE -p $TARGET_DIR
    fi
    TARGET_LINK=$HOME/$LINK
    if [ -d $TARGET_DIR ]; then
      if ! [ -f $TARGET_LINK ] && ! [ -L $TARGET_LINK ] && ! [ -d $TARGET_LINK ] ; then
        echo "Creating user link for '$TYPE'"
        if ! ( ln -sn $TARGET_DIR $TARGET_LINK 2>&1 ); then
          echo "Warning: A '$TYPE' directory is available but a link cannot be created on this node" >&2
      fi
      fi
    else
      if [ -L $TARGET_LINK ]; then
        echo "Warning: A '$TYPE' link exists but the target is not available on this node" >&2
      fi
    fi
  fi
}

if ( check_user ); then
  do_userpath "Local Scratch" localscratch $LOCALSCRATCH_DIR
  do_userpath "Shared Scratch" sharedscratch $SHAREDSCRATCH_DIR
  do_userpath "Archive" archive $ARCHIVE_DIR
fi

EOF

<% if node.name == 'local' -%>
# NTP
cat << EOF > /etc/chrony.conf
server <%= node.plugins.flightcenter.config.flightcenter_ntpserver %> iburst

stratumweight 0

driftfile /var/lib/chrony/drift

rtcsync

makestep 10 3

bindcmdaddress 127.0.0.1
bindcmdaddress ::1

keyfile /etc/chrony.keys

commandkey 1

generatecommandkey

noclientlog

logchange 0.5

logdir /var/log/chrony

allow <%= config.networks.pri.network %>/<% require 'ipaddr'; netmask=IPAddr.new(config.networks.pri.netmask.to_s).to_i.to_s(2).count('1') %><%= netmask %>
EOF

# Mail relay
sed -n -e '/^relayhost\s*=/!p' -e '$arelayhost=[<%=node.plugins.flightcenter.config.flightcenter_mailserver%>]' /etc/postfix/main.cf -i
sed -n -e '/^inet_interfaces\s*=/!p' -e '$ainet_interfaces = all' /etc/postfix/main.cf -i
cat << EOF >> /etc/postfix/main.cf
sender_canonical_maps = regexp:/etc/postfix/master-rewrite-sender
local_header_rewrite_clients = static:all
myorigin = <%= domain.config.cluster %>.alces.network
EOF

echo '/^(.*)@.*$/  ${1}@<%= domain.config.cluster %>.alces.network' > /etc/postfix/master-rewrite-sender

# Ganglia
systemctl stop gmetad
systemctl disable gmetad

<% end -%>
