#!/bin/bash
set -e

DEFAULT_CONFIG='{}'

create_lightweb_user() {
  local username="$1"

  if id "$username" &>/dev/null; then
    echo "User $username already exists, skipping creation"
  else
    useradd -m -g lightweb -s /bin/bash "$username"
    echo "Created user $username"
  fi

  mkdir -p "/home/$username/config" "/home/$username/skills" "/home/$username/keys"

  if [ ! -f "/home/$username/config/registry.json" ]; then
    echo "$DEFAULT_CONFIG" > "/home/$username/config/registry.json"
  fi

  chown -R "$username:lightweb" "/home/$username"
  chmod 700 "/home/$username"
}

create_lightweb_user alice
create_lightweb_user bob

exec "$@"
