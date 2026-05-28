#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Export user ID for docker compose (so volume files are owned by the host user)
export APP_UID=$(id -u)
export APP_GID=$(id -g)

# Export bats-assert library path for bats_load_library
export BATS_LIB_PATH="/usr/lib/bats"

# Image name (override with IMAGE='foobar' ./run-tests.sh)
IMAGE="${IMAGE:-fuseki-plus:6.1.0}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}fuseki-docker-plus — plugin tests${NC}"
echo

# Check prerequisites
if ! command -v bats &>/dev/null; then
    echo -e "${RED}Error: bats is not installed${NC}"
    exit 1
fi

if ! command -v docker &>/dev/null; then
    echo -e "${RED}Error: docker is not installed${NC}"
    exit 1
fi

if ! docker info &>/dev/null; then
    echo -e "${RED}Error: docker daemon is not running${NC}"
    exit 1
fi

# Verify bats-assert is available
if [ ! -f "${BATS_LIB_PATH}/bats-assert/load.bash" ]; then
    echo -e "${RED}Error: bats-assert not found at ${BATS_LIB_PATH}/bats-assert/load.bash${NC}"
    echo "Install it with: sudo apt install bats bats-assert"
    exit 1
fi

# Ensure image exists
echo -n "Checking image $IMAGE ... "
if ! docker image inspect "$IMAGE" &>/dev/null; then
    echo -e "${YELLOW}not found, building...${NC}"
    docker build -t "$IMAGE" "$SCRIPT_DIR/.."
else
    echo -e "${GREEN}found${NC}"
fi

# Clean up any leftover containers
./dc down -v --remove-orphans 2>/dev/null || true

# Run tests
echo
echo "Running tests..."
echo
result=0
bats "$@" plugins.bats || result=$?

# Clean up
./dc down -v --remove-orphans 2>/dev/null || true

echo
if [ "$result" -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
else
    echo -e "${RED}Tests failed (exit code: $result)${NC}"
fi

exit "$result"
