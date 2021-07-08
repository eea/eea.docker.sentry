FROM postgres:9.6


ENV WAL2JSON_VERSION=0.0.2 \
    WAL2JSON_FILE_NAME="wal2json-Linux-x86_64-glibc.so" \
    POSTGRES_HOST_AUTH_METHOD="trust"

COPY postgres-entrypoint.sh /opt/sentry/

COPY init_hba.sh /docker-entrypoint-initdb.d/init_hba.sh

RUN apt-get update \
 && apt-get install -y --no-install-recommends  curl ca-certificates \
 && curl -o wal2json.so https://github.com/getsentry/wal2json/releases/download/$WAL2JSON_VERSION/$WAL2JSON_FILE_NAME \
 && mv wal2json.so `pg_config --pkglibdir`/wal2json.so \
 && rm -rf /var/lib/apt/lists/* 

ENTRYPOINT ["/opt/sentry/postgres-entrypoint.sh"]
CMD ["postgres", "-c", "wal_level=logical", "-c", "max_replication_slots=1", "-c", "max_wal_senders=1"]
