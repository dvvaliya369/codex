# Mac Debugging Summary: Complete Guide

## 📚 Documentation Overview

You now have a complete set of debugging resources for Codex CLI on Mac. Here's what each file does:

### 🎯 Start Here

| File | Purpose | When to Use |
|------|---------|-------------|
| **MAC_QUICK_START.md** | Quick reference guide | First stop for any issue |
| **mac-debug-helper.sh** | Interactive debugging script | Hands-on troubleshooting |
| **MAC_DEBUG_GUIDE.md** | Detailed step-by-step guide | Deep dive into debugging |
| **MAC_DEBUG_FLOWCHART.md** | Visual decision tree | Understanding the process |

### 📖 Additional Resources

| File | Purpose |
|------|---------|
| **DEBUGGING_GUIDE.md** | General debugging (all platforms) |
| **APP_LAUNCH_ANALYSIS.md** | Technical deep dive into launch process |
| **diagnose_launch.sh** | Automated diagnostic script (Linux-focused) |

---

## 🚀 Quick Start (3 Steps)

### Step 1: Run the Helper Script

```bash
cd /path/to/codex-project
./mac-debug-helper.sh
```

Choose option **1** for quick diagnostic.

### Step 2: Run with Debug Logging

In the same script, choose option **2** to run Codex with debug logging.

### Step 3: Analyze the Results

- If terminal screen changes → **Success!** Codex is working.
- If shows login screen → **Normal!** Follow the prompts.
- If hangs → Check the log file created in `~/codex-debug-logs/`

---

## 🎓 Understanding Codex CLI

### What It Is

- **Terminal User Interface (TUI)** application
- Runs **inside your terminal window**
- Like `vim`, `htop`, `nano`, or `top`
- Uses the full terminal screen

### What It's NOT

- ❌ NOT a graphical application
- ❌ Does NOT open a separate window
- ❌ Does NOT have a GUI
- ❌ Does NOT run in the background

### How It Looks When Working

```
Before running 'codex':
┌─────────────────────────────────────┐
│ $ codex                             │
│ █                                   │  ← Your cursor
│                                     │
│                                     │
└─────────────────────────────────────┘

After running 'codex' (TUI mode):
┌─────────────────────────────────────┐
│ ╔═══════════════════════════════╗   │
│ ║   Codex CLI                   ║   │  ← Full screen interface
│ ║                               ║   │
│ ║   [Login Screen]              ║   │
│ ║   or [Main Interface]         ║   │
│ ║                               ║   │
│ ╚═══════════════════════════════╝   │
└─────────────────────────────────────┘
```

---

## 🔍 Common Scenarios

### Scenario 1: First Time Running Codex

**What you'll see:**
1. Terminal switches to TUI mode
2. Welcome/onboarding screen appears
3. Login prompt (ChatGPT or API key)
4. Directory trust confirmation

**What to do:**
- Follow the on-screen prompts
- Use arrow keys to navigate
- Press Enter to select
- Complete authentication

**Expected time:** 1-2 minutes

**This is NORMAL, not a bug!**

---

### Scenario 2: "Nothing Happens"

**What you see:**
- Cursor blinks
- No visible change
- Process seems stuck

**What to do:**

```bash
# Terminal 1: Watch logs
tail -f ~/.config/codex/logs/codex-tui.log

# Terminal 2: Run Codex
RUST_LOG=debug codex
```

**Look for:**
- Last log message before hang
- Error messages
- Network activity
- "Waiting for..." messages

**Common causes:**
- Network request (loading cloud requirements)
- Config file parsing
- Model download (if using --oss)
- Waiting for user input (not visible)

---

### Scenario 3: Shows Error Message

**Common errors and fixes:**

