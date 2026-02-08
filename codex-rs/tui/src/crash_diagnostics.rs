use std::fs::OpenOptions;
use std::io::Write;
use std::path::PathBuf;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Mutex;
use std::time::Instant;

/// Global flag to prevent recursive crash handling
static CRASH_IN_PROGRESS: AtomicBool = AtomicBool::new(false);

/// Application start time for uptime calculation
static APP_START_TIME: Mutex<Option<Instant>> = Mutex::new(None);

/// Initialize crash diagnostics tracking
pub fn init() {
    if let Ok(mut start_time) = APP_START_TIME.lock() {
        *start_time = Some(Instant::now());
    }
}

/// Get the crash log file path based on the platform
fn get_crash_log_path() -> Option<PathBuf> {
    #[cfg(target_os = "macos")]
    {
        if let Some(home) = dirs::home_dir() {
            let log_dir = home.join("Library").join("Logs").join("Codex");
            std::fs::create_dir_all(&log_dir).ok()?;
            return Some(log_dir.join("codex-tui-crash.log"));
        }
    }

    #[cfg(not(target_os = "macos"))]
    {
        if let Some(cache_dir) = dirs::cache_dir() {
            let log_dir = cache_dir.join("codex").join("logs");
            std::fs::create_dir_all(&log_dir).ok()?;
            return Some(log_dir.join("codex-tui-crash.log"));
        }
    }

    None
}

/// Write crash diagnostics to a file
pub fn write_crash_diagnostics(reason: &str, panic_info: Option<&std::panic::PanicInfo>) {
    // Prevent recursive crash handling
    if CRASH_IN_PROGRESS.swap(true, Ordering::SeqCst) {
        eprintln!("Recursive crash detected, aborting diagnostics");
        return;
    }

    let Some(log_path) = get_crash_log_path() else {
        eprintln!("Could not determine crash log path");
        return;
    };

    let mut file = match OpenOptions::new()
        .create(true)
        .append(true)
        .open(&log_path)
    {
        Ok(f) => f,
        Err(e) => {
            eprintln!("Failed to open crash log at {}: {}", log_path.display(), e);
            return;
        }
    };

    // Write crash header
    let timestamp = chrono::Local::now().format("%Y-%m-%d %H:%M:%S%.3f");
    let _ = writeln!(file, "\n{'=':<80}");
    let _ = writeln!(file, "CRASH REPORT: {timestamp}");
    let _ = writeln!(file, "{'=':<80}");
    let _ = writeln!(file, "Reason: {reason}");

    // Write process information
    let pid = std::process::id();
    let _ = writeln!(file, "\nProcess Information:");
    let _ = writeln!(file, "  PID: {pid}");

    #[cfg(unix)]
    {
        let ppid = unsafe { libc::getppid() };
        let _ = writeln!(file, "  Parent PID: {ppid}");
    }

    // Write uptime
    if let Ok(start_time) = APP_START_TIME.lock() {
        if let Some(start) = *start_time {
            let uptime = start.elapsed();
            let _ = writeln!(
                file,
                "  Uptime: {:.2}s",
                uptime.as_secs_f64()
            );
        }
    }

    // Write panic information if available
    if let Some(info) = panic_info {
        let _ = writeln!(file, "\nPanic Information:");
        let _ = writeln!(file, "  {info}");

        if let Some(location) = info.location() {
            let _ = writeln!(file, "  Location: {}:{}:{}", 
                location.file(), 
                location.line(), 
                location.column()
            );
        }

        // Try to get backtrace
        if let Some(payload) = info.payload().downcast_ref::<&str>() {
            let _ = writeln!(file, "  Payload: {payload}");
        } else if let Some(payload) = info.payload().downcast_ref::<String>() {
            let _ = writeln!(file, "  Payload: {payload}");
        }
    }

    // Write environment information
    let _ = writeln!(file, "\nEnvironment:");
    let _ = writeln!(file, "  OS: {}", std::env::consts::OS);
    let _ = writeln!(file, "  Arch: {}", std::env::consts::ARCH);
    
    if let Ok(term) = std::env::var("TERM") {
        let _ = writeln!(file, "  TERM: {term}");
    }
    
    if let Ok(term_program) = std::env::var("TERM_PROGRAM") {
        let _ = writeln!(file, "  TERM_PROGRAM: {term_program}");
    }

    // Write terminal state information
    let _ = writeln!(file, "\nTerminal State:");
    let _ = writeln!(file, "  stdout is_terminal: {}", std::io::IsTerminal::is_terminal(&std::io::stdout()));
    let _ = writeln!(file, "  stderr is_terminal: {}", std::io::IsTerminal::is_terminal(&std::io::stderr()));
    let _ = writeln!(file, "  stdin is_terminal: {}", std::io::IsTerminal::is_terminal(&std::io::stdin()));

    let _ = writeln!(file, "\n{'-':<80}");
    let _ = file.flush();

    tracing::error!(
        crash_log = %log_path.display(),
        "Crash diagnostics written"
    );

    // Also print to stderr for immediate visibility
    eprintln!("\nCrash diagnostics written to: {}", log_path.display());
}

/// Log a graceful shutdown
pub fn write_shutdown_diagnostics(reason: &str) {
    let Some(log_path) = get_crash_log_path() else {
        return;
    };

    let mut file = match OpenOptions::new()
        .create(true)
        .append(true)
        .open(&log_path)
    {
        Ok(f) => f,
        Err(_) => return,
    };

    let timestamp = chrono::Local::now().format("%Y-%m-%d %H:%M:%S%.3f");
    let _ = writeln!(file, "\n{'=':<80}");
    let _ = writeln!(file, "SHUTDOWN: {timestamp}");
    let _ = writeln!(file, "{'=':<80}");
    let _ = writeln!(file, "Reason: {reason}");
    
    if let Ok(start_time) = APP_START_TIME.lock() {
        if let Some(start) = *start_time {
            let uptime = start.elapsed();
            let _ = writeln!(file, "Uptime: {:.2}s", uptime.as_secs_f64());
        }
    }
    
    let _ = writeln!(file, "{'-':<80}");
    let _ = file.flush();
}
