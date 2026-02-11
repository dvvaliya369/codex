# Mac Debug Guide: Safely Capture Codex CLI Launch Logs

## 🎯 Goal
This guide will help you safely capture detailed logs and debug information when Codex CLI appears to hang or won't launch on your Mac, without breaking anything.

---

## ⚠️ Important: What Codex CLI Actually Is

**Codex CLI is a Terminal User Interface (TUI)**, not a graphical application with a separate window.

- ✅ It runs **inside your terminal window** (like `vim`, `htop`, or `nano`)
- ❌ It does **NOT** open a separate window
- ✅ When it launches, your terminal screen changes to show the interface
- ❌ Don't expect a new window to pop up

**Most "hanging" issues are actually the app waiting for you to interact with it in the terminal!**

---

## 📋 Step-by-Step Debugging Process

### Step 1: Open a New Terminal Window

1. Open **Terminal.app** (or iTerm2, if you use it)
2. Navigate to your project directory:
   ```bash
   cd /path/to/your/project
   ```

### Step 2: Check Your Current Setup

Run this quick diagnostic to see what's already there:

```bash
# Check if Codex is installed
which codex

# Check Node.js version (should be >= 16)
node --version

# Check your terminal type
echo $TERM

# Verify you're in a real terminal
tty
```

**Expected output:**
- `which codex` → Shows path to codex binary
- `node --version` → Shows v16.x.x or higher
- `echo $TERM` → Shows something like `xterm-256color` (NOT `dumb`)
- `tty` → Shows something like `/dev/ttys001`

### Step 3: Create a Debug Log Directory

Let's create a safe place to store debug logs:

```bash
# Create a debug directory in your home folder
mkdir -p ~/codex-debug-logs

# Navigate to it
cd ~/codex-debug-logs

# Confirm you're in the right place
pwd
```

**What this does:** Creates a dedicated folder for debug files, keeping them separate from your project.

### Step 4: Capture Basic System Information

Save your system info for reference:

```bash
# Save system information
cat > system-info.txt << 'EOF'
=== System Information ===
Date: $(date)
macOS Version: $(sw_vers -productVersion)
Architecture: $(uname -m)
Node Version: $(node --version)
Terminal: $TERM
TTY: $(tty)
Shell: $SHELL
EOF

# View the file
cat system-info.txt
```

**What this does:** Creates a text file with your Mac's configuration. Safe to share if you need help.

### Step 5: Check Codex Configuration

Let's see what Codex has configured:

```bash
# Check if Codex config directory exists
ls -la ~/.config/codex/

# If it exists, check the config file
if [ -f ~/.config/codex/config.toml ]; then
    echo "=== Config file exists ==="
    cat ~/.config/codex/config.toml
else
    echo "No config file yet (normal for first run)"
fi

# Check if there are any existing logs
if [ -d ~/.config/codex/logs ]; then
    echo "=== Existing logs ==="
    ls -lh ~/.config/codex/logs/
fi
```

**What this does:** Shows your current Codex configuration without modifying anything.

### Step 6: Run Codex with Debug Logging (Method 1: Simple)

Now let's try running Codex with debug output:

```bash
# Run Codex with debug logging enabled
RUST_LOG=debug codex 2>&1 | tee ~/codex-debug-logs/codex-debug-$(date +%Y%m%d-%H%M%S).log
```

**What this does:**
- `RUST_LOG=debug` → Enables detailed debug output
- `codex` → Runs the Codex CLI
- `2>&1` → Captures both normal output and errors
- `| tee ...` → Saves output to a timestamped file AND shows it on screen
- **Safe:** Only reads/logs, doesn't modify your system

**What to watch for:**
1. Does the terminal screen change? → **App is working!** Try interacting with it
2. Does it show a login screen? → **Normal!** Follow the prompts
3. Does it stop at a specific message? → **Note the last line** before it hangs
4. Press `Ctrl+C` to stop if it hangs

### Step 7: Run Codex with Maximum Logging (Method 2: Verbose)

If Step 6 didn't show enough detail, try this:

```bash
# Run with maximum verbosity
RUST_LOG=trace codex 2>&1 | tee ~/codex-debug-logs/codex-trace-$(date +%Y%m%d-%H%M%S).log
```

