FROM sentry:8.22.0
LABEL maintainer="EEA: IDM2 A-Team <eea-edw-a-team-alerts@googlegroups.com>"

ARG SENTRY_AUTH_REPO=https://github.com/getsentry/sentry-auth-github.git
ARG SENTRY_AUTH_VERSION=43f6b270b3fac32326518a78be77562ebe5abacf
ARG SENTRY_REDMINE_REPO=https://github.com/getsentry/sentry-redmine.git
ARG SENTRY_REDMINE_VERSION=1e747a8a8258b3477fe25204380c04b4b21c1fe4

RUN cd /tmp \
 && git clone $SENTRY_AUTH_REPO && cd sentry-auth-github && git checkout $SENTRY_AUTH_VERSION && pip install . && cd ../ \
 && git clone $SENTRY_REDMINE_REPO && cd sentry-redmine && git checkout $SENTRY_REDMINE_VERSION && pip install . && cd ../ \
 && rm -vrf /tmp/sentry-*
