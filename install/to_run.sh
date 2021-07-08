/

stack_name=sentrynew

echo "Stack name is $stack_name ? If yes, enter, if not write the name"
read tempor

if [ -n "$tempor" ]; then
	stack_name=$tempor
fi

rancher stop $stack_name

container_list=$(rancher ps -c | grep " $stack_name-")
container_id=''
container_host=''
container_name=''

get_id(){

	line=$(echo $container_list | grep -E " $stack_name-$1-[0-9]+ ")
	container_id=$(echo $line	| awk '{print $1}')
	container_host=$(echo $line | awk '{print $5}')
        container_name=$(echo $line | awk '{print $2}')
}


#set-up-zookeper

get_id zookeper

ZOOKEEPER_SNAPSHOT_FOLDER_EXISTS=$(rancher exec -it $container_id /bin/bash -c 'ls 2>/dev/null -Ubad1 -- /var/lib/zookeeper/data/version-2 | wc -l | tr -d '[:space:]'')
if [[ "$ZOOKEEPER_SNAPSHOT_FOLDER_EXISTS" -eq 1 ]]; then
  ZOOKEEPER_LOG_FILE_COUNT=$(rancher exec -it $container_id /bin/bash -c 'ls 2>/dev/null -Ubad1 -- /var/lib/zookeeper/log/version-2/* | wc -l | tr -d '[:space:]'')
  ZOOKEEPER_SNAPSHOT_FILE_COUNT=$(ancher exec -it $container_id /bin/bash -c 'ls 2>/dev/null -Ubad1 -- /var/lib/zookeeper/data/version-2/* | wc -l | tr -d '[:space:]'')
  # This is a workaround for a ZK upgrade bug: https://issues.apache.org/jira/browse/ZOOKEEPER-3056
  if [[ "$ZOOKEEPER_LOG_FILE_COUNT" -gt 0 ]] && [[ "$ZOOKEEPER_SNAPSHOT_FILE_COUNT" -eq 0 ]]; then
    rancher --host $container_host docker cp zookeper/snapshot.0 $container_name:/var/lib/zookeeper/data/version-2/snapshot.0 

    rancher exec -it $container_id /bin/bash -c 'ZOOKEEPER_SNAPSHOT_TRUST_EMPTY=true /etc/confluent/docker/run'
    rancher restart $container_id
  fi
  cd 
fi



echo "Bootstrapping Snuba..."
# `bootstrap` is for fresh installs, and `migrate` is for existing installs
# Running them both for both cases is harmless so we blindly run them

get_id snuba-api

rancher exec $container_id /usr/src/snuba/docker_entrypoint.sh bootstrap --no-migrate --force
rancher exec $container_id /usr/src/snuba/docker_entrypoint.sh migrate --force
echo ""


echo "create kafka topics"

get_id kafka

# NOTE: This step relies on `kafka` being available from the previous `snuba-api bootstrap` step
# XXX(BYK): We cannot use auto.create.topics as Confluence and Apache hates it now (and makes it very hard to enable)
EXISTING_KAFKA_TOPICS=$(rancher exec $container_id /bin/bash -c 'kafka-topics --list --bootstrap-server kafka:9092 2>/dev/null')
NEEDED_KAFKA_TOPICS="ingest-attachments ingest-transactions ingest-events"
for topic in $NEEDED_KAFKA_TOPICS; do
  if ! echo "$EXISTING_KAFKA_TOPICS" | grep -wq $topic; then
    rancher exec $container_id /bin/bash -c 'kafka-topics --create --topic $topic --bootstrap-server kafka:9092'
    echo ""
  fi
done


#setup and upgrade database
get_id web

rancher --host $container_host docker cp sentry/* $container_name:/etc/sentry/

rancher start $container_id



if [[ -n "${CI:-}" || "${SKIP_USER_PROMPT:-0}" == 1 ]]; then
  rancher exec $container_id /docker-entrypoint.sh upgrade --noinput
  echo ""
  echo "Did not prompt for user creation due to non-interactive shell."
  echo "Run the following command to create one yourself (recommended):"
  echo ""
  echo "  docker-compose run --rm web createuser"
  echo ""
else
  rancher exec $container_id /docker-entrypoint.sh upgrade
fi

#migrate /data to /data/files


rancher exec $container_id /bin/sh -c 'mkdir -p /data/files; for i in $(ls /data | grep -v files); do mv /data/$i /data/files/$i; done; chown -R sentry:sentry /data'