**What this does:**
- `RUST_LOG=trace` → Maximum detail (very verbose!)
- Everything else same as Method 1

**Warning:** This creates LARGE log files. Press `Ctrl+C` after 30 seconds if it hangs.

### Step 8: Check the Codex Log File

Codex also writes to its own log file. Let's check it:

```bash
# Watch the log file in real-time (in a second terminal window)
tail -f ~/.config/codex/logs/codex-tui.log
```

**How to use this:**
1. Open a **second terminal window**
2. Run the `tail -f` command above
3. In your **first terminal window**, run `codex`
4. Watch the second window for log messages
5. Press `Ctrl+C` in the second window to stop watching

### Step 9: Test Non-Interactive Mode

Let's see if Codex works in non-interactive mode:

```bash
# Try a simple non-interactive command
echo "What is 2+2?" | codex exec 2>&1 | tee ~/codex-debug-logs/codex-exec-test.log
```

**What this does:**
- Tests if Codex can run without the TUI
- If this works but TUI doesn't, it's a terminal compatibility issue

### Step 10: Check for Hanging Processes

If Codex appears stuck, let's see what it's doing:

```bash
# In a second terminal window, find the Codex process
ps aux | grep codex

# Check what files it has open
lsof -p <PID>  # Replace <PID> with the process ID from ps command

# Check network connections
lsof -i -n | grep codex
```

**What this does:**
- Shows if Codex is actually running
- Shows what files/network connections it's using
- Helps identify if it's waiting on network, disk, etc.

### Step 11: Collect All Debug Information

Let's gather everything into one place:

```bash
# Create a comprehensive debug report
cat > ~/codex-debug-logs/debug-report-$(date +%Y%m%d-%H%M%S).txt << 'EOF'
=== Codex CLI Debug Report ===
Generated: $(date)

--- System Info ---
macOS: $(sw_vers -productVersion)
Architecture: $(uname -m)
Node: $(node --version)
Terminal: $TERM
TTY: $(tty)

--- Codex Binary ---
$(which codex)
$(file $(which codex) 2>&1)

--- Codex Config ---
$(ls -la ~/.config/codex/ 2>&1)

--- Recent Logs (last 50 lines) ---
$(tail -n 50 ~/.config/codex/logs/codex-tui.log 2>&1)

--- Running Processes ---
$(ps aux | grep codex | grep -v grep)

--- Network Connectivity ---
$(curl -s -o /dev/null -w "OpenAI API: %{http_code}\n" https://api.openai.com 2>&1)

EOF

# View the report
cat ~/codex-debug-logs/debug-report-*.txt
```

**What this does:** Creates a comprehensive snapshot of your system state. Safe to share when asking for help.

---

## 🔍 Common Issues and What to Look For

### Issue 1: "Nothing happens, cursor just blinks"

**What to check in logs:**
```bash
grep -i "error\|panic\|failed" ~/codex-debug-logs/codex-debug-*.log
```

**Common causes:**
- Waiting for network response (check for "connecting" or "loading")
- Waiting for user input (look for "onboarding" or "login")
- Config file error (look for "config" or "toml")

### Issue 2: "stdin is not a terminal" error

**Fix:**
```bash
# Make sure you're running in a real terminal
[ -t 0 ] && echo "stdin OK" || echo "stdin NOT a terminal"

# If using SSH, connect with:
ssh -t user@host
```

### Issue 3: "TERM=dumb" warning

**Fix:**
```bash
# Set proper terminal type
export TERM=xterm-256color

# Add to your ~/.zshrc or ~/.bash_profile to make permanent
echo 'export TERM=xterm-256color' >> ~/.zshrc
```

### Issue 4: App shows login screen but you expected it to work

**This is normal!** First-time setup requires:
1. Authentication (sign in with ChatGPT or API key)
2. Directory trust confirmation
3. Provider selection (if using `--oss` flag)

**Not a bug** - just follow the on-screen prompts!

---

## 📊 Analyzing Your Logs

### What to look for in debug logs:

1. **Last successful operation:**
   ```bash
   grep "INFO\|DEBUG" ~/codex-debug-logs/codex-debug-*.log | tail -20
   ```

2. **Error messages:**
   ```bash
   grep -i "error\|panic\|failed\|timeout" ~/codex-debug-logs/codex-debug-*.log
   ```

