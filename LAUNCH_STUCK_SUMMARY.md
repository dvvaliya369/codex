# Where Codex CLI Gets Stuck During Launch - Summary

## Critical Understanding

**Codex CLI is NOT a GUI application with a separate window.** It's a Terminal User Interface (TUI) that runs directly in your terminal, similar to `vim`, `htop`, or `nano`. If you're expecting a separate graphical window to open, that's the fundamental misconception.

## Launch Process Flow

```
Node.js Wrapper (codex.js)
    ↓
Rust Binary (codex)
    ↓
CLI Argument Parsing
    ↓
Config Loading ← POTENTIAL HANG #1
    ↓
OSS Provider Selection ← POTENTIAL HANG #2 (if --oss flag used)
    ↓
Logging Setup
    ↓
Terminal Detection ← POTENTIAL FAILURE #3
    ↓
Terminal Mode Setup ← POTENTIAL FAILURE #4
    ↓
Update Check ← POTENTIAL HANG #5
    ↓
Onboarding/Login ← POTENTIAL HANG #6
    ↓
TUI Event Loop ← APPLICATION RUNNING
```

## Most Likely Blocking Points

### 1. **Config Loading Hangs** (Probability: HIGH)
**Location**: `codex-rs/tui/src/lib.rs:180-210`

**What happens:**
- Loads `~/.config/codex/config.toml`
- Makes network call to fetch cloud requirements
- Parses configuration with CLI overrides

**Why it blocks:**
- Network timeout waiting for cloud API
- Invalid TOML syntax in config file
- Permission issues reading config directory

**How to detect:**
```bash
# Check if config file exists and is valid
cat ~/.config/codex/config.toml

# Run with debug logging
RUST_LOG=debug codex 2>&1 | tee debug.log

# Check the log file
tail -f ~/.config/codex/logs/codex-tui.log
```

**How to fix:**
- Check network connectivity
- Validate config.toml syntax
- Delete config file to regenerate: `rm ~/.config/codex/config.toml`

### 2. **OSS Provider Selection Blocks** (Probability: MEDIUM)
**Location**: `codex-rs/tui/src/lib.rs:230-245`

**What happens:**
- If `--oss` flag is used and no provider is configured
- Shows interactive selection menu
- Waits for user input

**Why it blocks:**
- Terminal not properly initialized yet
- User input not visible
- Waiting for selection that appears frozen

**How to detect:**
```bash
# Check if you used --oss flag
# Try pressing arrow keys and Enter
```

**How to fix:**
- Don't use `--oss` flag initially
- Configure provider in config.toml first
- Press Ctrl+C and reconfigure

### 3. **Terminal Detection Fails** (Probability: MEDIUM)
**Location**: `codex-rs/tui/src/tui.rs:210-215`

**What happens:**
```rust
if !stdin().is_terminal() {
    return Err(std::io::Error::other("stdin is not a terminal"));
}
if !stdout().is_terminal() {
    return Err(std::io::Error::other("stdout is not a terminal"));
}
```

**Why it fails:**
- Running with redirected I/O: `codex < input.txt`
- Running in non-interactive environment
- SSH session with improper TTY allocation

**How to detect:**
```bash
# Check if stdin/stdout are terminals
[ -t 0 ] && echo "stdin is terminal" || echo "stdin NOT terminal"
[ -t 1 ] && echo "stdout is terminal" || echo "stdout NOT terminal"
```

**How to fix:**
- Run in proper terminal emulator
- For SSH: use `ssh -t user@host`
- Don't redirect stdin/stdout

### 4. **TERM=dumb Environment** (Probability: LOW)
**Location**: `codex-rs/tui/src/lib.rs:850-870`

**What happens:**
- Detects TERM environment variable is "dumb"
- Shows warning and asks for confirmation
- Waits for user to type 'y' or 'n'

**Why it blocks:**
- Confirmation prompt not visible
- User doesn't know to respond

**How to detect:**
```bash
echo $TERM
# If output is "dumb", this is the issue
```

