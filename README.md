# Official Chia Simulator Docker Container
 Docker Containers for 1 click Chia™ simulator setup

## Quick Start

These examples show valid setups using the Chia Simulator for both docker run and docker-compose. Note that you should read some documentation at some point, but this is a good place to start.

### Docker run

```bash
docker run --name chia-simulator -d ghcr.io/chia-network/chia-simulator:latest --expose=8555 -v ~/.chia:/root/.chia
```
Syntax
```bash
docker run --name <container-name> -d ghcr.io/chia-network/chia-simulator:latest -v /path/to/simulator/files:/root
optional: accept incoming rpc calls: --expose=8555
optional: persiststantly use the same simulator -v ~/.chia/simulator:/root/.chia/simulator
```

### Docker compose

```yaml
version: "3.6"
services:
  chia-simulator:
    container_name: chia-simulator
    restart: unless-stopped
    image: ghcr.io/chia-network/chia-simulator:latest
    ports:
      - "8555:8555"
    volumes:
      - ~/.chia/simulator:/root/.chia/simulator
```

## Configuration

You can modify the behavior of your Chia Simulator container by setting specific environment variables.

### Timezone

Set the timezone for the container (optional, defaults to UTC).
Timezones can be configured using the `TZ` env variable. A list of supported time zones can be found [here](http://manpages.ubuntu.com/manpages/focal/man3/DateTime::TimeZone::Catalog.3pm.html)
```bash
-e TZ="America/Chicago"
```

### Add your custom keys

To use your own keys pass a file with your mnemonic as arguments on startup
```bash
-e mnemonic=<your-24-word-mnemonic>
```
or pass keys into the running container with your mnemonic
```bash
docker exec -it <container-name> venv/bin/chia keys add
```
alternatively you can pass in your local keychain, if you have previously deployed chia with these keys on the host machine
```bash
-v ~/.local/share/python_keyring/:/root/.local/share/python_keyring/ -e fingerprint="<fingerprint>"
```

### Set a custom reward address
```bash
-e reward_address="<reward-address>"
```

### Disable automatic farming
```bash
-e auto_farm="false"
```

### Persist configuration and db

You can persist whole db and configuration, simply mount it to Host. If you are using multiple simulators, please read the simulator naming documentation below.
```bash
-v ~/.chia/simulator:/root/.chia/simulator
```

### Change the simulator name
```bash
-e name="<simulator-name>"
```

### Simulator Only

To only start the simulator pass
```bash
-e start_wallet="false"
```

### Log to file
Log file can be used by external tools like chiadog, etc. Enabled by default.

To disable log file generation, use
```bash
-e log_to_file="false"
```

### Docker Compose

```yaml
version: "3.6"
services:
  chia-simulator:
    container_name: chia-simulator
    restart: unless-stopped
    image: ghcr.io/chia-network/chia-simulator:latest
    ports:
      - "8555:8555"
    environment:
      # If you would like to add keys manually via mnemonic words
#     mnemonic: "today grape album ticket joy idle supreme sausage oppose voice angle roast you oven betray exact memory riot escape high dragon knock food blade"
      TZ: ${TZ}
      # Enable log file generation
#     log_to_file: true
    volumes:
      - /home/user/.chia/simulator:/root/.chia/simulator
```

## CLI
You can connect to the simulator's shell and easily run commands
```bash
docker exec -it chia-simulator /bin/bash
```
or

You can run commands externally with venv (this works for most chia & cdv [CLI commands](https://github.com/Chia-Network/chia-blockchain/wiki/CLI-Commands-Reference))
```bash
docker exec -it chia-simulator venv/bin/chia plots add -d /plots
```

### Is it working?

You can see status from outside the container
```bash
docker exec -it chia-simulator venv/bin/cdv sim status
```
or
```bash
docker exec -it chia-simulator venv/bin/chia show -s -c
```

#### Need a wallet?

To get new wallet, execute command and follow the prompts:

```bash
docker exec -it chia-simulator venv/bin/chia wallet show
```

## Building

```bash
docker build -t chia-simulator --build-arg CHIA_BRANCH=latest --build-arg DEV_TOOLS_BRANCH=main .
```

## Healthchecks

The Dockerfile includes a HEALTHCHECK instruction that runs one or more curl commands against the Chia RPC API. In Docker, this can be disabled using an environment variable `-e healthcheck=false` as part of the `docker run` command. Or in docker-compose you can add it to your Chia service, like so:

```yaml
version: "3.6"
services:
  chia-simulator:
    ...
    environment:
      healthcheck: "false"
```

In Kubernetes, Docker healthchecks are disabled by default. Instead, readiness and liveness probes should be used, which can be configured in a Pod or Deployment manifest file like the following:

```yaml
livenessProbe:
  exec:
    command:
    - /bin/sh
    - -c
    - '/usr/local/bin/docker-healthcheck.sh || exit 1'
  initialDelaySeconds: 60
readinessProbe:
  exec:
    command:
    - /bin/sh
    - -c
    - '/usr/local/bin/docker-healthcheck.sh || exit 1'
  initialDelaySeconds: 60
```

See [Configure Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#configure-probes) for more information about configuring readiness and liveness probes for Kubernetes clusters. The `initialDelaySeconds` parameter may need to be adjusted higher or lower depending on the speed to start up on the host the container is running on.
