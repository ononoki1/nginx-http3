# nginx-http3

## Distribution switch notice

According to [Debian Wiki](https://wiki.debian.org/DebianReleases), Debian bullseye will reach its end-of-life date in July 2024. Therefore, the project will switch to Debian bookworm as the packaging environment in June 2024.

## Table of Contents

- [Features](#features)
- [Usage](#usage)
- [Note](#note)
- [Removed modules](#removed-modules)
- [Add modules back](#add-modules-back)
- [Use in another distribution](#use-in-another-distribution)
- [Recommended NGINX config](#recommended-nginx-config)

## Features

- Based on latest [NGINX](https://hg.nginx.org/nginx) mainline version
- HTTP/3 and QUIC support
- Brotli support, powered by [ngx_brotli](https://github.com/google/ngx_brotli)
- GeoIP2 support, powered by [ngx_http_geoip2_module](https://github.com/leev/ngx_http_geoip2_module)
- Headers More support, powered by [ngx_headers_more](https://github.com/openresty/headers-more-nginx-module)
- OCSP stapling support, powered by [this patch](https://github.com/kn007/patch/blob/master/Enable_BoringSSL_OCSP.patch)
- Remove mountains of useless modules to improve performance

## Usage

Run following commands.

```bash
wget https://github.com/ononoki1/nginx-http3/releases/latest/download/nginx.deb
sudo apt install ./nginx.deb
```

## Note

Due to usage of BoringSSL instead of OpenSSL, some directives may not work, e.g. `ssl_conf_command`. Besides, direct OCSP stapling via `ssl_stapling on; ssl_stapling_verify on;` does not work too. You should use `ssl_stapling on; ssl_stapling_file /path/to/ocsp;`. The OCSP file can be generated via `openssl ocsp -no_nonce -issuer /path/to/intermediate -cert /path/to/cert -url "$(openssl x509 -in /path/to/cert -noout -ocsp_uri)" -respout /path/to/ocsp`.

If you really need these directives, you should consider [nginx-quictls](https://github.com/ononoki1/nginx-quictls).

## Removed modules

- All modules that are not built by default, except `http_ssl_module`, `http_v2_module` and `http_v3_module`
- `http_access_module`
- `http_autoindex_module`
- `http_browser_module`
- `http_charset_module`
- `http_empty_gif_module`
- `http_limit_conn_module`
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

## Add modules back

Fork this repo, enable GitHub Actions, edit `build.sh` and find the modules you want. Then remove related parameters and wait for GitHub Actions to run. After it finishes, you can download from releases.

For example, if you want to add `http_scgi_module` back, you need to remove `--http-scgi-temp-path=/var/cache/nginx/scgi_temp` and `--without-http_scgi_module` in `build.sh`.

## Use in another distribution

Fork this repo, enable GitHub Actions, edit `Dockerfile` and `build.sh`, and change `bullseye` to the one you like. Then wait for GitHub Actions to run. After it finishes, you can download from releases.

For example, if you want to use in Debian buster, you need to change `bullseye` to `buster`.

Note: if you are using newer version of Debian (e.g. Debian bookworm or unstable), you can simply use releases from this repo as Debian is backward compatible.

## Recommended NGINX config

```nginx
http {
  brotli on;
  gzip on;
  http2 on;
  http3 on;
  quic_gso on;
  quic_retry on;
  ssl_certificate /path/to/cert_plus_intermediate;
  ssl_certificate_key /path/to/key;
  ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305; # change `ECDSA` to `RSA` if you use RSA certificate
  ssl_early_data on;
  ssl_protocols TLSv1.2 TLSv1.3;
  ssl_session_cache shared:SSL:10m;
  ssl_session_timeout 1d;
  server {
    listen 80 reuseport;
    listen [::]:80 reuseport; # delete if ipv6 is unavailable
    return 444;
  }
  server {
    listen 443 reuseport ssl;
    listen [::]:443 reuseport ssl;
    listen 443 reuseport quic;
    listen [::]:443 reuseport quic;
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
    listen 443 quic;
    listen [::]:443 quic;
    server_name example.com;
    root /path/to/static/site;
    add_header Alt-Svc 'h3=":443"; ma=86400';
  }
  server { # example for dynamic site
    listen 443;
    listen [::]:443;
    listen 443 quic;
    listen [::]:443 quic;
    server_name dynamic.example.com;
    add_header Alt-Svc 'h3=":443"; ma=86400';
    location / {
      proxy_pass http://ip:port;
    }
  }
  server { # example for dynamic site with php
    listen 443;
    listen [::]:443;
    listen 443 quic;
    listen [::]:443 quic;
    server_name php.example.com;
    root /path/to/php/site;
    index index.php;
    add_header Alt-Svc 'h3=":443"; ma=86400';
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
    listen 443 quic;
    listen [::]:443 quic;
    server_name www.example.com;
    add_header Alt-Svc 'h3=":443"; ma=86400';
    return 308 https://example.com$request_uri;
  }
}
```
