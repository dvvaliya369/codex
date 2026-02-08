# macOS Codex.app Crash Fix - Quick Reference

## What Was Fixed

**Problem**: Codex.app crashes intermittently on macOS with no crash reports

**Root Causes Found**:
1. Duplicate panic hooks (second shadowed first, preventing terminal cleanup)
2. No signal handling (SIGTERM/SIGINT left terminal corrupted)
3. No crash diagnostics (impossible to debug)
4. Fragile terminal restoration (could fail silently)

## Changes Made

### New Files Created (2)

1. **`codex-rs/tui/src/crash_diagnostics.rs`** (181 lines)
   - Writes crash logs to `~/Library/Logs/Codex/codex-tui-crash.log`
   - Captures: panic info, process details, uptime, environment, terminal state
   - Prevents recursive crashes with atomic flags

2. **`codex-rs/tui/src/signal_handler.rs`** (99 lines)
   - Handles SIGINT, SIGTERM, SIGQUIT on Unix
   - Graceful shutdown with diagnostics
   - Tokio-based async signal monitoring

### Files Modified (2)

1. **`codex-rs/tui/src/lib.rs`**
   - Added module declarations for new modules
   - Consolidated panic hook in `run_ratatui_app()`:
     * Calls `crash_diagnostics::init()` on startup
     * Single panic hook: diagnostics → terminal restore → color-eyre
   - Spawns signal handler on Unix platforms
   - Removed duplicate panic hook

2. **`codex-rs/tui/src/tui.rs`**
   - Enhanced `restore_common()` with better error handling
   - Added `emergency_terminal_reset()` for failsafe recovery
   - Removed old `set_panic_hook()` function
   - Added debug logging for terminal state

## How to Build & Test

```bash
# Format code
cd codex-rs
just fmt

# Run tests
cargo test -p codex-tui

# Build release
cargo build -p codex-tui --release
```

## Testing the Fix

### Test Signal Handling
```bash
# Run app
./target/release/codex-tui

# In another terminal, test signals
pkill -TERM codex-tui  # Should exit gracefully
pkill -INT codex-tui   # Should exit gracefully
```

### Check Crash Logs
```bash
# macOS
tail -f ~/Library/Logs/Codex/codex-tui-crash.log

# Linux
tail -f ~/.cache/codex/crash-logs/codex-tui-crash.log
```

## What to Expect

### Before Fix
- ❌ App quits unexpectedly
- ❌ Terminal left in corrupted state
- ❌ No crash reports
- ❌ Impossible to debug

### After Fix
- ✅ Graceful shutdown on signals
- ✅ Terminal always restored
- ✅ Detailed crash logs
- ✅ Easy to diagnose issues

## Key Improvements

| Issue | Solution |
|-------|----------|
| Duplicate panic hooks | Single consolidated hook in lib.rs |
| No signal handling | Signal handler catches TERM/INT/QUIT |
| No crash diagnostics | Crash logs written to ~/Library/Logs/Codex/ |
| Terminal corruption | Emergency VT100 reset as fallback |
| Silent failures | Comprehensive logging throughout |

## Files Summary

```
codex-rs/tui/src/
├── crash_diagnostics.rs  [NEW] - Crash logging module
├── signal_handler.rs     [NEW] - Unix signal handling (cfg(unix))
├── lib.rs               [MOD] - Consolidated panic hook, signal spawning
└── tui.rs               [MOD] - Enhanced terminal restoration
```

## Dependencies

**No new dependencies required** - Uses existing:
- `tokio` (signal feature already enabled)
- `dirs` (for home directory)
- `chrono` (for timestamps)
- `tracing` (for logging)

## Documentation

- `CRASH_FIX_SUMMARY.md` - Detailed implementation guide
- `IMPLEMENTATION_CHECKLIST.md` - Verification checklist
- This file - Quick reference

## Next Steps

1. ✅ Code implementation complete
2. ⏳ Run `just fmt` to format
3. ⏳ Run `cargo test -p codex-tui`
4. ⏳ Build and test manually
5. ⏳ Monitor crash logs in production

## Monitoring After Deployment

Watch for:
- Crash log files being created at `~/Library/Logs/Codex/`
- Reduced terminal corruption reports
- Graceful exits on Ctrl+C
- Panic information captured in logs

## Support

If issues arise:
1. Check crash logs at `~/Library/Logs/Codex/codex-tui-crash.log`
2. Look for signal handling in logs
3. Verify terminal reset sequences executed
4. Check process uptime and environment in crash logs

---

**Status**: ✅ Implementation Complete - Ready for Testing
