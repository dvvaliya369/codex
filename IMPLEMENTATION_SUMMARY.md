# Implementation Summary: macOS Codex.app Crash Diagnostics

## Problem Statement

Codex.app intermittently quits unexpectedly on macOS shortly after launch or during normal use. No crash reports (`.crash` or `.ips` files) are generated in `~/Library/Logs/DiagnosticReports/`, and crashpad folders appear empty, making it impossible to diagnose the root cause.

## Root Cause Analysis

The existing implementation had no crash detection or diagnostic capabilities:

1. **Fire-and-forget launch**: The `open -a Codex.app` command returns immediately without monitoring the app's lifecycle
2. **No crash detection**: The CLI had no way to know if the app crashed after launch
3. **No logging infrastructure**: No persistent logs were created to track launch attempts
4. **No diagnostic collection**: When crashes occurred, there was no automated way to gather debugging information

## Solution Implemented

Implemented a comprehensive crash diagnostics system in `/vercel/sandbox/codex-rs/cli/src/desktop_app/mac.rs`:

### 1. Launch Monitoring (`is_codex_app_running()`)
- After launching Codex.app, the CLI waits 3 seconds for initialization
- Uses `pgrep -f "Codex.app"` to verify the app process is still running
- If the process is not found, triggers comprehensive diagnostic collection

### 2. Launch Marker Logging (`write_launch_marker()`)
- Creates `~/Library/Logs/Codex/codex-cli-launch.log` before each launch
- Records Unix timestamp of each launch attempt
- Provides correlation between CLI invocations and app behavior
- Survives across sessions for historical analysis

### 3. Multi-Source Diagnostic Collection (`check_for_crash_logs()`)

When a crash is detected, the system automatically collects information from multiple sources:

#### a) Console Logs (`check_console_logs()`)
```rust
Command::new("log")
    .arg("show")
    .arg("--predicate")
    .arg("processImagePath CONTAINS 'Codex'")
    .arg("--last")
    .arg("5m")
```
- Retrieves unified logging output for the last 5 minutes
- Displays the 20 most recent Codex-related log entries
- Captures app-level errors and warnings

#### b) Application Logs (`check_app_logs()`)
- Scans `~/Library/Logs/Codex/` directory
- Reads last 10 lines from each log file (`.log` files or files starting with "codex")
- Displays application-generated debug information

#### c) Crash Reports (`check_diagnostic_reports()`)
- Searches `~/Library/Logs/DiagnosticReports/` for crash files
- Matches files: `Codex*.crash` or `Codex*.ips`
- Sorts by modification time to find most recent crashes
- Displays first 30 lines of up to 3 most recent crash reports
- Notes when crash reports are absent (common for graceful terminations)

#### d) System Crash Logs (`check_system_log()`)
```rust
Command::new("log")
    .arg("show")
    .arg("--predicate")
    .arg("(processImagePath CONTAINS 'Codex' OR message CONTAINS 'Codex') AND 
          (eventMessage CONTAINS 'crash' OR eventMessage CONTAINS 'terminate' OR 
           eventMessage CONTAINS 'exit')")
    .arg("--last")
    .arg("10m")
```
- Searches for crash/terminate/exit events in system logs
- Shows last 15 relevant log entries
- Captures system-level termination signals

### 4. User Guidance
- Provides clear diagnostic output with section headers
- Instructs users to check Console.app for additional details
- Encourages reporting with collected diagnostic information

## Files Modified

### `/vercel/sandbox/codex-rs/cli/src/desktop_app/mac.rs`

**Added imports:**
```rust
use std::time::Duration;
use tokio::time::sleep;
```

**Modified function:**
- `open_codex_app()` - Added crash detection and diagnostic triggering

**New functions:**
- `is_codex_app_running()` - Process existence check via pgrep
- `get_app_log_directory()` - Returns `~/Library/Logs/Codex`
- `write_launch_marker()` - Creates timestamped launch marker
- `check_for_crash_logs()` - Orchestrates diagnostic collection
- `check_console_logs()` - Retrieves unified logging output
- `check_app_logs()` - Reads application log files
- `check_diagnostic_reports()` - Scans for macOS crash reports
- `check_system_log()` - Searches system logs for crash events

**Total additions:** ~227 lines of new diagnostic code

## Files Created

### `/vercel/sandbox/codex-rs/cli/CRASH_DIAGNOSTICS.md`
Comprehensive documentation covering:
- Problem overview
- Solution architecture
- Usage examples
- Files created and locations checked
- Troubleshooting guidance
- Implementation details
- Future improvement ideas

### User-visible artifact:
- `~/Library/Logs/Codex/codex-cli-launch.log` - Launch marker file

## User Experience Changes

### Before:
```bash
$ codex app .
Opening Codex Desktop at /Applications/Codex.app...
Opening workspace /path/to/workspace...
# [App crashes silently - no feedback]
```

### After (Successful Launch):
```bash
$ codex app .
Opening Codex Desktop at /Applications/Codex.app...
Opening workspace /path/to/workspace...
Checking for crash logs in /Users/username/Library/Logs/Codex...
Waiting for app to launch...
Codex.app launched successfully.
```

