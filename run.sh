#!/bin/sh

cat /etc/envoy/envoy.yaml.tmpl | sed 's/TARGET_PORT/'"$TARGET_PORT"'/' | sed 's/TARGET_HOST/'"$TARGET_HOST"'/' | sed 's/LISTENER_PORT/'"$LISTENER_PORT"'/' | sed 's/WEBSOCKET_ENABLED/'"$WEBSOCKET_ENABLED"'/' > /etc/envoy/envoy.yaml

if expr "$TARGET_HOST" : '[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$' >/dev/null; then
  echo "VALID IP, DO NOTHING"
else
  echo "NOT AN IP, SETTING TYPE TO STRICT_DNS"
  sed -i 's/STATIC/strict_dns/' /etc/envoy/envoy.yaml
fi

certHash=$(md5sum /etc/ssl/private/tls.crt)
keyHash=$(md5sum /etc/ssl/private/tls.key)

python /etc/envoy/hot-restart.py /etc/envoy/hot-restart.sh &
pythonPid=$(echo $!)
echo "Python process id: ${pythonPid}"

sleep ${REFRESH_INTERVAL}

while [ 1 ]
do
    compareCertHash=$(md5sum /etc/ssl/private/tls.crt)
    compareKeyHash=$(md5sum /etc/ssl/private/tls.key)

    if [ "${certHash}" != "${compareCertHash}" ]; then
        certHash=$(md5sum /etc/ssl/private/tls.crt)
        keyHash=$(md5sum /etc/ssl/private/tls.key)

        echo "$(date) SSL Cert has changed, update Envoy!"

        kill -s SIGHUP $pythonPid
    fi

    sleep ${REFRESH_INTERVAL}
done
