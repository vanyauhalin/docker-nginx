FROM vanyauhalin/nginx
WORKDIR /srv
COPY le.sh .
RUN set -e && \
# Install Let's Encrypt dependencies
	apk add --no-cache certbot && \
	chmod +x le.sh
