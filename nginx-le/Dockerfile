FROM vanyauhalin/nginx
WORKDIR /srv
COPY cmd.sh /
COPY le.sh .
RUN set -e && \
	apk add --no-cache certbot openssl && \
	chmod +x /cmd.sh && \
	chmod +x le.sh
CMD ["/cmd.sh"]
