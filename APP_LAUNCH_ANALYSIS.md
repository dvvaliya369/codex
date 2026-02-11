# Codex CLI Application Launch Process Analysis

## Overview
This document analyzes the Codex CLI application launch process to identify where it might be getting stuck and why the window might not be appearing.

## Application Architecture

The Codex CLI is a **Terminal User Interface (TUI)** application, not a graphical window application. It runs directly in the terminal using the `ratatui` library with a `crossterm` backend.

### Key Components

1. **Entry Point**: `codex-cli/bin/codex.js` (Node.js wrapper)
2. **Native Binary**: Rust binary located in `vendor/<platform>/codex/codex`
3. **Main CLI**: `codex-rs/cli/src/main.rs`
4. **TUI Module**: `codex-rs/tui/src/lib.rs`
5. **App Loop**: `codex-rs/tui/src/app.rs`

## Launch Sequence

### 1. JavaScript Wrapper (`codex-cli/bin/codex.js`)

```javascript
const child = spawn(binaryPath, process.argv.slice(2), {
  stdio: "inherit",
  env,
});
```

**Potential Issues:**
- Binary not found at expected path
- Binary not executable
- Platform detection failure (wrong `targetTriple`)
- Missing vendor directory

**Location**: `/vercel/sandbox/codex-cli/bin/codex.js:119`

### 2. Rust CLI Entry (`codex-rs/cli/src/main.rs`)

The main function dispatches to `cli_main()` which parses command-line arguments and routes to the appropriate subcommand.

**Key Decision Point**: Line 127-130
```rust
match subcommand {
    None => {
        // Interactive TUI mode
        let exit_info = run_interactive_tui(interactive, codex_linux_sandbox_exe).await?;
```

**Potential Issues:**
- Argument parsing failures
- Config file errors
- Permission issues accessing codex home directory

**Location**: `/vercel/sandbox/codex-rs/cli/src/main.rs:127-400`

### 3. TUI Initialization (`codex-rs/tui/src/lib.rs`)

The `run_main()` function performs extensive setup before launching the TUI:

#### Phase 1: Configuration Loading (Lines 127-220)
```rust
let codex_home = match find_codex_home() {
    Ok(codex_home) => codex_home.to_path_buf(),
    Err(err) => {
        eprintln!("Error finding codex home: {err}");
        std::process::exit(1);
    }
};

let config_toml = match load_config_as_toml_with_cli_overrides(...).await {
    Ok(config_toml) => config_toml,
    Err(err) => {
        eprintln!("Error loading config.toml:\n{}", ...);
        std::process::exit(1);
    }
};
```

**Potential Blocking Points:**
- `find_codex_home()` - Filesystem access
- `load_config_as_toml_with_cli_overrides()` - Config parsing, async operation
- Cloud requirements loading - Network call

#### Phase 2: OSS Provider Selection (Lines 221-250)
```rust
if cli.oss {
    let provider = oss_selection::select_oss_provider(&codex_home).await?;
    if provider == "__CANCELLED__" {
        return Err(std::io::Error::other("OSS provider selection was cancelled"));
    }
}
```

**Potential Blocking Points:**
- Interactive provider selection prompt
- User cancellation

#### Phase 3: Logging Setup (Lines 280-330)
```rust
let log_file = log_file_opts.open(log_dir.join("codex-tui.log"))?;
let (non_blocking, _guard) = non_blocking(log_file);
```

**Potential Blocking Points:**
- Log directory creation
- File permissions
- Disk I/O

#### Phase 4: OSS Provider Readiness (Lines 350-360)
```rust
if cli.oss && model_provider_override.is_some() {
    ensure_oss_provider_ready(provider_id, &config).await?;
}
```

**Potential Blocking Points:**
- Provider initialization
- Model downloads
- Network connectivity

#### Phase 5: Terminal Initialization (Lines 420-430)
```rust
let mut terminal = tui::init()?;
terminal.clear()?;
```

**Critical Point**: This is where the terminal UI should appear!

**Location**: `/vercel/sandbox/codex-rs/tui/src/tui.rs:208-225`

### 4. Terminal Init (`codex-rs/tui/src/tui.rs`)

```rust
pub fn init() -> Result<Terminal> {
    if !stdin().is_terminal() {
        return Err(std::io::Error::other("stdin is not a terminal"));
    }
    if !stdout().is_terminal() {
        return Err(std::io::Error::other("stdout is not a terminal"));
    }
    set_modes()?;
    flush_terminal_input_buffer();
    set_panic_hook();
    
    let backend = CrosstermBackend::new(stdout());
    let tui = CustomTerminal::with_options(backend)?;
    Ok(tui)
}
```

**Potential Blocking Points:**
- `stdin().is_terminal()` check fails
- `stdout().is_terminal()` check fails
- `set_modes()` fails (raw mode, keyboard enhancement)
- Terminal capability detection

#### Terminal Mode Setup (Lines 60-85)
```rust
pub fn set_modes() -> Result<()> {
    execute!(stdout(), EnableBracketedPaste)?;
    enable_raw_mode()?;
    execute!(stdout(), PushKeyboardEnhancementFlags(...))?;
    execute!(stdout(), EnableFocusChange)?;
    Ok(())
}
```

