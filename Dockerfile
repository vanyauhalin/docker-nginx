ARG \
	ACME_VERSION=3.0.9 \
	ALPINE_VERSION=3.20.3 \
	NGINX_VERSION=1.27.2 \
	NGX_BROTLI_COMMIT=a71f9312c2deb28875acc7bacfdd5695a111aa53 \
	PCRE2_VERSION=10.44

FROM alpine:$ALPINE_VERSION AS build
ARG \
	NGINX_VERSION \
	NGX_BROTLI_COMMIT \
	PCRE2_VERSION
RUN \
# Install dependencies
	apk add --no-cache --update \
		cmake \
		g++ \
		gcc \
		gettext \
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
	wget --no-verbose --output-document - \
		"https://github.com/PCRE2Project/pcre2/releases/download/pcre2-$PCRE2_VERSION/pcre2-$PCRE2_VERSION.tar.gz" | \
		tar --extract --gzip && \
	wget --no-verbose --output-document - \
		"https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz" | \
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
			--with-compat \
			--with-file-aio \
			--with-http_addition_module \
			--with-http_auth_request_module \
			--with-http_dav_module \
			--with-http_flv_module \
			--with-http_gunzip_module \
			--with-http_gzip_static_module \
			--with-http_mp4_module \
			--with-http_random_index_module \
			--with-http_realip_module \
			--with-http_secure_link_module \
			--with-http_slice_module \
			--with-http_ssl_module \
			--with-http_stub_status_module \
			--with-http_sub_module \
			--with-http_v2_module \
			--with-mail \
			--with-mail_ssl_module \
			--with-pcre-jit \
			--with-pcre="/pcre2-$PCRE2_VERSION" \
			--with-stream \
			--with-stream_realip_module \
			--with-stream_ssl_module \
			--with-stream_ssl_preread_module \
			--with-threads && \
		make && \
		make install

FROM alpine:$ALPINE_VERSION
ARG ACME_VERSION
LABEL org.opencontainers.image.title="nginx"
LABEL org.opencontainers.image.version="0.0.1"
LABEL org.opencontainers.image.authors="Ivan Uhalin <vanyauhalin@gmail.com>"
LABEL org.opencontainers.image.description="A simple Docker image for Nginx that eliminates the need to configure it over and over again"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.url="https://github.com/vanyauhalin/docker-nginx/"
LABEL org.opencontainers.image.source="https://github.com/vanyauhalin/docker-nginx/"
COPY --from=build /etc/nginx /etc/nginx
COPY --from=build /usr/bin/envsubst /usr/bin/envsubst
COPY --from=build /usr/lib/libintl.so.8 /usr/lib/libintl.so.8
COPY --from=build /usr/sbin/nginx /usr/sbin/nginx
COPY bin/ae.sh /usr/local/bin/ae
COPY bin/entrypoint.sh /usr/local/bin/entrypoint
COPY bin/ng.sh /usr/local/bin/ng
COPY snippets/base-headers.conf /etc/nginx/snippets/base-headers.conf
COPY snippets/base-options.conf /etc/nginx/snippets/base-options.conf
COPY snippets/brotli-options.conf /etc/nginx/snippets/brotli-options.conf
COPY snippets/force-https.conf /etc/nginx/snippets/force-https.conf
COPY snippets/force-non-www.conf /etc/nginx/snippets/force-non-www.conf
COPY snippets/gzip-options.conf /etc/nginx/snippets/gzip-options.conf
COPY snippets/map-non-www.conf /etc/nginx/snippets/map-non-www.conf
COPY snippets/proxy-headers.conf /etc/nginx/snippets/proxy-headers.conf
COPY snippets/proxy-options.conf /etc/nginx/snippets/proxy-options.conf
COPY snippets/proxy-ssl-options.conf /etc/nginx/snippets/proxy-ssl-options.conf
COPy snippets/ssl-headers.conf /etc/nginx/snippets/ssl-headers.conf
COPY snippets/ssl-options.conf /etc/nginx/snippets/ssl-options.conf
RUN \
# Install dependencies
# acme.sh does not work with busybox wget
# https://github.com/acmesh-official/acme.sh/issues/5319/
	apk add --no-cache --update ca-certificates openssl wget && \
	wget --no-verbose --output-document /usr/local/bin/acme \
		"https://raw.githubusercontent.com/acmesh-official/acme.sh/refs/tags/$ACME_VERSION/acme.sh" && \
	chmod +x \
		/usr/local/bin/acme \
		/usr/local/bin/ae \
		/usr/local/bin/entrypoint \
		/usr/local/bin/ng && \
# Create Nginx user
	addgroup --system nginx && \
	adduser \
		--disabled-password \
		--system \
		--home /var/cache/nginx \
		--shell /sbin/nologin \
		--ingroup nginx \
		nginx && \
# Forward Nginx logs
	mkdir /var/log/nginx && \
	cd /var/log/nginx && \
		touch access.log && \
		ln -sf /dev/stdout access.log && \
		touch error.log && \
		ln -sf /dev/stderr error.log
EXPOSE 80 443
ENTRYPOINT ["entrypoint"]
CMD ["nginx", "-g", "daemon off;"]
