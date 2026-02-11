# Codex CLI Launch Flow - Visual Diagram

## Complete Launch Sequence with Blocking Points

```
┌─────────────────────────────────────────────────────────────────┐
│ USER RUNS: codex                                                 │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ Node.js Wrapper (codex.js)                                       │
│ ─────────────────────────────────────────────────────────────── │
│ • Detects platform (Linux/macOS/Windows)                         │
│ • Detects architecture (x64/arm64)                               │
│ • Constructs binary path                                         │
│ • Spawns native binary with inherited stdio                      │
│                                                                   │
│ ⚠️  FAILURE POINT: Binary not found or not executable            │
│    Location: codex-cli/bin/codex.js:119                          │
│    Error: "spawn ENOENT" or permission denied                    │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ Rust Binary Starts (main.rs)                                     │
│ ─────────────────────────────────────────────────────────────── │
│ • Parses command-line arguments with clap                        │
│ • Determines subcommand or interactive mode                      │
│ • Validates feature flags                                        │
│                                                                   │
│ ⚠️  FAILURE POINT: Invalid arguments                             │
│    Location: codex-rs/cli/src/main.rs:127                        │
│    Error: Argument parsing error, exits with help message        │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ Config Loading Phase (lib.rs:127-220)                            │
│ ─────────────────────────────────────────────────────────────── │
│ • find_codex_home() → ~/.config/codex/                           │
│ • load_config_as_toml_with_cli_overrides()                       │
│   - Reads config.toml                                            │
│   - Applies CLI overrides (-c flags)                             │
│   - Validates TOML syntax                                        │
│ • cloud_requirements_loader()                                    │
│   - Makes network call to ChatGPT API                            │
│   - Fetches cloud requirements                                   │
│                                                                   │
│ 🔴 BLOCKING POINT #1: Config loading hangs                       │
│    Symptoms: Process starts, no output, cursor doesn't return    │
│    Causes:                                                        │
│      - Network timeout waiting for cloud API                     │
│      - Invalid TOML syntax in config.toml                        │
│      - Permission denied reading ~/.config/codex/                │
│    Debug: RUST_LOG=debug codex                                   │
│    Fix: Check network, validate config, check permissions        │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ OSS Provider Selection (lib.rs:230-245) [IF --oss FLAG]          │
│ ─────────────────────────────────────────────────────────────── │
│ • resolve_oss_provider()                                         │
│ • If no provider configured:                                     │
│   - select_oss_provider() shows interactive menu                 │
│   - Waits for user to select provider                            │
│                                                                   │
│ 🔴 BLOCKING POINT #2: OSS provider selection                     │
│    Symptoms: Appears frozen, waiting for input                   │
│    Causes:                                                        │
│      - Interactive menu not visible                              │
│      - User doesn't know to make selection                       │
│    Debug: Try pressing arrow keys and Enter                      │
│    Fix: Configure provider in config.toml first                  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ Logging Setup (lib.rs:280-330)                                   │
│ ─────────────────────────────────────────────────────────────── │
│ • Create log directory: ~/.config/codex/logs/                    │
│ • Open log file: codex-tui.log                                   │
│ • Set up tracing subscribers                                     │
│ • Initialize OpenTelemetry (if enabled)                          │
│                                                                   │
│ ⚠️  FAILURE POINT: Log file creation                             │
│    Causes: Permission denied, disk full                          │
│    Error: Exits with I/O error                                   │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ OSS Provider Readiness (lib.rs:350-360) [IF --oss FLAG]          │
│ ─────────────────────────────────────────────────────────────── │
│ • ensure_oss_provider_ready()                                    │
│   - Checks if model is downloaded                                │
│   - Downloads model if missing                                   │
│   - Validates model integrity                                    │
│                                                                   │
│ 🔴 BLOCKING POINT #3: Model download                             │
│    Symptoms: Long pause, no visible progress                     │
│    Causes:                                                        │
│      - Downloading large model files (GBs)                       │
│      - Slow network connection                                   │
│      - Insufficient disk space                                   │
│    Debug: Check network activity, disk space                     │
│    Fix: Wait for download, check connectivity                    │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ Terminal Initialization (tui.rs:208-225)                          │
│ ─────────────────────────────────────────────────────────────── │
│ • Check stdin.is_terminal()                                      │
│ • Check stdout.is_terminal()                                     │
│ • set_modes():                                                   │
│   - enable_raw_mode()                                            │
│   - EnableBracketedPaste                                         │
│   - PushKeyboardEnhancementFlags                                 │
│   - EnableFocusChange                                            │
│ • flush_terminal_input_buffer()                                  │
│ • Create CrosstermBackend                                        │
│ • Create CustomTerminal                                          │
│                                                                   │
│ ⚠️  FAILURE POINT: Terminal detection                            │
│    Causes:                                                        │
│      - stdin/stdout not a TTY (redirected I/O)                   │
│      - TERM=dumb environment                                     │
│      - SSH without proper TTY allocation                         │
│    Error: "stdin is not a terminal"                              │
│    Fix: Run in proper terminal, use ssh -t                       │
│                                                                   │
│ 🟢 SUCCESS: Terminal is now in raw mode                          │
│    The terminal should now be controlled by Codex                │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ TERM=dumb Check (lib.rs:850-870)                                 │
│ ─────────────────────────────────────────────────────────────── │
│ • terminal_info().name == TerminalName::Dumb                     │
│ • If TERM=dumb:                                                  │
│   - Print warning                                                │
│   - Ask: "Continue anyway? [y/N]: "                              │
│   - Wait for user input                                          │
│                                                                   │
│ 🔴 BLOCKING POINT #4: TERM=dumb confirmation                     │
│    Symptoms: Warning shown, waiting for y/n                      │
│    Causes: TERM environment variable set to "dumb"               │
│    Debug: echo $TERM                                             │
│    Fix: export TERM=xterm-256color                               │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ Update Check (lib.rs:430-450) [RELEASE BUILDS ONLY]              │
│ ─────────────────────────────────────────────────────────────── │
│ • run_update_prompt_if_needed()                                  │
│   - Checks for newer version                                     │
│   - Shows update prompt if available                             │
│   - Waits for user decision                                      │
│                                                                   │
│ 🔴 BLOCKING POINT #5: Update prompt                              │
│    Symptoms: Prompt shown, waiting for user action               │
│    Causes: Update available, waiting for confirmation            │
│    Debug: Look for update prompt in terminal                     │
│    Fix: Respond to prompt or skip with flag                      │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ Onboarding Flow (lib.rs:460-520)                                 │
│ ─────────────────────────────────────────────────────────────── │
│ • should_show_onboarding()                                       │
│   - Checks login status                                          │
│   - Checks if first run in directory                             │
│   - Checks trust screen requirement                              │
│                                                                   │
│ • If onboarding needed:                                          │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │ Login Screen (if not authenticated)                      │   │
│   │ • Shows login options                                    │   │
│   │ • Waits for user to authenticate                         │   │
│   │ • May open browser for OAuth                             │   │
│   │ • Network calls for authentication                       │   │
│   └─────────────────────────────────────────────────────────┘   │
│                              ↓                                    │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │ Trust Screen (if first run in directory)                 │   │
│   │ • Shows directory trust prompt                           │   │
│   │ • Waits for user to trust/deny                           │   │
│   │ • Saves trust decision                                   │   │
│   └─────────────────────────────────────────────────────────┘   │
│                                                                   │
│ 🔴 BLOCKING POINT #6: Onboarding/Login                           │
│    Symptoms: Screen showing, waiting for user interaction        │
│    Causes:                                                        │
│      - First-time setup                                          │
│      - Not authenticated                                         │
│      - Directory not trusted                                     │
│      - Network call for login                                    │
│    Debug: Look carefully at terminal for prompts                 │
│    Fix: Complete onboarding, authenticate first                  │
│                                                                   │
│ 🟢 MOST LIKELY BLOCKING POINT ON FIRST RUN                       │
│    The TUI is actually running and showing prompts!              │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ Session Selection (lib.rs:540-660)                               │
│ ─────────────────────────────────────────────────────────────── │
│ • Handle resume/fork flags                                       │
│ • Load existing session if resuming                              │
│ • Fork session if forking                                        │
│ • Start fresh session otherwise                                  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ App Initialization (app.rs:917-1100)                             │
│ ─────────────────────────────────────────────────────────────── │
│ • Create ThreadManager                                           │
│ • Get default model                                              │
│ • Handle model migration prompts                                 │
│ • Initialize ChatWidget                                          │
│ • Create App struct                                              │
│ • Set up event channels                                          │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ Main Event Loop (app.rs:1190-1230)                               │
│ ─────────────────────────────────────────────────────────────── │
│ • tui.frame_requester().schedule_frame()                         │
│ • loop {                                                         │
│     select! {                                                    │
│       app_event_rx.recv() → handle_event()                       │
│       tui_events.next() → handle_tui_event()                     │
│       thread_event → handle_active_thread_event()                │
│     }                                                            │
│   }                                                              │
│                                                                   │
│ 🟢 APPLICATION IS NOW RUNNING                                    │
│    The TUI is active and responding to user input                │
│    You should see the Codex interface in your terminal           │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ User Interacts with TUI                                          │
│ • Types messages                                                 │
│ • Receives AI responses                                          │
│ • Approves/denies tool executions                                │
│ • Views diffs and changes                                        │
└─────────────────────────────────────────────────────────────────┘
```

