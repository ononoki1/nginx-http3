set -e
cd /github/home
echo Install dependencies.
apt-get update > /dev/null 2>&1
apt-get dist-upgrade --allow-change-held-packages --allow-downgrades --allow-remove-essential -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold -fy
apt-get install --allow-change-held-packages --allow-downgrades --allow-remove-essential -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold -fy cmake curl dpkg-dev git golang libjemalloc-dev libpcre2-dev libunwind-dev libzstd-dev mercurial rsync wget unzip uuid-dev
wget -qO /etc/apt/trusted.gpg.d/nginx_signing.asc https://nginx.org/keys/nginx_signing.key
echo -e 'deb https://nginx.org/packages/mainline/debian bullseye nginx\ndeb-src https://nginx.org/packages/mainline/debian bullseye nginx' >> /etc/apt/sources.list
echo -e 'Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900' > /etc/apt/preferences.d/99nginx
apt-get update > /dev/null 2>&1
apt-get build-dep --allow-change-held-packages --allow-downgrades --allow-remove-essential -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold -fy nginx > /dev/null 2>&1
echo Fetch nginx and nginx-quic source code.
apt-get source nginx > /dev/null 2>&1
mv nginx-* nginx
hg clone -b quic https://hg.nginx.org/nginx-quic > /dev/null 2>&1
rsync -r nginx-quic/ nginx > /dev/null 2>&1
echo Add patches.
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
cmake .. > /dev/null 2>&1
make -j$(nproc) > /dev/null 2>&1
echo Fetch additional dependencies.
cd ../..
git clone --recursive https://github.com/google/ngx_brotli > /dev/null 2>&1
git clone https://github.com/openresty/headers-more-nginx-module > /dev/null 2>&1
git clone https://github.com/tokers/zstd-nginx-module > /dev/null 2>&1
git clone https://github.com/cloudflare/zlib > /dev/null 2>&1
cd zlib
make -f Makefile.in distclean > /dev/null 2>&1
echo Build nginx.
cd ../..
sed -i 's/CFLAGS=""/CFLAGS="-Wno-ignored-qualifiers"/g' rules
sed -i 's/--sbin-path=\/usr\/sbin\/nginx/--sbin-path=\/usr\/sbin\/nginx --add-module=$(CURDIR)\/debian\/modules\/ngx_brotli --add-module=$(CURDIR)\/debian\/modules\/headers-more-nginx-module --add-module=$(CURDIR)\/debian\/modules\/zstd-nginx-module/g' rules
sed -i 's/--with-cc-opt="$(CFLAGS)" --with-ld-opt="$(LDFLAGS)"/--with-http_v3_module --with-stream_quic_module --with-zlib=$(CURDIR)\/debian\/modules\/zlib --with-cc-opt="-I..\/modules\/boringssl\/include $(CFLAGS)" --with-ld-opt="-ljemalloc -L..\/modules\/boringssl\/build\/ssl -L..\/modules\/boringssl\/build\/crypto $(LDFLAGS)"/g' rules
cd ..
dpkg-buildpackage -b > /dev/null 2>&1
cd ..
mv nginx_*.deb nginx.deb
hash=$(sha256sum nginx.deb | awk '{print $1}')
version=$(cat /github/workspace/version)
if [[ $hash != $(cat /github/workspace/hash) ]]; then
  version=$(($(cat /github/workspace/version)+1))
  change=1
  echo This is a new version.
else
  echo This is an old version.
fi
echo $hash > /github/workspace/hash
echo $version > /github/workspace/version
echo -e "hash=$hash\nversion=$version\nchange=$change" >> $GITHUB_ENV
