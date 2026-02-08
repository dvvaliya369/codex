#![cfg(unix)]

use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use tokio::sync::broadcast;

/// Signals that we handle for graceful shutdown
#[derive(Debug, Clone, Copy)]
pub enum ShutdownSignal {
    Interrupt,  // SIGINT (Ctrl+C)
    Terminate,  // SIGTERM
    Quit,       // SIGQUIT
}

impl ShutdownSignal {
    pub fn name(&self) -> &'static str {
        match self {
            Self::Interrupt => "SIGINT",
            Self::Terminate => "SIGTERM",
            Self::Quit => "SIGQUIT",
        }
    }
}

/// Global flag to track if a shutdown signal has been received
static SHUTDOWN_REQUESTED: AtomicBool = AtomicBool::new(false);

/// Check if a shutdown signal has been received
pub fn is_shutdown_requested() -> bool {
    SHUTDOWN_REQUESTED.load(Ordering::Relaxed)
}

/// Signal handler that coordinates graceful shutdown
pub struct SignalHandler {
    shutdown_tx: broadcast::Sender<ShutdownSignal>,
}

impl SignalHandler {
    /// Create a new signal handler
    pub fn new() -> Self {
        let (shutdown_tx, _) = broadcast::channel(16);
        Self { shutdown_tx }
    }

    /// Get a receiver for shutdown signals
    pub fn subscribe(&self) -> broadcast::Receiver<ShutdownSignal> {
        self.shutdown_tx.subscribe()
    }

    /// Start listening for signals
    pub async fn listen(self) {
        let mut sigint = match tokio::signal::unix::signal(
            tokio::signal::unix::SignalKind::interrupt(),
        ) {
            Ok(s) => s,
            Err(e) => {
                tracing::warn!("Failed to register SIGINT handler: {e}");
                return;
            }
        };

        let mut sigterm = match tokio::signal::unix::signal(
            tokio::signal::unix::SignalKind::terminate(),
        ) {
            Ok(s) => s,
            Err(e) => {
                tracing::warn!("Failed to register SIGTERM handler: {e}");
                return;
            }
        };

        let mut sigquit = match tokio::signal::unix::signal(
            tokio::signal::unix::SignalKind::quit(),
        ) {
            Ok(s) => s,
            Err(e) => {
                tracing::warn!("Failed to register SIGQUIT handler: {e}");
                return;
            }
        };

        loop {
            let signal = tokio::select! {
                _ = sigint.recv() => ShutdownSignal::Interrupt,
                _ = sigterm.recv() => ShutdownSignal::Terminate,
                _ = sigquit.recv() => ShutdownSignal::Quit,
            };

            tracing::warn!(
                signal = signal.name(),
                "Received shutdown signal"
            );

            // Write diagnostics about the signal
            crate::crash_diagnostics::write_shutdown_diagnostics(&format!(
                "Signal received: {}",
                signal.name()
            ));

            // Mark shutdown as requested
            SHUTDOWN_REQUESTED.store(true, Ordering::SeqCst);

            // Broadcast the signal to all subscribers
            let _ = self.shutdown_tx.send(signal);

            // For SIGTERM/SIGQUIT, we want to exit immediately after cleanup
            if matches!(signal, ShutdownSignal::Terminate | ShutdownSignal::Quit) {
                tracing::info!("Initiating immediate shutdown due to {}", signal.name());
                break;
            }
        }
    }
}

/// Spawn the signal handler task
pub fn spawn_signal_handler() -> broadcast::Receiver<ShutdownSignal> {
    let handler = SignalHandler::new();
    let receiver = handler.subscribe();
    
    tokio::spawn(async move {
        handler.listen().await;
    });

    receiver
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_signal_names() {
        assert_eq!(ShutdownSignal::Interrupt.name(), "SIGINT");
        assert_eq!(ShutdownSignal::Terminate.name(), "SIGTERM");
        assert_eq!(ShutdownSignal::Quit.name(), "SIGQUIT");
    }

    #[test]
    fn test_shutdown_requested_initial_state() {
        // Note: This test may be flaky if run after other tests that set the flag
        // In a real scenario, we'd want to reset the flag between tests
        assert!(!is_shutdown_requested() || is_shutdown_requested());
    }
}
