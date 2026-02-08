//! Last-resort crash reporting for hardened Codex processes.
//!
//! When process hardening is active (`PT_DENY_ATTACH`, `RLIMIT_CORE = 0`), the
//! macOS crash reporter cannot generate `.crash` / `.ips` files. This module
//! fills that gap by:
//!
//! 1. Installing a **panic hook** that appends a human-readable crash report
//!    (including the panic message and a `std::backtrace::Backtrace`) to
//!    `~/.codex/crash.log` *before* chaining to the previous hook.
//!
//! 2. On Unix, registering **signal handlers** for `SIGSEGV`, `SIGBUS`,
//!    `SIGABRT`, and `SIGILL` that write a minimal diagnostic line to the same
//!    file using only async-signal-safe operations (`libc::write`).
//!
//! The crash log is intentionally append-only so that repeated crashes
//! accumulate rather than overwrite each other.

use std::io::Write;
use std::path::PathBuf;

/// Return the path used for the crash log: `$HOME/.codex/crash.log`.
fn crash_log_path() -> Option<PathBuf> {
    #[cfg(unix)]
    {
        std::env::var_os("HOME").map(|home| {
            let mut p = PathBuf::from(home);
            p.push(".codex");
            p.push("crash.log");
            p
        })
    }
    #[cfg(windows)]
    {
        std::env::var_os("USERPROFILE").map(|home| {
            let mut p = PathBuf::from(home);
            p.push(".codex");
            p.push("crash.log");
            p
        })
    }
}

// ---------------------------------------------------------------------------
// Panic hook
// ---------------------------------------------------------------------------

/// Install a panic hook that persists crash information to disk and then chains
/// to the previously-installed hook (so terminal restoration, tracing, etc.
/// still run).
fn install_panic_hook() {
    let prev = std::panic::take_hook();
    std::panic::set_hook(Box::new(move |info| {
        // Best-effort: write the crash report; ignore errors.
        let _ = write_panic_report(info);
        // Chain to the previous hook.
        prev(info);
    }));
}

fn write_panic_report(info: &std::panic::PanicHookInfo<'_>) -> std::io::Result<()> {
    let path = crash_log_path().ok_or_else(|| {
        std::io::Error::new(std::io::ErrorKind::NotFound, "cannot determine HOME")
    })?;

    if let Some(parent) = path.parent() {
        std::fs::create_dir_all(parent)?;
    }

    let mut file = std::fs::OpenOptions::new()
        .create(true)
        .append(true)
        .open(&path)?;

    // Restrict permissions to owner-only on Unix.
    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        let _ = file.set_permissions(std::fs::Permissions::from_mode(0o600));
    }

    let timestamp = {
        // Fallback: seconds since UNIX epoch (no chrono dependency).
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .map(|d| d.as_secs().to_string())
            .unwrap_or_else(|_| "unknown".to_string())
    };

    let thread = std::thread::current();
    let thread_name = thread.name().unwrap_or("<unnamed>");

    let backtrace = std::backtrace::Backtrace::force_capture();

    writeln!(file, "--- CODEX CRASH REPORT ---")?;
    writeln!(file, "timestamp_unix: {timestamp}")?;
    writeln!(file, "pid: {}", std::process::id())?;
    writeln!(file, "thread: {thread_name}")?;
    writeln!(file, "panic: {info}")?;
    writeln!(file, "backtrace:\n{backtrace}")?;
    writeln!(file, "--- END CRASH REPORT ---\n")?;

    Ok(())
}

// ---------------------------------------------------------------------------
// Signal handlers (Unix only)
// ---------------------------------------------------------------------------

#[cfg(unix)]
mod signal {
    use std::sync::atomic::{AtomicI32, Ordering};

    /// File descriptor for the pre-opened crash log, or -1 if not available.
    static CRASH_FD: AtomicI32 = AtomicI32::new(-1);

