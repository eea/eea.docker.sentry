FROM sentry:10.0.1
LABEL maintainer="EEA: IDM2 A-Team <eea-edw-a-team-alerts@googlegroups.com>"

ARG SENTRY_REDMINE_REPO=https://github.com/getsentry/sentry-redmine.git
ARG SENTRY_REDMINE_VERSION=ccf4686515995d530842639625f54da712e3c21b

ARG SENTRY_AUTH_REPO=https://github.com/getsentry/sentry-auth-github.git
ARG SENTRY_AUTH_VERSION=43f6b270b3fac32326518a78be77562ebe5abacf

RUN cd /tmp \
 && git clone $SENTRY_AUTH_REPO && cd sentry-auth-github && git checkout $SENTRY_AUTH_VERSION && pip install . && cd ../ \
 && git clone $SENTRY_REDMINE_REPO && cd sentry-redmine && git checkout $SENTRY_REDMINE_VERSION && pip install . && cd ../ \ 
 && rm -vrf /tmp/sentry-*

# Temporary, downgrade redis-py-cluster until the redis version incompatibility is fixed:
RUN apt-get update && apt-get install -y libsasl2-dev python-dev libldap2-dev libssl-dev && \
    pip install redis-py-cluster==1.3.4 sentry-ldap-auth && \
    rm -rf /var/lib/apt/lists/*

COPY auth.conf.py /tmp

RUN cat /tmp/auth.conf.py >> $SENTRY_CONF/sentry.conf.py


