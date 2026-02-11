# 🍎 Mac Debugging Resources for Codex CLI

## 📦 What's Included

This repository now includes a complete set of debugging resources specifically designed for Mac users experiencing Codex CLI launch issues.

### ✨ New Files Created

| File | Size | Description |
|------|------|-------------|
| **MAC_DEBUG_INDEX.md** | 9.4 KB | Navigation guide - start here to find the right resource |
| **MAC_QUICK_START.md** | 5.0 KB | Quick reference with common solutions (5 min read) |
| **MAC_DEBUG_GUIDE.md** | 12 KB | Detailed step-by-step debugging guide (15 min read) |
| **MAC_DEBUG_FLOWCHART.md** | 19 KB | Visual flowcharts and decision trees (10 min read) |
| **MAC_DEBUGGING_SUMMARY.md** | 15 KB | Comprehensive overview and quick reference (12 min read) |
| **mac-debug-helper.sh** | 16 KB | Interactive debugging script (executable) |

### 📚 Existing Resources

| File | Description |
|------|-------------|
| **DEBUGGING_GUIDE.md** | General debugging guide (all platforms) |
| **APP_LAUNCH_ANALYSIS.md** | Technical deep dive into launch process |
| **diagnose_launch.sh** | Automated diagnostic script (Linux-focused) |

---

## 🚀 Quick Start for Mac Users

### Step 1: Read the Quick Start Guide

```bash
# Open in your browser or text editor
open MAC_QUICK_START.md
# or
cat MAC_QUICK_START.md
```

**Reading time:** 5 minutes

### Step 2: Run the Interactive Helper Script

```bash
# Make sure you're in the project directory
cd /path/to/codex-project

# Run the helper script
./mac-debug-helper.sh

# Choose option 1 for quick diagnostic
```

**Time:** 1-2 minutes

### Step 3: Debug Based on Results

- **If diagnostic shows errors** → Fix them (script will guide you)
- **If no errors** → Run option 2 (debug logging)
- **If still stuck** → Run option 6 (full debug report)

---

## 🎯 Which File Should I Use?

### 🆘 "I just want to fix it!"

**→ [MAC_QUICK_START.md](MAC_QUICK_START.md)**

Quick solutions for 90% of common issues.

### 🔧 "I want step-by-step instructions"

**→ [MAC_DEBUG_GUIDE.md](MAC_DEBUG_GUIDE.md)**

Detailed guide with explanations for every command.

### 🗺️ "I'm a visual learner"

**→ [MAC_DEBUG_FLOWCHART.md](MAC_DEBUG_FLOWCHART.md)**

Flowcharts and decision trees to guide you.

### 📚 "I want the complete reference"

**→ [MAC_DEBUGGING_SUMMARY.md](MAC_DEBUGGING_SUMMARY.md)**

Comprehensive overview with all information in one place.

### 🤔 "I don't know where to start"

**→ [MAC_DEBUG_INDEX.md](MAC_DEBUG_INDEX.md)**

Navigation guide to help you find the right resource.

### 🛠️ "I want a tool to do it for me"

**→ `./mac-debug-helper.sh`**

Interactive script that guides you through debugging.

---

## ⚠️ Most Important Information

### Codex CLI is a TUI (Terminal User Interface)

**What this means:**
- ✅ Runs **inside your terminal window** (like `vim`, `htop`, `nano`)
- ❌ Does **NOT** open a separate window
- ✅ Your terminal screen changes when it launches
- ❌ Don't wait for a pop-up window

### 90% of "Stuck" Issues Are Actually:

