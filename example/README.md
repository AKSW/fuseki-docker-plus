# Example Fuseki Setup with Multiple Custom Plugins

In order for this complex example setup to work, you must enable *all* plugins before the Fuseki server will start up successfully.

1. List available plugins.
```bash
./dc run --rm --entrypoint plugins fuseki list
```
2. Enable *all* listing plugins.
```bash
./dc run --rm --entrypoint plugins fuseki add PLUGIN1 PLUGIN2 # ...
```
3. Start the server.
```bash
./dc up
```

