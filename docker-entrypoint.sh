#!/bin/bash
set -euo pipefail

# Load Default Vars
source /usr/local/etc/defaults.env

#Load var cache
if [ -f "$WORKDIR/cache.env" ]; then
  source "$WORKDIR/cache.env"
fi

# Load Custom Vars
if [ "${ENV_FILE:-}" ] && [ -f "${ENV_FILE}" ]; then
  source "${ENV_FILE}"
fi

TMPL_PATH=/usr/local/share/src/tmpl
STATIC_PATH=/usr/local/share/src/static

##############################
# BEGIN Unique Keys and Salts
SALTS=(
  WP_AUTH_KEY
  WP_SECURE_AUTH_KEY
  WP_LOGGED_IN_KEY
  WP_NONCE_KEY
  WP_AUTH_SALT
  WP_SECURE_AUTH_SALT
  WP_LOGGED_IN_SALT
  WP_NONCE_SALT
)

# Intialize Empty Salts
for s in "${SALTS[@]}"; do
  if [ -z "${!s:-}" ]; then
    eval "${s}"="$(head -c1m /dev/urandom | sha1sum | cut -d' ' -f1)"
  fi
done

unset SALTS
# END Unique Keys and Salts
###########################

#Save updated cache
> "$WORKDIR/cache.env"
for v in ${!WP_*}; do
  echo "${v}=\"${!v}\"" >> "$WORKDIR/cache.env"
done

# Initialize Files
tar cf - --one-file-system -C "$STATIC_PATH" . | tar xf -

#(re)create wp-cli.yml
cat "$TMPL_PATH/wp-cli.yml.tmpl" | mo --source="$WORKDIR/cache.env" > "$WORKDIR/wp-cli.yml"

# Update/Copy PHP files
cat "$TMPL_PATH/application.php.tmpl" | mo --source="$WORKDIR/cache.env" > "$WP_CONFIG_PATH/application.php"

# Copy Custom wp-config
if [ "${CUSTOM_CONFIG_FILE:-}" ] && [ -f "${CUSTOM_CONFIG_FILE}" ]; then
  cp "${CUSTOM_CONFIG_FILE}" "${WP_CONFIG_PATH}/custom.php"
fi

#Download Wordpress
if [ ! "$(ls -A ${WP_CORE_PATH})" ]; then
  wp core download
fi

timeout=$(($(date +%s) + 30))
until wp db check || wp db create || [[ $(date +%s) -gt $timeout ]]; do
  :
done
unset timeout

#Check for Wordpress update
#TODO Make this more robust and handle downgrades?
if [ $(php -r "echo version_compare( '$(wp core version)', '$WP_VERSION' );") -lt "0" ]; then
  wp core update
  wp core update-db
fi

exec "$@"
