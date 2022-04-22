set -e
apt-get update
apt-get install --allow-change-held-packages --allow-downgrades --allow-remove-essential -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold -fy cmake dpkg-dev git golang libunwind-dev mercurial rsync wget unzip uuid-dev
wget -O /etc/apt/trusted.gpg.d/nginx_signing.asc https://nginx.org/keys/nginx_signing.key
echo -e 'deb https://nginx.org/packages/mainline/debian bullseye nginx\ndeb-src https://nginx.org/packages/mainline/debian bullseye nginx' >> /etc/apt/sources.list
echo -e 'Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900' > /etc/apt/preferences.d/99nginx
apt-get update
apt-get build-dep --allow-change-held-packages --allow-downgrades --allow-remove-essential -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold -fy nginx
cd /github/home
apt-get source nginx
mv nginx-* nginx
hg clone -b quic https://hg.nginx.org/nginx-quic
rsync -r nginx-quic/ nginx
cd nginx
wget https://raw.githubusercontent.com/kn007/patch/master/Enable_BoringSSL_OCSP.patch
patch -p1 < Enable_BoringSSL_OCSP.patch
mkdir debian/modules
cd debian/modules
git clone https://github.com/google/boringssl
mkdir boringssl/build
cd boringssl/build
cmake ..
make -j$(nproc)
cd ../..
git clone --recursive https://github.com/google/ngx_brotli
cd ..
sed -i 's/CFLAGS=""/CFLAGS="-Wno-ignored-qualifiers"/g' rules
sed -i 's/--sbin-path=\/usr\/sbin\/nginx/--sbin-path=\/usr\/sbin\/nginx --add-module="$(CURDIR)\/debian\/modules\/ngx_brotli"/g' rules
sed -i 's/--with-cc-opt="$(CFLAGS)" --with-ld-opt="$(LDFLAGS)"/--with-http_v3_module --with-stream_quic_module --with-cc-opt="-I..\/modules\/boringssl\/include $(CFLAGS)" --with-ld-opt="-L..\/modules\/boringssl\/build\/ssl -L..\/modules\/boringssl\/build\/crypto $(LDFLAGS)"/g' rules
cd ..
dpkg-buildpackage -b
cd ..
mv nginx_*.deb nginx.deb
