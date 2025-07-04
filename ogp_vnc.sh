#!/bin/sh
export PATH="/usr/local/sbin:/sbin:/bin:/usr/sbin:/usr/bin"
agent_user=ogp_agent
#service=ogp_vnc.service

start() {
    # start daemon
    echo -n "Starting OGP Agent WINE VNC: "
    su -c "vncserver :1 -geometry 800x600 -depth 24" $agent_user
    RETVAL=$?
    return $RETVAL
}

stop() {
    # stop daemon
    echo -n "Stopping OGP Agent WINE VNC: "
    su -c "vncserver -kill :1 >/dev/null 2>&1" $agent_user
    RETVAL=$?
    return $RETVAL
}

case "$1" in
    start)
    start
    RETVAL=$?
    ;;
    stop)
    stop
    RETVAL=$?
    ;;
    restart)
    stop
    sleep 1
    start
    RETVAL=$?
    ;;
    condrestart)
    stop
    sleep 1
    start
    ;;
    status)
    status $service
    RETVAL=0
    ;;
    *)
    echo "Usage: $service {start|stop|restart|condrestart|status}"
    RETVAL=1
    ;;
esac

exit $RETVAL
