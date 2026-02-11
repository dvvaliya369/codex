# 🍎 Mac Debugging Resources - Start Here!

## 🎯 Which File Should I Read?

### 🚀 Just Want to Fix It Fast?

**→ Start with: [MAC_QUICK_START.md](MAC_QUICK_START.md)**

Quick reference with the most common solutions. 90% of issues are solved here.

**→ Then run: `./mac-debug-helper.sh`**

Interactive script that guides you through debugging step-by-step.

---

### 📖 Want Detailed Instructions?

**→ Read: [MAC_DEBUG_GUIDE.md](MAC_DEBUG_GUIDE.md)**

Complete step-by-step guide with detailed explanations of every command.

---

### 🗺️ Want a Visual Guide?

**→ See: [MAC_DEBUG_FLOWCHART.md](MAC_DEBUG_FLOWCHART.md)**

Visual flowchart showing decision trees and debugging paths.

---

### 📚 Want the Complete Overview?

**→ Read: [MAC_DEBUGGING_SUMMARY.md](MAC_DEBUGGING_SUMMARY.md)**

Comprehensive summary tying all resources together with quick reference.

---

### 🔧 Want to Understand the Technical Details?

**→ Read: [APP_LAUNCH_ANALYSIS.md](APP_LAUNCH_ANALYSIS.md)**

Deep technical analysis of the Codex CLI launch process.

---

### 🌐 Want General (Cross-Platform) Debugging Info?

**→ Read: [DEBUGGING_GUIDE.md](DEBUGGING_GUIDE.md)**

General debugging guide covering all platforms (Linux, Mac, Windows).

---

## 📁 All Available Resources

| File | Type | Purpose | Audience |
|------|------|---------|----------|
| **MAC_QUICK_START.md** | Guide | Quick reference and common solutions | Everyone - start here! |
| **mac-debug-helper.sh** | Script | Interactive debugging tool | Everyone - hands-on |
| **MAC_DEBUG_GUIDE.md** | Guide | Detailed step-by-step instructions | Users wanting details |
| **MAC_DEBUG_FLOWCHART.md** | Visual | Decision trees and flowcharts | Visual learners |
| **MAC_DEBUGGING_SUMMARY.md** | Reference | Complete overview and quick reference | Power users |
| **MAC_DEBUG_INDEX.md** | Index | This file - navigation guide | Everyone |
| **APP_LAUNCH_ANALYSIS.md** | Technical | Deep dive into launch process | Developers |
| **DEBUGGING_GUIDE.md** | Guide | General debugging (all platforms) | All users |
| **diagnose_launch.sh** | Script | Automated diagnostic script | Linux/Mac users |

---

## 🎓 Recommended Reading Order

### For First-Time Users

1. **MAC_QUICK_START.md** - Understand what Codex CLI is
2. **Run `./mac-debug-helper.sh`** - Quick diagnostic
3. **MAC_DEBUG_GUIDE.md** - If you need more help

### For Experienced Users

1. **Run `./mac-debug-helper.sh`** - Quick diagnostic
2. **MAC_DEBUGGING_SUMMARY.md** - Quick reference
3. **APP_LAUNCH_ANALYSIS.md** - If you need technical details

### For Developers/Contributors

1. **APP_LAUNCH_ANALYSIS.md** - Understand the codebase
2. **DEBUGGING_GUIDE.md** - General debugging approach
3. **MAC_DEBUG_GUIDE.md** - Mac-specific considerations

---

## 🚀 Quick Start (30 Seconds)

```bash
# 1. Run the diagnostic script
./mac-debug-helper.sh

# 2. Choose option 1 (Quick diagnostic)

# 3. If issues found, choose option 2 (Debug logging)

# 4. If still stuck, choose option 6 (Full debug report)
```

---

## ⚠️ Most Important Thing to Know

**Codex CLI is a Terminal User Interface (TUI), NOT a graphical application!**

- ✅ It runs **inside your terminal window**
- ❌ It does **NOT** open a separate window
- ✅ Your terminal screen changes when it launches
- ❌ Don't wait for a pop-up window

**90% of "stuck" issues are users expecting a separate window!**

---

## 🎯 Common Scenarios - Quick Links

| Scenario | What to Do |
|----------|------------|
| **First time running Codex** | Read [MAC_QUICK_START.md](MAC_QUICK_START.md) - Section "What to Expect" |
| **Nothing happens when I run `codex`** | Run `./mac-debug-helper.sh` option 2 |
| **Shows error message** | Check [MAC_DEBUG_GUIDE.md](MAC_DEBUG_GUIDE.md) - Section "Common Issues" |
| **Terminal freezes** | Check [MAC_DEBUG_FLOWCHART.md](MAC_DEBUG_FLOWCHART.md) - "Symptom: Terminal freezes" |
| **Shows login screen** | This is NORMAL! Follow the prompts. |
| **Need to report a bug** | Run `./mac-debug-helper.sh` option 6, then share the report |

---

## 📊 File Sizes and Reading Times

| File | Size | Reading Time |
|------|------|--------------|
| MAC_QUICK_START.md | ~8 KB | 5 minutes |
| MAC_DEBUG_GUIDE.md | ~25 KB | 15 minutes |
| MAC_DEBUG_FLOWCHART.md | ~15 KB | 10 minutes |
| MAC_DEBUGGING_SUMMARY.md | ~20 KB | 12 minutes |
| APP_LAUNCH_ANALYSIS.md | ~30 KB | 20 minutes |
| DEBUGGING_GUIDE.md | ~20 KB | 15 minutes |

**Total reading time if you read everything:** ~77 minutes  
**Recommended reading time:** 5-15 minutes (just the quick start and guide)

