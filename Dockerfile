FROM getsentry/sentry:10.0.1
LABEL maintainer="EEA: IDM2 A-Team <eea-edw-a-team-alerts@googlegroups.com>"

# Temporary, downgrade redis-py-cluster until the redis version incompatibility is fixed:
RUN apt-get update && apt-get install -y git gcc libsasl2-dev python-dev libldap2-dev libssl-dev && \
    pip install redis-py-cluster==1.3.4 sentry-ldap-auth && \
    rm -rf /var/lib/apt/lists/*

COPY auth.conf.py /tmp

RUN cat /tmp/auth.conf.py >> $SENTRY_CONF/sentry.conf.py


