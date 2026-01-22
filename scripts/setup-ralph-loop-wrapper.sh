#!/bin/bash
# Wrapper script to handle argument passing on Windows
# This script receives all arguments as a single string and passes them correctly

# Get the plugin root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(dirname "$SCRIPT_DIR")"

# Execute the actual setup script with all arguments
exec "$PLUGIN_ROOT/scripts/setup-ralph-loop.sh" "$@"
