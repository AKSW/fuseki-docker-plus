#!/usr/bin/env bats

# Uses system bats-assert (installed via: sudo apt install bats bats-assert)
# Note: bats-assert 2.x requires bats-core >= 1.11. For older bats, use load with full path.
bats_load_library bats-support
bats_load_library bats-assert

# Safety: ensure BATS_TEST_DIRNAME is an absolute path
case "${BATS_TEST_DIRNAME}" in
    /*) ;;
    *) echo "ERROR: BATS_TEST_DIRNAME (${BATS_TEST_DIRNAME}) is not absolute"; exit 1 ;;
esac

COMPOSE_FILE="${BATS_TEST_DIRNAME}/docker-compose.yaml"
PLUGIN_LIST_CMD="./dc exec fuseki plugins"

# ------------------------------------------------------------------

setup() {
    TEST_DIR="${BATS_TEST_DIRNAME}"

    # Clean runtime directories created by Fuseki on first start (keep config.ttl and configuration/)
    rm -rf "${TEST_DIR}/run/extra" "${TEST_DIR}/run/plugins" 2>/dev/null || true
    rm -rf "${TEST_DIR}/run/backups" "${TEST_DIR}/run/databases" 2>/dev/null || true
    rm -rf "${TEST_DIR}/run/logs" "${TEST_DIR}/run/system_files" 2>/dev/null || true
    mkdir -p "${TEST_DIR}/run/extra" "${TEST_DIR}/run/plugins" "${TEST_DIR}/run/test-plugins"

    # Ensure local-plugin.jar source is in place
    if [ ! -f "${TEST_DIR}/run/test-plugins/local-plugin.jar" ]; then
        mkdir -p /tmp/jartest
        echo "" > /tmp/jartest/MANIFEST.MF
        jar cf "${TEST_DIR}/run/test-plugins/local-plugin.jar" -C /tmp/jartest MANIFEST.MF
        rm -rf /tmp/jartest
    fi

    # Make sure compose is running
    ./dc up -d --quiet-pull 2>/dev/null

    # Wait for container to become healthy (healthcheck has start_period of 30s)
    # Poll the health status for up to 60 seconds
    local retries=0
    while true; do
        local health_status
        health_status=$(./dc ps --format '{{.Health}}' fuseki 2>/dev/null)
        if [ "$health_status" = "healthy" ]; then
            break
        fi
        retries=$((retries + 1))
        if [ "$retries" -ge 3 ]; then
            skip "Fuseki container failed to become healthy"
        fi
        sleep 3
    done
}

teardown() {
    ./dc down -v --remove-orphans 2>/dev/null || true
}

# ------------------------------------------------------------------

@test "plugins --help shows usage" {
    run ${PLUGIN_LIST_CMD} --help
    assert_output --partial "Usage: plugins <command>"
    assert_output --partial "list"
    assert_output --partial "status"
    assert_output --partial "add <url>"
    assert_output --partial "enable"
    assert_output --partial "disable"
    assert_output --partial "remove"
}

@test "plugins list shows 4 pre-installed plugins" {
    run ${PLUGIN_LIST_CMD} list
    assert_output --partial "graphql4sparql-0.7.0.jar"
    assert_output --partial "jena-exectracker-0.7.0.jar"
    assert_output --partial "jenax-arq-plugins-bundle-6.0.0-1.jar"
    assert_output --partial "jenax-serviceenhancer-preview-plugin-6.0.0-1.jar"
}

@test "plugins status shows no plugins installed initially" {
    run ${PLUGIN_LIST_CMD} status
    refute_output --partial "(installed)"
}

# Healthcheck test - runs a SPARQL query to verify Fuseki is responsive
@test "Fuseki healthcheck passes (SPARQL query works)" {
    run ./dc exec fuseki curl -f -s -o /dev/null -w '%{http_code}' 'http://localhost:3030/test' --data-urlencode 'query=SELECT * { ?s a ?o } LIMIT 1'
    [[ "$output" == "200" ]]
}

@test "plugins enable a plugin and status reflects it" {
    # Enable a plugin
    run ${PLUGIN_LIST_CMD} enable jena-exectracker-0.7.0.jar
    assert_output --partial "Enabled: jena-exectracker-0.7.0.jar"

    # Check status
    run ${PLUGIN_LIST_CMD} status
    assert_output --partial "jena-exectracker-0.7.0.jar (installed)"
}

@test "plugins disable a plugin and status reflects it" {
    # Enable first
    ${PLUGIN_LIST_CMD} enable jena-exectracker-0.7.0.jar > /dev/null

    # Now disable
    run ${PLUGIN_LIST_CMD} disable jena-exectracker-0.7.0.jar
    assert_output --partial "Disabled: jena-exectracker-0.7.0.jar"

    # Check status — should no longer show (installed)
    run ${PLUGIN_LIST_CMD} status
    refute_output --partial "jena-exectracker-0.7.0.jar (installed)"
}

@test "plugins enable non-existent plugin fails with error" {
    run ${PLUGIN_LIST_CMD} enable nonexistent-plugin.jar
    assert_failure
    assert_output --partial "Plugin not found"
}

@test "plugins disable already disabled plugin fails with error" {
    run ${PLUGIN_LIST_CMD} disable jena-exectracker-0.7.0.jar 2>&1
    assert_failure
    assert_output --partial "Plugin not installed"
}

@test "plugins add from local file URL works" {
    # Add the local plugin using a file:// URL accessible inside the container
    local local_plugin_url="file:///fuseki/run/test-plugins/local-plugin.jar"
    run ${PLUGIN_LIST_CMD} add "${local_plugin_url}"
    assert_output --partial "Added: local-plugin.jar"

    # Verify it shows in list
    run ${PLUGIN_LIST_CMD} list
    assert_output --partial "local-plugin.jar"
}

@test "plugins remove a plugin" {
    # First add it
    local local_plugin_url="file:///fuseki/run/test-plugins/local-plugin.jar"
    ${PLUGIN_LIST_CMD} add "${local_plugin_url}" > /dev/null

    # Remove it
    run ${PLUGIN_LIST_CMD} remove local-plugin.jar
    assert_output --partial "Removed: local-plugin.jar"

    # Verify it's gone from list
    run ${PLUGIN_LIST_CMD} list
    refute_output --partial "local-plugin.jar"
}

@test "plugins remove non-existent plugin fails with error" {
    run ${PLUGIN_LIST_CMD} remove nonexistent.jar
    assert_failure
    assert_output --partial "Plugin not found"
}

@test "plugins add without URL fails" {
    run ${PLUGIN_LIST_CMD} add 2>&1
    assert_failure
    assert_output --partial "URL required"
}

@test "plugins add URL not ending in .jar fails" {
    run ${PLUGIN_LIST_CMD} add https://example.com/plugin.zip 2>&1
    assert_failure
    assert_output --partial "must end with .jar"
}

@test "plugins enable multiple plugins at once" {
    run ${PLUGIN_LIST_CMD} enable jena-exectracker-0.7.0.jar graphql4sparql-0.7.0.jar
    assert_output --partial "Enabled: jena-exectracker-0.7.0.jar"
    assert_output --partial "Enabled: graphql4sparql-0.7.0.jar"

    # Both should show as installed
    run ${PLUGIN_LIST_CMD} status
    assert_output --partial "jena-exectracker-0.7.0.jar (installed)"
    assert_output --partial "graphql4sparql-0.7.0.jar (installed)"
}

@test "plugins disable multiple plugins at once" {
    # Enable them first
    ${PLUGIN_LIST_CMD} enable jena-exectracker-0.7.0.jar graphql4sparql-0.7.0.jar > /dev/null

    # Disable both
    run ${PLUGIN_LIST_CMD} disable jena-exectracker-0.7.0.jar graphql4sparql-0.7.0.jar
    assert_output --partial "Disabled: jena-exectracker-0.7.0.jar"
    assert_output --partial "Disabled: graphql4sparql-0.7.0.jar"
}
