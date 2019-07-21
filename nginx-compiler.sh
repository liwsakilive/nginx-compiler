#!/bin/bash

apt update && apt upgrade -y

apt install -y wget curl sudo

apt install -y build-essential git tree software-properties-common dirmngr apt-transport-https ufw

wget https://nginx.org/download/nginx-1.17.0.tar.gz && tar zxvf nginx-1.17.0.tar.gz

# PCRE version 8.42
wget https://ftp.pcre.org/pub/pcre/pcre-8.42.tar.gz && tar xzvf pcre-8.42.tar.gz

# zlib version 1.2.11
wget https://www.zlib.net/zlib-1.2.11.tar.gz && tar xzvf zlib-1.2.11.tar.gz

# OpenSSL version 1.1.1a
wget https://www.openssl.org/source/openssl-1.1.1a.tar.gz && tar xzvf openssl-1.1.1a.tar.gz

apt install -y perl libperl-dev libgd3 libgd-dev libgeoip1 libgeoip-dev geoip-bin libxml2 libxml2-dev libxslt1.1 libxslt1-dev

rm -rf *.tar.gz

cd ~/nginx-1.17.0

cp ~/nginx-1.17.0/man/nginx.8 /usr/share/man/man8
gzip /usr/share/man/man8/nginx.8
ls /usr/share/man/man8/ | grep nginx.8.gz
# Check that Man page for nginx is working:
#man nginx

git clone https://github.com/weibocom/nginx-upsync-module.git

./configure --prefix=/etc/nginx \
            --sbin-path=/usr/sbin/nginx \
            --modules-path=/usr/lib/nginx/modules \
            --conf-path=/etc/nginx/nginx.conf \
            --error-log-path=/var/log/nginx/error.log \
            --pid-path=/var/run/nginx.pid \
            --lock-path=/var/run/nginx.lock \
            --user=nginx \
            --group=nginx \
            --build=Ubuntu \
            --builddir=nginx-1.17.0 \
            --with-select_module \
            --with-poll_module \
            --with-threads \
            --with-file-aio \
            --with-http_ssl_module \
            --with-http_v2_module \
            --with-http_realip_module \
            --with-http_addition_module \
            --with-http_xslt_module=dynamic \
            --with-http_image_filter_module=dynamic \
            --with-http_geoip_module=dynamic \
            --with-http_sub_module \
            --with-http_dav_module \
            --with-http_flv_module \
            --with-http_mp4_module \
            --with-http_gunzip_module \
            --with-http_gzip_static_module \
            --with-http_auth_request_module \
            --with-http_random_index_module \
            --with-http_secure_link_module \
            --with-http_degradation_module \
            --with-http_slice_module \
            --with-http_stub_status_module \
            --with-http_perl_module=dynamic \
            --with-perl_modules_path=/usr/share/perl/5.24.1 \
            --with-perl=/usr/bin/perl \
            --http-log-path=/var/log/nginx/access.log \
            --http-client-body-temp-path=/var/cache/nginx/client_temp \
            --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
            --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
            --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
            --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
            --with-mail=dynamic \
            --with-mail_ssl_module \
            --with-stream=dynamic \
            --with-stream_ssl_module \
            --with-stream_realip_module \
            --with-stream_geoip_module=dynamic \
            --with-stream_ssl_preread_module \
            --with-compat \
            --with-pcre=../pcre-8.42 \
            --with-pcre-jit \
            --with-zlib=../zlib-1.2.11 \
            --with-openssl=../openssl-1.1.1a \
            --with-openssl-opt=no-nextprotoneg \
            --add-module=nginx-upsync-module \
            --with-debug

make
make install

cd ~

ln -s /usr/lib/nginx/modules /etc/nginx/modules

nginx -V

sudo adduser --system --home /nonexistent --shell /bin/false --no-create-home --disabled-login --disabled-password --gecos "nginx user" --group nginx

sudo nginx -t
# Will throw this error -> nginx: [emerg] mkdir() "/var/cache/nginx/client_temp" failed (2: No such file or directory)

# Create nginx cache directories and set proper permissions
mkdir -p /var/cache/nginx/client_temp /var/cache/nginx/fastcgi_temp /var/cache/nginx/proxy_temp /var/cache/nginx/scgi_temp /var/cache/nginx/uwsgi_temp
chmod 700 /var/cache/nginx/*
chown nginx:root /var/cache/nginx/*

# Re-check syntax and potential errors.
nginx -t

echo "[Unit]
Description=nginx - high performance web server
Documentation=https://nginx.org/en/docs/
After=network-online.target remote-fs.target nss-lookup.target
Wants=network-online.target

[Service]
Type=forking
PIDFile=/var/run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t -c /etc/nginx/nginx.conf
ExecStart=/usr/sbin/nginx -c /etc/nginx/nginx.conf
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s TERM $MAINPID

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/nginx.service


systemctl enable nginx.service
systemctl start nginx.service
systemctl is-enabled nginx.service
systemctl status nginx.service

curl -I 127.0.0.1
