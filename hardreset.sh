#! /bin/bash -e

: '
###################################################################################################################################################
#                                       Script To Hard Restart All Opsview Components On An Opsview Host                                          #
#  If an Opsview host shuts down before all its Opsview components stop, old .pid and .lock files might prevent the components starting properly. #
#  Follow these steps to cleanly restart all Opsview components on an Opsview host, including tidying up left-over .pid and .lock files.          #
###################################################################################################################################################'

read -p "Are you sure? " -n 1 -r
    echo # (Optiononal) new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

    echo "Stopping All Opsview Services, Wait For 1.30 Minutes"
    echo $(/opt/opsview/watchdog/bin/opsview-monit stop all && sleep 100s)

if $(/opt/opsview/watchdog/bin/opsview-monit summary -B | awk '{print $2}' | head -n 3 | grep Not -q;)
then
    echo "All Services Are Now Stopped"
else
    echo "Error: Services Are Not Stopped"
fi
    echo "Stopping Opsview Agent & Watchdog"
    echo $(systemctl stop opsview-agent opsview-watchdog && sleep 5s)
    echo $(pkill -u opsview)
    echo $(find /opt/opsview/* -name *.pid -delete && find /opt/opsview/* -name *.lock -delete) 
    echo $(systemctl start opsview-agent opsview-watchdog)
    echo "Starting All Opsview Services, Wait For 3 Minutes"
if $(/opt/opsview/watchdog/bin/opsview-monit start all && sleep 3m && /opt/opsview/watchdog/bin/opsview-monit summary -B | grep OK -q;
)
then
    echo "OK"
else
    echo "Error: Not OK"
fi