---

## 🛠️ Tools Available

### Interactive Script: `mac-debug-helper.sh`

```bash
./mac-debug-helper.sh
```

**Features:**
1. Quick diagnostic check
2. Run Codex with debug logging
3. Run Codex with trace logging (very verbose)
4. Check existing logs
5. Test non-interactive mode
6. Create full debug report
7. Watch live logs
8. Clean up debug files
9. Show help

**Safe:** All operations are non-destructive and won't break your system.

---

### Automated Diagnostic: `diagnose_launch.sh`

```bash
./diagnose_launch.sh
```

**Features:**
- Checks Node.js wrapper
- Verifies platform detection
- Tests binary execution
- Validates terminal environment
- Checks Codex configuration
- Tests network connectivity

**Note:** Originally designed for Linux but works on Mac too.

---

## 📞 Getting Help

### Self-Help (Try These First)

1. ✅ Read **MAC_QUICK_START.md**
2. ✅ Run `./mac-debug-helper.sh` (option 1)
3. ✅ Check `~/.config/codex/logs/codex-tui.log`
4. ✅ Try interacting with your terminal (arrow keys, Enter, Esc)

### Community Help (If Self-Help Doesn't Work)

1. ✅ Run `./mac-debug-helper.sh` (option 6) to create debug report
2. ✅ Review report and remove sensitive information
3. ✅ Share report with:
   - What you expected to happen
   - What actually happened
   - Steps to reproduce
   - System info (macOS version, architecture)

---

## 🎯 Success Indicators

You'll know Codex is working when:

- ✅ Terminal screen changes (goes into TUI mode)
- ✅ You see a menu, prompt, or interface
- ✅ Cursor disappears or moves to a specific position
- ✅ You can interact with arrow keys or typing
- ✅ Shows login/onboarding screen (normal for first run)

**Remember:** There's no separate window - it all happens in your terminal!

---

## 🔍 Quick Diagnostic Commands

```bash
# Check if Codex is installed
which codex

# Check version
codex --version

# Check Node.js
node --version

# Check terminal type
echo $TERM

# Check if terminal is interactive
[ -t 0 ] && echo "stdin OK" || echo "stdin NOT a terminal"
[ -t 1 ] && echo "stdout OK" || echo "stdout NOT a terminal"

# Check recent logs
tail -n 20 ~/.config/codex/logs/codex-tui.log

# Test non-interactive mode
echo "test" | codex exec
```

---

## 📁 Where Files Are Located

### Documentation (This Repository)

```
/path/to/codex-project/
├── MAC_DEBUG_INDEX.md              ← You are here
├── MAC_QUICK_START.md              ← Start here
├── mac-debug-helper.sh             ← Run this
├── MAC_DEBUG_GUIDE.md
├── MAC_DEBUG_FLOWCHART.md
├── MAC_DEBUGGING_SUMMARY.md
├── APP_LAUNCH_ANALYSIS.md
├── DEBUGGING_GUIDE.md
└── diagnose_launch.sh
```

### Codex Configuration (Your Mac)

```
~/.config/codex/
├── config.toml                     ← Configuration file
├── logs/
│   └── codex-tui.log              ← Main log file
├── sessions/                       ← Saved sessions
└── trust/                          ← Directory trust
```

### Debug Files (Created by Scripts)

```
~/codex-debug-logs/
├── codex-debug-TIMESTAMP.log       ← Debug logs
├── codex-trace-TIMESTAMP.log       ← Trace logs
├── codex-exec-test.log             ← Test logs
└── debug-report-TIMESTAMP.txt      ← Full reports
```

---

## 🎓 Learning Path

### Beginner Path

1. Read **MAC_QUICK_START.md** (5 min)
2. Run `./mac-debug-helper.sh` option 1 (1 min)
3. Try running `codex` (1 min)
4. If stuck, run option 2 for debug logging (2 min)

**Total time:** ~10 minutes

---

### Intermediate Path

1. Read **MAC_QUICK_START.md** (5 min)
2. Read **MAC_DEBUG_GUIDE.md** (15 min)
3. Run `./mac-debug-helper.sh` options 1-2 (3 min)
4. Analyze logs using guide (5 min)

**Total time:** ~30 minutes

---

### Advanced Path

1. Read **MAC_DEBUGGING_SUMMARY.md** (12 min)
2. Read **APP_LAUNCH_ANALYSIS.md** (20 min)
3. Run manual debug commands (10 min)
4. Deep log analysis (15 min)

**Total time:** ~60 minutes

---

## ✅ Checklist Before Asking for Help

- [ ] Read MAC_QUICK_START.md
- [ ] Run `./mac-debug-helper.sh` option 1
- [ ] Run `./mac-debug-helper.sh` option 2
- [ ] Checked `~/.config/codex/logs/codex-tui.log`
- [ ] Verified I'm looking at my terminal (not waiting for a window)
- [ ] Tried interacting with terminal (arrow keys, Enter, Esc)
- [ ] Checked if it's showing login/onboarding screen
- [ ] Tested non-interactive mode
- [ ] Created full debug report (option 6)
- [ ] Reviewed debug report for clues
- [ ] Searched existing documentation

---

## 🎉 You're All Set!

You now have a complete set of debugging resources for Codex CLI on Mac. Start with **MAC_QUICK_START.md** and use the **mac-debug-helper.sh** script for hands-on troubleshooting.

**Most important:** Remember that Codex CLI is a TUI that runs in your terminal, not a separate window!

Good luck! 🚀

---

**Last Updated:** February 11, 2026  
**Platform:** macOS  
**Maintained by:** Codex CLI Team
