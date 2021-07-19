FROM getsentry/relay:21.7.0

COPY config.example.yml /tmp/config.yml

RUN mkdir -p /work/.relay \
  && relay --config /tmp credentials generate --stdout > /work/.relay/credentials.json \
  && mv /tmp/config.yml /work/.relay
