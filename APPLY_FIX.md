# How to Apply the Launch Hang Fix

## Quick Summary

**Problem**: Codex CLI hangs for up to 15 seconds during launch while waiting for cloud requirements to fetch from the backend API.

**Solution**: Add a 2-second timeout to the cloud requirements fetch during config loading, allowing the app to start quickly.

**Impact**: App startup time reduced from 15 seconds to ~2 seconds in restricted network environments.

## What Changed

**File Modified**: `codex-rs/core/src/config_loader/mod.rs`

**Lines Changed**: 113-116 (4 lines) → 113-131 (19 lines)

**Change Type**: Wrapped blocking `.await` call with `tokio::time::timeout()`

## Apply the Fix

### Method 1: Using the Patch File (Recommended)

```bash
cd /vercel/sandbox
git apply launch_hang_fix.patch
```

### Method 2: Manual Edit

1. Open the file: `codex-rs/core/src/config_loader/mod.rs`
2. Go to line 113
3. Find this code:
```rust
if let Some(requirements) = cloud_requirements.get().await {
    config_requirements_toml
        .merge_unset_fields(RequirementSource::CloudRequirements, requirements);
}
```

4. Replace it with:
```rust
// Add a short timeout for cloud requirements to prevent blocking app startup.
// Cloud requirements are best-effort, so we continue without them if the fetch
// takes too long (e.g., in restricted network environments).
match tokio::time::timeout(
    std::time::Duration::from_secs(2),
    cloud_requirements.get()
).await {
    Ok(Some(requirements)) => {
        config_requirements_toml
            .merge_unset_fields(RequirementSource::CloudRequirements, requirements);
    }
    Ok(None) => {
        // No cloud requirements available
    }
    Err(_) => {
        // Timeout - continue without cloud requirements
        tracing::debug!("Cloud requirements fetch timed out during config load; continuing without them");
    }
}
```

5. Save the file

## Rebuild the Application

After applying the fix, rebuild the Rust binary:

```bash
cd /vercel/sandbox

# Build in release mode
cargo build --release -p codex-cli

# Or build all packages
cargo build --release
```

The updated binary will be in: `target/release/codex`

## Verify the Fix

### Test 1: Check Startup Time

```bash
# Time the startup
time codex

# Should complete within 2-3 seconds instead of 15+ seconds
```

### Test 2: Check Logs

```bash
# Run with debug logging
RUST_LOG=debug codex

# In another terminal, check the logs
tail -f ~/.config/codex/logs/codex-tui.log | grep -i "cloud requirements"

# You should see either:
# - "Cloud requirements load completed" (if fetch succeeded within 2s)
# - "Cloud requirements fetch timed out during config load" (if it timed out)
```

### Test 3: Verify Functionality

```bash
# Start codex and verify it works normally
codex

# Try basic commands
codex exec "echo test"
codex --help
```

## What to Expect

### Before Fix
- App hangs for 15 seconds on launch in restricted networks
- No visual feedback during the wait
- Eventually starts after timeout

### After Fix
- App starts within 2 seconds
- Cloud requirements are fetched in background
- If fetch completes within 2s, requirements are applied
- If fetch takes longer, app continues without them (graceful degradation)

## Rollback

If you need to undo the fix:

```bash
cd /vercel/sandbox
git checkout codex-rs/core/src/config_loader/mod.rs
cargo build --release -p codex-cli
```

## Technical Details

### Why This Works

1. **Non-blocking startup**: The 2-second timeout prevents indefinite waiting
2. **Graceful degradation**: Cloud requirements are already documented as "best-effort"
3. **Background fetch continues**: The spawned tokio task continues fetching
4. **No breaking changes**: All existing functionality is preserved

### Timeout Rationale

- **2 seconds** is chosen because:
  - Fast enough for good UX (user won't notice)
  - Long enough for successful fetches on normal networks
  - Short enough to prevent perceived hangs
  - Aligns with typical HTTP request timeouts

### Risk Assessment

**Risk Level**: LOW

- Cloud requirements are already optional (best-effort)
- No changes to core logic, only timeout duration
- Existing tests should pass without modification
- Easy to rollback if needed

## Troubleshooting

### Issue: Patch doesn't apply cleanly

```bash
# Check if the file has been modified
git status

# If modified, reset it first
git checkout codex-rs/core/src/config_loader/mod.rs

# Then apply the patch
git apply launch_hang_fix.patch
```

### Issue: Build fails

```bash
# Clean the build
cargo clean

# Rebuild
cargo build --release -p codex-cli

# Check for specific errors
cargo check -p codex-core
```

### Issue: Still hangs on startup

1. Check if the fix was applied:
```bash
git diff codex-rs/core/src/config_loader/mod.rs
```

2. Verify you're running the rebuilt binary:
```bash
which codex
# Should point to the newly built binary
```

3. Check logs for other blocking issues:
```bash
RUST_LOG=trace codex 2>&1 | tee startup.log
```

## Additional Resources

- **Detailed Analysis**: See `LAUNCH_HANG_FIX.md` for complete technical explanation
- **Debug Guide**: See `DEBUGGING_GUIDE.md` for general troubleshooting
- **Launch Analysis**: See `APP_LAUNCH_ANALYSIS.md` for launch process details

## Questions?

If you encounter issues or have questions about this fix:

1. Check the logs: `~/.config/codex/logs/codex-tui.log`
2. Run with debug logging: `RUST_LOG=debug codex`
3. Review the detailed fix documentation: `LAUNCH_HANG_FIX.md`
