# macOS Launch Debugging Guide - Step by Step

This guide will walk you through capturing logs and debug information when the Codex CLI app hangs on launch on your Mac. All steps are safe and non-destructive.

---

## Important First: What You're Looking For

**Codex CLI is a Terminal User Interface (TUI)**, not a GUI app with windows. It runs **inside your terminal window**, similar to vim or htop. There's **no separate window that opens**.

When you run `codex`, the interface appears in the **same terminal window** where you typed the command.

---

## Step-by-Step Debugging Process

### Step 1: Check If It's Actually Running

Open a new terminal window and run:

```bash
# Check if codex is running
ps aux | grep codex

# You should see something like:
# yourusername  12345  0.0  0.1  ...  codex
```

If you see a codex process, it's running but might be waiting for input or stuck.

---

### Step 2: Check the Log File (Safest First Step)

Codex automatically writes logs to a file. Let's look at them:

```bash
# View the most recent log entries
tail -50 ~/.config/codex/logs/codex-tui.log

# Or follow the log in real-time (if codex is running)
tail -f ~/.config/codex/logs/codex-tui.log
```

**What to look for:**
- The last line will show where the app stopped
- Look for errors containing "ERROR", "WARN", or "panic"
- Note the timestamp of the last entry

**Common patterns:**
- `Loading config...` - Stuck during config loading
- `Waiting for authentication...` - Needs login
- `Checking for updates...` - Update check hanging
- `Loading managed preferences...` - macOS preferences timeout

---

### Step 3: Run With Debug Logging (Still Safe)

If the log file doesn't have enough detail, run codex with verbose debug logging:

```bash
# Run with debug output
RUST_LOG=debug codex
```

This will print detailed information directly to your terminal as the app launches.

**What to look for:**
- The last message before it stops
- Any lines containing "ERROR" or "timeout"
- Messages about config loading, authentication, or network calls

**To save this output to a file:**

```bash
# Run and save all output to a file
RUST_LOG=debug codex 2>&1 | tee ~/codex-debug-output.txt
```

This creates a file `~/codex-debug-output.txt` with all debug information.

---

### Step 4: Run the Diagnostic Script

The repository includes an automated diagnostic tool:

```bash
# Navigate to where codex is installed
cd /path/to/codex  # Usually where you cloned it

# Make the script executable (if needed)
chmod +x diagnose_launch.sh

# Run diagnostics
./diagnose_launch.sh
```

This will check:
- If the binary exists and is executable
- Terminal compatibility
- Config file validity
- Network connectivity
- Common issues

**Save the output:**

```bash
./diagnose_launch.sh > ~/codex-diagnostic-report.txt
```

---

### Step 5: Check macOS-Specific Issues

macOS has some specific behaviors that can cause hangs:

#### A. Check for Managed Preferences Timeout

macOS can try to load enterprise/managed preferences, which might timeout. Check the logs:

```bash
grep -i "managed preferences" ~/.config/codex/logs/codex-tui.log
grep -i "timeout" ~/.config/codex/logs/codex-tui.log
```

If you see timeout messages, this is a known issue. The app should continue after 5 seconds.

#### B. Check Network Connectivity

Some launch steps require network access:

```bash
# Test OpenAI API connectivity
curl -v https://api.openai.com

# Test Anthropic API connectivity
curl -v https://api.anthropic.com
```

If these timeout, you might have firewall or network issues.

#### C. Check Terminal Type

```bash
# Check your terminal type
echo $TERM

# Should be something like: xterm-256color or screen-256color
# If it shows "dumb", that could cause issues
```

---

### Step 6: Test in Different Scenarios

Try launching codex in different ways to isolate the issue:

#### A. Try Version Check (Fastest Test)

```bash
# This should work instantly without TUI
codex --version
```

If this hangs, there's a fundamental issue with the binary.

#### B. Try Non-Interactive Mode

```bash
# This bypasses the TUI
codex exec "echo test"
```

If this works but regular `codex` doesn't, the issue is in TUI initialization.

#### C. Try With Minimal Options

```bash
# Skip update check
codex --skip-update-prompt
```

---

### Step 7: Advanced Logging (Optional)

For the most detailed information:

```bash
# Maximum verbosity
RUST_LOG=trace codex 2>&1 | tee ~/codex-trace.log
```

**Warning:** This creates VERY verbose output, but shows every internal step.

---

### Step 8: Monitor System Activity (Optional)

While codex is running (or stuck), check what it's doing:

#### A. Check CPU and Memory Usage

```bash
# Find the process ID
pgrep codex

# Monitor it (replace PID with actual process ID)
top -pid <PID>
```

**What to look for:**
- High CPU = actively doing something (maybe downloading/processing)
- Low CPU = waiting on I/O or user input

#### B. Check Network Activity

```bash
# Check if codex is making network connections
lsof -i -P | grep codex
```

Shows active network connections (downloads, API calls, etc.)

#### C. Check Open Files

```bash
# See what files codex has open
lsof -p <PID>
```

Shows config files, logs, etc. that are being accessed.

---

## Common Issues and Solutions

### Issue 1: Waiting for Login/Authentication

**Symptoms:**
- App appears stuck
- Last log entry mentions "authentication" or "login"

**What to do:**
Look at your terminal carefully - you might see a login prompt or menu that needs input. Try:
- Pressing arrow keys (↑ ↓)
- Pressing Enter
- Pressing Tab

