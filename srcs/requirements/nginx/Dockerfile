FROM debian:bookworm

# Install nginx and openssl (used to create the certificate).
RUN apt-get update && apt-get install -y nginx openssl \
    && rm -rf /var/lib/apt/lists/*

# Self-signed TLS certificate. The domain is local with no real authority, so a
# self-signed cert is expected (the browser just shows a warning).
RUN mkdir -p /etc/nginx/ssl && \
    openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
        -keyout /etc/nginx/ssl/inception.key \
        -out    /etc/nginx/ssl/inception.crt \
        -subj   "/C=FR/L=Mulhouse/O=42/CN=mlorenzo.42.fr"

# Add our HTTPS site (conf.d is included by nginx), and remove Debian's default
# site so nothing listens on port 80.
COPY conf/nginx.conf /etc/nginx/conf.d/default.conf
RUN rm -f /etc/nginx/sites-enabled/default

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]
