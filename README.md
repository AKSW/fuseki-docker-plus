# fuseki-docker-plus

Customized Apache Jena Fuseki Docker Image with Pre-installed Plugins and
a simple plugin manager for self contained plugin JARs.

## Features

- Base: [aksw/fuseki-vanilla:6.1.0](https://github.com/AKSW/fuseki-docker-vanilla)
- Pre-installed plugins in `/app/fuseki/plugins/`:
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
docker build -t aksw/fuseki-plus:6.1.0-rc1 .
```

### Run with Docker Compose

```bash
docker compose up -d
```

### Docker Compose Usage (Recommended)

Set environment variables for proper permissions:
```bash
export APP_UID="$(id -u)"
export APP_GID="$(id -g)"
export DOCKER_GID="$(getent group docker | cut -d: -f3)"
```

Manage plugins using `docker compose run --rm --entrypoint plugins` (works even when container is stopped):
```bash
docker compose run --rm --entrypoint plugins fuseki list
docker compose run --rm --entrypoint plugins fuseki status
docker compose run --rm --entrypoint plugins fuseki add https://example.com/plugin-1.0.0.jar
docker compose run --rm --entrypoint plugins fuseki enable jena-exectracker-0.7.0.jar
docker compose run --rm --entrypoint plugins fuseki disable jena-exectracker-0.7.0.jar
docker compose run --rm --entrypoint plugins fuseki remove jena-exectracker-0.7.0.jar
```
```

**Alternative:** Create a `.env` file in the same directory as `docker-compose.yaml`:
```bash
echo "APP_UID=$(id -u)" >> .env
echo "APP_GID=$(id -g)" >> .env
echo "DOCKER_GID=$(getent group docker | cut -d: -f3)" >> .env
```

After creating the `.env` file, you can run without exports:
```bash
docker compose run --rm --entrypoint plugins fuseki list
```

### Using the dc Wrapper Script

The `example/` folder includes a `dc` wrapper script for simplified docker compose commands:

### Using the dc Wrapper Script

The `example/` folder includes a `dc` wrapper script for simplified docker compose commands:

**Alternative:** Use the `dc` wrapper script (from the `example` folder):
```bash
./dc plugins list
./dc plugins status
./dc plugins add https://example.com/plugin-1.0.0.jar
```

Replace `fuseki` with your actual service name if different.

### Using the dc Wrapper Script

The `example/` folder includes a `dc` wrapper script for simplified docker compose commands:

### Using the dc Wrapper Script

The `example/` folder includes a `dc` wrapper script for simplified docker compose commands:
```bash
./dc plugins list
./dc plugins status
./dc plugins add https://example.com/plugin-1.0.0.jar
```

### Plain Docker Usage

List available plugins:
```bash
docker run --rm --entrypoint plugins aksw/fuseki-plus:6.1.0-rc1 list
```

Check plugin status:
```bash
docker run --rm --entrypoint plugins aksw/fuseki-plus:6.1.0-rc1 status
```

With docker compose (replace `fuseki` with your actual service name):
```bash
docker compose exec fuseki plugins list
```

Add a plugin from URL:
```bash
docker compose exec fuseki plugins add https://example.com/plugin-1.0.0.jar
```

Enable a plugin (activates it):
```bash
docker compose exec fuseki plugins enable jena-exectracker-0.7.0.jar
```

Disable a plugin:
```bash
docker compose exec fuseki plugins disable jena-exectracker-0.7.0.jar
```

Remove a plugin:
```bash
docker compose exec fuseki plugins remove jena-exectracker-0.7.0.jar
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

Current version: **6.1.0-rc1** (Jena 6.1.0)

Release tag: `aksw/fuseki-plus:6.1.0-rc1`

## Requirements

- Docker
- [bats](https://github.com/bats-core/bats-core) and [bats-assert](https://github.com/bats-core/bats-assert) (install via `sudo apt install bats bats-assert`)

## License

This project is licensed under the Apache License 2.0. See [LICENSE](LICENSE) for details.
