#!/bin/sh

# Optional ENV variables:
# * ADVERTISED_HOST: the external ip for the container, e.g. `docker-machine ip \`docker-machine active\``
# * ADVERTISED_PORT: the external port for Kafka, e.g. 9092
# * ZK_CHROOT: the zookeeper chroot that's used by Kafka (without / prefix), e.g. "kafka"
# * LOG_RETENTION_HOURS: the minimum age of a log file in hours to be eligible for deletion (default is 168, for 1 week)
# * LOG_RETENTION_BYTES: configure the size at which segments are pruned from the log, (default is 1073741824, for 1GB)
# * NUM_PARTITIONS: configure the default number of log partitions per topic

# Configure advertised host/port if we run in helios
if [ ! -z "$HELIOS_PORT_kafka" ]; then
    ADVERTISED_HOST=`echo $HELIOS_PORT_kafka | cut -d':' -f 1 | xargs -n 1 dig +short | tail -n 1`
    ADVERTISED_PORT=`echo $HELIOS_PORT_kafka | cut -d':' -f 2`
fi

# Set the external host and port
if [ ! -z "$ADVERTISED_HOST" ]; then
    echo "advertised host: $ADVERTISED_HOST"
    if grep -q "^advertised.host.name" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s/#(advertised.host.name)=(.*)/\1=$ADVERTISED_HOST/g" $KAFKA_HOME/config/server.properties
    else
        echo "advertised.host.name=$ADVERTISED_HOST" >> $KAFKA_HOME/config/server.properties
    fi
fi
if [ ! -z "$ADVERTISED_PORT" ]; then
    echo "advertised port: $ADVERTISED_PORT"
    if grep -q "^advertised.port" $KAFKA_HOME/config/server.properties; then
        sed -r -i "s/#(advertised.port)=(.*)/\1=$ADVERTISED_PORT/g" $KAFKA_HOME/config/server.properties
    else
        echo "advertised.port=$ADVERTISED_PORT" >> $KAFKA_HOME/config/server.properties
    fi
fi

# Set the zookeeper connection string
if [ ! -z "$ZK_CONNECT" ]; then
    # configure kafka
    sed -r -i "s/(zookeeper.connect)=(.*)/\1=$ZK_CONNECT/g" $KAFKA_HOME/config/server.properties
fi

# Set the SSL configuration if any
if [ "$SSL" = true ]; then
	if  grep -q "^security.protocol" $KAFKA_HOME/config/$MODE.properties; then
		echo "Configuration already exists"
	else
		echo "Configuring SSL on clients"
	   	echo security.protocol=SSL >> $KAFKA_HOME/config/$MODE.properties
		echo ssl.truststore.location=/tmp/truststore.jks >> $KAFKA_HOME/config/$MODE.properties
		echo ssl.truststore.password=c4_trust_d3f4ult_k3yst0r3 >> $KAFKA_HOME/config/$MODE.properties
		echo ssl.keystore.location=/tmp/keystore.jks >> $KAFKA_HOME/config/$MODE.properties
		echo ssl.keystore.password=br0k3r_2_c0nflu3nt_k4fk4_s3c >> $KAFKA_HOME/config/$MODE.properties
		echo ssl.key.password=br0k3r_2_c0nflu3nt_k4fk4_s3c >> $KAFKA_HOME/config/$MODE.properties
		echo ssl.enabled.protocols=TLSv1.2 >> $KAFKA_HOME/config/$MODE.properties
		echo ssl.truststore.type=JKS >> $KAFKA_HOME/config/$MODE.properties
		echo ssl.keystore.type=JKS >> $KAFKA_HOME/config/$MODE.properties
	fi
else 
	echo "No SSL configuration required"
	if grep -q "^security.protocol" $KAFKA_HOME/config/$MODE.properties; then
		echo "Removing SSL configuration from clients"
		sed -i '/ssl./ d' $KAFKA_HOME/config/$MODE.properties
		sed -i '/security./ d' $KAFKA_HOME/config/$MODE.properties
	fi
fi

# Run Kafka
#$KAFKA_HOME/bin/kafka-server-start.sh $KAFKA_HOME/config/server.properties
echo "Launching $MODE"
if [ "$MODE" = "consumer" ]; then
	$KAFKA_HOME/bin/kafka-console-consumer.sh --new-consumer --bootstrap-server $BOOTSTRAP -topic $TOPIC --consumer.config $KAFKA_HOME/config/consumer.properties
else 
	$KAFKA_HOME/bin/kafka-console-producer.sh --broker-list $BOOTSTRAP --topic $TOPIC --producer.config $KAFKA_HOME/config/producer.properties
fi