3. **Network activity:**
   ```bash
   grep -i "http\|connect\|request\|api" ~/codex-debug-logs/codex-debug-*.log
   ```

4. **Config loading:**
   ```bash
   grep -i "config\|toml\|load" ~/codex-debug-logs/codex-debug-*.log
   ```

5. **Terminal initialization:**
   ```bash
   grep -i "terminal\|tui\|tty\|raw mode" ~/codex-debug-logs/codex-debug-*.log
   ```

---

## 🧪 Safe Testing Commands

These commands are safe to run and won't break anything:

```bash
# Test 1: Check version (should be instant)
codex --version

# Test 2: Show help (should be instant)
codex --help

# Test 3: Non-interactive execution (safe, exits when done)
echo "Hello" | codex exec

# Test 4: Run with timeout (auto-stops after 10 seconds)
timeout 10s codex

# Test 5: Check binary directly
~/.config/codex/bin/codex --version  # Or wherever your binary is
```

---

## 🛡️ Safety Notes

**These commands are SAFE:**
- ✅ Reading log files (`cat`, `tail`, `grep`)
- ✅ Checking processes (`ps`, `lsof`)
- ✅ Running with `RUST_LOG=debug` or `RUST_LOG=trace`
- ✅ Creating files in `~/codex-debug-logs/`
- ✅ Running `codex --help` or `codex --version`

**These commands are SAFE but will modify Codex config:**
- ⚠️ Running `codex` (may create config files on first run)
- ⚠️ Editing `~/.config/codex/config.toml`

**Avoid these unless you know what you're doing:**
- ❌ `sudo` commands (not needed for debugging)
- ❌ Deleting `~/.config/codex/` (you'll lose your settings)
- ❌ `kill -9` (use `Ctrl+C` instead)

---

## 📤 Sharing Debug Information

If you need to ask for help, share these files:

```bash
# Create a shareable debug package
cd ~/codex-debug-logs
tar -czf codex-debug-package-$(date +%Y%m%d).tar.gz *.log *.txt

# The file is now at:
ls -lh ~/codex-debug-logs/codex-debug-package-*.tar.gz
```

**Before sharing:**
- Review logs for sensitive information (API keys, passwords, personal data)
- Redact anything private using a text editor

---

## 🔄 Clean Up After Debugging

When you're done debugging:

```bash
# Remove debug logs (optional)
rm -rf ~/codex-debug-logs/

# Keep Codex config intact (don't delete this!)
# ~/.config/codex/
```

---

## 📞 Next Steps

After collecting logs:

1. **Review the logs yourself** using the "Analyzing Your Logs" section above
2. **Check common issues** in the "Common Issues" section
3. **Look at the last log message** before it hangs - that's usually the clue
4. **Try the safe testing commands** to narrow down the issue
5. **Share your debug package** if you need help from the community

---

## 🎓 Understanding the Launch Process

Codex CLI goes through these stages when launching:

1. **Binary Execution** (instant)
   - Node.js wrapper finds and runs the Rust binary
   
2. **Config Loading** (1-2 seconds)
   - Reads `~/.config/codex/config.toml`
   - May fetch cloud requirements (network call)
   
3. **Terminal Initialization** (instant)
   - Switches terminal to "raw mode"
   - Enables keyboard enhancements
   
4. **Onboarding/Login** (if first run)
   - Shows welcome screen
   - Requires user interaction
   
5. **Main TUI Loop** (continuous)
   - Displays interface
   - Waits for your input

**Most hangs occur at steps 2, 4, or 5** - check your logs to see which stage it reached!

---

## ✅ Success Indicators

You'll know Codex is working when:

- ✅ Your terminal screen changes (goes into TUI mode)
- ✅ You see a menu, prompt, or interface
- ✅ Cursor disappears or moves to a specific position
- ✅ You can interact with arrow keys or typing

**Remember:** There's no separate window - it all happens in your terminal!

---

## 📚 Additional Resources

- **Full debugging guide:** `DEBUGGING_GUIDE.md`
- **Launch analysis:** `APP_LAUNCH_ANALYSIS.md`
- **Automated diagnostic:** Run `./diagnose_launch.sh` (if in the repo)

---

**Last Updated:** February 11, 2026
