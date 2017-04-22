#!/bin/bash
# Build NGINX and modules on Heroku.
# This program is designed to run in a web dyno provided by Heroku.
# We would like to build an NGINX binary for the builpack on the
# exact machine in which the binary will run.
# Our motivation for running in a web dyno is that we need a way to
# download the binary once it is built so we can vendor it in the buildpack.
#
# Once the dyno has is 'up' you can open your browser and navigate
# this dyno's directory structure to download the nginx binary.

NGINX_VERSION=${NGINX_VERSION-1.11.12}
PCRE_VERSION=${PCRE_VERSION-8.40}
HEADERS_MORE_VERSION=${HEADERS_MORE_VERSION-0.32}
ZLIB_VERSION=${ZLIB_VERSION-1.2.11}
NCHAN_VERSION=${NCHAN_VERSION-1.1.3}

nginx_tarball_url=http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
headers_more_url=https://github.com/openresty/headers-more-nginx-module/archive/v${HEADERS_MORE_VERSION}.tar.gz
pcre_tarball_url=ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-${PCRE_VERSION}.tar.gz
zlib_url=http://zlib.net/zlib-${ZLIB_VERSION}.tar.gz
nchan_url=https://github.com/slact/nchan/archive/v${NCHAN_VERSION}.tar.gz

temp_dir=$(mktemp -d /tmp/nginx.XXXXXXXXXX)

echo "Serving files from /tmp on $PORT"
cd /tmp
python -m SimpleHTTPServer $PORT &

cd $temp_dir
echo "Temp dir: $temp_dir"

echo "Downloading $nginx_tarball_url"
curl -L $nginx_tarball_url | tar xzv

echo "Downloading $headers_more_url"
curl -L $headers_more_url | tar xzv

echo "Downloading $nchan_url"
curl -L $nchan_url | tar xzv

echo "Downloading $pcre_tarball_url"
(cd nginx-${NGINX_VERSION} && curl -L $pcre_tarball_url | tar xvz )

echo "Downloading $zlib_url"
(cd nginx-${NGINX_VERSION} && curl -L $zlib_url | tar xvz )

(
  cd nginx-${NGINX_VERSION}
  ./configure \
    --with-pcre=pcre-${PCRE_VERSION} \
    --with-zlib=zlib-${ZLIB_VERSION} \
    --prefix=/tmp/nginx \
    --with-http_gzip_static_module \
    --add-module=/${temp_dir}/headers-more-nginx-module-${HEADERS_MORE_VERSION} \
    --add-module=/${temp_dir}/nchan-${NCHAN_VERSION} \
    --with-http_v2_module \
    --with-http_ssl_module \
    --with-http_stub_status_module \
    --with-cc-opt='-g -O2 -fstack-protector --param=ssp-buffer-size=4 -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2' \
    --with-ld-opt='-Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,--as-needed'

  make install
)

while true
do
  sleep 1
  echo "."
done
