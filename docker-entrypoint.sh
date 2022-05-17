#!/bin/sh
set -e

[ -n "${RTTYS_TOKEN}" ] && \
    echo "TOKEN: ${RTTYS_TOKEN}"

if [ "$#" -eq 1 ] && [ -z "${1##/rttys/rttys}" ]; then
    if [ -e "./rttys.conf" ]; then
        echo "Running RTTYS use config"
        exec "$@" run --conf ./rttys.conf
    else
        echo "Running RTTYS use argments"
        exec "$@" run \
            ${RTTYS_TOKEN:+"--token ${RTTYS_TOKEN}"} \
            ${RTTYS_VERBOSE:+"--verbose ${RTTYS_VERBOSE}"} \
            ${RTTYS_ADDR_DEV:+"--addr-dev ${RTTYS_ADDR_DEV}"} \
            ${RTTYS_ADDR_USER:+"--addr-user ${RTTYS_ADDR_USER}"} \
            ${RTTYS_ADDR_HTTP_PROXY:+"--addr-http-proxy ${RTTYS_ADDR_HTTP_PROXY}"} \
            ${RTTYS_HTTP_PROXY_REDIRURL:+"--http-proxy-redir-url ${RTTYS_HTTP_PROXY_REDIRURL}"} \
            ${RTTYS_SSL_CERT:+"--ssl-cert ${RTTYS_SSL_CERT}"} \
            ${RTTYS_SSL_KEY:+"--ssl-key ${RTTYS_SSL_KEY}"} \
            ${RTTYS_SSL_CA:+"--ssl-cacert ${RTTYS_SSL_CAPATH}"} \
            ${RTTYS_WHITE_LIST:+"--white-list ${RTTYS_WHITE_LIST}"} \
            ${RTTYS_DATABASE:+"--db ${RTTYS_DATABASE}"} \
            ${RTTYS_LOCAL_AUTH:+"--local-auth"} \
            ${RTTYS_LOG_FILE:+"--log ${RTTYS_LOG_FILE}"}
    fi
else
    exec "$@"
fi