1. **App IS running** and showing login/onboarding screen
2. **User expecting** a separate window (there isn't one!)
3. **User not looking** at their terminal window

### Quick Test:

```bash
# Run Codex
codex

# Look at your terminal window (not elsewhere!)
# Try pressing:
# - Arrow keys (↑ ↓ ← →)
# - Enter
# - Escape
# - Tab

# If you see any response → It's working!
```

---

## 🛠️ Interactive Helper Script Features

The `mac-debug-helper.sh` script provides:

1. **Quick diagnostic check** - Verify your system setup
2. **Debug logging** - Run Codex with detailed logs
3. **Trace logging** - Maximum verbosity for deep debugging
4. **Log viewer** - Check existing logs
5. **Non-interactive test** - Test Codex without TUI
6. **Full debug report** - Create comprehensive report for sharing
7. **Live log watching** - Monitor logs in real-time
8. **Cleanup** - Remove debug files when done
9. **Help** - Built-in help and guidance

### Usage:

```bash
./mac-debug-helper.sh
```

Then choose from the menu (1-9).

**Safe:** All operations are non-destructive and won't break your system.

---

## 📊 Common Scenarios

### Scenario 1: First Time Running Codex

**What happens:**
- Terminal switches to TUI mode
- Shows welcome/onboarding screen
- Asks for login (ChatGPT or API key)
- Asks to trust directory

**What to do:**
- Follow the on-screen prompts
- This is NORMAL, not a bug!

**Expected time:** 1-2 minutes

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

# Terminal 2: Run Codex with debug
RUST_LOG=debug codex
```

**Look for:**
- Last log message before hang
- Error messages
- Network activity

---

### Scenario 3: Shows Error Message

**Common errors:**

| Error | Fix |
|-------|-----|
| "stdin is not a terminal" | Use real terminal, not redirected I/O |
| "TERM=dumb" | `export TERM=xterm-256color` |
| "config.toml error" | Check `~/.config/codex/config.toml` |
| "Binary not found" | Reinstall Codex |

See [MAC_DEBUG_GUIDE.md](MAC_DEBUG_GUIDE.md) for detailed fixes.

---

## 📁 File Locations

### Documentation (This Repository)

```
/path/to/codex-project/
├── README_MAC_DEBUGGING.md         ← This file
├── MAC_DEBUG_INDEX.md              ← Navigation guide
├── MAC_QUICK_START.md              ← Quick reference
├── mac-debug-helper.sh             ← Interactive script
├── MAC_DEBUG_GUIDE.md              ← Detailed guide
├── MAC_DEBUG_FLOWCHART.md          ← Visual guide
├── MAC_DEBUGGING_SUMMARY.md        ← Complete reference
├── APP_LAUNCH_ANALYSIS.md          ← Technical analysis
├── DEBUGGING_GUIDE.md              ← General guide
└── diagnose_launch.sh              ← Diagnostic script
```

### Codex Configuration (Your Mac)

```
~/.config/codex/
├── config.toml                     ← Configuration
└── logs/
    └── codex-tui.log              ← Main log file
```

### Debug Files (Created by Scripts)

```
~/codex-debug-logs/
├── codex-debug-*.log               ← Debug logs
├── codex-trace-*.log               ← Trace logs
└── debug-report-*.txt              ← Full reports
```

---

## 🎓 Recommended Reading Order

### For First-Time Users (10 minutes)

1. **MAC_QUICK_START.md** (5 min) - Understand what Codex CLI is
2. **Run `./mac-debug-helper.sh`** (2 min) - Quick diagnostic
3. **Try running `codex`** (3 min) - See if it works

### For Troubleshooting (30 minutes)

1. **MAC_QUICK_START.md** (5 min) - Quick reference
2. **MAC_DEBUG_GUIDE.md** (15 min) - Detailed instructions
3. **Run `./mac-debug-helper.sh`** (5 min) - Debug logging
4. **Analyze logs** (5 min) - Find the issue

### For Deep Understanding (60 minutes)

1. **MAC_DEBUGGING_SUMMARY.md** (12 min) - Complete overview
2. **APP_LAUNCH_ANALYSIS.md** (20 min) - Technical details
3. **MAC_DEBUG_FLOWCHART.md** (10 min) - Visual guide
4. **Hands-on debugging** (18 min) - Practice with tools

---

## ✅ Success Checklist

Before asking for help, make sure you've:

- [ ] Read **MAC_QUICK_START.md**
- [ ] Run `./mac-debug-helper.sh` option 1 (diagnostic)
- [ ] Run `./mac-debug-helper.sh` option 2 (debug logging)
- [ ] Checked `~/.config/codex/logs/codex-tui.log`
- [ ] Verified you're looking at your terminal (not waiting for a window)
- [ ] Tried interacting with terminal (arrow keys, Enter, Esc)
- [ ] Checked if it's showing login/onboarding screen
- [ ] Tested non-interactive mode (`echo "test" | codex exec`)
- [ ] Created full debug report (option 6)
- [ ] Reviewed debug report for clues

---

## 🆘 Getting Help

### Self-Help Resources (Try First)

1. **MAC_QUICK_START.md** - Quick solutions
2. **mac-debug-helper.sh** - Interactive debugging
3. **MAC_DEBUG_GUIDE.md** - Detailed instructions
4. **~/.config/codex/logs/codex-tui.log** - Check logs

### Community Help (If Stuck)

1. Create debug report: `./mac-debug-helper.sh` (option 6)
2. Review and redact sensitive information
3. Share with:
   - Debug report file
   - What you expected vs what happened
   - Steps to reproduce
   - System info (macOS version, architecture)

---

## 🔐 Safety Notes

### All Commands Are Safe

✅ **Reading files:** `cat`, `tail`, `grep`, `less`  
✅ **Checking processes:** `ps`, `lsof`, `top`  
✅ **Running with logging:** `RUST_LOG=debug codex`  
✅ **Creating debug files:** in `~/codex-debug-logs/`  
✅ **Running scripts:** `./mac-debug-helper.sh`  

### No Destructive Operations

❌ **No `sudo` required** - All debugging is user-level  
❌ **No system modifications** - Only reads and logs  
❌ **No data deletion** - Debug files are separate  
❌ **No config changes** - Unless you explicitly choose to  

**You can safely run all commands and scripts without fear of breaking anything!**

---

## 📞 Quick Reference

### One-Line Commands

```bash
# Quick diagnostic
./mac-debug-helper.sh  # Choose option 1

# Debug run
RUST_LOG=debug codex 2>&1 | tee ~/debug-$(date +%Y%m%d-%H%M%S).log

# Watch logs
tail -f ~/.config/codex/logs/codex-tui.log

# Full report
./mac-debug-helper.sh  # Choose option 6

# Test non-interactive
echo "test" | codex exec

# Check version
codex --version
```

---

## 🎉 Summary

You now have a complete, safe, and comprehensive set of debugging resources for Codex CLI on Mac:

- **6 documentation files** covering everything from quick start to deep technical analysis
- **1 interactive script** that guides you through debugging step-by-step
- **All commands are safe** and won't break your system
- **Clear explanations** of what Codex CLI actually is (a TUI, not a GUI)
- **Common solutions** for 90% of issues
- **Tools for creating debug reports** to share when asking for help

**Start with [MAC_DEBUG_INDEX.md](MAC_DEBUG_INDEX.md) to find the right resource for your needs!**

---

**Created:** February 11, 2026  
**Platform:** macOS  
**Purpose:** Complete debugging guide for Codex CLI launch issues  
**Safe:** All operations are non-destructive  
**Maintained by:** Codex CLI Team

Good luck debugging! 🚀
