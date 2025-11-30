FROM docker.io/almalinux:9

COPY --chmod=755 docker-entrypoint.sh docker-ensure-initdb.sh /usr/local/bin/

RUN <<ENDRUN
#!/usr/bin/bash

set -o errexit
set -o pipefail
set -o nounset

useradd -mUu 1000 postgres -s /usr/bin/bash

cat <<REPOFILE > /etc/yum.repos.d/timescale.repo
[timescale_timescaledb]
name=timescale_timescaledb
baseurl=https://packagecloud.io/timescale/timescaledb/el/9/\$basearch
repo_gpgcheck=0
gpgcheck=0
enabled=1
gpgkey=https://packagecloud.io/timescale/timescaledb/gpgkey
sslverify=0
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
metadata_expire=300
REPOFILE

dnf install -y epel-release dnf
dnf config-manager --set-enabled crb
dnf update -y --allowerasing

dnf install -y https://dnf.pgedge.com/reporpm/pgedge-release-latest.noarch.rpm

dnf install -y \
  pgedge-postgresql18 \
  pgedge-spock50_18 \
  pgedge-snowflake_18 \
  pgedge-lolor_18 \
  pgedge-pgaudit_18 \
  pgedge-postgis35_18 \
  pgedge-pgvector_18 \
  pgedge-pgbackrest \
  pgedge-python3-psycopg2 \
  timescaledb-2-postgresql-18 \
  timescaledb-toolkit-postgresql-18 \
  python3-pip \
  glibc-locale-source \
  glibc-langpack-en

dnf clean all
rm -rf /usr/lib/dnf/*
rm -rf /usr/lib/rpm/*
rm -rf /var/cache/dnf/*
rm -rf /usr/share/doc/*
rm -rf /usr/share/man/*

cat <<ENDLOCALE > /etc/locale.conf
LANG=en_US.UTF-8
LC_ALL=en_US.UTF-8
ENDLOCALE

install --verbose --directory --owner root --group root --mode 0755 /docker-entrypoint-initdb.d
install --verbose --directory --owner postgres --group postgres --mode 1777 /data

pip install wheel
pip install 'patroni[etcd,jsonlogger]==4.1.0'
ENDRUN

USER postgres

STOPSIGNAL SIGINT

EXPOSE 5432

ENV PG_MAJOR=${POSTGRES_MAJOR_VERSION}
ENV PATH=$PATH:/usr/pgsql-${POSTGRES_MAJOR_VERSION}/bin

VOLUME "/data"
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["postgres"]
