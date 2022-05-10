set -e
cd /github/home
echo Install dependencies.
apt-get update > /dev/null 2>&1
apt-get install --allow-change-held-packages --allow-downgrades --allow-remove-essential -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold -fy cmake curl git golang libcurl4-openssl-dev libmodsecurity-dev libsodium-dev libunwind-dev libzstd-dev mercurial ninja-build rsync wget > /dev/null 2>&1
wget -qO /etc/apt/trusted.gpg.d/nginx_signing.asc https://nginx.org/keys/nginx_signing.key
echo deb-src http://nginx.org/packages/mainline/debian bullseye nginx >> /etc/apt/sources.list
echo -e 'Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900' > /etc/apt/preferences.d/99nginx
apt-get update > /dev/null 2>&1
apt-get build-dep --allow-change-held-packages --allow-downgrades --allow-remove-essential -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold -fy nginx > /dev/null 2>&1
echo Fetch nginx and nginx-quic source code.
apt-get source nginx > /dev/null 2>&1
mv nginx-* nginx
hg clone -b quic https://hg.nginx.org/nginx-quic > /dev/null 2>&1
rsync -r nginx-quic/ nginx > /dev/null 2>&1
cd nginx
curl -s https://raw.githubusercontent.com/kn007/patch/master/Enable_BoringSSL_OCSP.patch | patch -p1 > /dev/null 2>&1
curl -s https://raw.githubusercontent.com/kn007/patch/master/use_openssl_md5_sha1.patch | patch -p1 > /dev/null 2>&1
echo Fetch boringssl source code.
mkdir debian/modules
cd debian/modules
git clone https://github.com/google/boringssl > /dev/null 2>&1
echo Build boringssl.
mkdir boringssl/build
cd boringssl/build
cmake -GNinja .. > /dev/null 2>&1
ninja > /dev/null 2>&1
echo Fetch additional dependencies.
cd ../..
git clone -b current https://github.com/ADD-SP/ngx_waf > /dev/null 2>&1
cd ngx_waf
git clone https://github.com/DaveGamble/cJSON lib/cjson > /dev/null 2>&1
git clone https://github.com/troydhanson/uthash lib/uthash > /dev/null 2>&1
cd ..
git clone https://github.com/cloudflare/zlib > /dev/null 2>&1
cd zlib
make -f Makefile.in distclean > /dev/null 2>&1
cd ..
git clone https://github.com/jemalloc/jemalloc > /dev/null 2>&1
cd jemalloc
./autogen.sh > /dev/null 2>&1
make > /dev/null 2>&1
make install
ldconfig
cd ..
git clone --recursive https://github.com/google/ngx_brotli > /dev/null 2>&1
git clone https://github.com/openresty/headers-more-nginx-module > /dev/null 2>&1
git clone https://github.com/GetPageSpeed/ngx_security_headers > /dev/null 2>&1
git clone https://github.com/tokers/zstd-nginx-module > /dev/null 2>&1
echo Build nginx.
cd ..
sed -i 's/CFLAGS=""/CFLAGS="-fstack-protector-strong -Wno-ignored-qualifiers -Wno-sign-compare"/g' rules
sed -i 's/--sbin-path=\/usr\/sbin\/nginx/--sbin-path=\/usr\/sbin\/nginx --add-module=$(CURDIR)\/debian\/modules\/ngx_waf --add-module=$(CURDIR)\/debian\/modules\/ngx_brotli --add-module=$(CURDIR)\/debian\/modules\/headers-more-nginx-module --add-module=$(CURDIR)\/debian\/modules\/ngx_security_headers --add-module=$(CURDIR)\/debian\/modules\/zstd-nginx-module/g' rules
sed -i 's/--with-cc-opt="$(CFLAGS)" --with-ld-opt="$(LDFLAGS)"/--with-http_v3_module --with-stream_quic_module --with-zlib=$(CURDIR)\/debian\/modules\/zlib --with-cc-opt="-I..\/modules\/boringssl\/include $(CFLAGS)" --with-ld-opt="-ljemalloc -L..\/modules\/boringssl\/build\/ssl -L..\/modules\/boringssl\/build\/crypto $(LDFLAGS)"/g' rules
sed -i 's/dh_shlibdeps -a/dh_shlibdeps -a -- --ignore-missing-info/g' rules
cd ..
dpkg-buildpackage -b
cd ..
mv nginx_*.deb nginx.deb
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
    patch=$(($(cat /github/workspace/version)+1))
  fi
  echo $patch > /github/workspace/patch
  change=1
  echo This is a new version.
else
  echo This is an old version.
fi
echo -e "hash=$hash\npatch=$patch\nminor=$minor\nchange=$change" >> $GITHUB_ENV