**How to fix:**
```bash
export TERM=xterm-256color
# or
unset TERM
```

### 5. **Onboarding/Login Screen** (Probability: HIGH for first run)
**Location**: `codex-rs/tui/src/lib.rs:470-520`

**What happens:**
- First-time setup shows onboarding screens
- Login screen if not authenticated
- Trust screen for directory permissions
- Waits for user interaction

**Why it blocks:**
- Screen is actually showing but user doesn't realize
- Waiting for authentication flow
- Network call for login

**How to detect:**
- This is most likely on FIRST RUN
- Try pressing keys, clicking, or typing
- Look for any text in terminal

**How to fix:**
- Complete the onboarding flow
- Use API key authentication: `echo $OPENAI_API_KEY | codex login --with-api-key`
- Check if terminal is actually showing content

### 6. **Model Download Hangs** (Probability: MEDIUM with --oss)
**Location**: `codex-rs/tui/src/lib.rs:350-360`

**What happens:**
```rust
ensure_oss_provider_ready(provider_id, &config).await?;
```

**Why it blocks:**
- Downloading large model files
- Network timeout
- Insufficient disk space

**How to detect:**
```bash
# Check network activity
netstat -an | grep ESTABLISHED

# Check disk space
df -h ~

# Check download progress in logs
tail -f ~/.config/codex/logs/codex-tui.log
```

**How to fix:**
- Wait for download to complete
- Check network connectivity
- Free up disk space

## Diagnostic Steps

### Step 1: Run the diagnostic script
```bash
./diagnose_launch.sh
```

### Step 2: Check the logs
```bash
# Enable debug logging
RUST_LOG=debug codex

# In another terminal, watch the log
tail -f ~/.config/codex/logs/codex-tui.log
```

### Step 3: Try non-interactive mode
```bash
# This bypasses the TUI entirely
codex exec "echo test"
```

### Step 4: Check for visible output
- Look at your terminal carefully
- The TUI might actually be running but not obvious
- Try pressing keys: Ctrl+C, Escape, arrow keys

### Step 5: Trace system calls (Linux)
```bash
strace -e trace=open,openat,read,write,connect,poll codex 2>&1 | tee strace.log
# Look for where it hangs in the trace
```

## Quick Fixes

### If it's hanging on first run:
```bash
# Complete authentication first
echo $OPENAI_API_KEY | codex login --with-api-key

# Or use device code flow
codex login --device-auth
```

### If config is corrupted:
```bash
# Backup and reset
mv ~/.config/codex ~/.config/codex.backup
codex  # Will create fresh config
```

### If terminal is the issue:
```bash
# Set proper TERM
export TERM=xterm-256color

# Ensure TTY
tty  # Should show /dev/pts/X or similar
```

### If network is the issue:
```bash
# Test connectivity
curl -v https://api.openai.com

# Use offline mode (if available)
codex --offline  # Check if this flag exists
```

## What "Window Not Appearing" Actually Means

Since Codex CLI is a TUI, there are three scenarios:

1. **Process hangs before TUI starts** → No output at all, cursor doesn't return
2. **TUI is running but looks blank** → Terminal is in raw mode, but nothing rendered
3. **TUI is running normally** → You see the interface in your terminal

If you see NOTHING and the cursor doesn't return, it's scenario #1 - the process is stuck in one of the initialization phases above.

## Key Files for Investigation

1. **Log file**: `~/.config/codex/logs/codex-tui.log`
2. **Config file**: `~/.config/codex/config.toml`
3. **Binary**: `codex-cli/vendor/<platform>/codex/codex`
4. **Wrapper**: `codex-cli/bin/codex.js`

## Next Steps

1. Run `./diagnose_launch.sh` to identify the issue
2. Check the specific blocking point from the output
3. Apply the corresponding fix
4. If still stuck, examine the log file with `RUST_LOG=debug`
5. Try non-interactive mode to isolate TUI issues

## Important Reminder

**The application runs IN your terminal, not as a separate window.** When it works correctly, your terminal will switch to "raw mode" and show the Codex interface. There is no separate window that opens.
