# nginx-http3

## Features

- Based on latest [NGINX](https://hg.nginx.org/nginx) mainline version
- HTTP/3 and QUIC support, powered by [nginx-quic](https://hg.nginx.org/nginx-quic)
- Brotli support, powered by [ngx_brotli](https://github.com/google/ngx_brotli)
- WAF support, powered by [ngx_waf](https://github.com/ADD-SP/ngx_waf)
- Headers More support, powered by [ngx_headers_more](https://github.com/openresty/headers-more-nginx-module)
- GeoIP2 support, powered by [ngx_http_geoip2_module](https://github.com/leev/ngx_http_geoip2_module)
- OCSP stapling support, powered by [this patch](https://github.com/kn007/patch/blob/master/Enable_BoringSSL_OCSP.patch)
- Use [BoringSSL](https://github.com/google/boringssl), [Cloudflare's zlib](https://github.com/cloudflare/zlib) and [jemalloc](https://github.com/jemalloc/jemalloc)
- Remove mountains of useless modules to improve performance

## Usage

Download `nginx.deb` package from [releases](https://github.com/ononoki1/nginx-http3/releases), then install it with the following command.

```bash
apt install ./nginx.deb
```

## Removed modules

- All modules that are not built by default, except `http_ssl_module` and `http_v2_module`
- `http_access_module`
- `http_autoindex_module`
- `http_browser_module`
- `http_charset_module`
- `http_empty_gif_module`
- `http_geo_module`
- `http_limit_conn_module`
- `http_limit_req_module`
- `http_memcached_module`
- `http_mirror_module`
- `http_referer_module`
- `http_split_clients_module`
- `http_scgi_module`
- `http_ssi_module`
- `http_upstream_hash_module`
- `http_upstream_ip_hash_module`
- `http_upstream_keepalive_module`
- `http_upstream_least_conn_module`
- `http_upstream_random_module`
- `http_upstream_zone_module`
- `http_userid_module`
- `http_uwsgi_module`

## Add modules back

Fork this repo, enable GitHub Actions, edit `build.sh` and find the modules you want. Then remove related parameters and wait for GitHub Actions to run. After it finishes, you can download from releases.

For example, if you want to add `http_uwsgi_module`, you need to change `sed -i 's/--http-uwsgi-temp-path=\/var\/cache\/nginx\/uwsgi_temp --http-scgi-temp-path=\/var\/cache\/nginx\/scgi_temp //g' rules` to `sed -i 's/--http-scgi-temp-path=\/var\/cache\/nginx\/scgi_temp //g' rules`, and change `sed -i 's/--with-mail --with-mail_ssl_module --with-stream --with-stream_realip_module --with-stream_ssl_module --with-stream_ssl_preread_module/--with-http_v3_module --without-http_access_module --without-http_autoindex_module --without-http_browser_module --without-http_charset_module --without-http_empty_gif_module --without-http_geo_module --without-http_limit_conn_module --without-http_limit_req_module --without-http_memcached_module --without-http_mirror_module --without-http_referer_module --without-http_split_clients_module --without-http_scgi_module --without-http_ssi_module --without-http_upstream_hash_module --without-http_upstream_ip_hash_module --without-http_upstream_keepalive_module --without-http_upstream_least_conn_module --without-http_upstream_random_module --without-http_upstream_zone_module --without-http_userid_module --without-http_uwsgi_module/g' rules` to `sed -i 's/--with-mail --with-mail_ssl_module --with-stream --with-stream_realip_module --with-stream_ssl_module --with-stream_ssl_preread_module/--with-http_v3_module --without-http_access_module --without-http_autoindex_module --without-http_browser_module --without-http_charset_module --without-http_empty_gif_module --without-http_geo_module --without-http_limit_conn_module --without-http_limit_req_module --without-http_memcached_module --without-http_mirror_module --without-http_referer_module --without-http_split_clients_module --without-http_scgi_module --without-http_ssi_module --without-http_upstream_hash_module --without-http_upstream_ip_hash_module --without-http_upstream_keepalive_module --without-http_upstream_least_conn_module --without-http_upstream_random_module --without-http_upstream_zone_module --without-http_userid_module/g' rules`.

## Use in another distribution

Fork this repo, enable GitHub Actions, edit `Dockerfile` and change `bookworm` to the one you like (e.g. `bullseye`). Then wait for GitHub Actions to run. After it finishes, you can download from releases.

## Recommended NGINX config

```nginx
http {
  brotli on;
  brotli_types application/atom+xml application/javascript application/json application/rss+xml application/vnd.ms-fontobject application/x-font-opentype application/x-font-truetype application/x-font-ttf application/x-javascript application/xhtml+xml application/xml font/eot font/opentype font/otf font/truetype image/svg+xml image/vnd.microsoft.icon image/x-icon image/x-win-bitmap text/css text/javascript text/plain text/xml;
  etag off;
  gzip on;
  gzip_types application/atom+xml application/javascript application/json application/rss+xml application/vnd.ms-fontobject application/x-font-opentype application/x-font-truetype application/x-font-ttf application/x-javascript application/xhtml+xml application/xml font/eot font/opentype font/otf font/truetype image/svg+xml image/vnd.microsoft.icon image/x-icon image/x-win-bitmap text/css text/javascript text/plain text/xml;
  more_clear_headers server;
  quic_gso on;
  quic_retry on;
  sendfile on;
  server_tokens off;
  ssl_certificate /path/to/cert_plus_intermediate;
  ssl_certificate_key /path/to/key;
  ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305; # change ECDSA to RSA if you use RSA certificate
  ssl_early_data on;
  ssl_ecdh_curve X25519:P-256;
  ssl_protocols TLSv1.2 TLSv1.3;
  ssl_session_cache shared:SSL:10m;
  ssl_session_timeout 1d;
  ssl_stapling on;
  ssl_stapling_file /path/to/ocsp; # generate by `openssl ocsp -no_nonce -issuer /path/to/intermediate -cert /path/to/cert -url "$(openssl x509 -in /path/to/cert -noout -ocsp_uri)" -respout /path/to/ocsp`
  tcp_nopush on;
  server {
    listen 80 reuseport;
    listen [::]:80 reuseport; # delete these lines if ipv6 is unavailable
    return 444;
  }
  server {
    listen 443 reuseport ssl http2;
    listen [::]:443 reuseport ssl http2;
    listen 443 reuseport http3;
    listen [::]:443 reuseport http3;
    ssl_reject_handshake on;
  }
  server {
    listen 80;
    listen [::]:80;
    server_name example.com dynamic.example.com php.example.com www.example.com;
    return 308 https://$host$request_uri;
  }
  server { # example for static site
    listen 443;
    listen [::]:443;
    listen 443 http3;
    listen [::]:443 http3;
    server_name example.com;
    root /path/to/static/site;
    add_header Alt-Svc 'h3=":443"; ma=3600';
  }
  server { # example for dynamic site
    listen 443;
    listen [::]:443;
    listen 443 http3;
    listen [::]:443 http3;
    server_name dynamic.example.com;
    add_header Alt-Svc 'h3=":443"; ma=3600';
    location / {
      proxy_pass http://ip:port;
    }
  }
  server { # example for dynamic site with php
    listen 443;
    listen [::]:443;
    listen 443 http3;
    listen [::]:443 http3;
    server_name php.example.com;
    root /path/to/php/site;
    index index.php;
    add_header Alt-Svc 'h3=":443"; ma=3600';
    location ~ ^.+\.php$ {
      include fastcgi_params;
      fastcgi_param HTTP_PROXY '';
      fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
      fastcgi_pass unix:/path/to/php/sock;
    }
  }
  server {
    listen 443;
    listen [::]:443;
    listen 443 http3;
    listen [::]:443 http3;
    server_name www.example.com;
    add_header Alt-Svc 'h3=":443"; ma=3600';
    return 308 https://example.com$request_uri;
  }
}
```
