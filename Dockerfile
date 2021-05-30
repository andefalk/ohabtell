FROM alpine:latest
MAINTAINER Andreas Segerfalk <friden.andreas@gmail.com>
COPY setup/ /tmp/
ENV WEEWX_VERSION 3.9.2
# The font file is used for the generated images
# With mqtt and newwx skin extention
RUN apt-get update && apt-get -y --no-install-recommends install \
    python-cjson \
        python-paho-mqtt \
        python-configobj \
        python-cheetah \
        python-pil \
        python-pillow \
        python-serial \
        python-usb \
        ssh \
        rsync \
        fonts-freefont-ttf \
        fonts-roboto \
        wget \
        && apt-get clean && rm -rf /var/lib/apt/lists/*
WORKDIR /tmp/src
RUN wget "http://www.weewx.com/downloads/released_versions/weewx_${WEEWX_VERSION}-1_all.deb" \
    && wget "http://lancet.mit.edu/mwall/projects/weather/releases/weewx-mqtt-0.19.tgz" \
        && wget --no-check-certificate --mirror --no-parent -O neowx-latest.zip "https://projects.neoground.com/neowx/download/latest" \
    && dpkg -i "weewx_${WEEWX_VERSION}-1_all.deb" || apt-get -y --no-install-recommends -f install \
        && /usr/bin/wee_extension --install weewx-mqtt-0.19.tgz \
        && /usr/bin/wee_extension --install neowx-latest.zip \
        && mkdir -p /var/www/html/weewx \
        && mv /tmp/skin.conf /etc/weewx/skins/neowx/ \
        && mv /tmp/daily.json.tmpl /etc/weewx/skins/neowx/

VOLUME ["/var/lib/weewx"]
CMD ["/usr/bin/weewxd","/etc/weewx/weewx.conf"]
