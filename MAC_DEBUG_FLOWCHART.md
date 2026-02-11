# Mac Debug Flowchart: Codex CLI Launch Issues

## 🗺️ Visual Guide to Debugging

```
┌─────────────────────────────────────────────────────────────┐
│  START: Codex CLI won't launch or appears stuck on Mac     │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  STEP 1: Understand what Codex CLI actually is             │
│                                                             │
│  ❓ Are you expecting a separate window to open?           │
└─────────────────────────────────────────────────────────────┘
                            │
                ┌───────────┴───────────┐
                │                       │
               YES                     NO
                │                       │
                ▼                       ▼
┌───────────────────────────┐  ┌──────────────────────────┐
│  ⚠️  MISCONCEPTION!       │  │  ✅ Good! Continue...    │
│                           │  └──────────────────────────┘
│  Codex is a TUI app       │              │
│  (Terminal User Interface)│              │
│                           │              │
│  It runs INSIDE your      │              │
│  terminal window, like    │              │
│  vim or nano.             │              │
│                           │              │
│  NO separate window       │              │
│  will open!               │              │
└───────────────────────────┘              │
                │                          │
                └──────────┬───────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  STEP 2: Run Quick Diagnostic                               │
│                                                             │
│  $ ./mac-debug-helper.sh                                    │
│  Choose option: 1 (Quick diagnostic check)                  │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Did the diagnostic show any RED ✗ errors?                  │
└─────────────────────────────────────────────────────────────┘
                            │
                ┌───────────┴───────────┐
                │                       │
               YES                     NO
                │                       │
                ▼                       ▼
┌───────────────────────────┐  ┌──────────────────────────┐
│  Fix the errors:          │  │  System looks good!      │
│                           │  │  Continue to Step 3...   │
│  • Node.js < 16?          │  └──────────────────────────┘
│    → Update Node.js       │              │
│                           │              │
│  • Binary not found?      │              │
│    → Reinstall Codex      │              │
│                           │              │
│  • stdin not terminal?    │              │
│    → Use real terminal    │              │
│                           │              │
│  • TERM=dumb?             │              │
│    → export TERM=xterm... │              │
└───────────────────────────┘              │
                │                          │
                └──────────┬───────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  STEP 3: Run with Debug Logging                             │
│                                                             │
│  $ ./mac-debug-helper.sh                                    │
│  Choose option: 2 (Run Codex with debug logging)            │
│                                                             │
│  OR manually:                                               │
│  $ RUST_LOG=debug codex 2>&1 | tee ~/debug.log             │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  What happened when you ran Codex?                          │
└─────────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
┌──────────────┐  ┌──────────────────┐  ┌─────────────────┐
│ Terminal     │  │ Shows login/     │  │ Nothing visible,│
│ screen       │  │ welcome screen   │  │ cursor blinks   │
│ changed,     │  │ or menu          │  │ or hangs        │
│ showing UI   │  │                  │  │                 │
└──────────────┘  └──────────────────┘  └─────────────────┘
        │                   │                   │
        ▼                   ▼                   ▼
┌──────────────┐  ┌──────────────────┐  ┌─────────────────┐
│ ✅ SUCCESS!  │  │ ✅ NORMAL!       │  │ ⚠️  ISSUE       │
│              │  │                  │  │                 │
│ Codex is     │  │ First-time setup │  │ App is stuck    │
│ working!     │  │ requires:        │  │                 │
│              │  │                  │  │ Go to STEP 4    │
│ Use arrow    │  │ 1. Login/auth    │  └─────────────────┘
│ keys and     │  │ 2. Trust prompt  │          │
│ interact     │  │ 3. Provider pick │          │
│              │  │                  │          │
│ You're done! │  │ Follow prompts!  │          │
└──────────────┘  └──────────────────┘          │
                           │                    │
                           └────────────────────┘
                                      ▼
┌─────────────────────────────────────────────────────────────┐
│  STEP 4: Analyze Where It's Stuck                           │
│                                                             │
│  Open TWO terminal windows:                                 │
│                                                             │
│  Terminal 1:                                                │
│  $ tail -f ~/.config/codex/logs/codex-tui.log              │
│                                                             │
│  Terminal 2:                                                │
│  $ RUST_LOG=debug codex                                     │
│                                                             │
│  Watch Terminal 1 to see where it stops                     │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  What's the last message in the log before it hangs?        │
└─────────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┬─────────────┐
        │                   │                   │             │
        ▼                   ▼                   ▼             ▼
┌──────────────┐  ┌──────────────────┐  ┌─────────────┐  ┌────────────┐
│ "Loading     │  │ "Connecting to"  │  │ "Waiting    │  │ "Terminal  │
│  config"     │  │ or "Fetching"    │  │  for model" │  │  init" or  │
│              │  │                  │  │             │  │ "Raw mode" │
└──────────────┘  └──────────────────┘  └─────────────┘  └────────────┘
        │                   │                   │             │
        ▼                   ▼                   ▼             ▼
┌──────────────┐  ┌──────────────────┐  ┌─────────────┐  ┌────────────┐
│ Config Issue │  │ Network Issue    │  │ OSS Model   │  │ Terminal   │
│              │  │                  │  │ Download    │  │ Issue      │
│ Check:       │  │ Check:           │  │             │  │            │
│ • config.toml│  │ • Internet conn. │  │ This can    │  │ Check:     │
│ • Syntax err │  │ • Firewall       │  │ take 10+    │  │ • TERM var │
│ • Permissions│  │ • VPN            │  │ minutes!    │  │ • TTY      │
│              │  │ • API access     │  │             │  │ • Raw mode │
│ Fix:         │  │                  │  │ Be patient  │  │   support  │
│ • Validate   │  │ Fix:             │  │ or Ctrl+C   │  │            │
│   TOML       │  │ • Test: curl     │  │ and skip    │  │ Fix:       │
│ • Check logs │  │   api.openai.com │  │ OSS mode    │  │ • Different│
│ • Recreate   │  │ • Check proxy    │  │             │  │   terminal │
│   config     │  │ • Disable VPN    │  │             │  │ • Update   │
└──────────────┘  └──────────────────┘  └─────────────┘  └────────────┘
        │                   │                   │             │
        └───────────────────┴───────────────────┴─────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  STEP 5: Create Full Debug Report                           │
│                                                             │
│  $ ./mac-debug-helper.sh                                    │
│  Choose option: 6 (Create full debug report)                │
│                                                             │
│  This creates: ~/codex-debug-logs/debug-report-*.txt        │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  STEP 6: Review and Share                                   │
│                                                             │
│  1. Review the debug report                                 │
│  2. Remove any sensitive information                        │
│  3. Share with the community or support                     │
│                                                             │
│  Include:                                                   │
│  • Debug report file                                        │
│  • Last log message before hang                             │
│  • What you expected vs what happened                       │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
                    ┌───────────────┐
                    │   RESOLVED!   │
                    └───────────────┘
```

