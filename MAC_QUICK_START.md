# 🍎 Mac Quick Start: Debug Codex CLI Launch Issues

## TL;DR - Start Here!

If Codex CLI won't launch or appears stuck on your Mac, run this:

```bash
./mac-debug-helper.sh
```

Choose option **1** for a quick diagnostic, then option **2** to run with debug logging.

---

## 🚀 Three Ways to Debug

### Option 1: Interactive Helper Script (Recommended)

```bash
# Make sure you're in the project directory
cd /path/to/codex-project

# Run the helper script
./mac-debug-helper.sh

# Choose from the menu:
# 1 = Quick check
# 2 = Run with debug logs
# 6 = Full debug report
```

**Best for:** Most users, especially if you're not comfortable with command line.

---

### Option 2: Manual Debug Commands

```bash
# Create a folder for logs
mkdir -p ~/codex-debug-logs

# Run Codex with debug logging
RUST_LOG=debug codex 2>&1 | tee ~/codex-debug-logs/debug-$(date +%Y%m%d-%H%M%S).log

# Press Ctrl+C if it hangs
# Then check the log file in ~/codex-debug-logs/
```

**Best for:** Quick one-off debugging.

---

### Option 3: Watch Logs in Real-Time

**Terminal 1:**
```bash
# Watch the log file
tail -f ~/.config/codex/logs/codex-tui.log
```

**Terminal 2:**
```bash
# Run Codex
codex
```

**Best for:** Seeing exactly where it gets stuck.

---

## ⚠️ Important: What to Expect

### Codex CLI is NOT a separate window app!

- ✅ It runs **inside your terminal** (like `vim` or `nano`)
- ❌ No separate window will open
- ✅ Your terminal screen will change when it launches
- ❌ Don't wait for a pop-up window

### First-time launch requires interaction:

1. **Login screen** → Sign in with ChatGPT or API key
2. **Trust prompt** → Confirm you trust the directory
3. **Provider selection** → Choose AI provider (if using `--oss`)

**This is normal!** Just follow the on-screen prompts.

---

## 🔍 Common Issues

### "Nothing happens, just a blinking cursor"

**Likely cause:** Waiting for network, config loading, or user input.

**Fix:**
```bash
# Check what it's doing
./mac-debug-helper.sh
# Choose option 7 (Watch live logs)
```

---

### "stdin is not a terminal" error

**Likely cause:** Running in a non-interactive environment.

**Fix:**
```bash
# Make sure you're in a real terminal
[ -t 0 ] && echo "OK" || echo "Problem!"

# If using SSH:
ssh -t user@host
```

---

### "TERM=dumb" warning

**Likely cause:** Terminal type not set correctly.

**Fix:**
```bash
# Set proper terminal type
export TERM=xterm-256color

# Make it permanent
echo 'export TERM=xterm-256color' >> ~/.zshrc
source ~/.zshrc
```

---

### App shows login screen but I expected it to work

**This is normal!** First run requires:
- Authentication
- Directory trust confirmation

**Not a bug** - just follow the prompts!

---

## 📊 Where Are My Logs?

### Debug logs (created by helper script):
```
~/codex-debug-logs/
├── codex-debug-20260211-143022.log
├── codex-trace-20260211-143045.log
└── debug-report-20260211-143100.txt
```

### Codex application logs:
```
~/.config/codex/
├── config.toml              # Configuration
└── logs/
    └── codex-tui.log        # Main log file
```

---

## 🛠️ Quick Diagnostic Commands

```bash
# Check if Codex is installed
which codex

# Check Node.js version (needs >= 16)
node --version

# Check terminal type
echo $TERM

# Test Codex binary
codex --version

# Test non-interactive mode
echo "Hello" | codex exec
```

---

## 📦 Create a Debug Package to Share

```bash
# Run the helper script
./mac-debug-helper.sh

# Choose option 6 (Full debug report)

# The report is saved to:
# ~/codex-debug-logs/debug-report-TIMESTAMP.txt

# Review it for sensitive info, then share!
```

---

## 🆘 Still Stuck?

1. **Read the detailed guide:** `MAC_DEBUG_GUIDE.md`
2. **Check existing docs:** `DEBUGGING_GUIDE.md` and `APP_LAUNCH_ANALYSIS.md`
3. **Run the diagnostic script:** `./diagnose_launch.sh` (Linux-focused but still useful)
4. **Create a debug report:** Use option 6 in `mac-debug-helper.sh`

---

## ✅ Success Checklist

Before asking for help, make sure you've tried:

- [ ] Run `./mac-debug-helper.sh` option 1 (Quick diagnostic)
- [ ] Run `./mac-debug-helper.sh` option 2 (Debug logging)
- [ ] Check `~/.config/codex/logs/codex-tui.log` for errors
- [ ] Verify you're looking at your terminal (not waiting for a window)
- [ ] Try interacting with the terminal (arrow keys, Enter, Esc)
- [ ] Check if it's showing a login/onboarding screen
- [ ] Create a full debug report (option 6)

---

## 🎯 Most Common Solution

**90% of "stuck" issues are actually:**

1. The app IS running and showing a login/onboarding screen
2. User is expecting a separate window (there isn't one!)
3. User isn't looking at their terminal

**Try this:**
1. Run `codex` in your terminal
2. **Look at that same terminal window**
3. Try pressing arrow keys, Enter, or Esc
4. If you see any response → **It's working!** Follow the prompts.

---

**Created:** February 11, 2026  
**For:** macOS users debugging Codex CLI launch issues  
**Safe:** All commands are non-destructive and won't break your system
