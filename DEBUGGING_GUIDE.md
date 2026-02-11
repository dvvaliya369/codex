# Codex CLI Launch Debugging Guide

## Quick Start

If Codex CLI appears to be "stuck" or the "window won't appear", follow these steps:

### Step 1: Understand What You're Looking For

**IMPORTANT**: Codex CLI is a **Terminal User Interface (TUI)**, not a GUI application. It runs directly in your terminal window, similar to `vim`, `htop`, or `nano`. There is **NO separate window** that opens.

When you run `codex`, the interface appears **in the same terminal window** where you typed the command.

### Step 2: Run the Diagnostic Script

```bash
cd /vercel/sandbox
./diagnose_launch.sh
```

This will check:
- Binary existence and permissions
- Platform compatibility
- Terminal environment
- Config files
- Common blocking issues

### Step 3: Check Your Terminal

Look at the terminal where you ran `codex`. You might see:

1. **Nothing** - Process is stuck before TUI starts
2. **A prompt or menu** - TUI is running, waiting for your input
3. **An error message** - Something failed

### Step 4: Try These Quick Fixes

#### If you see nothing and cursor doesn't return:

```bash
# In another terminal, check the log
tail -f ~/.config/codex/logs/codex-tui.log

# Or run with debug logging
RUST_LOG=debug codex
```

#### If you see a login/welcome screen:

**This is normal!** The TUI is working. Follow the on-screen prompts to:
- Sign in with ChatGPT
- Or sign in with API key
- Or configure settings

#### If you get "stdin is not a terminal" error:

```bash
# Make sure you're in a real terminal
tty  # Should show /dev/pts/X or similar

# If using SSH, ensure TTY allocation
ssh -t user@host
```

#### If TERM=dumb warning appears:

```bash
# Set proper terminal type
export TERM=xterm-256color
codex
```

## Documentation Files

This repository contains several debugging resources:

### 1. **LAUNCH_FLOW_DIAGRAM.md**
Visual flowchart showing the complete launch sequence with all blocking points marked.

**Use this when**: You want to understand the overall flow and identify where it might be stuck.

### 2. **LAUNCH_STUCK_SUMMARY.md**
Practical troubleshooting guide with the most common issues and fixes.

**Use this when**: You need quick solutions to common problems.

### 3. **APP_LAUNCH_ANALYSIS.md**
Detailed technical analysis of the codebase and launch process.

**Use this when**: You need to understand the implementation details or debug complex issues.

### 4. **diagnose_launch.sh**
Automated diagnostic script that checks your environment.

**Use this when**: You want a quick health check of your setup.

## Common Scenarios

### Scenario 1: First Time Running Codex

**What happens:**
1. You run `codex`
2. Terminal switches to TUI mode
3. Onboarding screen appears
4. You need to authenticate

**What to do:**
- Follow the on-screen prompts
- Choose "Sign in with ChatGPT" or "Sign in with API Key"
- Complete the authentication flow
- Trust the directory when prompted

**Expected time:** 1-2 minutes

### Scenario 2: Stuck on Config Loading

**What happens:**
1. You run `codex`
2. Nothing appears
3. Cursor doesn't return
4. Process is running but no output

**What to do:**
```bash
# Check if it's a network issue
curl -v https://api.openai.com

# Check config file
cat ~/.config/codex/config.toml

# Try with debug logging
RUST_LOG=debug codex 2>&1 | tee debug.log

# Check the log file
tail -f ~/.config/codex/logs/codex-tui.log
```

**Expected time:** Should load within 5-10 seconds

### Scenario 3: Using --oss Flag

**What happens:**
1. You run `codex --oss`
2. Provider selection menu appears
3. Waiting for you to choose a provider

**What to do:**
- Use arrow keys to navigate
- Press Enter to select
- Or configure provider in config.toml first:

```toml
[model_providers.ollama]
enabled = true
```

**Expected time:** Immediate selection, then possible model download (minutes to hours)