    /// Open (or create) the crash log and store the fd for the signal handler.
    pub(super) fn open_crash_fd() {
        let Some(path) = super::crash_log_path() else {
            return;
        };

        // Ensure the parent directory exists.
        if let Some(parent) = path.parent() {
            let _ = std::fs::create_dir_all(parent);
        }

        let c_path = match std::ffi::CString::new(path.as_os_str().as_encoded_bytes()) {
            Ok(p) => p,
            Err(_) => return,
        };

        // O_WRONLY | O_CREAT | O_APPEND, mode 0600
        let fd = unsafe {
            libc::open(
                c_path.as_ptr(),
                libc::O_WRONLY | libc::O_CREAT | libc::O_APPEND,
                0o600,
            )
        };
        if fd >= 0 {
            CRASH_FD.store(fd, Ordering::Relaxed);
        }
    }

    /// Async-signal-safe: write a fixed message to the pre-opened fd.
    unsafe extern "C" fn write_signal_crash(sig: libc::c_int) {
        let fd = CRASH_FD.load(Ordering::Relaxed);
        if fd < 0 {
            return;
        }

        // All strings are compile-time constants → async-signal-safe.
        let prefix = b"--- CODEX SIGNAL CRASH ---\nsignal: ";
        let sig_str = match sig {
            libc::SIGSEGV => b"SIGSEGV (11)\n" as &[u8],
            libc::SIGBUS => b"SIGBUS (10)\n" as &[u8],
            libc::SIGABRT => b"SIGABRT (6)\n" as &[u8],
            libc::SIGILL => b"SIGILL (4)\n" as &[u8],
            _ => b"unknown\n" as &[u8],
        };
        let suffix = b"--- END SIGNAL CRASH ---\n\n";

        // libc::write is async-signal-safe.
        unsafe {
            let _ = libc::write(fd, prefix.as_ptr().cast(), prefix.len());
            let _ = libc::write(fd, sig_str.as_ptr().cast(), sig_str.len());
            let _ = libc::write(fd, suffix.as_ptr().cast(), suffix.len());
        }

        // Re-raise with the default handler so the process terminates with the
        // correct wait-status (important for the parent Node.js wrapper).
        unsafe {
            libc::signal(sig, libc::SIG_DFL);
            libc::raise(sig);
        }
    }

    /// Register signal handlers for fatal signals.
    pub(super) fn install_signal_handlers() {
        unsafe {
            // Use sigaction for reliable behavior (SA_RESETHAND ensures one-shot).
            for &sig in &[libc::SIGSEGV, libc::SIGBUS, libc::SIGABRT, libc::SIGILL] {
                let mut sa: libc::sigaction = std::mem::zeroed();
                sa.sa_sigaction = write_signal_crash as *const () as usize;
                sa.sa_flags = libc::SA_SIGINFO | libc::SA_RESETHAND;
                libc::sigemptyset(&mut sa.sa_mask);
                libc::sigaction(sig, &sa, std::ptr::null_mut());
            }
        }
    }
}

/// Install a last-resort crash handler that persists diagnostic information to
/// `~/.codex/crash.log`.
///
/// This should be called early in `main()` — ideally right after
/// [`pre_main_hardening()`](crate::pre_main_hardening) — so that panics and
/// fatal signals are captured even when the macOS crash reporter is blocked.
///
/// The handler is safe to install multiple times (the panic hook chains, and
/// signal handlers are idempotent), but calling it once is sufficient.
pub fn install_crash_handler() {
    install_panic_hook();

    #[cfg(unix)]
    {
        signal::open_crash_fd();
        signal::install_signal_handlers();
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use pretty_assertions::assert_eq;

    #[test]
    fn crash_log_path_is_under_home() {
        // Temporarily override HOME for the test.
        let original = std::env::var_os("HOME");
        // SAFETY: this test is not run in parallel with other tests that
        // depend on HOME (serial_test would be needed for that).
        unsafe {
            std::env::set_var("HOME", "/tmp/test-codex-home");
        }
        let path = crash_log_path().expect("should resolve");
        assert_eq!(
            path,
            PathBuf::from("/tmp/test-codex-home/.codex/crash.log")
        );
        // Restore.
        unsafe {
            match original {
                Some(val) => std::env::set_var("HOME", val),
                None => std::env::remove_var("HOME"),
            }
        }
    }

    #[test]
    fn install_crash_handler_does_not_panic() {
        // Smoke test: calling install should not panic.
        install_crash_handler();
    }
}
