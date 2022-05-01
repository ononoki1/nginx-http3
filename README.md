# nginx

## Features

- Based on latest [NGINX](https://hg.nginx.org/nginx) mainline version
- QUIC support, powered by [nginx-quic](https://hg.nginx.org/nginx-quic)
- Brotli support, powered by [ngx_brotli](https://github.com/google/ngx_brotli)
- Headers More support, powered by [ngx_headers_more](https://github.com/openresty/headers-more-nginx-module)
- OCSP stapling support, powered by [this patch](https://github.com/kn007/patch/blob/master/Enable_BoringSSL_OCSP.patch)
- WAF support, powered by [ngx_waf](https://github.com/ADD-SP/ngx_waf/tree/current)
- Security Headers support, powered by [ngx_security_headers](https://github.com/GetPageSpeed/ngx_security_headers)
- Zstandard support, powered by [zstd-nginx-module](https://github.com/tokers/zstd-nginx-module)
- Use [BoringSSL](https://github.com/google/boringssl), [Cloudflare's zlib](https://github.com/cloudflare/zlib) and [jemalloc](https://github.com/jemalloc/jemalloc/tree/master)
- Use OpenSSL's hash functions instead of NGINX's, powered by [this patch](https://github.com/kn007/patch/blob/master/use_openssl_md5_sha1.patch)

## Used by

- [ononoki.org](https://ononoki.org/): main site
- [data.ononoki.org](https://data.ononoki.org/): backend server
- [s.ononoki.org](https://s.ononoki.org/): private search engine
