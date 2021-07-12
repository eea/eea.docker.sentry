#!/bin/bash

set -e

stack_name=sentrynew

echo "Stack name is $stack_name ? If yes, enter, if not write the name"
read tempor

if [ -n "$tempor" ]; then
	stack_name=$tempor
fi

#rancher stop $stack_name

container_list="$(rancher ps -c -a | grep " $stack_name-")"
container_id=''
container_host=''
container_name=''

get_id(){

	line=$(echo -e "$container_list" | grep -E " $stack_name-$1-[0-9]+ ")
	echo "Found $line"
	container_id=$(echo $line	| awk '{print $1}')
	container_host=$(echo $line | awk '{print $5}')
        container_name=$(rancher inspect $container_id | jq '.externalId'  | tr -d \" )
	container_status=$(echo $line | awk '{print $4}')
        echo $container_name
}


#set-up-zookeeper

echo "Do zookeeper - write yes to continue"
read r
if [[ "$r" == "yes" ]]; then

    get_id zookeeper

    if [[ "$container_status" == "stopped" ]]; then
	echo "Starting container zookeper"
	rancher start $container_id
    	sleep 15
    fi

    rancher exec "$container_id" mkdir -p /var/lib/zookeeper/data/version-2/

    echo "rancher --host $container_host docker cp zookeeper/snapshot.0 $container_name:/var/lib/zookeeper/data/version-2/snapshot.0"


    rancher --host $container_host docker cp zookeeper/snapshot.0 $container_name:/var/lib/zookeeper/data/version-2/snapshot.0

    rancher exec -it $container_id /bin/bash -c 'ZOOKEEPER_SNAPSHOT_TRUST_EMPTY=true /etc/confluent/docker/run'
    rancher restart $container_id

else
	echo "Skipping zookeper"
fi


echo "Do Kafka - write yes to continue"
read r
if [[ "$r" == "yes" ]]; then


echo "create kafka topics"

get_id kafka

    if [[ "$container_status" == "stopped" ]]; then
        echo "Starting container kafka"
	rancher start $container_id
        sleep 15
    fi


# NOTE: This step relies on `kafka` being available from the previous `snuba-api bootstrap` step
# XXX(BYK): We cannot use auto.create.topics as Confluence and Apache hates it now (and makes it very hard to enable)
EXISTING_KAFKA_TOPICS=$(rancher exec $container_id /bin/bash -c 'kafka-topics --list --bootstrap-server kafka:9092 2>/dev/null')
NEEDED_KAFKA_TOPICS="ingest-attachments ingest-transactions ingest-events"
echo "Found existing topics:"
echo $EXISTING_KAFKA_TOPICS
for topic in $NEEDED_KAFKA_TOPICS; do
  if ! echo "$EXISTING_KAFKA_TOPICS" | grep -wq $topic; then
    rancher exec $container_id /bin/bash -c "kafka-topics --create --topic $topic --bootstrap-server kafka:9092"
    echo ""
  fi
done


else
        echo "Skipping kafka"
fi








echo "Do Snuba - write yes to continue"
read r
if [[ "$r" == "yes" ]]; then


     echo "Bootstrapping Snuba..."
	

    get_id clickhouse

    if [[ "$container_status" == "stopped" ]]; then
        echo "Starting container clickhouse"
        rancher start $container_id
        sleep 15
    fi
    get_id snuba-api


    if [[ "$container_status" == "stopped" ]]; then
        echo "Starting container snuba-api"
	rancher start $container_id
        sleep 15
    fi
    echo "bootstrap"
    rancher exec $container_id /usr/src/snuba/docker_entrypoint.sh bootstrap --no-migrate --force
    echo "migrate"
    rancher exec $container_id /usr/src/snuba/docker_entrypoint.sh  migrations migrate --force
    echo ""
else
        echo "Skipping snuba"
fi


echo "Do Sentry web - write yes to continue"
read r
if [[ "$r" == "yes" ]]; then



#setup and upgrade database
get_id web



    if [[ "$container_status" == "stopped" ]]; then
        echo "Starting container web ( sentry)"
        rancher start $container_id
        sleep 15
    fi



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

else
        echo "Skipping sentry web"
fi





