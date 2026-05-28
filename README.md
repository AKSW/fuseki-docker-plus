# fuseki-docker-plus

Customized Apache Jena Fuseki Docker Image with Pre-installed Plugins and
a simple plugin manager for self contained plugin JARs.

## Features

- Base: [aksw/fuseki-vanilla:6.1.0](https://github.com/AKSW/fuseki-docker-vanilla)
- Pre-installed plugins in `/fuseki/builtin-plugins/`:
  - [jena-exectracker](https://github.com/Scaseco/jena-exectracker) (v0.7.0)
  - [graphql4sparql](https://github.com/Scaseco/graphql4sparql) (v0.7.0)
  - [jenax-arq-plugins](https://github.com/Scaseco/jenax) (v6.1.0-1)
  - [jenax-serviceenhancer](https://github.com/Scaseco/jenax) (v6.1.0-1)
- Plugin management via CLI: `plugins`
- Dynamic plugin installation from URLs
- Volume-based plugin persistence

## Quick Start

### Build the Image

```bash
docker build -t aksw/fuseki-plus:6.1.0 .
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
APP_UID="$(id -u)" APP_GID="$(id -g)" DOCKER_GID="$(getent group docker | cut -d: -f3)" docker compose "$@"
```

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
docker run --rm --entrypoint plugins aksw/fuseki-plus:6.1.0 list
```

Check plugin status:
```bash
docker run --rm --entrypoint plugins aksw/fuseki-plus:6.1.0 status
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

Current version: **6.1.0** (Jena 6.1.0)

Release tag: `aksw/fuseki-plus:6.1.0`

## Requirements

- Docker
- [bats](https://github.com/bats-core/bats-core) and [bats-assert](https://github.com/bats-core/bats-assert) (install via `sudo apt install bats bats-assert`)

## License

This project is licensed under the Apache License 2.0. See [LICENSE](LICENSE) for details.

