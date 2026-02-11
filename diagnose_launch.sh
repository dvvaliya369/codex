#!/bin/bash
# Codex CLI Launch Diagnostic Script
# This script helps identify where the Codex CLI launch process is getting stuck

set -e

echo "=== Codex CLI Launch Diagnostics ==="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
    else
        echo -e "${RED}✗${NC} $2"
    fi
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_section() {
    echo ""
    echo "=== $1 ==="
}

# 1. Check Node.js wrapper
print_section "1. Node.js Wrapper Check"

if [ -f "codex-cli/bin/codex.js" ]; then
    print_status 0 "codex.js wrapper found"
    
    # Check if it's executable
    if [ -x "codex-cli/bin/codex.js" ]; then
        print_status 0 "codex.js is executable"
    else
        print_status 1 "codex.js is NOT executable"
        echo "  Fix: chmod +x codex-cli/bin/codex.js"
    fi
else
    print_status 1 "codex.js wrapper NOT found"
fi

# 2. Check platform detection
print_section "2. Platform Detection"

PLATFORM=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

echo "Platform: $PLATFORM"
echo "Architecture: $ARCH"

case "$PLATFORM" in
    linux)
        case "$ARCH" in
            x86_64)
                TARGET_TRIPLE="x86_64-unknown-linux-musl"
                ;;
            aarch64|arm64)
                TARGET_TRIPLE="aarch64-unknown-linux-musl"
                ;;
            *)
                TARGET_TRIPLE="unknown"
                ;;
        esac
        ;;
    darwin)
        case "$ARCH" in
            x86_64)
                TARGET_TRIPLE="x86_64-apple-darwin"
                ;;
            arm64)
                TARGET_TRIPLE="aarch64-apple-darwin"
                ;;
            *)
                TARGET_TRIPLE="unknown"
                ;;
        esac
        ;;
    *)
        TARGET_TRIPLE="unknown"
        ;;
esac

echo "Expected target triple: $TARGET_TRIPLE"

if [ "$TARGET_TRIPLE" = "unknown" ]; then
    print_status 1 "Unsupported platform/architecture combination"
else
    print_status 0 "Platform supported"
fi

# 3. Check binary existence
print_section "3. Binary Check"

BINARY_PATH="codex-cli/vendor/$TARGET_TRIPLE/codex/codex"

if [ -f "$BINARY_PATH" ]; then
    print_status 0 "Binary found at $BINARY_PATH"
    
    # Check if executable
    if [ -x "$BINARY_PATH" ]; then
        print_status 0 "Binary is executable"
    else
        print_status 1 "Binary is NOT executable"
        echo "  Fix: chmod +x $BINARY_PATH"
    fi
    
    # Check file type
    echo "Binary type:"
    file "$BINARY_PATH" | sed 's/^/  /'
    
    # Check dependencies (Linux only)
    if [ "$PLATFORM" = "linux" ]; then
        echo "Binary dependencies:"
        if command -v ldd &> /dev/null; then
            ldd "$BINARY_PATH" 2>&1 | sed 's/^/  /' || echo "  (static binary or ldd failed)"
        else
            echo "  ldd not available"
        fi
    fi
else
    print_status 1 "Binary NOT found at $BINARY_PATH"
    echo "  Expected location: $BINARY_PATH"
    echo "  Available vendor directories:"
    if [ -d "codex-cli/vendor" ]; then
        ls -la codex-cli/vendor/ | sed 's/^/    /'
    else
        echo "    vendor directory does not exist"
    fi
fi

# 4. Check terminal environment
print_section "4. Terminal Environment"

if [ -t 0 ]; then
    print_status 0 "stdin is a terminal"
else
    print_status 1 "stdin is NOT a terminal"
    print_warning "Codex CLI requires stdin to be a terminal"
fi

if [ -t 1 ]; then
    print_status 0 "stdout is a terminal"
else
    print_status 1 "stdout is NOT a terminal"
    print_warning "Codex CLI requires stdout to be a terminal"
fi

echo "TERM environment variable: ${TERM:-<not set>}"
if [ "$TERM" = "dumb" ]; then
    print_warning "TERM is set to 'dumb' - this may cause issues"
fi

echo "TTY: $(tty 2>/dev/null || echo '<not available>')"

# 5. Check Codex home directory
print_section "5. Codex Home Directory"

CODEX_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/codex"
echo "Expected Codex home: $CODEX_HOME"

