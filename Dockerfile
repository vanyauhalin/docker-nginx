ARG \
	ACME_VERSION=3.0.9 \
	ALPINE_VERSION=3.20.0 \
	NGINX_VERSION=1.25.5 \
	NGX_BROTLI_COMMIT=a71f9312c2deb28875acc7bacfdd5695a111aa53 \
	PCRE2_VERSION=10.43

FROM alpine:$ALPINE_VERSION AS build
ARG \
	NGINX_VERSION \
	NGX_BROTLI_COMMIT \
	PCRE2_VERSION
RUN \
# Install dependencies
	apk update && \
	apk add --no-cache \
		cmake \
		g++ \
		gcc \
		git \
		linux-headers \
		make \
		openssl-dev \
		zlib-dev && \
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
			cmake \
				-DBUILD_SHARED_LIBS=OFF \
				-DCMAKE_BUILD_TYPE=Release \
				-DCMAKE_INSTALL_PREFIX=installed \
				.. && \
			cmake --build . --config Release --target brotlienc && \
			cd / && \
# Build Nginx
	wget --output-document=- "https://github.com/PCRE2Project/pcre2/releases/download/pcre2-$PCRE2_VERSION/pcre2-$PCRE2_VERSION.tar.gz" | \
		tar --extract --gzip && \
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
			--add-module=/ngx_brotli \
			--with-threads \
			--with-file-aio \
			--with-http_ssl_module \
			--with-http_v2_module \
			--with-http_v3_module \
			--without-http_ssi_module \
			--without-http_userid_module \
			--without-http_access_module \
			--without-http_auth_basic_module \
			--without-http_mirror_module \
			--without-http_autoindex_module \
			--without-http_geo_module \
			--without-http_map_module \
			--without-http_split_clients_module \
			--without-http_referer_module \
			--without-http_fastcgi_module \
			--without-http_uwsgi_module \
			--without-http_scgi_module \
			--without-http_grpc_module \
			--without-http_memcached_module \
			--without-http_limit_conn_module \
			--without-http_limit_req_module \
			--without-http_empty_gif_module \
			--without-http_browser_module \
			--without-http_upstream_hash_module \
			--without-http_upstream_ip_hash_module \
			--without-http_upstream_least_conn_module \
			--without-http_upstream_random_module \
			--without-http_upstream_keepalive_module \
			--without-http_upstream_zone_module \
			--without-mail_pop3_module \
			--without-mail_imap_module \
			--without-mail_smtp_module \
			--without-stream_limit_conn_module \
			--without-stream_access_module \
			--without-stream_geo_module \
			--without-stream_map_module \
			--without-stream_split_clients_module \
			--without-stream_return_module \
			--without-stream_set_module \
			--without-stream_upstream_hash_module \
			--without-stream_upstream_least_conn_module \
			--without-stream_upstream_random_module \
			--without-stream_upstream_zone_module \
			--with-pcre="/pcre2-$PCRE2_VERSION" && \
		make && \
		make install && \
		rm -r \
			/etc/nginx/fastcgi* \
			/etc/nginx/scgi* \
			/etc/nginx/uwsgi*

FROM alpine:$ALPINE_VERSION
ARG ACME_VERSION
LABEL org.opencontainers.image.title="nginx"
LABEL org.opencontainers.image.version="0.0.1"
LABEL org.opencontainers.image.authors="Ivan Uhalin <vanyauhalin@gmail.com>"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.url="https://github.com/vanyauhalin/docker-nginx/"
LABEL org.opencontainers.image.source="https://github.com/vanyauhalin/docker-nginx/"
COPY --from=build /etc/nginx /etc/nginx
COPY --from=build /usr/sbin/nginx /usr/sbin
COPY bin/ae.sh /usr/local/bin/ae
COPY bin/entrypoint.sh /usr/local/bin/entrypoint
RUN \
# Install dependencies
	apk add --no-cache --update ca-certificates openssl wget && \
	wget --no-verbose --output-document /usr/local/bin/acme \
		"https://raw.githubusercontent.com/acmesh-official/acme.sh/refs/tags/$ACME_VERSION/acme.sh" && \
	chmod +x /usr/local/bin/acme /usr/local/bin/ae /usr/local/bin/entrypoint && \
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
ENTRYPOINT ["entrypoint"]
CMD ["nginx", "-g", "daemon off;"]
