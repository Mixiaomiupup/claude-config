#!/usr/bin/env bash
# sync-to-remote.sh — Sync local ~/.claude/ config to remote Git repo
# Usage:
#   sync-to-remote.sh              # Preview diff, confirm, then push
#   sync-to-remote.sh --dry-run    # Preview only, no commit/push
#   sync-to-remote.sh -m "message" # Custom commit message
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/sync-config.sh"

# --- Parse arguments ---
DRY_RUN=false
CUSTOM_MSG=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=true; shift ;;
        -m) CUSTOM_MSG="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# --- Lock to prevent concurrent runs ---
acquire_lock() {
    if [ -f "$LOCK_FILE" ]; then
        local pid
        pid=$(cat "$LOCK_FILE" 2>/dev/null || echo "")
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            echo "ERROR: Another sync is running (PID $pid). Exiting."
            exit 1
        fi
        echo "WARNING: Stale lock file found. Removing."
        rm -f "$LOCK_FILE"
    fi
    echo $$ > "$LOCK_FILE"
}

release_lock() {
    rm -f "$LOCK_FILE"
}
trap release_lock EXIT

acquire_lock

# --- Dependency check ---
for cmd in git rsync jq; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "ERROR: $cmd is required but not found."
        exit 1
    fi
done

# --- Clone or update staging repo ---
echo "==> Preparing staging directory: $STAGING_DIR"
if [ -d "$STAGING_DIR/.git" ]; then
    git -C "$STAGING_DIR" fetch origin "$BRANCH" --quiet
    git -C "$STAGING_DIR" checkout "$BRANCH" --quiet
    git -C "$STAGING_DIR" reset --hard "origin/$BRANCH" --quiet
else
    rm -rf "$STAGING_DIR"
    git clone --branch "$BRANCH" "$REPO_URL" "$STAGING_DIR" --quiet
fi

# --- Sync plain files ---
echo "==> Syncing files..."
for f in "${SYNC_FILES[@]}"; do
    src="$CLAUDE_DIR/$f"
    if [ -f "$src" ]; then
        cp "$src" "$STAGING_DIR/$f"
        echo "  copied: $f"
    else
        echo "  skipped (not found): $f"
    fi
done