| Error | Cause | Fix |
|-------|-------|-----|
| "stdin is not a terminal" | Not running in real terminal | Use Terminal.app, not redirected I/O |
| "stdout is not a terminal" | Output is redirected | Run directly in terminal |
| "TERM=dumb" | Terminal type not set | `export TERM=xterm-256color` |
| "config.toml error" | Invalid config syntax | Check `~/.config/codex/config.toml` |
| "Binary not found" | Installation issue | Reinstall Codex |
| "Permission denied" | File permissions | `chmod +x` on binary |

---

### Scenario 4: Hangs During Launch

**Debugging steps:**

1. **Identify where it hangs:**
   ```bash
   RUST_LOG=debug codex 2>&1 | tee ~/debug.log
   # Wait 30 seconds, then Ctrl+C
   tail ~/debug.log
   ```

2. **Check the last operation:**
   - "Loading config" → Config file issue
   - "Connecting to" → Network issue
   - "Initializing terminal" → Terminal compatibility
   - "Waiting for model" → OSS model download (can take 10+ minutes)

3. **Test non-interactive mode:**
   ```bash
   echo "test" | codex exec
   ```
   If this works, it's a TUI-specific issue.

4. **Check running processes:**
   ```bash
   ps aux | grep codex
   lsof -p <PID>  # Replace <PID> with process ID
   ```

---

## 📊 Debug Information to Collect

### Minimal Debug Info

```bash
# System info
sw_vers -productVersion
uname -m
node --version
echo $TERM

# Codex info
which codex
codex --version

# Recent logs
tail -n 50 ~/.config/codex/logs/codex-tui.log
```

### Full Debug Report

```bash
./mac-debug-helper.sh
# Choose option 6

# Creates: ~/codex-debug-logs/debug-report-TIMESTAMP.txt
```

### Debug Logs

```bash
# Run with debug logging
RUST_LOG=debug codex 2>&1 | tee ~/codex-debug-logs/debug-$(date +%Y%m%d-%H%M%S).log

# Or use the helper script
./mac-debug-helper.sh
# Choose option 2
```

---

## 🛠️ Troubleshooting Tools

### Tool 1: Interactive Helper Script

```bash
./mac-debug-helper.sh
```

**Features:**
- Quick diagnostic (option 1)
- Debug logging (option 2)
- Trace logging (option 3)
- Log viewer (option 4)
- Non-interactive test (option 5)
- Full debug report (option 6)
- Live log watching (option 7)
- Cleanup (option 8)

**Best for:** Most users, guided troubleshooting

---

### Tool 2: Manual Commands

```bash
# Quick check
codex --version

# Debug run
RUST_LOG=debug codex

# Trace run (very verbose)
RUST_LOG=trace codex

# Non-interactive test
echo "test" | codex exec

# Watch logs
tail -f ~/.config/codex/logs/codex-tui.log

# Check processes
ps aux | grep codex

# Check network
curl -v https://api.openai.com
```

**Best for:** Experienced users, quick tests

---

### Tool 3: Log Analysis

```bash
# Find errors
grep -i "error\|panic\|failed" ~/.config/codex/logs/codex-tui.log

# Last 20 lines
tail -n 20 ~/.config/codex/logs/codex-tui.log

# Network activity
grep -i "http\|connect\|api" ~/.config/codex/logs/codex-tui.log

# Config loading
grep -i "config\|toml" ~/.config/codex/logs/codex-tui.log

# Terminal init
grep -i "terminal\|tui\|raw" ~/.config/codex/logs/codex-tui.log
```

**Best for:** Analyzing what went wrong

---

## 🎯 Decision Tree

```
Problem: Codex won't launch or appears stuck
│
├─ Is this your first time running Codex?
│  ├─ YES → Expect login/onboarding (NORMAL)
│  └─ NO  → Continue...
│
├─ Does the terminal screen change at all?
│  ├─ YES → Codex is working! Interact with it.
│  ├─ Shows login → Follow prompts (NORMAL)
│  └─ NO  → Continue...
│
├─ Run: ./mac-debug-helper.sh (option 1)
│  ├─ Shows errors → Fix them
│  └─ No errors → Continue...
│
├─ Run: ./mac-debug-helper.sh (option 2)
│  ├─ Hangs → Note last log message
│  ├─ Shows error → Fix it
│  └─ Works → Success!
│
└─ Still stuck?
   ├─ Create debug report (option 6)
   ├─ Review MAC_DEBUG_GUIDE.md
   └─ Ask for help with debug report
```

