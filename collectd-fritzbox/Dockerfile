FROM jammsen/base:ubuntu-18.04

LABEL maintainer="Sebastian Schmidt"

ENV TIMEZONE=Europe/Berlin \
    DEBIAN_FRONTEND=noninteractive \
    CheckInterval=10 \
    InfluxDbIp=192.168.178.2 \
    InfluxDbCollectdPort=25826 \
    FritzBoxIp=192.168.178.1 \
    FritzBoxUser=collectd \
    FritzBoxPassword=mypassword 

RUN dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y python-pip \
    && pip install fritzcollectd 

RUN apt-get install -y collectd

RUN apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD collectd.conf /etc/collectd/collectd.conf
ADD start.sh /start.sh
RUN chmod +x /start.sh

ENV DEBUG=false

CMD ["/start.sh"]