### Issue 2: First-Time Setup/Onboarding

**Symptoms:**
- First time running codex
- App appears stuck

**What to do:**
The app is likely showing an onboarding screen. Check your terminal for:
- "Welcome" messages
- Options to sign in
- Directory trust prompts

Use arrow keys to navigate and Enter to select.

### Issue 3: Update Check Hanging

**Symptoms:**
- Logs show "Checking for updates"
- Process stops there

**What to do:**
```bash
# Skip update check
codex --skip-update-prompt
```

### Issue 4: Config File Issues

**Symptoms:**
- Logs show config parsing errors
- App exits with error

**What to do:**
```bash
# Check config syntax
cat ~/.config/codex/config.toml

# Backup and reset config
mv ~/.config/codex/config.toml ~/.config/codex/config.toml.backup
codex  # Will create new default config
```

### Issue 5: Stuck in Background

**Symptoms:**
- Process running but nothing visible
- Terminal prompt returned but codex still in `ps`

**What to do:**
```bash
# Find and stop the hung process
pkill codex

# Or more forcefully if needed
pkill -9 codex
```

---

## What Information to Collect

If you need to report the issue, gather:

1. **System Information:**
   ```bash
   sw_vers  # macOS version
   uname -m  # Processor architecture (Intel vs Apple Silicon)
   echo $TERM  # Terminal type
   ```

2. **Codex Version:**
   ```bash
   codex --version
   ```

3. **Log Files:**
   - `~/.config/codex/logs/codex-tui.log`
   - Output from `RUST_LOG=debug codex`

4. **Diagnostic Output:**
   - Output from `./diagnose_launch.sh`

5. **Last Working State:**
   - When did it last work?
   - What changed? (macOS update, codex update, etc.)

---

## Safe Cleanup If Things Go Wrong

If you need to reset everything:

```bash
# Stop any running codex processes
pkill codex

# Backup your config
mv ~/.config/codex ~/.config/codex.backup

# Next run will create fresh config
codex
```

**To restore your backup:**

```bash
rm -rf ~/.config/codex
mv ~/.config/codex.backup ~/.config/codex
```

---

## Quick Reference: Key Log Locations

```bash
# Main log file
~/.config/codex/logs/codex-tui.log

# Config directory
~/.config/codex/

# Config file
~/.config/codex/config.toml

# Session data
~/.config/codex/sessions/
```

---

## Understanding What's Normal

**Normal launch sequence (under 10 seconds):**

1. Binary starts (instant)
2. Config loads (< 1 second)
3. Managed preferences check on macOS (< 5 seconds or timeout)
4. Terminal switches to TUI mode (< 1 second)
5. Update check (1-3 seconds, can skip)
6. Auth check (instant if already logged in)
7. TUI appears in terminal

**First-time launch (1-2 minutes):**

1. Steps 1-5 above
2. Onboarding screen appears (waits for your input)
3. Authentication flow (requires web browser)
4. Directory trust setup (waits for your input)
5. TUI ready

---

## Key Debugging Commands Summary

```bash
# View recent logs
tail -50 ~/.config/codex/logs/codex-tui.log

# Follow logs in real-time
tail -f ~/.config/codex/logs/codex-tui.log

# Run with debug output
RUST_LOG=debug codex

# Save debug output to file
RUST_LOG=debug codex 2>&1 | tee ~/codex-debug.txt

# Check if running
ps aux | grep codex

# Quick test
codex --version

# Run diagnostic
./diagnose_launch.sh

# Stop hung process
pkill codex
```

---

## When to Seek Help

Seek additional help if:
- Log files show errors you don't understand
- App consistently hangs at the same point
- Diagnostic script reports failures
- You've tried all the steps above

**Include in your help request:**
- macOS version (`sw_vers`)
- Processor type (`uname -m`)
- Output from `./diagnose_launch.sh`
- Last 100 lines of log: `tail -100 ~/.config/codex/logs/codex-tui.log`
- Output from `RUST_LOG=debug codex` showing where it hangs

---

## macOS-Specific Notes

### Apple Silicon (M1/M2/M3) vs Intel

The correct binary is automatically selected. Check if the right one is being used:

```bash
# On Apple Silicon, should use aarch64
# On Intel, should use x86_64
file $(which codex)
```

### macOS Security and Permissions

First launch might trigger macOS security prompts:
- "codex is from an unidentified developer"
- Click "Open Anyway" in System Settings > Privacy & Security

### Managed/Enterprise Macs

If your Mac is managed by an organization:
- Managed preferences loading may timeout (this is OK, logged)
- Some security policies might block execution
- Check with IT if codex is allowed

---

## Summary

**Most common causes of "hanging":**

1. ✅ TUI is actually running - check your terminal for prompts
2. ✅ Waiting for authentication - first-time setup
3. ✅ Waiting for directory trust - security prompt
4. ✅ Update check taking time - can skip with flag
5. ✅ Network timeout - check connectivity

**Remember:** Codex runs IN your terminal, not as a separate window. Look carefully at the terminal where you typed `codex` - the interface is there!

**Quick diagnostic flow:**

1. Check the terminal where you ran `codex` (look for prompts)
2. Check `tail -50 ~/.config/codex/logs/codex-tui.log`
3. Run `RUST_LOG=debug codex` to see what's happening
4. Try `codex --version` to test basic functionality
5. Run `./diagnose_launch.sh` for automated checks

Most issues can be diagnosed within 5 minutes using these steps!
