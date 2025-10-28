# Custom build for INSPIRE validator

- Overrides the built-in http://localhost:8090 references from `ghcr.io/inspire-mif/helpdesk-validator/inspire-validator:2025.1.1`
- Removes debug port listening from Jetty
- Works around the container not working properly on WSL/Kubernetes/Azure container app
- Adds a ROOT webapp so calling without the /validator path redirects to /validator

You can use `SERVICE_DOMAIN_OVERRIDE` env variable to swith the domain that the service is running on.
If not given it will default to an empty string that will be used to replace references to http://localhost:8090.
The empty string works for most cases (the domain is only passed to js/html for links so the missing domain works as only the client/browser uses it).

You can modify `etf-config.properties` for the domain (affects the app running on port 8080), but you don't need to (the env-variable will modify the domain).
It's a file that is inside the war-file the container downloads so its easier to pass inside the container with separate file instead of modifying the one inside.

## Build with

```sh
podman build --tag validator:0.1 .
```

Replace `podman` with `docker` depending on which you use.

## Run with

```sh
podman run --rm -dt -p 8080:8080/tcp -p 8090:8090/tcp localhost/validator:0.1
```
Or if you want to define the domain you can use the env-variable to do so:
```sh
podman run --rm -e SERVICE_DOMAIN_OVERRIDE="https://your.domain" -dt -p 8080:8080/tcp -p 8090:8090/tcp localhost/validator:0.1
```
The `--rm` flag removes the container when done. It's useful when developing/running on localhost for testing

### Behind corporate proxy?

Add these on the run command (required to be _BEFORE_ the `localhost/validator:0.1`)
```sh
-e HTTP_PROXY_HOST={your.proxy.host} -e HTTP_PROXY_PORT={your.proxy.port}  -e HTTPS_PROXY_HOST={your.proxy.host} -e HTTPS_PROXY_PORT={your.proxy.port}
```

## Take a look inside to see if something is wrong

```sh
podman exec -it -l /bin/sh -c sh
```
-l means last container (replace with id if needed)
-it means interactive to run commands on sh (where -dt means detached/run on background)

### Inside the container

- validator logs: /etf/logs/etf.log
- validator config with domain override: /etf/config/etf-config.properties
- config.js with the domain override: /etf/validator/js/config.js

You can get the id to replace `-l` with:
```sh
podman ps -a
```

### Known issues

#### The UI on port 8090 doesn't work properly when SERVICE_DOMAIN_OVERRIDE is not defined.

The validation requests are sent to wrong path when the domain is not configured.
