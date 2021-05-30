FROM alpine:latest
MAINTAINER Andreas Segerfalk <friden.andreas@gmail.com>

ENV ALTITUDE="30, meter" \
    LATITUDE=50.00 \
    LONGITUDE=-80.00 \
    COMPUTER_TYPE="unbranded PC" \
    DB_BINDING_SUFFIX=mysql \
    DB_DRIVER=weedb.mysql \
    DB_HOST=db \
    DB_NAME=weewx_a \
    DB_NAME_FORECAST=weewx_f \
    DB_USER=weewx \
    DEBUG=0 \
    DEVICE_PORT=/dev/ttyUSB0 \
    HTML_ROOT=/var/www/weewx \
    LOCATION="Anytown, USA" \
    LOGGING_INTERVAL=300 \
    OPERATOR="Al Roker" \
    OPTIONAL_ACCESSORIES=False \
    RAIN_YEAR_START=7 \
    RAPIDFIRE=True \
    RSYNC_HOST=web01 \
    RSYNC_PORT=22 \
    RSYNC_DEST=/usr/share/nginx/html \
    RSYNC_USER=wx \
    SKIN=Standard \
    STATION_FEATURES="fan-aspirated shield" \
    STATION_ID=unset \
    STATION_MODEL=6152 \
    STATION_TYPE=Vantage \
    STATION_URL= \
    SYSLOG_DEST=/var/log/messages \
    TZ=US/Eastern \
    TZ_CODE=10 \
    WEEK_START=6 \
    WX_USER=weewx \
    XTIDE_LOCATION=unset

ARG WEEWX_VERSION=4.5.1
ARG WEEWX_SHA=9650f9a4ce0f300a652d926820bc5b683a1826fd668c0e71413e88c772d7f056
ARG WX_GROUP=dialout
ARG WX_UID=2071
ARG XTIDE_SHA=e5c4afbb17269fdde296e853f2cb84845ed1c1bb1932f780047ad71d623bc681

COPY setup/install-input.txt setup/requirements.txt /root/
RUN apk add --no-cache --update \
      curl freetype libjpeg libstdc++ openssh openssl python3 py3-cheetah \
      py3-configobj py3-mysqlclient py3-pillow py3-requests py3-six py3-usb \
      rsync rsyslog tzdata && \
    adduser -u $WX_UID -s /bin/sh -G $WX_GROUP -D $WX_USER && \
    mkdir build && cd build && \
    curl -sLo weewx.tar.gz \
      http://www.weewx.com/downloads/released_versions/weewx-$WEEWX_VERSION.tar.gz && \
    echo "$WEEWX_SHA  weewx.tar.gz" >> /build/checksums && \
    sha256sum -c /build/checksums && \
    apk add --no-cache --virtual .fetch-deps \
      file freetype-dev g++ gawk gcc git jpeg-dev libpng-dev make musl-dev \
      py3-pip py3-wheel python3-dev zlib-dev && \
      py3-paho-mqtt fonts-freefont-ttf fonts-roboto && \
    pip install -r /root/requirements.txt && \
    ln -s python3 /usr/bin/python && \
    tar xf weewx.tar.gz --strip-components=1 && \
    cd /build && \
    ./setup.py build && ./setup.py install < /root/install-input.txt && \
    curl -sLo /tmp/weewx-mqtt.zip \
         https://github.com/matthewwall/weewx-mqtt/archive/master.zip && \
    curl -sLo /tmp/neowx-latest.zip \
         https://projects.neoground.com/neowx/download/latest && \
    /home/weewx/bin/wee_extension --install /tmp/weewx-mqtt.zip && \
    /home/weewx/bin/wee_extension --install /tmp/neowx-latest.zip && \
    mkdir -p /var/www/html/weewx && \
    apk del .fetch-deps && \
    rm -fr /build /home/$WX_USER/weewx.conf.2* /home/$WX_USER/docs \
      /home/$WX_USER/skins/WeeGreen/.git \
      /root/.cache /var/cache/apk/* /var/log/* /tmp/* && \
    find /home/$WX_USER/bin -name '*.pyc' -exec rm '{}' +;

COPY entrypoint.sh /usr/local/bin
COPY setup/skin.conf /etc/weewx/skins/neowx/ 
COPY setup/daily.json.tmpl /etc/weewx/skins/neowx/

VOLUME ["/var/lib/weewx"]
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

#CMD ["/usr/bin/weewxd","/etc/weewx/weewx.conf"]