if [ -d "$CODEX_HOME" ]; then
    print_status 0 "Codex home directory exists"
    
    # Check permissions
    if [ -r "$CODEX_HOME" ] && [ -w "$CODEX_HOME" ]; then
        print_status 0 "Codex home is readable and writable"
    else
        print_status 1 "Codex home has permission issues"
        ls -ld "$CODEX_HOME" | sed 's/^/  /'
    fi
    
    # Check config file
    if [ -f "$CODEX_HOME/config.toml" ]; then
        print_status 0 "config.toml exists"
        echo "Config file size: $(wc -c < "$CODEX_HOME/config.toml") bytes"
        
        # Try to validate TOML syntax (if toml-cli is available)
        if command -v toml &> /dev/null; then
            if toml get "$CODEX_HOME/config.toml" . &> /dev/null; then
                print_status 0 "config.toml syntax is valid"
            else
                print_status 1 "config.toml has syntax errors"
            fi
        fi
    else
        print_warning "config.toml does not exist (will be created on first run)"
    fi
    
    # Check log directory
    if [ -d "$CODEX_HOME/logs" ]; then
        print_status 0 "Logs directory exists"
        
        # Check latest log
        LATEST_LOG="$CODEX_HOME/logs/codex-tui.log"
        if [ -f "$LATEST_LOG" ]; then
            echo "Latest log file: $LATEST_LOG"
            echo "Last 10 lines of log:"
            tail -n 10 "$LATEST_LOG" 2>/dev/null | sed 's/^/  /' || echo "  (unable to read log)"
        fi
    else
        print_warning "Logs directory does not exist (will be created on first run)"
    fi
else
    print_warning "Codex home directory does not exist (will be created on first run)"
fi

# 6. Check Node.js
print_section "6. Node.js Environment"

if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    print_status 0 "Node.js found: $NODE_VERSION"
    
    # Check version (should be >= 16)
    NODE_MAJOR=$(echo "$NODE_VERSION" | sed 's/v\([0-9]*\).*/\1/')
    if [ "$NODE_MAJOR" -ge 16 ]; then
        print_status 0 "Node.js version is sufficient (>= 16)"
    else
        print_status 1 "Node.js version is too old (< 16)"
    fi
else
    print_status 1 "Node.js NOT found"
fi

# 7. Test binary execution
print_section "7. Binary Execution Test"

if [ -f "$BINARY_PATH" ] && [ -x "$BINARY_PATH" ]; then
    echo "Testing binary with --version flag..."
    if timeout 5s "$BINARY_PATH" --version 2>&1; then
        print_status 0 "Binary executes successfully"
    else
        EXIT_CODE=$?
        if [ $EXIT_CODE -eq 124 ]; then
            print_status 1 "Binary execution timed out (hung)"
        else
            print_status 1 "Binary execution failed with exit code $EXIT_CODE"
        fi
    fi
else
    print_warning "Skipping binary execution test (binary not found or not executable)"
fi

# 8. Check for common blocking issues
print_section "8. Common Blocking Issues"

# Check for network connectivity (for cloud requirements)
if command -v curl &> /dev/null; then
    if curl -s --connect-timeout 3 https://api.openai.com > /dev/null 2>&1; then
        print_status 0 "Network connectivity to OpenAI API"
    else
        print_warning "Cannot reach OpenAI API (may affect cloud features)"
    fi
else
    print_warning "curl not available, cannot test network connectivity"
fi

# Check disk space
DISK_USAGE=$(df -h "$HOME" 2>/dev/null | awk 'NR==2 {print $5}' | sed 's/%//')
if [ -n "$DISK_USAGE" ]; then
    if [ "$DISK_USAGE" -lt 90 ]; then
        print_status 0 "Sufficient disk space (${DISK_USAGE}% used)"
    else
        print_warning "Low disk space (${DISK_USAGE}% used)"
    fi
fi

# Summary
print_section "Summary"

echo ""
echo "If the application is hanging, check:"
echo "  1. Log file: $CODEX_HOME/logs/codex-tui.log"
echo "  2. Run with debug logging: RUST_LOG=debug codex"
echo "  3. Try non-interactive mode: codex exec 'echo test'"
echo "  4. Check if waiting for user input (onboarding, login, etc.)"
echo ""
echo "Remember: Codex CLI is a TERMINAL application, not a GUI."
echo "It runs in your current terminal window, not a separate window."
echo ""
