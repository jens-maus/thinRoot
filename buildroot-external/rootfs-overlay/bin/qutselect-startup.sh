#!/bin/sh

. $TS_GLOBAL

has_ewmh_wm()
{
    local name
    local id
    local child_id

    # If property does not exist, "id" will contain "no such atom on any window"
    id=`/bin/xprop -root 32x ' $0\n' _NET_SUPPORTING_WM_CHECK | awk '{ print $2 }'`
    child_id=`/bin/xprop -id "${id}" 32x ' $0\n' _NET_SUPPORTING_WM_CHECK 2>/dev/null | awk '{ print $2 }'`

    if [ "${id}" != "${child_id}" ]; then
        return 1
    fi

    return 0
}

wait_for_wm()
{
    for i in `seq 30`; do
        if has_ewmh_wm; then
            return 0
        fi

        sleep 1
    done
    return 1
}

get_qutselect_files()
{
  # make sure we download the latest slist and motd file
  if [ -n "$SERVER_IP" ]; then
    
    # make sure we have a thinlinc config dir in the user home
    if [ ! -d $HOME/.qutselect ] ; then
      mkdir -p $HOME/.qutselect
    fi

    TMPFILE=`mktemp`
    SRC_SLISTPATH="$BASEPATH/$SESSION_0_QUTSELECT_SLIST"
    DST_SLISTPATH="${HOME}/.qutselect/qutselect.slist"
    if `transport $SRC_SLISTPATH $TMPFILE $SERVER_IP` ; then
      rm -f $DST_SLISTPATH
      catv $TMPFILE | sed -e 's/\^M//g' >$DST_SLISTPATH 2>/dev/null
      echo >> $DST_SLISTPATH
    fi
    rm -f $TMPFILE

    TMPFILE=`mktemp`
    SRC_MOTDPATH="$BASEPATH/$SESSION_0_QUTSELECT_MOTD"
    DST_MOTDPATH="${HOME}/.qutselect/qutselect.motd"
    if `transport $SRC_MOTDPATH $TMPFILE $SERVER_IP` ; then
      rm -f $DST_MOTDPATH
      catv $TMPFILE | sed -e 's/\^M//g' >$DST_MOTDPATH 2>/dev/null
      echo >> $DST_MOTDPATH
    fi
    rm -f $TMPFILE
  fi

  return 0
}

create_thinlinc_conf()
{
  # make sure we have a thinlinc config dir in the user home
  if [ ! -d $HOME/.thinlinc ] ; then
    mkdir -p $HOME/.thinlinc
  fi

  # WORKAROUND: link known_hosts file if not present
  if [ ! -e ${HOME}/.thinlinc/known_hosts ]; then
    ln -s ${HOME}/.ssh/known_hosts ${HOME}/.thinlinc/
  fi

  # check if chooser should be forces
  if [ -n "${SESSION_0_QUTSELECT_CHOOSER}" ]; then
    export SESSION_0_THINLINC_CONFIG_AUTHENTICATION_METHOD=publickey
    export SESSION_0_THINLINC_CONFIG_AUTOLOGIN=1
    export SESSION_0_THINLINC_CONFIG_PRIVATE_KEY=/tmp/user.key
  fi

  # lets parse for SESSION_0_* env variables which we can forward
  # to the thinlinc configuration file
  TLCLIENTCONF=$HOME/.thinlinc/tlclient.conf
  let x=0
  while [ -n "`eval echo '$SESSION_'$x'_TYPE'`" ] ; do
    TLTYPE=`eval echo '$SESSION_'$x'_TYPE'`
    if [ "`make_caps $TLTYPE`" = "HZDR" ] ; then

      (set | grep "SESSION_"$x"_THINLINC_CONFIG_" ) |
      while read session; do
        tlvalue=`echo $session | cut -f2 -d"="`
        tlvalue=`eval echo $tlvalue`
        line=`echo $session | cut -f1 -d"="`
        tlparam=`echo $line | sed -e s/SESSION_${x}_THINLINC_CONFIG_//`
        tlparam=`make_caps $tlparam`

        echo "${tlparam}=${tlvalue}" >> $TLCLIENTCONF
      done
    fi
    let x=x+1
  done

  return 0
}

# get the slist and motd files
get_qutselect_files

# create thinlinc conf file
create_thinlinc_conf

# Clean up after earlier WMs
/bin/xprop -root -remove _NET_NUMBER_OF_DESKTOPS \
                 -remove _NET_DESKTOP_NAMES \
                 -remove _NET_CURRENT_DESKTOP 2> /dev/null

# start wm
/bin/xfwm4 --daemon

# wait for wm to start
if ! wait_for_wm; then
    echo "$0: Timeout waiting for wm to start"
fi

# update the default pa sink
/bin/pa-update-default-sink.sh

# if the chooser should be preferred
if [ -n "${SESSION_0_QUTSELECT_CHOOSER}" ]; then
  export SESSION_0_QUTSELECT_CMD="/bin/chooser >>${HOME}/chooser.log 2>&1"
fi

# start qutselect unlimited
while true; do
  ${SESSION_0_QUTSELECT_CMD}
  if [ $? -ne 0 ]; then
    break 
  fi
done
