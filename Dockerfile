FROM docker.io/debian:bookworm-slim AS cf
ARG VERSION
ENV DEBIAN_FRONTEND noninteractive
WORKDIR /
RUN set -x && \
  apt update && \
  apt install -y gnupg ca-certificates libcap2-bin curl lsb-release tini && \
  curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg && \
  echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/cloudflare-client.list && \
  apt update && \
  apt install cloudflare-warp=$VERSION -y && \
  apt autoremove -y && \
  apt clean -y &&\
  rm -rf /var/lib/apt/lists/*

FROM docker.io/debian:bookworm-slim AS tinyproxy
ENV DEBIAN_FRONTEND noninteractive
ARG VERSION
RUN apt update && \
  apt install -y build-essential curl && \
  curl -OL https://github.com/tinyproxy/tinyproxy/releases/download/1.11.2/tinyproxy-1.11.2.tar.gz && \
  tar zvxf tinyproxy-1.11.2.tar.gz
RUN cd tinyproxy-1.11.2 && \
  ./configure && make && make install && \
  cp src/tinyproxy /

FROM cf AS final
ENV DEBIAN_FRONTEND noninteractive
ARG VERSION

COPY --from=tinyproxy /tinyproxy /usr/bin/
COPY run.sh tinyproxy.conf ./
RUN chmod +x /run.sh && mkdir -p /var/log/warp
EXPOSE 8888
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/run.sh"]
