ARG \
	ALPINE_VERSION=3.19.1 \
	CERTBOT_VERSION=2.10.0 \
	NGINX_CONFIGURE_PARAMETERS=--with-compat --with-threads --with-file-aio --with-http_gzip_static_module --with-http_ssl_module --with-http_v2_module --with-http_v3_module \
	NGINX_VERSION=1.25.5 \
	NGX_BROTLI_COMMIT=a71f9312c2deb28875acc7bacfdd5695a111aa53 \
	PCRE2_VERSION=10.43

FROM alpine:$ALPINE_VERSION AS build
ARG \
	CERTBOT_VERSION \
	NGINX_CONFIGURE_PARAMETERS \
	NGINX_VERSION \
	NGX_BROTLI_COMMIT \
	PCRE2_VERSION
RUN set -e && \
# Install dependencies
	apk update && \
	apk add --no-cache \
		cmake \
		g++ \
		gcc \
		git \
		libc-dev \
		linux-headers \
		make \
		openssl-dev \
		zlib-dev && \
# Download PCRE2
	wget --output-document=- "https://github.com/PCRE2Project/pcre2/releases/download/pcre2-$PCRE2_VERSION/pcre2-$PCRE2_VERSION.tar.gz" | \
		tar --extract --gzip && \
# Build Brotli
	mkdir ngx_brotli && \
	cd ngx_brotli && \
		git init && \
		git remote add origin https://github.com/google/ngx_brotli.git && \
		git fetch --depth 1 origin "$NGX_BROTLI_COMMIT" && \
		git checkout FETCH_HEAD && \
		git submodule update --init --recursive --depth 1 && \
		mkdir deps/brotli/out && \
		cd deps/brotli/out && \
			cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=installed .. && \
			cmake --build . --config Release --target brotlienc && \
			cd / && \
# Build Nginx
	wget --output-document=- "https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz" | \
		tar --extract --gzip && \
	cd "nginx-$NGINX_VERSION" && \
		./configure \
			--prefix=/etc/nginx \
			--sbin-path=/usr/sbin/nginx \
			--modules-path=/usr/lib/nginx/modules \
			--conf-path=/etc/nginx/nginx.conf \
			--error-log-path=/var/log/nginx/error.log \
			--http-log-path=/var/log/nginx/access.log \
			--pid-path=/var/run/nginx.pid \
			--lock-path=/var/run/nginx.lock \
			--http-client-body-temp-path=/var/cache/nginx/client_temp \
			--http-proxy-temp-path=/var/cache/nginx/proxy_temp \
			--http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
			--http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
			--http-scgi-temp-path=/var/cache/nginx/scgi_temp \
			--user=nginx \
			--group=nginx \
			--with-pcre="/pcre2-$PCRE2_VERSION" \
			--add-module=/ngx_brotli \
			$NGINX_CONFIGURE_PARAMETERS && \
		make && \
		make install && \
# Download additional SSL configurations
	mkdir /etc/nginx/snippets && \
	cd /etc/nginx/snippets && \
		wget --output-document=options-ssl-nginx.conf "https://raw.githubusercontent.com/certbot/certbot/v$CERTBOT_VERSION/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf" && \
		wget --output-document=ssl-dhparams.pem "https://raw.githubusercontent.com/certbot/certbot/v$CERTBOT_VERSION/certbot/certbot/ssl-dhparams.pem"

FROM alpine:$ALPINE_VERSION
COPY --from=build /etc/nginx /etc/nginx
COPY --from=build /usr/sbin/nginx /usr/sbin
RUN set -e && \
# Update dependencies
	apk update && \
# Create nginx user and group
	addgroup --system nginx && \
	adduser \
		--disabled-password \
		--system \
		--home /var/cache/nginx \
		--shell /sbin/nologin \
		--ingroup nginx \
		nginx && \
# Forward request and error logs to Docker log collector
	mkdir /var/log/nginx && \
	cd /var/log/nginx && \
		touch access.log && \
		ln -sf /dev/stdout access.log && \
		touch error.log && \
		ln -sf /dev/stderr error.log
EXPOSE 80 443
STOPSIGNAL SIGTERM
CMD ["nginx", "-g", "daemon off;"]
