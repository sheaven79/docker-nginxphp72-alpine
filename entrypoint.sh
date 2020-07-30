#!/bin/ash
set -eo pipefail

[[ "${DEBUG}" == true ]] && set -x

start_system() {
    echo "Starting env! ..."
    /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
}

start_system

exit 0