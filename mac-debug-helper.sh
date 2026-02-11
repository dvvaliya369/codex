#!/bin/bash
# Mac Debug Helper for Codex CLI
# Safe, non-destructive debugging script for macOS
# Run this to quickly diagnose Codex CLI launch issues

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Debug log directory
DEBUG_DIR="$HOME/codex-debug-logs"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

print_header() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${BLUE}Codex CLI Debug Helper for Mac${NC}                        ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_section() {
    echo ""
    echo -e "${BLUE}▶ $1${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

# Create debug directory
mkdir -p "$DEBUG_DIR"

print_header

# Menu
echo "What would you like to do?"
echo ""
echo "  1) Quick diagnostic check"
echo "  2) Run Codex with debug logging"
echo "  3) Run Codex with maximum logging (trace)"
echo "  4) Check existing logs"
echo "  5) Test non-interactive mode"
echo "  6) Create full debug report"
echo "  7) Watch live logs (requires second terminal)"
echo "  8) Clean up debug files"
echo "  9) Show help"
echo ""
read -p "Enter your choice (1-9): " choice

case $choice in
    1)
        print_section "Quick Diagnostic Check"
        
        # System info
        echo "macOS Version: $(sw_vers -productVersion)"
        echo "Architecture: $(uname -m)"
        echo "Terminal: $TERM"
        echo "TTY: $(tty)"
        echo ""
        
        # Node.js
        if command -v node &> /dev/null; then
            NODE_VERSION=$(node --version)
            print_success "Node.js: $NODE_VERSION"
            
            NODE_MAJOR=$(echo "$NODE_VERSION" | sed 's/v\([0-9]*\).*/\1/')
            if [ "$NODE_MAJOR" -ge 16 ]; then
                print_success "Node.js version is sufficient (>= 16)"
            else
                print_error "Node.js version is too old (< 16)"
            fi
        else
            print_error "Node.js not found"
        fi
        echo ""
        
        # Codex binary
        if command -v codex &> /dev/null; then
            CODEX_PATH=$(which codex)
            print_success "Codex found: $CODEX_PATH"
            
            # Try version check
            if timeout 5s codex --version &> /dev/null; then
                print_success "Codex binary executes successfully"
            else
                print_error "Codex binary failed to execute or timed out"
            fi
        else
            print_error "Codex not found in PATH"
        fi
        echo ""
        
        # Terminal check
        if [ -t 0 ]; then
            print_success "stdin is a terminal"
        else
            print_error "stdin is NOT a terminal"
        fi
        
        if [ -t 1 ]; then
            print_success "stdout is a terminal"
        else
            print_error "stdout is NOT a terminal"
        fi
        
        if [ "$TERM" = "dumb" ]; then
            print_warning "TERM is set to 'dumb' - this may cause issues"
            print_info "Fix: export TERM=xterm-256color"
        else
            print_success "TERM is set to: $TERM"
        fi
        echo ""
        
        # Codex config
        CODEX_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/codex"
        if [ -d "$CODEX_HOME" ]; then
            print_success "Codex config directory exists: $CODEX_HOME"
            
            if [ -f "$CODEX_HOME/config.toml" ]; then
                print_success "config.toml exists"
            else
                print_warning "config.toml does not exist (normal for first run)"
            fi
            
            if [ -d "$CODEX_HOME/logs" ]; then
                print_success "Logs directory exists"
                if [ -f "$CODEX_HOME/logs/codex-tui.log" ]; then
                    LOG_SIZE=$(wc -c < "$CODEX_HOME/logs/codex-tui.log")
                    print_info "Log file size: $LOG_SIZE bytes"
                fi
            fi
        else
            print_warning "Codex config directory does not exist (will be created on first run)"
        fi
        echo ""
        
        # Network check
        print_info "Testing network connectivity..."
        if curl -s --connect-timeout 3 https://api.openai.com > /dev/null 2>&1; then
            print_success "Can reach OpenAI API"
        else
            print_warning "Cannot reach OpenAI API (may affect cloud features)"
        fi
        echo ""
        
        print_info "Diagnostic complete! Check above for any errors or warnings."
        ;;
        
    2)
        print_section "Running Codex with Debug Logging"
        
        LOG_FILE="$DEBUG_DIR/codex-debug-$TIMESTAMP.log"
        print_info "Log will be saved to: $LOG_FILE"
        print_info "Press Ctrl+C to stop"
        echo ""
        
        print_warning "The terminal will switch to TUI mode - this is normal!"
        print_warning "If you see a login screen or menu, interact with it!"
        echo ""
        
        sleep 2
        
        RUST_LOG=debug codex 2>&1 | tee "$LOG_FILE"
        
        echo ""
        print_success "Log saved to: $LOG_FILE"
        ;;
        
    3)
        print_section "Running Codex with Maximum Logging (Trace)"
        
        LOG_FILE="$DEBUG_DIR/codex-trace-$TIMESTAMP.log"
        print_info "Log will be saved to: $LOG_FILE"
        print_warning "This will generate VERY verbose output!"
        print_info "Press Ctrl+C to stop"
        echo ""
        
        sleep 2
        
        RUST_LOG=trace codex 2>&1 | tee "$LOG_FILE"
        
        echo ""
        print_success "Log saved to: $LOG_FILE"
        ;;
        
    4)
        print_section "Checking Existing Logs"
        
        CODEX_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/codex"
        LOG_FILE="$CODEX_HOME/logs/codex-tui.log"
        
        if [ -f "$LOG_FILE" ]; then
            print_success "Found log file: $LOG_FILE"
            echo ""
            
            echo "Last 30 lines of log:"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            tail -n 30 "$LOG_FILE"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            
            # Check for errors
            ERROR_COUNT=$(grep -i "error\|panic\|failed" "$LOG_FILE" 2>/dev/null | wc -l | tr -d ' ')
            if [ "$ERROR_COUNT" -gt 0 ]; then
                print_warning "Found $ERROR_COUNT error-related messages"
                echo ""
                echo "Recent errors:"
                grep -i "error\|panic\|failed" "$LOG_FILE" | tail -n 10
            else
                print_success "No obvious errors found in log"
            fi
        else
            print_warning "No log file found at: $LOG_FILE"
            print_info "This is normal if you haven't run Codex yet"
        fi
        ;;
        
    5)
        print_section "Testing Non-Interactive Mode"
        
        LOG_FILE="$DEBUG_DIR/codex-exec-test-$TIMESTAMP.log"
        print_info "Testing with simple prompt: 'What is 2+2?'"
        print_info "Log will be saved to: $LOG_FILE"
        echo ""
        
        echo "What is 2+2?" | codex exec 2>&1 | tee "$LOG_FILE"
        
        echo ""
        if [ $? -eq 0 ]; then
            print_success "Non-interactive mode works!"
            print_info "If this works but TUI doesn't, it's likely a terminal compatibility issue"
        else
            print_error "Non-interactive mode failed"
        fi
        
        print_success "Log saved to: $LOG_FILE"
        ;;
        
    6)
        print_section "Creating Full Debug Report"
        
        REPORT_FILE="$DEBUG_DIR/debug-report-$TIMESTAMP.txt"
        print_info "Collecting comprehensive debug information..."
        echo ""
        
        {
            echo "=== Codex CLI Debug Report for Mac ==="
            echo "Generated: $(date)"
            echo ""
            
            echo "--- System Information ---"
            echo "macOS Version: $(sw_vers -productVersion)"
            echo "Build: $(sw_vers -buildVersion)"
            echo "Architecture: $(uname -m)"
            echo "Kernel: $(uname -r)"
            echo "Hostname: $(hostname)"
            echo ""
            
            echo "--- Terminal Environment ---"
            echo "TERM: $TERM"
            echo "TTY: $(tty)"
            echo "SHELL: $SHELL"
            echo "LANG: $LANG"
            echo "stdin is terminal: $([ -t 0 ] && echo 'yes' || echo 'no')"
            echo "stdout is terminal: $([ -t 1 ] && echo 'yes' || echo 'no')"
            echo ""
            
            echo "--- Node.js ---"
            if command -v node &> /dev/null; then
                echo "Version: $(node --version)"
                echo "Path: $(which node)"
            else
                echo "Not found"
            fi
            echo ""
            
            echo "--- Codex Binary ---"
            if command -v codex &> /dev/null; then
                echo "Path: $(which codex)"
                echo "Type: $(file $(which codex))"
                echo "Version test: $(timeout 5s codex --version 2>&1 || echo 'Failed or timed out')"
            else
                echo "Not found in PATH"
            fi
            echo ""
            
            echo "--- Codex Configuration ---"
            CODEX_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/codex"
            echo "Config directory: $CODEX_HOME"
            if [ -d "$CODEX_HOME" ]; then
                echo "Directory exists: yes"
                echo "Contents:"
                ls -la "$CODEX_HOME" 2>&1 | sed 's/^/  /'
                
                if [ -f "$CODEX_HOME/config.toml" ]; then
                    echo ""
                    echo "config.toml (first 50 lines):"
                    head -n 50 "$CODEX_HOME/config.toml" 2>&1 | sed 's/^/  /'
                fi
            else
                echo "Directory exists: no"
            fi
            echo ""
            
            echo "--- Recent Logs (last 50 lines) ---"
            if [ -f "$CODEX_HOME/logs/codex-tui.log" ]; then
                tail -n 50 "$CODEX_HOME/logs/codex-tui.log" 2>&1
            else
                echo "No log file found"
            fi
            echo ""
            
            echo "--- Running Processes ---"
            ps aux | grep -i codex | grep -v grep || echo "No Codex processes running"
            echo ""
            
            echo "--- Network Connectivity ---"
            echo "OpenAI API: $(curl -s -o /dev/null -w '%{http_code}' --connect-timeout 3 https://api.openai.com 2>&1)"
            echo ""
            
            echo "--- Disk Space ---"
            df -h "$HOME" | tail -n 1
            echo ""
            
            echo "--- Environment Variables (Codex-related) ---"
            env | grep -i "codex\|rust\|term\|lang" || echo "None found"
            echo ""
            
        } > "$REPORT_FILE"
        
        print_success "Debug report created: $REPORT_FILE"
        echo ""
        print_info "You can review this file and share it when asking for help"
        print_warning "Review the file first to remove any sensitive information!"
        echo ""
        
        read -p "Would you like to view the report now? (y/n): " view_choice
        if [ "$view_choice" = "y" ] || [ "$view_choice" = "Y" ]; then
            less "$REPORT_FILE"
        fi
        ;;
        
    7)
        print_section "Watch Live Logs"
        
        CODEX_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/codex"
        LOG_FILE="$CODEX_HOME/logs/codex-tui.log"
        
        print_info "This will watch the Codex log file in real-time"
        print_warning "You need to run 'codex' in ANOTHER terminal window"
        echo ""
        print_info "Steps:"
        echo "  1. Keep this terminal open"
        echo "  2. Open a NEW terminal window"
        echo "  3. Run 'codex' in the new window"
        echo "  4. Watch the logs appear here"
        echo ""
        print_info "Press Ctrl+C to stop watching"
        echo ""
        
        sleep 3
        
        if [ -f "$LOG_FILE" ]; then
            tail -f "$LOG_FILE"
        else
            print_warning "Log file doesn't exist yet: $LOG_FILE"
            print_info "It will be created when you run Codex"
            print_info "Waiting for log file to appear..."
            
            # Wait for log file to be created
            while [ ! -f "$LOG_FILE" ]; do
                sleep 1
            done
            
            print_success "Log file appeared! Watching..."
            tail -f "$LOG_FILE"
        fi
        ;;
        
    8)
        print_section "Clean Up Debug Files"
        
        if [ -d "$DEBUG_DIR" ]; then
            FILE_COUNT=$(ls -1 "$DEBUG_DIR" 2>/dev/null | wc -l | tr -d ' ')
            
            if [ "$FILE_COUNT" -gt 0 ]; then
                echo "Found $FILE_COUNT debug file(s) in $DEBUG_DIR"
                echo ""
                ls -lh "$DEBUG_DIR"
                echo ""
                
                read -p "Delete all debug files? (y/n): " delete_choice
                if [ "$delete_choice" = "y" ] || [ "$delete_choice" = "Y" ]; then
                    rm -rf "$DEBUG_DIR"
                    print_success "Debug files deleted"
                else
                    print_info "Debug files kept"
                fi
            else
                print_info "No debug files to clean up"
            fi
        else
            print_info "Debug directory doesn't exist"
        fi
        
        echo ""
        print_warning "Note: This only deletes files in $DEBUG_DIR"
        print_info "Your Codex config (~/.config/codex/) is NOT affected"
        ;;
        
    9)
        print_section "Help"
        
        echo "This script helps you debug Codex CLI launch issues on Mac."
        echo ""
        echo "Common scenarios:"
        echo ""
        echo "1. First time running Codex:"
        echo "   → Run option 1 (Quick diagnostic)"
        echo "   → Then run option 2 (Debug logging)"
        echo "   → Look for login/onboarding screens in your terminal"
        echo ""
        echo "2. Codex appears to hang:"
        echo "   → Run option 7 (Watch live logs) in one terminal"
        echo "   → Run 'codex' in another terminal"
        echo "   → See where it stops in the logs"
        echo ""
        echo "3. Need to report an issue:"
        echo "   → Run option 6 (Full debug report)"
        echo "   → Review and share the report file"
        echo ""
        echo "Remember:"
        echo "  • Codex is a TUI (runs IN your terminal, not a separate window)"
        echo "  • First run requires login/authentication"
        echo "  • Check logs at: ~/.config/codex/logs/codex-tui.log"
        echo ""
        echo "For more detailed help, see: MAC_DEBUG_GUIDE.md"
        ;;
        
    *)
        print_error "Invalid choice"
        exit 1
        ;;
esac

echo ""
print_info "Debug files are saved in: $DEBUG_DIR"
echo ""
