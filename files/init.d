#!/bin/bash
### BEGIN INIT INFO
# Provides:          weechatd
# Required-Start:    $network
# Required-Stop:     $network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start weechat daemon within tmux session at boot time
# Description:       This init script will start a weechat session under tmux using the settings provided in /etc/weechatd.conf
### END INIT INFO

# Include the LSB library functions
. /lib/lsb/init-functions

# FROM HERE: http://majic.rs/book/initd-scripts/running-irssi-on-boot

# Setup static variables
configFile='/etc/weechatd.conf'
daemonExec='/usr/bin/tmux'
daemonArgs='-2 new-session -d'
daemonName="$(basename "$daemonExec")"
pidFile='/var/run/weechatd.pid'

# Checks if the environment is capable of running the script (such as
# availability of programs etc).
#
# Return: 0 if the environmnt is properly setup for execution of init script, 1
#         if not all conditions have been met.
#
function checkEnvironment() {
    # Verify that the necessary binaries are available for execution.
    local binaries=(weechat tmux)

    for bin in "${binaries[@]}"; do
        if ! which "$bin" > /dev/null; then
            log_failure_msg "Binary '$bin' is not available. Please install \
package containing it."
            exit 5
        fi
    done
}

# Checks if the configuration files are available and properly setup.
#
# Return: 0 if weechat if properly configured, 1 otherwise.
#
function checkConfig() {
    # Make sure the configuration file has been created
    if ! [[ -f $configFile ]]; then
        log_failure_msg "Please populate the configuration file '$configFile' \
before running."
        exit 6
    fi

    # Make sure the required options have been set
    local reqOptions=(user group session)
    for option in "${reqOptions[@]}"; do
        if ! grep -q -e "^[[:blank:]]*$option=" "$configFile"; then
            log_failure_msg "Mandatory option '$option' was not specified in \
'$configFile'"
            exit 6
        fi
    done
}

#
# Loads the configuration file and performs any additional configuration steps.
#
function configure() {
    . "$configFile"
    daemonArgs="$daemonArgs -s $session weechat"
    [[ -n $args ]] && daemonArgs="$daemonArgs $args"
    daemonCommand="$daemonExec $daemonArgs"
}

#
# Starts the daemon.
#
# Return: LSB-compliant code.
#
function start() {
    start-stop-daemon --start --quiet --oknodo --pidfile "$pidFile" \
        --make-pidfile --chuid "$user:$group" --background \
        --exec "$daemonExec" -- $daemonArgs
}

#
# Stops the daemon.
#
# Return: LSB-compliant code.
#
function stop() {
    start-stop-daemon --stop --quiet --oknodo --retry 30 --pidfile "$pidFile" \
        --chuid "$user:$group" --exec "$daemonExec" -- $daemonArgs
}

checkEnvironment
checkConfig
configure

case "$1" in
    start)
        log_daemon_msg "Starting daemon" "weechatd"
        start && log_end_msg 0 || log_end_msg $?
        ;;
    stop)
        log_daemon_msg "Stopping daemon" "weechatd"
        stop && log_end_msg 0 || log_end_msg $?
        ;;
    restart)
        log_daemon_msg "Restarting daemon" "weechatd"
        stop
        start && log_end_msg 0 || log_end_msg $?
        ;;
    force-reload)
        log_daemon_msg "Restarting daemon" "weechatd"
        stop
        start && log_end_msg 0 || log_end_msg $?
        ;;
    status)
        status_of_proc -p "$pidFile" "$daemonExec" screen && exit 0 || exit $?
        ;;
    *)
        echo "weechatd (start|stop|restart|force-reload|status|help)"
        ;;
esac
