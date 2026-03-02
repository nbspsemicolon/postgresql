FROM docker.io/almalinux:9 as base

COPY --chmod=755 src/*.sh /usr/local/bin/
COPY --chmod=644 src/timescale.repo /etc/yum.repos.d/

RUN cat /etc/yum.repos.d/timescale.repo

RUN /usr/local/bin/container-build.sh base

FROM base as pgedge
RUN /usr/local/bin/container-build.sh pgedge

FROM pgedge as plugins
RUN /usr/local/bin/container-build.sh plugins
RUN /usr/local/bin/container-build.sh clean

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

