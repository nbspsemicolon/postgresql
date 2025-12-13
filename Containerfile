FROM docker.io/almalinux:9 as base

COPY --chmod=755 docker-entrypoint.sh docker-ensure-initdb.sh container-build.sh /usr/local/bin/
COPY --chmod=644 timescale.repo /etc/yum.repos.d/

RUN container-build.sh base

FROM base as pgedge
RUN container-build.sh pgedge

FROM pgedge as plugins
RUN container-build.sh plugins

FROM plugins
ENV PG_MAJOR="18"
ENV PGDATA="/data"
ENV PGUSER="postgres"
ENV PGPASSWORD="changeme"
ENV POSTGRES_DB="postgres"
ENV POSTGRES_INITDB_ARGS=""
ENV POSTGRES_INITDB_WALDIR="/wal"
ENV POSTGRES_HOST_AUTH_METHOD="scram-sha-256"
ENV PATH="$PATH:/usr/pgsql-18/bin"

USER postgres

EXPOSE 5432

VOLUME "/data"
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["postgres"]
STOPSIGNAL SIGINT

