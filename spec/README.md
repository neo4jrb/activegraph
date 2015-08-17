## Configuration

The specs are configured to run against `http://localhost:7474` by default. In order to change this in your local setup you can set the `NEO4J_URL` environment variable on your system to suit your needs.

To make this easier, the neo4j spec suite allows you to add a `.env` file locally to configure this. For example, to set the `NEO4J_URL` you simply need to add a `.env` file that looks like this:

```
NEO4J_URL=http://localhost:7475
```

