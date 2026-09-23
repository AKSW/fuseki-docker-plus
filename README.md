# fuseki-docker-plus

Customized Apache Jena Fuseki Docker Image with pre-installed plugins and
a simple plugin manager for self-contained plugin JARs.
The plugin JARs bundled with the image must be enabled explicitly with a [one-liner](example).
Otherwise, you just get a [Vanilla Fuseki Setup](https://github.com/AKSW/fuseki-docker-vanilla).

## Features

- Base: [aksw/fuseki-vanilla:6.2.0](https://github.com/AKSW/fuseki-docker-vanilla)
- Pre-installed plugins in `/fuseki/builtin-plugins/`:
  - [jena-exectracker](https://github.com/Scaseco/jena-exectracker) (v0.7.2)
  - [graphql4sparql](https://github.com/Scaseco/graphql4sparql) (v0.7.0)
  - [jenax-arq-plugins](https://github.com/Scaseco/jenax) (v6.1.0-1)
  - [jenax-serviceenhancer](https://github.com/Scaseco/jenax) (v6.1.0-1)
  - [Proxy Plugin](https://github.com/Scaseco/jena-proxy) (v0.7.0)
- Plugin management via CLI: `plugins`
- Dynamic plugin installation from URLs
- Volume-based plugin persistence

## Quick Start

### Build the Image

```bash
docker build -t aksw/fuseki-plus:6.2.0-2 .
```

### Run with Docker Compose

```bash
docker compose up -d
```

### Docker Compose Usage (Recommended)

#### Recommendation: Use a `dc` Wrapper Script
This script sets user and group ids to that of the current user.
The `DOCKER_GID` is optional.
It is needed if you want to use our Qlever Fuseki Plugin. This plugin binds the life-cycle of a dockerized Qlever instance to that of the Fuseki server.

```bash
#!/usr/bin/env bash

mkdir -p run/configuration
WANT_UID="$(id -u)" WANT_GID="$(id -g)" DOCKER_GID="$(getent group docker | cut -d: -f3)" docker compose "$@"
```

## Running as a Non-Root User

The image starts as root, chowns the data volume (`/fuseki/run`) to the requested
UID:GID, then drops privileges via `setpriv` before starting the server. Set the
target user with:

- `WANT_UID` — user ID to run Fuseki as (default: `1000`)
- `WANT_GID` — group ID to run Fuseki as (default: `1000`)

The UID/GID do not need to exist in the image's `/etc/passwd`.

> **Note:** Do not set `user:` in compose (or `--user` with `docker run`). The
> entrypoint needs root privileges for the chown phase; setting `user:` would break it.
>
> Note that files mounted `:ro` (e.g. the example config files) are skipped by the
> chown phase and must stay readable by `WANT_UID` — so with read-only config mounts,
> `WANT_UID` should match the host user that owns those files.

The `example/` folder includes a setup with the `dc` wrapper script for simplified docker compose commands.

#### Plugin Management

```
Usage: plugins <command> [options]

Commands:
  list              List available plugins
  status            List all plugins with installation status
  add <url>         Download plugin from URL to /fuseki/run/plugins/
  remove <name>     Remove plugin from /fuseki/run/plugins/ and /fuseki/run/extra/
  enable <names>    Copy plugin(s) to /fuseki/run/extra/ (activate)
  disable <names>   Remove plugin(s) from /fuseki/run/extra/ (deactivate)
```


```bash
./dc run --rm --entrypoint plugins fuseki list
./dc run --rm --entrypoint plugins fuseki status
./dc run --rm --entrypoint plugins fuseki add https://example.com/plugin-1.0.0.jar
./dc run --rm --entrypoint plugins fuseki enable plugin-1.0.0.jar anotherplugin.jar
./dc run --rm --entrypoint plugins fuseki disable plugin-1.0.0.jar anotherplugin.jar
./dc run --rm --entrypoint plugins fuseki remove plugin-1.0.0.jar
```

Replace `fuseki` with your actual service name if different.

### Plain Docker Usage

The usage without compose is similar. Instead of the service name you need to specify the image name:

List available plugins:
```bash
docker run --rm --entrypoint plugins aksw/fuseki-plus:6.2.0-2 list
```

Check plugin status:
```bash
docker run --rm --entrypoint plugins aksw/fuseki-plus:6.2.0-2 status
```

## Directory Structure of a Container

| Path | Purpose | In Volume? |
|------|---------|------------|
| `/fuseki/builtin-plugins/` | Pre-bundled plugins (in image) | No |
| `/fuseki/run/plugins/` | User-downloaded plugins | Yes |
| `/fuseki/run/extra/` | Active plugins (copied here) | Yes |
| `/fuseki/run/config.ttl` | Fuseki configuration | Yes |

## Versioning

Image tag format: `aksw/fuseki-plus:<fuseki-version>`

Current version: **6.2.0-2** (based on Jena 6.2.0)

Release tag: `aksw/fuseki-plus:6.2.0-2`

| Version   | Changes |
|-----------|---------|
| 6.2.0-2   | Adopted the base image's `WANT_UID`/`WANT_GID` privilege model: compose examples no longer set `user:`; the `plugins` CLI now chowns the data volume and drops to the target user via the base image's `run-as.sh` before running. |
| 6.2.0-1   | Upgrade to jena 6.2.0. Fixed priority issue that caused `jena-exectracker` to not be able to track query executions for a `jena-proxy` dataset. |
| 6.1.0-3   | Added [Proxy Plugin](https://github.com/Scaseco/jena-proxy) which supports Datasets over HTTP(S) SPARQL endpoints. |
| 6.1.0-2   | Updated [ExecTracker Plugin](https://github.com/Scaseco/jena-exectracker/releases/tag/v0.7.1) which features a nicer UI. |
| 6.1.0     | Changed `FUSEKI_BASE` from  `/app/fuseki` to `/fuseki`. |
| 6.1.0-rc1 | Initial version. |

## Requirements

- Docker
- [bats](https://github.com/bats-core/bats-core) and [bats-assert](https://github.com/bats-core/bats-assert) (install via `sudo apt install bats bats-assert`)

## License

This project is licensed under the Apache License 2.0. See [LICENSE](LICENSE) for details.

