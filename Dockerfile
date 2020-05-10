#FROM ubuntu:18.04
FROM debian:10-slim

ENV ZEEK_VERSION 3.1.1

LABEL maintainer "https://github.com/berthayes"

RUN apt-get update && apt-get upgrade -y

RUN apt-get install -y cmake make gcc g++ flex bison libpcap-dev libssl-dev python-dev swig zlib1g-dev git tcpreplay clang librdkafka-dev net-tools iproute2

RUN echo "===> Cloning zeek..." \
  && cd /tmp \
  && git clone --recursive --branch v$ZEEK_VERSION https://github.com/zeek/zeek.git

RUN echo "===> Compiling zeek..." \
  && cd /tmp/zeek \
  && ./configure --prefix=/usr/local/zeek \
  --build-type=MinSizeRel \
  --disable-broker-tests \
  --disable-auxtools \
  --disable-python \
  && make -j 2 \
  && make install

RUN echo "===> Compiling af_packet plugin..." \
  && cd /tmp/zeek/aux/ \
  && git clone https://github.com/J-Gras/zeek-af_packet-plugin.git \
  && cd /tmp/zeek/aux/zeek-af_packet-plugin \
  && CC=clang ./configure --with-kernel=/usr --zeek-dist=/tmp/zeek \
  && make -j 2 \
  && make install \
  && /usr/local/zeek/bin/zeek -NN Zeek::AF_Packet

RUN echo "===> Installing hosom/file-extraction package..." \
  && cd /tmp \
  && git clone https://github.com/hosom/file-extraction.git \
  && find file-extraction -name "*.bro" -exec sh -c 'mv "$1" "${1%.bro}.zeek"' _ {} \; \
  && mv file-extraction/scripts /usr/local/zeek/share/zeek/site/file-extraction

RUN echo "===> Installing apache/metron-bro-plugin-kafka package..." \
  && cd /tmp/zeek/aux/ \
  && git clone https://github.com/apache/metron-bro-plugin-kafka.git \
  && cd /tmp/zeek/aux/metron-bro-plugin-kafka \
  && find . -name "*.bro" -exec sh -c 'mv "$1" "${1%.bro}.zeek"' _ {} \; \
  && sed -i 's/bro/zeek/g' ./configure \
  && ./configure --zeek-dist=/tmp/zeek \
  && make -j 2 \
  && make install \
  && /usr/local/zeek/bin/zeek -N Apache::Kafka

RUN echo "===> Check if kafka plugin installed..." && /usr/local/zeek/bin/zeek -N Apache::Kafka

COPY local.zeek /usr/local/zeek/share/zeek/site/local.zeek
COPY send-to-kafka.zeek /usr/local/zeek/share/zeek/site/send-to-kafka.zeek

COPY init_dummy.sh /init_dummy.sh
RUN chmod +x /init_dummy.sh
ENTRYPOINT ["/init_dummy.sh"]
