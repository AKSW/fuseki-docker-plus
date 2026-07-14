#!/bin/bash
set -e

[[ -n "${FUSEKI_HOME:-}" ]] || { echo "Error: FUSEKI_HOME is not set" >&2; exit 1; }
[[ -n "${FUSEKI_BASE:-}" ]] || { echo "Error: FUSEKI_BASE is not set" >&2; exit 1; }

BUILTIN_PLUGINS="${FUSEKI_BUILTIN_PLUGINS:-${FUSEKI_HOME}/builtin-plugins}"
USER_PLUGINS="${FUSEKI_USER_PLUGINS:-${FUSEKI_BASE}/plugins}"
EXTRA_DIR="${FUSEKI_BASE}/extra"

# Ensure directories exist
mkdir -p "$BUILTIN_PLUGINS" "$USER_PLUGINS" "$EXTRA_DIR"

# Get all available plugin filenames
get_available_plugins() {
    local files=()
    if [[ -d "$BUILTIN_PLUGINS" ]]; then
        for f in "$BUILTIN_PLUGINS"/*.jar; do
            [[ -e "$f" ]] && files+=("$(basename "$f")")
        done
    fi
    if [[ -d "$USER_PLUGINS" ]]; then
        for f in "$USER_PLUGINS"/*.jar; do
            [[ -e "$f" ]] && files+=("$(basename "$f")")
        done
    fi
    printf '%s\n' "${files[@]}" | sort -u
}

# Get all plugins from /extra directory
get_extra_plugins() {
    local files=()
    if [[ -d "$EXTRA_DIR" ]]; then
        for f in "$EXTRA_DIR"/*.jar; do
            [[ -e "$f" ]] && files+=("$(basename "$f")")
        done
    fi
    printf '%s\n' "${files[@]}" | sort -u
}

# Get all plugins (available + extra)
get_all_plugins() {
    { get_available_plugins; get_extra_plugins; } | sort -u
}

# Check if plugin is enabled (exists in EXTRA_DIR)
is_enabled() {
    local plugin="$1"
    [[ -f "$EXTRA_DIR/$plugin" ]]
}

# Check if plugin exists in either plugins directory
plugin_exists() {
    local plugin="$1"
    [[ -f "$BUILTIN_PLUGINS/$plugin" ]] || [[ -f "$USER_PLUGINS/$plugin" ]]
}

# List available plugins (filenames only)
cmd_list() {
    get_available_plugins
}

# Show status of all plugins
cmd_status() {
    local plugins
    plugins=$(get_all_plugins)
    
    if [[ -z "$plugins" ]]; then
        echo "No plugins available."
        return 0
    fi
    
    echo "$plugins" | while read -r plugin; do
        if is_enabled "$plugin"; then
            echo "$plugin (enabled)"
        else
            echo "$plugin"
        fi
    done
}

# Add plugin from URL
cmd_add() {
    local url="$1"
    
    if [[ -z "$url" ]]; then
        echo "Error: URL required" >&2
        echo "Usage: plugins add <url>" >&2
        exit 1
    fi
    
    # Validate URL ends with .jar
    if [[ ! "$url" =~ \.jar$ ]]; then
        echo "Error: URL must end with .jar" >&2
        exit 1
    fi
    
    # Extract filename from URL
    local filename
    filename=$(basename "$url")
    
    # Check if file already exists
    if [[ -f "$USER_PLUGINS/$filename" ]]; then
        echo "Error: Plugin already exists: $filename" >&2
        exit 1
    fi
    
    echo "Downloading $filename..."
    if ! curl -L --proto =https,http,file -o "$USER_PLUGINS/$filename" "$url"; then
        echo "Error: Download failed for $url" >&2
        rm -f "$USER_PLUGINS/$filename"
        exit 1
    fi
    
    if [ ! -s "$USER_PLUGINS/$filename" ]; then
        echo "Error: Downloaded file is empty" >&2
        rm -f "$USER_PLUGINS/$filename"
        exit 1
    fi
    
    echo "Added: $filename"
}

# Remove plugin
cmd_remove() {
    local plugins=("$@")
    
    if [[ ${#plugins[@]} -eq 0 ]]; then
        echo "Error: At least one plugin name required" >&2
        echo "Usage: plugins remove <filename> [filename...]" >&2
        exit 1
    fi
    
    # Validate all plugins exist first
    for plugin in "${plugins[@]}"; do
        if ! plugin_exists "$plugin"; then
            echo "Error: Plugin not found: $plugin" >&2
            exit 1
        fi
    done
    
    # Remove from both locations
    for plugin in "${plugins[@]}"; do
        local removed=0
        if [[ -f "$USER_PLUGINS/$plugin" ]]; then
            rm "$USER_PLUGINS/$plugin"
            removed=1
        fi
        if [[ -f "$EXTRA_DIR/$plugin" ]]; then
            rm "$EXTRA_DIR/$plugin"
            removed=1
        fi
        if [[ $removed -eq 1 ]]; then
            echo "Removed: $plugin"
        fi
    done
}

# Enable plugins
cmd_enable() {
    local plugins=("$@")
    
    if [[ ${#plugins[@]} -eq 0 ]]; then
        echo "Error: At least one plugin name required" >&2
        echo "Usage: plugins enable <filename> [filename...]" >&2
        exit 1
    fi
    
    # Validate all plugins exist first
    for plugin in "${plugins[@]}"; do
        if ! plugin_exists "$plugin"; then
            echo "Error: Plugin not found: $plugin" >&2
            exit 1
        fi
    done
    
    # Copy to extra directory
    for plugin in "${plugins[@]}"; do
        local source
        if [[ -f "$USER_PLUGINS/$plugin" ]]; then
            source="$USER_PLUGINS/$plugin"
        else
            source="$BUILTIN_PLUGINS/$plugin"
        fi
        cp "$source" "$EXTRA_DIR/$plugin"
        echo "Enabled: $plugin"
    done
}

# Disable plugins
cmd_disable() {
    local plugins=("$@")
    
    if [[ ${#plugins[@]} -eq 0 ]]; then
        echo "Error: At least one plugin name required" >&2
        echo "Usage: plugins disable <filename> [filename...]" >&2
        exit 1
    fi
    
    # Validate all plugins are enabled first
    for plugin in "${plugins[@]}"; do
        if ! is_enabled "$plugin"; then
            echo "Error: Plugin not enabled: $plugin" >&2
            exit 1
        fi
    done
    
    # Remove from extra directory
    for plugin in "${plugins[@]}"; do
        rm "$EXTRA_DIR/$plugin"
        echo "Disabled: $plugin"
    done
}

# Show usage
usage() {
    cat <<EOF
Usage: plugins <command> [options]

Commands:
  list              List available plugins
  status            List all plugins with activation status
  add <url>         Download plugin from URL to ${USER_PLUGINS}
  remove <name>     Remove plugin from ${USER_PLUGINS} and ${EXTRA_DIR}
  enable <names>    Copy plugin(s) to ${EXTRA_DIR} (activate)
  disable <names>   Remove plugin(s) from ${EXTRA_DIR} (deactivate)

Examples:
  plugins list
  plugins status
  plugins add https://example.com/plugin-1.0.0.jar
  plugins enable exectracker.jar
  plugins disable exectracker.jar graphql.jar
  plugins remove exectracker.jar
EOF
}

# Main command dispatcher
main() {
    local cmd="$1"
    shift || true
    
    case "$cmd" in
        list)
            cmd_list
            ;;
        status)
            cmd_status
            ;;
        add)
            cmd_add "$@"
            ;;
        remove)
            cmd_remove "$@"
            ;;
        enable)
            cmd_enable "$@"
            ;;
        disable)
            cmd_disable "$@"
            ;;
        help|--help|-h)
            usage
            ;;
        "")
            echo "Error: No command specified" >&2
            usage >&2
            exit 1
            ;;
        *)
            echo "Error: Unknown command: $cmd" >&2
            usage >&2
            exit 1
            ;;
    esac
}

# Run main only if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
