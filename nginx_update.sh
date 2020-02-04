#!/bin/bash

# Version Nginx for install and source
NGINX_REQ_VER=1.16.1
NGINX_SRC="http://nginx.org/download/nginx-"
# https://github.com/leev/ngx_http_geoip2_module
NGINX_GEOIP2_SRC="https://github.com/leev/ngx_http_geoip2_module.git"
# Nginx configuration params
NGINX_CONF_STRING="./configure --prefix=/etc/nginx --sbin-path=/usr/sbin/nginx --conf-path=/etc/nginx/nginx.conf --pid-path=/var/run/nginx.pid --error-log-path=/logs/nginx/nginx-error.log --http-log-path=/logs/nginx/nginx-access.log --user=nginx --group=nginx --with-http_ssl_module --add-dynamic-module=/opt/nginx/ngx_http_geoip2_module"
# https://github.com/maxmind/libmaxminddb/releases/latest
# Repo author/repo_name on github
LIBMAXMINDDB_REPO="maxmind/libmaxminddb"
# The path that will be saved
SAFE_PATH=/etc/nginx
# Requaired programs
REQ_SOFT="openssl openssl-devel git curl jq"

# Save the path
if [[ $SAFE_PATH != 0 ]]
then
	mkdir /opt/backups
	cp -R $SAFE_PATH /opt/backups/
fi

# Get latest release from github
get_latest_release() {
	curl -s https://api.github.com/repos/$1/releases/latest | jq -r ".assets[] | select(.name | test(\"${spruce_type}\")) | .browser_download_url"
}


make_env(){
	# Creating directory for build new version of the nginx
	mkdir /opt/nginx
	cd /opt/nginx
}

install_req(){
	# Installing requariment software
	yum install -y $REQ_SOFT > /dev/null
	# Getting geoip2 module
	git clone $NGINX_GEOIP2_SRC
	# Downloading libmaxminddb release and installing it
	wget $(get_latest_release $LIBMAXMINDDB_REPO)
	LIBMAXMINDDB=`get_latest_release $LIBMAXMINDDB_REPO | awk -F '/' '{print $9}'`
	echo $LIBMAXMINDDB
	mkdir libmaxminddb && tar -xvf $LIBMAXMINDDB -C libmaxminddb --strip-components 1
	cd libmaxminddb
	./configure
	make
	make check
	make install
	ldconfig
	cd ..
}

install_nginx(){
	#NGINX_VER=`nginx -v 2>&1 | awk -F ' ' '{print $3}'| awk -F '/' '{print $2}'`
	# Downloading Nginx tarball, compiling and installing it
	wget $NGINX_SRC$NGINX_REQ_VER.tar.gz
	mkdir nginx && tar -xvf nginx-$NGINX_REQ_VER.tar.gz -C nginx --strip-components 1
	cd nginx
	pwd
	$NGINX_CONF_STRING
	make
	make install
	cd ..
	# Updating nginx.conf for add geoip2 module
	if grep -Fxq "load_module modules/ngx_http_geoip2_module.so;" /etc/nginx/nginx.conf
	then
    		echo "nginx.conf is already configured"
	else
    		sed -i '1iload_module modules/ngx_http_geoip2_module.so;' /etc/nginx/nginx.conf
	fi
}

echo "Cleanup path /opt/nginx"
rm -rf /opt/nginx
echo "Prepare envirmoment for the nginx and modules"
make_env
echo "Installing requariment software"
install_req
echo "Installing Nginx"
install_nginx

