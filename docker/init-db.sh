#!/bin/bash
set -e

for user in alice bob; do
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-SQL
    CREATE DATABASE lightweb_${user};
SQL
  echo "Created database lightweb_${user}"
done