---

## 🎯 Quick Decision Tree

**Start here:**

```
Is this your first time running Codex?
│
├─ YES → Expect login/onboarding screens
│         This is NORMAL, not a bug!
│         Follow the on-screen prompts.
│
└─ NO  → Did it work before?
          │
          ├─ YES → What changed?
          │         • Updated Codex?
          │         • Changed terminal?
          │         • New macOS version?
          │         • Network/VPN changes?
          │
          └─ NO  → Run diagnostic:
                    ./mac-debug-helper.sh (option 1)
```

---

## 🔍 Symptom-Based Quick Guide

### Symptom: "Nothing happens at all"

```
1. Check if process is running:
   $ ps aux | grep codex

2. If running → Check logs:
   $ tail -f ~/.config/codex/logs/codex-tui.log

3. If not running → Check binary:
   $ codex --version
```

### Symptom: "Terminal freezes"

```
1. Press Ctrl+C to stop

2. Run with timeout:
   $ timeout 30s codex

3. Check where it stops:
   $ RUST_LOG=debug codex 2>&1 | tee debug.log
   (Ctrl+C after 30 seconds)
   $ tail debug.log
```

### Symptom: "Shows error message"

```
1. Read the error carefully

2. Common errors:
   • "stdin is not a terminal"
     → Run in real terminal, not redirected

   • "TERM=dumb"
     → export TERM=xterm-256color

   • "config.toml error"
     → Check ~/.config/codex/config.toml syntax

   • "Binary not found"
     → Reinstall Codex
```

### Symptom: "Shows login screen but I'm already logged in"

```
This is NORMAL if:
• First time in this directory
• Directory trust not confirmed
• Session expired

Just follow the prompts!
```

---

## 📊 Log Analysis Guide

### What to look for in logs:

```
GOOD signs (normal operation):
✅ "Loading config from..."
✅ "Terminal initialized"
✅ "Starting TUI"
✅ "Event loop started"

WARNING signs (might be normal):
⚠️  "Waiting for user input"
⚠️  "Onboarding required"
⚠️  "Authentication needed"

BAD signs (actual issues):
❌ "Error loading config"
❌ "Failed to initialize terminal"
❌ "Connection timeout"
❌ "Panic" or "Fatal error"
```

### How to search logs:

```bash
# Find errors
grep -i "error\|panic\|failed" ~/.config/codex/logs/codex-tui.log

# Find last operation
tail -n 20 ~/.config/codex/logs/codex-tui.log

# Find network activity
grep -i "http\|connect\|api" ~/.config/codex/logs/codex-tui.log

# Find config loading
grep -i "config\|toml" ~/.config/codex/logs/codex-tui.log
```

---

## 🛠️ Emergency Fixes

### Nuclear Option 1: Reset Config

```bash
# Backup first!
mv ~/.config/codex ~/.config/codex.backup

# Run Codex (will create fresh config)
codex

# If it works, you had a config issue
# If not, restore backup:
rm -rf ~/.config/codex
mv ~/.config/codex.backup ~/.config/codex
```

### Nuclear Option 2: Reinstall Codex

```bash
# Uninstall (method depends on how you installed)
npm uninstall -g codex-cli
# or
brew uninstall codex
# or
rm -rf /path/to/codex

# Reinstall
npm install -g codex-cli
# or
brew install codex
```

### Nuclear Option 3: Different Terminal

```bash
# Try a different terminal app:
# • Terminal.app (default)
# • iTerm2
# • Alacritty
# • Kitty

# Or try a different shell:
bash
# then run: codex
```

---

**Remember:** 90% of issues are just misunderstanding what Codex CLI is (a TUI, not a GUI)!