### After (Crash Detected):
```bash
$ codex app .
Opening Codex Desktop at /Applications/Codex.app...
Opening workspace /path/to/workspace...
Checking for crash logs in /Users/username/Library/Logs/Codex...
Waiting for app to launch...
WARNING: Codex.app does not appear to be running after launch.
This may indicate a crash or early termination.

=== Diagnostic Information ===

Checking recent console logs for Codex.app...
Recent console logs:
  2026-02-08 12:00:01 Codex[12345]: [ERROR] Initialization failed
  2026-02-08 12:00:02 Codex[12345]: [FATAL] Uncaught exception

Checking application logs at /Users/username/Library/Logs/Codex...
Found log file: main.log
  Last 10 lines:
    [2026-02-08 12:00:00] Starting application
    [2026-02-08 12:00:01] Error: Cannot load module
    ...

Checking /Users/username/Library/Logs/DiagnosticReports for crash reports...
No crash reports found for Codex.app
Note: macOS may not generate crash reports for all types of failures.

Checking for crash-related system logs...
Recent crash-related logs:
  2026-02-08 12:00:02 kernel: Codex[12345] terminated with signal 11

=== End Diagnostic Information ===

If the app continues to crash, please report this issue with the diagnostic information above.
You can also check Console.app for more detailed crash information.
```

## Technical Implementation Details

### Async/Await Pattern
All diagnostic functions use async/await for non-blocking I/O:
- File system operations remain synchronous (for simplicity and reliability)
- Process execution uses `tokio::process::Command` for async execution
- Launch delay uses `tokio::time::sleep()` for non-blocking wait

### Error Handling
- Diagnostic failures are non-fatal (use `eprintln!` for warnings)
- Missing log files/directories are handled gracefully
- Failed command executions print error messages but don't crash
- Uses `Result` types with `anyhow` for error context

### Performance
- 3-second delay adds minimal overhead to successful launches
- Diagnostic collection only runs when crash is detected
- File reading is limited (10 lines from app logs, 30 from crash reports)
- Console log queries are time-bounded (5-10 minutes)

## Testing Considerations

### Manual Testing Scenarios
1. **Normal launch**: App should launch successfully without false positives
2. **Immediate crash**: App crashes within 3 seconds - diagnostics triggered
3. **Delayed crash**: App crashes after 3 seconds - may not be detected (acceptable limitation)
4. **Missing directories**: Handles absent log directories gracefully
5. **No crash reports**: Provides helpful message when .crash/.ips files absent
6. **Slow system**: 3-second delay may cause false positives on heavily loaded systems

### Edge Cases Handled
- `HOME` environment variable not set
- Log directories don't exist (created automatically for marker)
- No crash reports generated (common scenario)
- `pgrep` or `log` commands unavailable
- UTF-8 decoding errors in log files
- Empty log files or directories

## Limitations

1. **3-second detection window**: Crashes occurring >3 seconds after launch won't be detected
2. **Process name matching**: `pgrep -f "Codex.app"` may match other processes with "Codex.app" in their path
3. **No automatic reporting**: Diagnostics are displayed but not automatically uploaded
4. **macOS-specific**: Implementation only works on macOS (platform-gated)
5. **No crash prevention**: This is purely diagnostic, doesn't prevent crashes

## Future Enhancements

Potential improvements identified in CRASH_DIAGNOSTICS.md:
1. Automatic crash report upload to issue tracker
2. Integration with crash reporting services (Sentry, etc.)
3. Persistent crash history tracking
4. Automatic retry with safe mode
5. Memory/resource usage monitoring
6. CoreDump collection for native crashes
7. Configurable detection delay
8. Background monitoring for delayed crashes

## Compliance & Security

- **No PII collected**: Only technical logs and crash reports
- **Local-only**: All diagnostic data stays on user's machine
- **User-controlled**: Users can delete log files at any time
- **Read-only operations**: Only reads existing system logs (except launch marker)
- **Standard tools**: Uses built-in macOS utilities (`log`, `pgrep`)

## Dependencies

**No new external dependencies added**. Uses:
- Standard library: `std::path`, `std::time`, `std::fs`
- Existing dependencies: `tokio`, `anyhow`
- macOS built-in commands: `log`, `pgrep`

## Verification

The implementation has been verified for:
- ✅ Correct Rust syntax
- ✅ Proper async/await usage
- ✅ Error handling with anyhow::Result
- ✅ File structure integrity
- ✅ No unwrap() calls (all errors handled gracefully)
- ✅ Existing tests preserved
- ✅ Documentation created

## Conclusion

This implementation provides comprehensive crash diagnostics for Codex.app on macOS without requiring any changes to the app itself. It enables users and developers to understand why the app is crashing by automatically collecting relevant diagnostic information from multiple sources when a crash is detected.

The solution is non-invasive, performant, and provides immediate value for troubleshooting the intermittent crash issue described in the problem statement.
