# Crash Diagnostics for Codex.app on macOS

## Overview

When Codex.app crashes or unexpectedly quits on macOS, the CLI now includes comprehensive diagnostic capabilities to help identify and troubleshoot the issue.

## Problem

Previously, when Codex.app crashed on macOS:
- No crash reports were generated in `~/Library/Logs/DiagnosticReports/`
- The `open -a` command was fire-and-forget with no crash detection
- Users had no visibility into what caused the crash
- Debugging required manual Console.app inspection

## Solution

The CLI now implements multi-layered crash detection and diagnostics:

### 1. Launch Monitoring
- After launching Codex.app, the CLI waits 3 seconds
- Uses `pgrep` to verify the app is still running
- If not running, triggers comprehensive diagnostics

### 2. Launch Marker Logging
- Creates `~/Library/Logs/Codex/codex-cli-launch.log`
- Records timestamp of each launch attempt
- Helps correlate crashes with launch events

### 3. Diagnostic Information Collection

When a crash is detected, the CLI automatically collects:

#### a) Console Logs
- Uses `log show` to retrieve recent Codex.app logs (last 5 minutes)
- Displays the 20 most recent log entries
- Filters for Codex-specific process logs

#### b) Application Logs
- Checks `~/Library/Logs/Codex/` for application-generated logs
- Displays last 10 lines of each log file found
- Helps identify app-level errors

#### c) Crash Reports
- Scans `~/Library/Logs/DiagnosticReports/` for Codex crash files
- Looks for files matching `Codex*.crash` or `Codex*.ips`
- Displays the 3 most recent crash reports with first 30 lines
- Notes when crash reports are absent (common for certain failure modes)

#### d) System Crash Logs
- Searches system logs for crash/terminate/exit events
- Uses predicates to filter for Codex-related messages
- Shows last 15 relevant log entries

## Usage

When running `codex app`, the diagnostics run automatically if a crash is detected:

```bash
codex app /path/to/workspace
```

### Expected Output (Normal Launch)
```
Opening workspace /path/to/workspace...
Checking for crash logs in /Users/username/Library/Logs/Codex...
Waiting for app to launch...
Codex.app launched successfully.
```

### Expected Output (Crash Detected)
```
Opening workspace /path/to/workspace...
Checking for crash logs in /Users/username/Library/Logs/Codex...
Waiting for app to launch...
WARNING: Codex.app does not appear to be running after launch.
This may indicate a crash or early termination.

=== Diagnostic Information ===

Checking recent console logs for Codex.app...
Recent console logs:
  [timestamp] Codex[12345]: Error message...
  ...

Checking application logs at /Users/username/Library/Logs/Codex...
Found log file: main.log
  Last 10 lines:
    [ERROR] Failed to initialize...
    ...

Checking /Users/username/Library/Logs/DiagnosticReports for crash reports...
Found 1 crash report(s):
  - Codex-2026-02-08-120000.crash (modified: ...)
    First 30 lines:
      Process: Codex [12345]
      ...

=== End Diagnostic Information ===

If the app continues to crash, please report this issue with the diagnostic information above.
You can also check Console.app for more detailed crash information.
```

## Files Created

- `~/Library/Logs/Codex/codex-cli-launch.log` - Launch marker file

## Locations Checked

1. Console logs (via `log show`)
2. `~/Library/Logs/Codex/` - Application logs
3. `~/Library/Logs/DiagnosticReports/` - macOS crash reports
4. System logs (via `log show` with crash predicates)

## Troubleshooting

### No Crash Reports Generated

This is common when:
- The app terminates gracefully (but unexpectedly)
- The crash handler fails to write reports
- macOS doesn't classify the termination as a crash
- The app exits due to an uncaught exception in JavaScript/TypeScript

In these cases, console logs and application logs are more valuable.

### False Positives

The 3-second wait may occasionally cause false positives if:
- The system is under heavy load
- The app takes >3 seconds to fully launch

Users can verify manually with Activity Monitor or Console.app.

## Implementation Details

### Key Functions

- `is_codex_app_running()` - Checks if Codex.app process exists
- `check_for_crash_logs()` - Main diagnostic orchestrator
- `check_console_logs()` - Retrieves unified logging output
- `check_app_logs()` - Reads application log files
- `check_diagnostic_reports()` - Scans for .crash/.ips files
- `check_system_log()` - Searches for crash-related system events
- `write_launch_marker()` - Creates timestamped launch marker

### Dependencies

- `tokio::time::sleep` - For launch delay
- `tokio::process::Command` - For async process execution
- macOS `log` command - For unified logging access
- macOS `pgrep` command - For process detection

## Future Improvements

Potential enhancements:
1. Automatic crash report upload to issue tracker
2. Integration with crash reporting services
3. Persistent crash history tracking
4. Automatic retry with safe mode
5. Memory/resource usage monitoring
6. CoreDump collection for native crashes