## Blocking Points Summary

| # | Location | Probability | Symptom | Fix |
|---|----------|-------------|---------|-----|
| 1 | Config Loading | HIGH | No output, cursor doesn't return | Check network, validate config.toml |
| 2 | OSS Provider | MEDIUM | Appears frozen | Press arrow keys + Enter, or configure provider |
| 3 | Model Download | MEDIUM | Long pause | Wait, check network/disk space |
| 4 | TERM=dumb | LOW | Warning shown | Type 'y' or set TERM properly |
| 5 | Update Prompt | LOW | Prompt shown | Respond to prompt |
| 6 | Onboarding/Login | **VERY HIGH** (first run) | Screen showing prompts | Complete authentication/trust flow |

## Key Insight

**On first run, the most likely scenario is that the TUI IS actually running and showing the onboarding/login screen, but the user doesn't realize it because they're expecting a separate window to open.**

The application runs IN the terminal where you typed `codex`, not as a separate window.

## Quick Diagnostic

```bash
# 1. Check if process is running
ps aux | grep codex

# 2. Check if it's waiting for input
# Try pressing these keys in the terminal:
#   - Arrow keys
#   - Enter
#   - Escape
#   - Ctrl+C (to exit)

# 3. Check the log
tail -f ~/.config/codex/logs/codex-tui.log

# 4. Run diagnostic script
./diagnose_launch.sh
```

## Expected Visual States

### State 1: Before Launch
```
user@host:~$ codex
█  ← cursor blinking, waiting
```

### State 2: Stuck in Config Loading
```
user@host:~$ codex
   ← cursor gone, no output, process running
```

### State 3: Onboarding Screen (MOST COMMON)
```
┌─────────────────────────────────────────┐
│  Welcome to Codex CLI                   │
│                                         │
│  Please sign in to continue:            │
│  > Sign in with ChatGPT                 │
│    Sign in with API Key                 │
│    Exit                                 │
└─────────────────────────────────────────┘
```

### State 4: Running Normally
```
┌─────────────────────────────────────────┐
│ Codex CLI - gpt-4                       │
├─────────────────────────────────────────┤
│                                         │
│ You: _                                  │
│                                         │
└─────────────────────────────────────────┘
```

## Files Created for Debugging

1. **APP_LAUNCH_ANALYSIS.md** - Detailed technical analysis
2. **LAUNCH_STUCK_SUMMARY.md** - Practical troubleshooting guide
3. **LAUNCH_FLOW_DIAGRAM.md** - This visual flow diagram
4. **diagnose_launch.sh** - Automated diagnostic script
