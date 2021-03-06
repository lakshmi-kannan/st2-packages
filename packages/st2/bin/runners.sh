#!/bin/sh

INITCOMM=$(cat /proc/1/comm)
SYSTEMDCTL=/bin/systemctl
UPSTARTCTL=/sbin/initctl
SPAWNSVC=st2actionrunner
WORKERSVC=st2actionrunner-worker
# Set default number of workers
WORKERS="${WORKERS:-10}"

## Use running init system detection criterias
#
if [ -d /run/systemd/system ]; then
  # systemd is running
  sv=systemd
  svbin=$SYSTEMDCTL
elif [ "$INITCOMM" = init ] && ($UPSTARTCTL version 2>&1) &&
        [ -f /etc/init/$WORKERSVC.conf ]; then
  # init is running and upstart has been detected
  sv=upstart
  svbin=$UPSTARTCTL
else
  # In all other cases which may apply to older debians, redhats and
  # centos, amazon etc.
  sv=sysv
  svbin=/etc/init.d/$WORKERSVC
  if [ ! -x $svbin ]; then
    >&2 echo "Init file not found: $svbin"
    >&2 echo "Unknown platform, we support ONLY debian, systemd and sysv!"
    exit 99
  fi
fi

## Spwan workers
#
action="$1"; shift;
rs=0
i=1
while [ $i -le $WORKERS ]; do
  if [ $sv = systemd ]; then
    $svbin $action $SPAWNSVC@$i
  elif [ $sv = upstart ]; then
    $svbin $action $WORKERSVC WORKERID=$i
  elif [ $sv = sysv ]; then
    WORKERID=$i $svbin $action
  fi
  cmdrs=$?
  [ $cmdrs -gt 0 ] && rs=$cmdrs
  i=`expr $i + 1`
done

exit $rs
