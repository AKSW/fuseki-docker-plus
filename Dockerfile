FROM aksw/fuseki-vanilla:6.1.0

# FUSEKI_HOME built arg is assumed to match that of the base image!
ARG FUSEKI_HOME=/fuseki

ARG FUSEKI_BUILTIN_PLUGINS=${FUSEKI_HOME}/builtin-plugins
ENV FUSEKI_BUILTIN_PLUGINS=${FUSEKI_BUILTIN_PLUGINS}

ENV FUSEKI_USER_PLUGINS=${FUSEKI_BASE}/plugins

# Install curl for downloading plugins
RUN apt-get update && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

# Create plugin directories
RUN mkdir -p ${FUSEKI_BUILTIN_PLUGINS} /usr/local/bin

# Download pre-bundled plugins (exectracker, graphql4sparql, jenax-arq-plugins, jenax-serviceenhancer)
RUN curl -LJO --create-dirs --output-dir ${FUSEKI_BUILTIN_PLUGINS}/ \
    "https://github.com/Scaseco/jena-exectracker/releases/download/v0.7.1/jena-exectracker-fuseki-plugin-0.7.1.jar" && \
    curl -LJO --create-dirs --output-dir ${FUSEKI_BUILTIN_PLUGINS}/ \
    "https://github.com/Scaseco/graphql4sparql/releases/download/v0.7.0/graphql4sparql-fuseki-plugin-0.7.0.jar" && \
    curl -LJO --create-dirs --output-dir ${FUSEKI_BUILTIN_PLUGINS}/ \
    "https://github.com/Scaseco/jenax/releases/download/v6.1.0-1/jenax-arq-plugins-bundle-6.1.0-1.jar" && \
    curl -LJO --create-dirs --output-dir ${FUSEKI_BUILTIN_PLUGINS}/ \
    "https://github.com/Scaseco/jenax/releases/download/v6.1.0-1/jenax-serviceenhancer-preview-plugin-6.1.0-1.jar" && \
    curl -LJO --create-dirs --output-dir ${FUSEKI_BUILTIN_PLUGINS}/ \
    "https://github.com/Scaseco/jena-proxy/releases/download/v0.7.0-rc1/jena-proxy-fuseki-plugin-0.7.0-rc1.jar"

# Copy plugins CLI with executable permission.
# Plugins CLI is thus available at /usr/local/bin/plugins
COPY --chmod=755 plugins /usr/local/bin/

# Inherited from base:
# VOLUME /fuseki/run

# Inherited from base:
# ENTRYPOINT ["/fuseki/entrypoint.sh]

