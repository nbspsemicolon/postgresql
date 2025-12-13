#!/usr/bin/bash

set -o errexit
set -o pipefail
set -o nounset

BUILD_CMD="${1-none}"

if [ "$UID" -ne "0" ]; then
  echo "must be run as root"
  exit 1
fi

clean_image() {
  dnf clean all
  rm -rf /usr/lib/dnf/*
  rm -rf /usr/lib/rpm/*
  rm -rf /var/cache/dnf/*
  rm -rf /usr/share/doc/*
  rm -rf /usr/share/man/*
}

build_base() {
  if [ "$(getent passwd postgres)" != "" ]; then
    echo "$0 base already run"
    exit 1
  fi

  useradd -mUu 1000 postgres -s /usr/bin/bash

  dnf install -y epel-release dnf
  dnf config-manager --set-enabled crb
  dnf update -y --allowerasing

  dnf install -y \
    https://dnf.pgedge.com/reporpm/pgedge-release-latest.noarch.rpm \
    python3-pip \
    glibc-locale-source \
    glibc-langpack-en

  echo 'LANG="en_US.UTF-8"' > /etc/locale.conf
  echo 'LC_ALL="en_US.UTF-8"' >> /etc/locale.conf

  install --verbose --directory --owner root --group root --mode 0755 /docker-entrypoint-initdb.d
  install --verbose --directory --owner postgres --group postgres --mode 1777 /data
  install --verbose --directory --owner postgres --group postgres --mode 1777 /wal

  clean_image
}

build_pgedge() {
  if [ "$(getent passwd postgres)" == "" ]; then
    echo "run $0 base first"
    exit 1
  fi

  dnf install -y \
    pgedge-postgresql18 \
    pgedge-spock50_18 \
    pgedge-lolor_18

  clean_image
}

build_plugins() {
  if [ "$(getent passwd postgres)" == "" ]; then
    echo "run $0 base first"
    exit 1
  fi

  dnf install -y \
    pgedge-pgaudit_18 \
    pgedge-postgis35_18 \
    pgedge-pgvector_18 \
    pgedge-pgbackrest \
    pgedge-python3-psycopg2 \
    timescaledb-2-postgresql-18 \
    timescaledb-toolkit-postgresql-18

  pip install wheel
  pip install 'patroni[etcd,jsonlogger]==4.1.0'

  clean_image
  chmod a-x "$0"
}

case "$BUILD_CMD" in
  "base")
    build_base
    ;;
  "pgedge")
    build_pgedge
    ;;
  "plugins")
    build_plugins
    ;;
  *)
    echo "script argument should be base, pgedge or plugins."
    exit 1
    ;;
esac
