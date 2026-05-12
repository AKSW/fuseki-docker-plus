# fuseki-docker-plus

Customized Apache Jena Fuseki Docker Image with Pre-installed Plugins and
a simple plugin manager for self contained plugin JARs.

## Features

- Base: [aksw/fuseki-vanilla:6.0.0](https://github.com/AKSW/docker-fuseki-vanilla)
- Pre-installed plugins in `/app/fuseki/plugins/`:
  - [jena-exectracker](https://github.com/Scaseco/jena-exectracker) (v0.7.0)
  - [graphql4sparql](https://github.com/Scaseco/graphql4sparql) (v0.7.0)
  - [jenax-arq-plugins](https://github.com/Scaseco/jenax) (v6.0.0-1)
  - [jenax-serviceenhancer](https://github.com/Scaseco/jenax) (v6.0.0-1)
- Plugin management via CLI: `plugins`
- Dynamic plugin installation from URLs
- Volume-based plugin persistence

## Quick Start

### Build the Image

```bash
docker build -t aksw/fuseki-plus:6.0.0 .
```

### Run with Docker Compose

```bash
docker compose up -d
```

### Manage Plugins

The `plugins` CLI is available on PATH. For `docker run`, override the entrypoint with `--entrypoint plugins`. For `docker compose exec`, just run `plugins` as the command directly.

List available plugins:
```bash
docker run --rm --entrypoint plugins aksw/fuseki-plus:6.0.0 list
```

Check plugin status:
```bash
docker run --rm --entrypoint plugins aksw/fuseki-plus:6.0.0 status
```

With docker compose (replace `fuseki-service` with your actual service name):
```bash
docker compose exec fuseki-service plugins list
```

Add a plugin from URL:
```bash
docker compose exec fuseki-service plugins add https://example.com/plugin-1.0.0.jar
```

Enable a plugin (activates it):
```bash
docker compose exec fuseki-service plugins enable jena-exectracker-0.7.0.jar
```

Disable a plugin:
```bash
docker compose exec fuseki-service plugins disable jena-exectracker-0.7.0.jar
```

Remove a plugin:
```bash
docker compose exec fuseki-service plugins remove jena-exectracker-0.7.0.jar
```

## Directory Structure

| Path | Purpose | Persistent |
|------|---------|------------|
| `/app/fuseki/plugins/` | Pre-bundled plugins (in image) | No |
| `/app/fuseki/run/plugins/` | User-downloaded plugins | Yes |
| `/app/fuseki/run/extra/` | Active plugins (copied here) | Yes |
| `/app/fuseki/run/config.ttl` | Fuseki configuration | Yes |

## Plugin Management CLI

```
Usage: plugins <command> [options]

Commands:
  list              List available plugins
  status            List all plugins with installation status
  add <url>         Download plugin from URL to /app/fuseki/run/plugins/
  remove <name>     Remove plugin from /app/fuseki/run/plugins/ and /app/fuseki/run/extra/
  enable <names>    Copy plugin(s) to /app/fuseki/run/extra/ (activate)
  disable <names>   Remove plugin(s) from /app/fuseki/run/extra/ (deactivate)
```

## Versioning

Image tag format: `aksw/fuseki-plus:<fuseki-version>`

Current version: **6.0.0**

## Requirements

- Docker
- [bats](https://github.com/bats-core/bats-core) (install via `sudo apt install bats`)
- [bats-assert](https://github.com/bats-core/bats-assert) and [bats-file](https://github.com/bats-core/bats-file) — vendored in `tests/vendor/`

## License

This project is licensed under the Apache License 2.0. See [LICENSE](LICENSE) for details.