### Scenario 4: Model Download (with --oss)

**What happens:**
1. You selected an OSS provider
2. Model needs to be downloaded
3. Long pause with no visible progress

**What to do:**
```bash
# Check network activity
netstat -an | grep ESTABLISHED

# Check disk space
df -h ~

# Watch the log for progress
tail -f ~/.config/codex/logs/codex-tui.log

# Be patient - models can be several GB
```

**Expected time:** Depends on model size and network speed (can be 10+ minutes)

## Advanced Debugging

### Enable Full Debug Logging

```bash
RUST_LOG=trace codex 2>&1 | tee full-debug.log
```

### Trace System Calls (Linux)

```bash
strace -f -e trace=open,openat,read,write,connect,poll,select codex 2>&1 | tee strace.log
```

Look for:
- Last successful operation before hang
- Repeated poll/select calls (waiting for I/O)
- Failed open/connect calls

### Check Process State

```bash
# Find the process
ps aux | grep codex

# Check what it's doing
top -p <PID>

# Check open files
lsof -p <PID>

# Check network connections
netstat -anp | grep <PID>
```

### Attach Debugger (if built with debug symbols)

```bash
# Find the process
pgrep codex

# Attach gdb
gdb -p <PID>

# Get backtrace
(gdb) bt
(gdb) thread apply all bt
```

## Environment Variables

Useful environment variables for debugging:

```bash
# Logging level
RUST_LOG=debug          # Debug level
RUST_LOG=trace          # Trace level (very verbose)
RUST_LOG=codex_tui=trace  # Trace only TUI module

# Disable color output
NO_COLOR=1

# Force terminal type
TERM=xterm-256color

# Disable analytics
CODEX_ANALYTICS_ENABLED=false
```

## File Locations

### Config Directory
```
~/.config/codex/
├── config.toml          # Main configuration
├── logs/
│   └── codex-tui.log   # TUI log file
├── sessions/            # Saved sessions
└── trust/               # Directory trust settings
```

### Binary Locations
```
codex-cli/
├── bin/
│   └── codex.js        # Node.js wrapper
└── vendor/
    ├── x86_64-unknown-linux-musl/
    │   └── codex/
    │       └── codex   # Linux x64 binary
    ├── aarch64-unknown-linux-musl/
    │   └── codex/
    │       └── codex   # Linux ARM64 binary
    └── ...
```

## Getting Help

### Check Logs First
```bash
# Most recent log entries
tail -n 100 ~/.config/codex/logs/codex-tui.log

# Follow log in real-time
tail -f ~/.config/codex/logs/codex-tui.log

# Search for errors
grep -i error ~/.config/codex/logs/codex-tui.log
```

### Collect Debug Information

If you need to report an issue, collect this information:

```bash
# System info
uname -a
echo $TERM
tty

# Codex version
codex --version

# Run diagnostic
./diagnose_launch.sh > diagnostic-output.txt

# Collect logs
cp ~/.config/codex/logs/codex-tui.log codex-debug.log

# Run with debug logging
RUST_LOG=debug codex 2>&1 | tee codex-debug-run.log
```

## Summary

**Key Points to Remember:**

1. ✅ Codex CLI is a **TUI**, not a GUI - it runs in your terminal
2. ✅ No separate window opens - look at your current terminal
3. ✅ First run requires authentication and directory trust
4. ✅ Check logs at `~/.config/codex/logs/codex-tui.log`
5. ✅ Use `./diagnose_launch.sh` for automated checks
6. ✅ Most "stuck" issues are actually waiting for user input

**Most Common Issue:**
The TUI is actually running and showing prompts, but users expect a separate window and don't realize they need to interact with their terminal.

**Quick Test:**
```bash
# Try pressing these keys in the terminal where you ran codex:
# - Arrow keys (↑ ↓ ← →)
# - Enter
# - Escape
# - Tab
# - Ctrl+C (to exit)
```

If any of these produce a response, the TUI is running!
