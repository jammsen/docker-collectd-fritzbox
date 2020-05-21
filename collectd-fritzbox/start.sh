#!/usr/bin/env bash
_target="/etc/collectd/collectd.conf"
if [ -n "$InfluxDbIp" ]; then
    sed "s|InfluxDbIp|$InfluxDbIp|g" -i "${_target}"
fi
if [ -n "$InfluxDbCollectdPort" ]; then
    sed "s/InfluxDbCollectdPort/$InfluxDbCollectdPort/g" -i "${_target}"
fi
if [ -n "$FritzBoxIp" ]; then
    sed "s/FritzBoxIp/$FritzBoxIp/g" -i "${_target}"
fi
if [ -n "$FritzBoxUser" ]; then
    sed "s/FritzBoxUser/$FritzBoxUser/g" -i "${_target}"
fi
if [ -n "$FritzBoxPassword" ]; then
    sed "s/FritzBoxPassword/$FritzBoxPassword/g" -i "${_target}"
fi
if [ -n "$CheckInterval" ]; then
    sed "s/CheckInterval/$CheckInterval/g" -i "${_target}"
fi
if [ $DEBUG == true ]; then
    cat /etc/collectd/collectd.conf
fi
collectd -f