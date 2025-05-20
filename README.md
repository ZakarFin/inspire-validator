# Custom build for INSPIRE validator

- Overrides the built-in http://localhost:8090 references from `ghcr.io/inspire-mif/helpdesk-validator/inspire-validator:2024.3`
- Removes debug port listening from Jetty
- Works around the container not working properly on WSL/Kubernetes/Azure container app
- Adds a ROOT webapp so calling without the /validator path redirects to /validator

You could modify etf-config.properties for the domain (works for the app running on port 8080).
 If it's left as is, the http://localhost:8090 will be replaced with the value from `SERVICE_DOMAIN_OVERRIDE` env variable.
 The env variable defaults to empty string which works for most cases (the domain is only passed to js/html for links so the missing domain works).

## Build with

```sh
podman build --tag validator:0.1 .
```

## Run with

```sh
podman run --rm -e SERVICE_DOMAIN_OVERRIDE="https://your.domain" -dt -p 8080:8080/tcp -p 8090:8090/tcp localhost/validator:0.1
```
The `--rm` flag removes the container when done. It's useful when developing/running on localhost for testing

### Behind corporate proxy?

Use these on the run command
```sh
-e HTTP_PROXY_HOST={your.proxy.host} -e HTTP_PROXY_PORT={your.proxy.port}  -e HTTPS_PROXY_HOST={your.proxy.host} -e HTTPS_PROXY_PORT={your.proxy.port}
```

## Take a look inside to see if something is wrong

```sh
podman exec -it -l /bin/sh -c bash
```
-l means last container (replace with id if needed)
-it means interactive to run commands on bash (where -dt means detached/run on background)

### Inside the container

- validator logs: /etf/logs/etf.log
- validator config with domain override: /etf/config/etf-config.properties
- config.js with the domain override: /etf/validator/js/config.js

You can get the id to replace `-l` with:
```sh
podman ps -a
```
