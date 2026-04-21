FROM ubuntu:24.04@sha256:c4a8d5503dfb2a3eb8ab5f807da5bc69a85730fb49b5cfca2330194ebcc41c7b

LABEL maintainer="Sebastian Schmidt"

ENV TIMEZONE=Europe/Berlin \
    DEBIAN_FRONTEND=noninteractive \
    CheckInterval=10 \
    InfluxDbIp=192.168.178.2 \
    InfluxDbCollectdPort=25826 \
    FritzBoxIp=192.168.178.1 \
    FritzBoxUser=collectd \
    FritzBoxPassword=mypassword

RUN apt-get update \
    && apt-get install -y \
        tzdata \
        python3-pip \
        collectd \
    && pip3 install --break-system-packages lxml pbr requests \
    && pip3 install --break-system-packages --no-deps "fritzconnection==0.8.5" \
    && pip3 install --break-system-packages --no-deps "fritzcollectd==0.7.0" \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Patch fritzconnection 0.8.x: lxml >=5 blocks etree.parse() on URLs for security.
# Replace the URL fetch with requests so the XML is fetched via HTTP, then parsed from bytes.
COPY fritzconnection-lxml5.patch /tmp/fritzconnection-lxml5.patch
RUN patch --fuzz=3 \
    "$(python3 -c 'import fritzconnection.fritzconnection as m, os; print(os.path.abspath(m.__file__))')" \
    /tmp/fritzconnection-lxml5.patch

COPY collectd.conf /etc/collectd/collectd.conf
COPY start.sh /start.sh
RUN chmod +x /start.sh

ENV DEBUG=false

CMD ["/start.sh"]