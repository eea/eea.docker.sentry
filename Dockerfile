FROM sentry:8.22.0
LABEL maintainer="EEA: IDM2 A-Team <eea-edw-a-team-alerts@googlegroups.com>"

ARG SENTRY_AUTH_GITHUB=https://github.com/getsentry/sentry-auth-github.git
ARG SENTRY_AUTH_VERSION=43f6b270b3fac32326518a78be77562ebe5abacf

RUN git clone $SENTRY_AUTH_GITHUB sentry-auth-github \
 && cd sentry-auth-github \
 && git checkout $SENTRY_AUTH_VERSION \
 && pip install . \
 && cd ../ \
 && rm -rf sentry-auth-github
