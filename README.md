# Streaming Zeek Events to Apache Kafka

This is a Docker image based on the slim Debian 10 image with the addition of tcpreplay, Zeek 3.1.1, and librdkafka.

This image does a few things when it starts up:
* Brings up a dummy0 network interface
* Starts an instance of tcpreplay that
  * Replays /pcaps/zeek_streamer.pcap
  * Sends the replayed packets to dummy0
* Starts an instance of Zeek that
  * monitors dummy0
  * sends its output as JSON to an Apache Kafka broker

Zeek is configured to send its output to a host named broker.

## Examples

```
docker run -it \
-v `pwd`/pcaps/:/pcaps \
--cap-add=NET_ADMIN \
--add-host broker:192.168.1.108 \
bertisondocker/zeek-tcpreplay-kafka:latest
```


