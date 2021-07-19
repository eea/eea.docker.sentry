FROM getsentry/sentry:21.7.0 

COPY config/* /etc/sentry/

RUN apt-get update && apt-get install -y git gcc libsasl2-dev python-dev libldap2-dev libssl-dev && \
    pip install sentry-ldap-auth && \
    apt-get remove -y gcc libsasl2-dev python-dev libldap2-dev libssl-dev && \
    rm -rf /var/lib/apt/lists/*

