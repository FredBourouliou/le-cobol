#!/bin/sh
# Hash the admin password (sha512crypt, as auth.cob expects) and start Apache.
set -eu

if [ -z "${COBILL_PASSWORD:-}" ]; then
    COBILL_PASSWORD="$(openssl rand -base64 18 | tr -d '/+=' | cut -c1-16)"
    echo "------------------------------------------------------------"
    echo " Le Cobol is starting on http://localhost:8080/login.html"
    echo " Admin password (generated): ${COBILL_PASSWORD}"
    echo "------------------------------------------------------------"
fi

COBILL_AUTH_HASH="$(openssl passwd -6 "${COBILL_PASSWORD}")"
export COBILL_AUTH_HASH
unset COBILL_PASSWORD

set +u  # envvars references unset variables
. /etc/apache2/envvars
exec apache2 -D FOREGROUND
