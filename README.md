Kafka in Docker
===

This repository contains a Docker image for Apache Kafka consumers and producers (zookeeper and brokers are not a part of this image)

One of it's main goals is to provide an easy way to use SSL based authentication on consumers and producers out of the box

Run
---

```bash
docker run -it --net=host -e MODE=producer -e TOPIC=test -e SSL=true -e BOOTSTRAP=broker1:port1,broker2:port2 alonsod86/kafka
```

```bash
docker run -it --net=host -e MODE=consumer -e TOPIC=test -e SSL=true -e BOOTSTRAP=broker1:port1,broker2:port2 alonsod86/kafka
```

In the box
---
* **alonsod86/kafka**

  The docker image apache Kafka. Built from the `kafka`
  directory. No Zookeeper.


Build from Source
---

    docker build -t alonsod86/kafka kafka/


