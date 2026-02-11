# Fix for Codex CLI Launch Hang

## The Problem in Simple Terms

When you run `codex`, it hangs for **15 seconds** before showing the interface. This happens because the app tries to download some configuration from the internet, and when that fails or is slow, it waits a long time before giving up.

## The Fix in Simple Terms

We add a **2-second timeout**. If the download doesn't finish in 2 seconds, the app just continues without it. This makes the app start in 2 seconds instead of 15 seconds.

## Is This Safe?

**Yes!** The configuration it's trying to download is optional. The app already works fine without it. We're just making it give up faster instead of waiting so long.

## What File Changed?

**One file**: `codex-rs/core/src/config_loader/mod.rs`

**One change**: Added a timeout wrapper around a network call.

## How to Apply

### Easy Way (Use the Patch)

```bash
cd /vercel/sandbox
git apply launch_hang_fix.patch
cargo build --release -p codex-cli
```

### Manual Way (Edit the File)

1. Open `codex-rs/core/src/config_loader/mod.rs`
2. Find line 113 (search for `cloud_requirements.get().await`)
3. Replace this:
```rust
if let Some(requirements) = cloud_requirements.get().await {
    config_requirements_toml
        .merge_unset_fields(RequirementSource::CloudRequirements, requirements);
}
```

4. With this:
```rust
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

5. Save and rebuild:
```bash
cargo build --release -p codex-cli
```

## Test It

```bash
# Should start within 2-3 seconds now
time codex
```

## What You Get

- **Before**: 15-second hang
- **After**: 2-second startup

That's it! Simple fix, big improvement.

## More Details

- **Quick Visual Guide**: See `QUICK_FIX_GUIDE.txt`
- **Summary**: See `FIX_SUMMARY.md`
- **Step-by-Step**: See `APPLY_FIX.md`
- **Technical Deep Dive**: See `LAUNCH_HANG_FIX.md`
