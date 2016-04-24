#!/bin/bash

set -e

function start_sentry {
    echo "Waiting for postgresql service"

    # wait for postgres container
    while [ "$(sentry config get system.admin-email 2>&1 | grep "Connection refused" > /dev/null; echo $?)" == "0" ];
    do
        echo "Retry in 2 seconds."
        sleep 2
    done

    # test if sentry already installed
    if [ "$(sentry config get system.admin-email 2>&1 | grep "Unable to fetch internal project" > /dev/null; echo $?)" == "0" ]; then
        sentry upgrade --noinput
        sentry createuser --email "$SENTRY_EMAIL" --password "$SENTRY_PASSWORD" --superuser --no-input
    fi

    sentry celery beat&
    sentry celery worker&
    sentry start
}

# first check if we're passing flags, if so
# prepend with sentry
if [ "${1:0:1}" = '-' ]; then
    set -- sentry "$@"
fi

case "$1" in
    start)
        start_sentry
    ;;
    celery|cleanup|config|createuser|devserver|django|export|help|import|init|plugins|queues|repair|shell|upgrade)
        set -- sentry "$@"
    ;;
    generate-secret-key)
        exec sentry config generate-secret-key
    ;;
esac

exec "$@"

