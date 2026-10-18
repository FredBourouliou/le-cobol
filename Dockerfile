# Le Cobol — one-command local run.
#
#   docker build -t lecobol .
#   docker run --rm -p 8080:80 lecobol
#
# Then open http://localhost:8080/login.html. The admin password is
# printed in the container logs (or set your own with -e COBILL_PASSWORD=...).

FROM debian:trixie-slim

RUN apt-get update -qq \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends \
        gnucobol ghostscript apache2 make curl jq ca-certificates openssl \
 && rm -rf /var/lib/apt/lists/*

# Same layout as deploy/setup-server.sh: /opt/cobill/{bin,data,pdf,lib,web,src}
WORKDIR /opt/cobill
COPY Cobill/Makefile ./
COPY Cobill/src ./src
COPY Cobill/lib ./lib
COPY Cobill/web ./web

RUN make build \
 && mkdir -p data pdf \
 && ln -sfn /opt/cobill/data bin/data \
 && ln -sfn /opt/cobill/pdf  bin/pdf \
 && ln -sfn /opt/cobill/src  bin/src \
 && ln -sfn /opt/cobill/lib  bin/lib \
 && chgrp -R www-data data pdf \
 && chmod -R 2775 data pdf

COPY Cobill/deploy/cobill.conf /etc/apache2/sites-available/cobill.conf
RUN a2enmod -q cgi headers rewrite \
 && a2dismod -q mpm_event \
 && a2enmod -q mpm_prefork \
 && a2dissite -q 000-default \
 && a2ensite -q cobill \
 && ln -sf /dev/stdout /var/log/apache2/cobill_access.log \
 && ln -sf /dev/stderr /var/log/apache2/cobill_error.log

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 80
ENTRYPOINT ["docker-entrypoint.sh"]