---

## 📁 File Locations Reference

### Codex Configuration

```
~/.config/codex/
├── config.toml              # Main configuration file
├── logs/
│   └── codex-tui.log        # Application log file
├── sessions/                # Saved chat sessions
└── trust/                   # Directory trust settings
```

### Debug Files (Created by Helper Script)

```
~/codex-debug-logs/
├── codex-debug-TIMESTAMP.log      # Debug run logs
├── codex-trace-TIMESTAMP.log      # Trace run logs
├── codex-exec-test.log            # Non-interactive test
└── debug-report-TIMESTAMP.txt     # Full debug report
```

### Project Files

```
/path/to/codex-project/
├── mac-debug-helper.sh            # Interactive helper script
├── MAC_QUICK_START.md             # Quick reference
├── MAC_DEBUG_GUIDE.md             # Detailed guide
├── MAC_DEBUG_FLOWCHART.md         # Visual flowchart
├── MAC_DEBUGGING_SUMMARY.md       # This file
├── DEBUGGING_GUIDE.md             # General guide
├── APP_LAUNCH_ANALYSIS.md         # Technical analysis
└── diagnose_launch.sh             # Diagnostic script
```

---

## 🔐 Safety Notes

### Safe Commands (Won't Break Anything)

✅ Reading files: `cat`, `tail`, `grep`, `less`  
✅ Checking processes: `ps`, `lsof`, `top`  
✅ Running with logging: `RUST_LOG=debug codex`  
✅ Creating debug files in `~/codex-debug-logs/`  
✅ Running helper script: `./mac-debug-helper.sh`  
✅ Checking version: `codex --version`  
✅ Getting help: `codex --help`  

### Caution Commands (Will Modify Config)

⚠️ Running `codex` (creates config on first run)  
⚠️ Editing `~/.config/codex/config.toml`  
⚠️ Deleting `~/.config/codex/` (loses settings)  

### Avoid Unless Necessary

❌ `sudo` commands (not needed for debugging)  
❌ `kill -9` (use `Ctrl+C` instead)  
❌ Deleting system files  
❌ Modifying system settings  

---

## 📤 Sharing Debug Information

### Before Sharing

1. **Review for sensitive data:**
   - API keys
   - Passwords
   - Personal information
   - Private file paths

2. **Redact if needed:**
   ```bash
   # Open in text editor
   nano ~/codex-debug-logs/debug-report-*.txt
   
   # Replace sensitive info with [REDACTED]
   ```

### What to Share

- Debug report file
- Last 50 lines of log before hang
- Error messages (full text)
- System info (macOS version, architecture)
- What you expected vs what happened
- Steps to reproduce

### How to Share

```bash
# Create a package
cd ~/codex-debug-logs
tar -czf codex-debug-$(date +%Y%m%d).tar.gz *.log *.txt

# Upload to file sharing service or attach to issue
```

---

## ✅ Success Checklist

Before asking for help, make sure you've:

- [ ] Read MAC_QUICK_START.md
- [ ] Run `./mac-debug-helper.sh` option 1 (diagnostic)
- [ ] Run `./mac-debug-helper.sh` option 2 (debug logging)
- [ ] Checked `~/.config/codex/logs/codex-tui.log`
- [ ] Verified you're looking at your terminal (not waiting for a window)
- [ ] Tried interacting with the terminal (arrow keys, Enter, Esc)
- [ ] Checked if it's showing a login/onboarding screen
- [ ] Tested non-interactive mode (`echo "test" | codex exec`)
- [ ] Created a full debug report (option 6)
- [ ] Reviewed the debug report for clues
- [ ] Searched existing issues/documentation

---

## 🎓 Learning Resources

