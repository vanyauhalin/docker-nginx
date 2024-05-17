FROM vanyauhalin/nginx
WORKDIR /srv
COPY entrypoint.sh /
COPY le.sh .
RUN set -e && \
	apk add --no-cache certbot openssl && \
	chmod +x /entrypoint.sh && \
	chmod +x le.sh
ENTRYPOINT ["/entrypoint.sh"]
