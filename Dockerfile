FROM envoyproxy/envoy-alpine:v1.10.0

# Install dependencies
RUN apk add --no-cache python

ENV LISTENER_PORT=8443 TARGET_PORT=8080 TARGET_HOST=127.0.0.1 REFRESH_INTERVAL=600 WEBSOCKET_ENABLED=false

COPY hot-restart.py /etc/envoy/hot-restart.py
COPY hot-restart.sh /etc/envoy/hot-restart.sh
COPY run.sh /etc/envoy/run.sh

COPY envoy.yaml.tmpl /etc/envoy/envoy.yaml.tmpl

CMD /etc/envoy/run.sh
