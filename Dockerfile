# Объявляем переменную BASE_IMAGE перед использованием в FROM
ARG BASE_IMAGE=alpine:3.22.0

# Этап загрузки Grafana
FROM alpine:3.22.0 AS downloader

ARG GRAFANA_VERSION
RUN mkdir /tmp/grafana \
  && wget -P /tmp/ https://dl.grafana.com/oss/release/grafana-${GRAFANA_VERSION}.linux-amd64.tar.gz \
  && tar xfz /tmp/grafana-${GRAFANA_VERSION}.linux-amd64.tar.gz --strip-components=1 -C /tmp/grafana

# Основной этап сборки
FROM ${BASE_IMAGE}

ENV PATH=/usr/share/grafana/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    GF_PATHS_CONFIG="/etc/grafana/grafana.ini" \
    GF_PATHS_DATA="/var/lib/grafana" \
    GF_PATHS_HOME="/usr/share/grafana" \
    GF_PATHS_LOGS="/var/log/grafana" \
    GF_PATHS_PLUGINS="/var/lib/grafana/plugins" \
    GF_PATHS_PROVISIONING="/etc/grafana/provisioning"

WORKDIR $GF_PATHS_HOME    

RUN set -ex \
    && addgroup -S grafana \
    && adduser -S -G grafana grafana \
    && apk add --no-cache libc6-compat ca-certificates su-exec bash

COPY --from=downloader /tmp/grafana "$GF_PATHS_HOME"

RUN mkdir -p "$GF_PATHS_HOME/.aws" \
    && mkdir -p "$GF_PATHS_PROVISIONING/datasources" \
        "$GF_PATHS_PROVISIONING/dashboards" \
        "$GF_PATHS_PROVISIONING/notifiers" \
        "$GF_PATHS_LOGS" \
        "$GF_PATHS_PLUGINS" \
        "$GF_PATHS_DATA" \
    && chown -R grafana:grafana "$GF_PATHS_DATA" "$GF_PATHS_HOME/.aws" "$GF_PATHS_LOGS" "$GF_PATHS_PLUGINS" "$GF_PATHS_PROVISIONING" \
    && chmod -R 777 "$GF_PATHS_DATA" "$GF_PATHS_HOME/.aws" "$GF_PATHS_LOGS" "$GF_PATHS_PLUGINS" "$GF_PATHS_PROVISIONING"

COPY ./config/grafana.ini "$GF_PATHS_CONFIG"
COPY ./config/run.sh /run.sh
RUN chmod +x /run.sh

EXPOSE 3000

CMD ["/run.sh"]
