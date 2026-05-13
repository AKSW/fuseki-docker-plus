FROM aksw/fuseki-vanilla:6.1.0

ARG FUSEKI_BUILTIN_PLUGINS=/app/fuseki/builtin-plugins

# Install curl for downloading plugins
RUN apt-get update && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

# Create plugin directories
RUN mkdir -p ${FUSEKI_BUILTIN_PLUGINS} /usr/local/bin

# Download pre-bundled plugins (exectracker, graphql4sparql, jenax-arq-plugins, jenax-serviceenhancer)
RUN curl -LJO --create-dirs --output-dir ${FUSEKI_BUILTIN_PLUGINS}/ \
    "https://github.com/Scaseco/jena-exectracker/releases/download/v0.7.0/jena-exectracker-fuseki-plugin-0.7.0.jar" && \
    curl -LJO --create-dirs --output-dir ${FUSEKI_BUILTIN_PLUGINS}/ \
    "https://github.com/Scaseco/graphql4sparql/releases/download/v0.7.0/graphql4sparql-fuseki-plugin-0.7.0.jar" && \
    curl -LJO --create-dirs --output-dir ${FUSEKI_BUILTIN_PLUGINS}/ \
    "https://github.com/Scaseco/jenax/releases/download/v6.1.0-1/jenax-arq-plugins-bundle-6.1.0-1.jar" && \
    curl -LJO --create-dirs --output-dir ${FUSEKI_BUILTIN_PLUGINS}/ \
    "https://github.com/Scaseco/jenax/releases/download/v6.1.0-1/jenax-serviceenhancer-preview-plugin-6.1.0-1.jar"

# Copy plugins CLI with executable permission
COPY --chmod=755 plugins /usr/local/bin/

# Set volume mount point
VOLUME /app/fuseki/run

# Use base image's entrypoint (plugins CLI is available at /usr/local/bin/plugins)
ENTRYPOINT ["/app/fuseki/fuseki-server"]
CMD ["--config=/app/fuseki/run/config.ttl"]