**Potential Issues:**
- Terminal doesn't support required features
- TERM environment variable set to "dumb"
- Running in non-interactive environment

### 5. Update Prompt (Lines 430-450)

```rust
if !skip_update_prompt {
    match update_prompt::run_update_prompt_if_needed(&mut tui, &initial_config).await? {
        UpdatePromptOutcome::Continue => {},
        UpdatePromptOutcome::RunUpdate(action) => {
            // Exit to run update
        }
    }
}
```

**Potential Blocking Points:**
- Update check network call
- User interaction required

### 6. Onboarding Flow (Lines 460-520)

```rust
let should_show_onboarding = should_show_onboarding(login_status, &initial_config, ...);

if should_show_onboarding {
    let onboarding_result = run_onboarding_app(...).await?;
    if onboarding_result.should_exit {
        return Ok(AppExitInfo { ... });
    }
}
```

**Potential Blocking Points:**
- Login screen interaction
- Trust screen interaction
- User authentication flow
- Network calls for authentication

### 7. App Main Loop (`codex-rs/tui/src/app.rs`)

```rust
let exit_reason = loop {
    let control = select! {
        Some(event) = app_event_rx.recv() => { ... }
        Some(event) = tui_events.next() => { ... }
        // ... other event sources
    };
    match control {
        AppRunControl::Continue => {},
        AppRunControl::Exit(reason) => break reason,
    }
};
```

**Location**: Lines 1190-1230

## Common Failure Scenarios

### 1. **Binary Not Found**
- **Symptom**: Process exits immediately with error
- **Location**: `codex.js` line 119
- **Check**: Verify `vendor/<platform>/codex/codex` exists

### 2. **Terminal Detection Failure**
- **Symptom**: Error "stdin is not a terminal" or "stdout is not a terminal"
- **Location**: `tui.rs` lines 210-215
- **Check**: Ensure running in actual terminal, not redirected I/O

### 3. **TERM=dumb Environment**
- **Symptom**: Warning about dumb terminal, requires confirmation
- **Location**: `lib.rs` lines 850-870
- **Check**: `echo $TERM` should not be "dumb"

### 4. **Config Loading Hangs**
- **Symptom**: Process starts but nothing appears
- **Location**: `lib.rs` lines 180-210
- **Check**: Config file syntax, network access for cloud requirements

### 5. **OSS Provider Selection Blocks**
- **Symptom**: Waiting for user input that's not visible
- **Location**: `lib.rs` lines 230-245
- **Check**: Provider already configured or `--oss` flag not used

### 6. **Onboarding Screen Blocks**
- **Symptom**: Waiting for login/trust interaction
- **Location**: `lib.rs` lines 470-520
- **Check**: First-time setup, authentication status

### 7. **Model Download Hangs**
- **Symptom**: Process appears stuck during OSS provider initialization
- **Location**: `lib.rs` lines 350-360
- **Check**: Network connectivity, disk space, model availability

## Debugging Strategy

### 1. Check Binary Execution
```bash
# Verify binary exists and is executable
ls -la vendor/*/codex/codex
file vendor/*/codex/codex
ldd vendor/*/codex/codex  # Check dependencies
```

### 2. Check Terminal Environment
```bash
echo $TERM
tty
[ -t 0 ] && echo "stdin is terminal"
[ -t 1 ] && echo "stdout is terminal"
```

### 3. Enable Debug Logging
```bash
RUST_LOG=debug codex
# Check log file at: ~/.config/codex/logs/codex-tui.log
```

### 4. Check Config Files
```bash
cat ~/.config/codex/config.toml
# Look for syntax errors or invalid values
```

### 5. Test Minimal Launch
```bash
# Skip onboarding/updates
codex --help  # Should work without TUI
codex exec "echo test"  # Non-interactive mode
```

### 6. Trace System Calls
```bash
strace -e trace=open,openat,read,write,connect codex 2>&1 | tee trace.log
# Look for where it hangs
```

## Key Files to Examine

1. **Launch wrapper**: `/vercel/sandbox/codex-cli/bin/codex.js`
2. **Main entry**: `/vercel/sandbox/codex-rs/cli/src/main.rs`
3. **TUI init**: `/vercel/sandbox/codex-rs/tui/src/lib.rs` (lines 127-700)
4. **Terminal setup**: `/vercel/sandbox/codex-rs/tui/src/tui.rs` (lines 60-225)
5. **App loop**: `/vercel/sandbox/codex-rs/tui/src/app.rs` (lines 917-1267)

## Expected Behavior

When working correctly:
1. Binary spawns from Node.js wrapper
2. Rust CLI parses arguments
3. Config loads from `~/.config/codex/`
4. Terminal switches to raw mode
5. TUI appears in terminal (NOT a separate window)
6. Event loop starts processing user input

## Important Note

**Codex CLI is NOT a GUI application** - it runs in the terminal itself. There is no separate window that opens. The "window" is the terminal viewport where you run the `codex` command. If you're expecting a separate graphical window, that's the misconception - this is a terminal-based interface like `vim`, `htop`, or `nano`.