### Understanding TUI Applications

- **What is a TUI?** Terminal User Interface - runs in terminal, not a separate window
- **Examples:** vim, nano, htop, top, tmux, ranger
- **How to exit:** Usually `Ctrl+C`, `Esc`, or `:q` (depends on app)
- **How to interact:** Keyboard only (arrow keys, Enter, letters)

### Understanding Codex Launch Process

1. **Binary Execution** (instant)
2. **Config Loading** (1-2 seconds)
3. **Terminal Initialization** (instant)
4. **Onboarding/Login** (if first run, requires interaction)
5. **Main TUI Loop** (continuous, waiting for input)

See **APP_LAUNCH_ANALYSIS.md** for technical details.

---

## 🆘 Getting Help

### Self-Help Resources

1. **MAC_QUICK_START.md** - Quick reference
2. **MAC_DEBUG_GUIDE.md** - Detailed guide
3. **MAC_DEBUG_FLOWCHART.md** - Visual guide
4. **DEBUGGING_GUIDE.md** - General debugging
5. **APP_LAUNCH_ANALYSIS.md** - Technical deep dive

### Community Help

1. Create debug report: `./mac-debug-helper.sh` (option 6)
2. Review and redact sensitive info
3. Share with:
   - Debug report file
   - Steps to reproduce
   - Expected vs actual behavior
   - System info

---

## 🎯 Most Common Solutions

### 90% of Issues

**Problem:** "Codex won't launch" or "appears stuck"

**Actual situation:**
- Codex IS running
- Showing login/onboarding screen
- User expecting separate window
- User not looking at terminal

**Solution:**
1. Look at your terminal window
2. Try pressing arrow keys, Enter, or Esc
3. If you see any response → It's working!
4. Follow the on-screen prompts

---

### 5% of Issues

**Problem:** Actual hang during launch

**Common causes:**
- Network request timeout
- Config file error
- OSS model download (takes 10+ minutes)

**Solution:**
1. Check logs for last operation
2. Fix network/config issue
3. Be patient for model downloads
4. Or skip OSS mode

---

### 5% of Issues

**Problem:** Terminal compatibility

**Common causes:**
- TERM=dumb
- stdin/stdout not a terminal
- Unsupported terminal emulator

**Solution:**
1. `export TERM=xterm-256color`
2. Use real terminal (Terminal.app or iTerm2)
3. Don't redirect I/O

---

## 📅 Maintenance

### Cleaning Up Debug Files

```bash
# Remove debug logs
rm -rf ~/codex-debug-logs/

# Keep Codex config (don't delete!)
# ~/.config/codex/
```

### Resetting Codex Config

```bash
# Backup first
mv ~/.config/codex ~/.config/codex.backup

# Run Codex (creates fresh config)
codex

# If it works, delete backup
rm -rf ~/.config/codex.backup

# If not, restore
rm -rf ~/.config/codex
mv ~/.config/codex.backup ~/.config/codex
```

---

## 📞 Quick Reference

### One-Line Diagnostic

```bash
./mac-debug-helper.sh
```

### One-Line Debug Run

```bash
RUST_LOG=debug codex 2>&1 | tee ~/debug-$(date +%Y%m%d-%H%M%S).log
```

### One-Line Log Check

```bash
tail -f ~/.config/codex/logs/codex-tui.log
```

### One-Line Full Report

```bash
./mac-debug-helper.sh  # Choose option 6
```

---

**Created:** February 11, 2026  
**Platform:** macOS  
**Purpose:** Complete debugging guide for Codex CLI launch issues  
**Safe:** All recommended commands are non-destructive

---

## 🎉 You're Ready!

You now have everything you need to debug Codex CLI launch issues on your Mac safely and effectively. Start with **MAC_QUICK_START.md** and use the **mac-debug-helper.sh** script for hands-on troubleshooting.

**Remember:** Most "stuck" issues are just the app waiting for you to interact with it in your terminal!

Good luck! 🚀
