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

## Why tcpreplay?
There are a few other (better) Docker images out there that can use Zeek to read pcaps and send the output to Apache Kafka.

This one uses ```tcpreplay``` to read a pcap and stream it in real-time as its original pace instead of all at once. In other words, if it took six hours to generate your 100MB pcap, this will stream those packets at their original rate over the course of those six hours.  In this way, streaming Zeek events stream into Apache Kafka at their original rate, instead of all at once.

This Docker image is also (*maybe*) unique in that it uses a ```dummy0``` network interface, so you can replay all kinds of nasty garbage without causing actual harm to network admins.

## Examples

Specify your broker host, run from your current working directory with a file named zeek_streamer.pcap at ```./pcaps/zeek_streamer.pcap``` 

```
docker run -it \
-v `pwd`/pcaps/:/pcaps \
--cap-add=NET_ADMIN \
--add-host broker:192.168.1.108 \
bertisondocker/zeek-tcpreplay-kafka:latest
```

Or, run with your own local.zeek and send-to-kafka.zeek files:

```
docker run -it \
-v `pwd`/local.zeek:/usr/local/zeek/share/zeek/site/local.zeek \
-v `pwd`/send-to-kafka.zeek:/usr/local/zeek/share/zeek/site/send-to-kafka.zeek \
--cap-add=NET_ADMIN \
--add-host broker:192.168.1.108 \
bertisondocker/zeek-tcpreplay-kafka:latest
```

## Streaming your own packet captures
This image is designed to start automatically replaying the file /pcaps/zeek_streamer.pcap
```
$ ls pcaps/
heavy_dns.pcap		zeek_streamer.pcap
```
So if you already have a file named ```zeek_streamer.pcap``` as above, then you're all set.  If your pcap isn't (or wasn't) named zeek_streamer.pcap when you started, you can still feed it to Zeek and have the results stream to Kafka.

Since ./pcaps/ is a bind mount to /pcaps in the docker image
:
```
docker exec -d 2f8f331fc56a /usr/bin/tcpreplay -i dummy0 /pcaps/heavy_dns.pcap
 ```
