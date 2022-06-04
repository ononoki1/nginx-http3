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

## Usage

Download `nginx.deb` package from [releases](https://github.com/ononoki1/nginx-http3/releases), then install it with the following command.

```bash
apt install ./nginx.deb
```

## Use in another distribution

Fork this repo, enable GitHub Actions, edit `Dockerfile` and change `bookworm` to the one you like (e.g. `bullseye`). Then wait for GitHub Actions to run. After it finishes, you can download from releases.

## Recommended NGINX config

```nginx
http {
  aio threads;
  aio_write on;
  brotli on;
  brotli_comp_level 0; # high level compression is simply a waste of cpu
  brotli_types application/atom+xml application/javascript application/json application/rss+xml application/vnd.ms-fontobject application/x-font-opentype application/x-font-truetype application/x-font-ttf application/x-javascript application/xhtml+xml application/xml font/eot font/opentype font/otf font/truetype image/svg+xml image/vnd.microsoft.icon image/x-icon image/x-win-bitmap text/css text/javascript text/plain text/xml;
  client_body_buffer_size 1m; # tweak these buffer sizes as you need
  client_header_buffer_size 4k;
  directio 1m;
  etag off;
  fastcgi_buffers 1024 16k;
  fastcgi_buffer_size 64k;
  fastcgi_busy_buffers_size 128k;
  gzip on;
  gzip_types application/atom+xml application/javascript application/json application/rss+xml application/vnd.ms-fontobject application/x-font-opentype application/x-font-truetype application/x-font-ttf application/x-javascript application/xhtml+xml application/xml font/eot font/opentype font/otf font/truetype image/svg+xml image/vnd.microsoft.icon image/x-icon image/x-win-bitmap text/css text/javascript text/plain text/xml;
  if_modified_since before;
  large_client_header_buffers 64 8k;
  more_clear_headers server;
  proxy_buffers 1024 16k;
  proxy_buffer_size 64k;
  proxy_busy_buffers_size 128k;
  proxy_http_version 1.1;
  proxy_set_header Connection $http_connection;
  proxy_set_header Host $host;
  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  proxy_ssl_protocols TLSv1.3;
  proxy_ssl_server_name on;
  proxy_ssl_trusted_certificate /etc/ssl/certs/ca-certificates.crt;
  proxy_ssl_verify on;
  proxy_ssl_verify_depth 2;
  quic_gso on;
  quic_retry on;
  resolver 127.0.0.1; # change if you don't have local dns
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
    return 301 https://$host$request_uri;
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
    return 301 https://example.com$request_uri;
  }
}
```