# --- Sync directories via rsync ---
echo "==> Syncing directories..."
for d in "${SYNC_DIRS[@]}"; do
    src="$CLAUDE_DIR/$d/"
    dst="$STAGING_DIR/$d/"
    if [ -d "$src" ]; then
        # Build rsync exclude flags
        excludes=()
        for ex in "${EXCLUDE_WITHIN[@]}"; do
            # If exclude starts with this dir, extract the relative part
            if [[ "$ex" == "$d/"* ]]; then
                rel="${ex#$d/}"
                excludes+=(--exclude="$rel")
            fi
        done
        if [ ${#excludes[@]} -gt 0 ]; then
            rsync -a --delete "${excludes[@]}" "$src" "$dst"
        else
            rsync -a --delete "$src" "$dst"
        fi
        echo "  synced: $d/ ${excludes[*]:-}"
    else
        echo "  skipped (not found): $d/"
    fi
done

# --- Remove excluded directories from staging ---
echo "==> Removing excluded directories from staging..."
for ex in "${EXCLUDE_WITHIN[@]}"; do
    target="$STAGING_DIR/$ex"
    if [ -d "$target" ]; then
        rm -r "$target"
        echo "  removed: $ex"
    fi
done

# --- Sanitize settings.json ---
echo "==> Sanitizing settings.json..."
for f in "${SANITIZE_FILES[@]}"; do
    src="$CLAUDE_DIR/$f"
    dst="$STAGING_DIR/$f"
    if [ -f "$src" ]; then
        local_json=$(cat "$src")

        # Replace sensitive keys with placeholder
        for key in "${SENSITIVE_KEYS[@]}"; do
            local_json=$(echo "$local_json" | jq --arg k "$key" '
                if .env[$k] then .env[$k] = "YOUR_TOKEN_HERE" else . end
            ')
        done

        # Strip fields entirely
        for field in "${STRIP_FIELDS[@]}"; do
            local_json=$(echo "$local_json" | jq "del(.$field)")
        done

        echo "$local_json" > "$dst"
        echo "  sanitized: $f"

        # Verify sanitization
        if grep -q "YOUR_TOKEN_HERE" "$dst"; then
            echo "  ✓ Token replaced with placeholder"
        fi
        if ! jq -e '.model' "$dst" &>/dev/null; then
            echo "  ✓ model field removed"
        fi
    fi
done

# --- Sync plans infrastructure ---
echo "==> Syncing plans infrastructure..."
for item in "${PLANS_INFRA[@]}"; do
    src="$CLAUDE_DIR/$item"
    dst="$STAGING_DIR/$item"
    if [ -f "$src" ]; then
        mkdir -p "$(dirname "$dst")"
        cp "$src" "$dst"
        echo "  copied: $item"
    elif [ -d "$src" ]; then
        mkdir -p "$dst"
        rsync -a "$src/" "$dst/"
        echo "  synced: $item/"
    else
        echo "  skipped (not found): $item"
    fi
done

# --- Sync plugin manifest ---
echo "==> Syncing plugin manifest..."
for item in "${PLUGIN_MANIFEST[@]}"; do
    src="$CLAUDE_DIR/$item"
    dst="$STAGING_DIR/$item"
    if [ -f "$src" ]; then
        mkdir -p "$(dirname "$dst")"
        cp "$src" "$dst"
        echo "  copied: $item"
    else
        echo "  skipped (not found): $item"
    fi
done

# --- Generate skill-sources.json ---
echo "==> Scanning for third-party skills..."
skill_sources="{}"
for skill_dir in "$CLAUDE_DIR/skills"/*/; do
    skill_name=$(basename "$skill_dir")
    if [ -d "$skill_dir/.git" ]; then
        remote_url=$(git -C "$skill_dir" remote get-url origin 2>/dev/null || echo "")
        if [ -n "$remote_url" ]; then
            skill_sources=$(echo "$skill_sources" | jq \
                --arg name "$skill_name" \
                --arg url "$remote_url" \
                --arg path "skills/$skill_name" \
                '.[$name] = {"url": $url, "path": $path}')
            echo "  detected: $skill_name → $remote_url"
        fi
    fi
done

echo "$skill_sources" | jq '.' > "$STAGING_DIR/$SKILL_SOURCES_FILE"
echo "  wrote: $SKILL_SOURCES_FILE"

# --- Check for changes ---
echo ""
echo "==> Checking for changes..."
cd "$STAGING_DIR"
git add -A

if git diff --cached --quiet; then
    echo "No changes to sync."
    exit 0
fi

# --- Show diff ---
echo ""
echo "--- Changes Summary ---"
git diff --cached --stat
echo ""

if $DRY_RUN; then
    echo "[DRY RUN] Full diff:"
    git diff --cached
    echo ""
    echo "[DRY RUN] No commit or push performed."
    exit 0
fi

# --- Show full diff and confirm ---
git diff --cached
echo ""
read -rp "Commit and push these changes? [y/N] " confirm
if [[ "$confirm" != [yY] ]]; then
    echo "Aborted."
    git reset HEAD --quiet
    exit 0
fi

# --- Commit and push ---
TIMESTAMP=$(date '+%Y-%m-%d %H:%M')
if [ -n "$CUSTOM_MSG" ]; then
    COMMIT_MSG="$CUSTOM_MSG"
else
    COMMIT_MSG="sync: manual sync $TIMESTAMP"
fi

# Append changed file list to commit message
CHANGED_FILES=$(git diff --cached --name-only | head -20)
FULL_MSG=$(printf '%s\n\nChanged files:\n%s' "$COMMIT_MSG" "$CHANGED_FILES")

git commit -m "$FULL_MSG" --quiet
git push origin "$BRANCH" --quiet

echo ""
echo "✓ Synced to $REPO_URL ($BRANCH)"
echo "  Commit: $(git rev-parse --short HEAD)"
