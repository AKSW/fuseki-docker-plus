# Example Fuseki Setup with Multiple Custom Plugins

In order for this complex example setup to work, you must enable *all* plugins before the Fuseki server will start up successfully.

1. List available plugins.
```bash
./dc run --rm --entrypoint plugins fuseki list
```
2. Enable *all* available plugins (those listed by the previous command).
```
./dc run --rm --entrypoint plugins fuseki enable $(./dc run --rm --entrypoint plugins fuseki list)
```

The command above effectively calls:
```bash
./dc run --rm --entrypoint plugins fuseki enable PLUGIN1 PLUGIN2 # ...
```
3. Start the server.
```bash
./dc up
```

