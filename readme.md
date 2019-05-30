# Vault-CRD-Proxy

The Vault-CRD-Proxy is an envoy proxy that can be installed as sidecar container in Kubernetes.
It will perform SSL Termination for applications and whenever a SSL Certificate changes it will be hot reloaded with the changed SSL Certificate.

This can be used in combination with Vault-CRD to refresh SSL Certificates when they are near the expiration date.

## Functionality

This Proxy allows SSL Termination and Certificate renewal in pods without a recreation of the pod.
Some Frameworks like Spring Boot can't reload the used SSL Certificate if it expires or it is very laborious to install this in each case.
In such cases normally a restart of the pod is required.

Whenever a secret in Kubernetes changes it will be updated inside the Pod that uses the secret.
The Vault-CRD-Proxy will detect the changed secret (in this case a SSL Certificate and Key) and performs an envoy hot restart.

## Usage

Here is an example Kubernetes file:

```yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-1
  namespace: test
  labels:
    app: nginx-1
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx-1
  template:
    metadata:
      labels:
        app: nginx-1
        version: v1
    spec:
      volumes:
      - name: nginx
        configMap:
          name: nginx-1
      - name: ssl-cert
        secret:
          secretName: ssl-cert
      containers:
      - name: nginx
        image: nginx:alpine
        volumeMounts:
        - name: nginx
          mountPath: /etc/nginx
      - name: proxy
        image: daspawnw/vault-crd-proxy:latest
        ports:
        - name: https
          containerPort: 8443
        env:
        - name: "TARGET_PORT"
          value: "80"
        volumeMounts:
          - mountPath: /etc/ssl/private
            name: ssl-cert
        livenessProbe:
          httpGet:
            port: 8443
            path: /envoy-health-check
            scheme: HTTPS
          timeoutSeconds: 5
          initialDelaySeconds: 5
          failureThreshold: 3
          successThreshold: 1
```

The interesting part here is the *proxy*-container. It mounts the ssl-cert secret where a **tls.crt** and **tls.key** file are located inside (Same structure as Ingress Certificates).
The name of the files are important and also the path **/etc/ssl/private** is mandatory.

Now it is configured to receive requests on port 8443, perform SSL Termination and then forward the requests to 127.0.0.1:80.

## Configuration properties

| Variable          | Default   | Description                                                                         |
|-------------------|-----------|-------------------------------------------------------------------------------------|
| LISTENER_PORT     | 8443      | The port Envoy is listening on for requests                                         |
| TARGET_PORT       | 8080      | The port Envoy will proxy requests to                                               |
| TARGET_HOST       | 127.0.0.1 | The host Envoy will proxy requests to (This must be an ip address)                  |
| REFRESH_INTERVAL  | 600       | The interval Envoy Wrapper script will check if the mounted Certificate has changed |
| WEBSOCKET_ENABLED | false     | Does the backend uses Websocket communication                                       |


## Mount Path

| Path                  | Description                 |
|-----------------------|-----------------------------|
| /etc/ssl/private/tls.crt | Path to the SSL Certificate |
| /etc/ssl/private/tls.key | Path to the SSL Key         |




