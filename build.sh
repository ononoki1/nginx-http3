set -e
cd /github/home
echo Install dependencies.
echo deb http://deb.debian.org/debian bullseye-backports main >> /etc/apt/sources.list
apt-get update > /dev/null 2>&1
apt-get install --allow-change-held-packages --allow-downgrades --allow-remove-essential \
-o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold -fy \
cmake git libmaxminddb-dev wget > /dev/null 2>&1
wget -qO /etc/apt/trusted.gpg.d/nginx_signing.asc https://nginx.org/keys/nginx_signing.key
echo deb-src https://nginx.org/packages/mainline/debian bullseye nginx \
>> /etc/apt/sources.list
echo -e 'Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900' \
> /etc/apt/preferences.d/99nginx
apt-get update > /dev/null 2>&1
apt-get build-dep --allow-change-held-packages --allow-downgrades --allow-remove-essential \
-o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold -fy \
nginx > /dev/null 2>&1
echo Fetch NGINX source code.
apt-get source nginx > /dev/null 2>&1
cd nginx-*
mkdir debian/modules
cd debian/modules
echo Fetch additional dependencies.
git clone --depth 1 --recursive https://github.com/google/ngx_brotli > /dev/null 2>&1
mkdir ngx_brotli/deps/brotli/out
cd ngx_brotli/deps/brotli/out
cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DCMAKE_INSTALL_PREFIX=installed .. \
> /dev/null 2>&1
cmake --build . --config Release --target brotlienc > /dev/null 2>&1
cd ../../../..
git clone --depth 1 --recursive https://github.com/leev/ngx_http_geoip2_module > /dev/null 2>&1
git clone --depth 1 --recursive https://github.com/openresty/headers-more-nginx-module > /dev/null 2>&1
echo Build nginx.
cd ..
sed -i 's|NGINX Packaging <nginx-packaging@f5.com>|ononoki <me@ononoki.org>|g' control
sed -i 's|--sbin-path=/usr/sbin/nginx|--sbin-path=/usr/sbin/nginx --add-module=$(CURDIR)/debian/modules/ngx_brotli --add-module=$(CURDIR)/debian/modules/ngx_http_geoip2_module --add-module=$(CURDIR)/debian/modules/headers-more-nginx-module|g' rules
sed -i 's|--http-scgi-temp-path=/var/cache/nginx/scgi_temp --user=nginx --group=nginx|--user=www-data --group=www-data|g' rules
sed -i 's|--with-compat||g' rules
sed -i 's|--with-http_addition_module --with-http_auth_request_module --with-http_dav_module --with-http_flv_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_mp4_module --with-http_random_index_module --with-http_realip_module --with-http_secure_link_module --with-http_slice_module --with-http_ssl_module --with-http_stub_status_module --with-http_sub_module|--with-http_ssl_module|g' rules
sed -i 's|--with-mail --with-mail_ssl_module --with-stream --with-stream_realip_module --with-stream_ssl_module --with-stream_ssl_preread_module|--with-pcre-jit --without-select_module --without-poll_module --without-http_access_module --without-http_autoindex_module --without-http_browser_module --without-http_charset_module --without-http_empty_gif_module --without-http_limit_conn_module --without-http_memcached_module --without-http_mirror_module --without-http_referer_module --without-http_split_clients_module --without-http_scgi_module --without-http_ssi_module --without-http_upstream_hash_module --without-http_upstream_ip_hash_module --without-http_upstream_keepalive_module --without-http_upstream_least_conn_module --without-http_upstream_random_module --without-http_upstream_zone_module|g' rules
cd ..
dpkg-buildpackage -b
cd ..
cp nginx_*.deb nginx.deb
hash=$(sha256sum nginx.deb | awk '{print $1}')
patch=$(cat /github/workspace/patch)
minor=$(cat /github/workspace/minor)
if [[ $hash != $(cat /github/workspace/hash) ]]; then
  echo $hash > /github/workspace/hash
  if [[ $GITHUB_EVENT_NAME == push ]]; then
    patch=0
    minor=$(($(cat /github/workspace/minor)+1))
    echo $minor > /github/workspace/minor
  else
    patch=$(($(cat /github/workspace/patch)+1))
  fi
  echo $patch > /github/workspace/patch
  change=1
  echo This is a new version.
else
  echo This is an old version.
fi
echo -e "hash=$hash\npatch=$patch\nminor=$minor\nchange=$change" >> $GITHUB_ENV
