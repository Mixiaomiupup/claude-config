#!/usr/bin/env bash
# restore-from-remote.sh — Restore ~/.claude/ config from remote Git repo
# Usage:
#   restore-from-remote.sh                  # Full restore with backup
#   restore-from-remote.sh --dry-run        # Preview only
#   restore-from-remote.sh --only skills hooks  # Selective restore
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Try to source sync-config.sh; if not available (fresh machine), use defaults
if [ -f "$SCRIPT_DIR/sync-config.sh" ]; then
    source "$SCRIPT_DIR/sync-config.sh"
else
    CLAUDE_DIR="$HOME/.claude"
    REPO_URL="git@github.com:Mixiaomiupup/claude-config.git"
    STAGING_DIR="/private/tmp/claude-config-staging"
    BRANCH="main"
    SYNC_FILES=("CLAUDE.md" "AUTO_APPROVE_GUIDE.md" "CONFIG_PACKAGE_GUIDE.md" "settings.local.json")
    SYNC_DIRS=("hooks" "skills" "agents" "commands" "output-styles")
    SANITIZE_FILES=("settings.json")
    PLANS_INFRA=("plans/README.md" "plans/PLANS_INDEX.md" "plans/templates")
    PLUGIN_MANIFEST=("plugins/installed_plugins.json")
    SENSITIVE_KEYS=("ANTHROPIC_AUTH_TOKEN")
    EXCLUDE_WITHIN=("skills/baoyu-skills")
    SKILL_SOURCES_FILE="skill-sources.json"
fi

# --- Parse arguments ---
DRY_RUN=false
ONLY_ITEMS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=true; shift ;;
        --only) shift; while [[ $# -gt 0 && "$1" != --* ]]; do ONLY_ITEMS+=("$1"); shift; done ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# --- Dependency check ---
for cmd in git rsync jq; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "ERROR: $cmd is required but not found."
        exit 1
    fi
done

# --- Helper: check if item is in --only list ---
should_restore() {
    local item="$1"
    if [ ${#ONLY_ITEMS[@]} -eq 0 ]; then
        return 0  # No filter, restore everything
    fi
    for only in "${ONLY_ITEMS[@]}"; do
        if [[ "$item" == "$only" ]]; then
            return 0
        fi
    done
    return 1
}

# --- Clone repo to staging ---
echo "==> Cloning config from $REPO_URL..."
rm -rf "$STAGING_DIR"
git clone --branch "$BRANCH" "$REPO_URL" "$STAGING_DIR" --quiet
echo "  ✓ Cloned to $STAGING_DIR"

# --- Backup existing config ---
if [ -d "$CLAUDE_DIR" ] && ! $DRY_RUN; then
    BACKUP_DIR="$HOME/.claude.backup.$(date '+%Y%m%d_%H%M%S')"
    echo "==> Backing up existing config to $BACKUP_DIR"
    cp -a "$CLAUDE_DIR" "$BACKUP_DIR"
    echo "  ✓ Backup created"
elif $DRY_RUN; then
    echo "[DRY RUN] Would backup ~/.claude/ to ~/.claude.backup.YYYYMMDD_HHMMSS/"
fi

# Ensure target exists
mkdir -p "$CLAUDE_DIR"

# --- Restore plain files ---
echo "==> Restoring files..."
for f in "${SYNC_FILES[@]}"; do
    src="$STAGING_DIR/$f"
    dst="$CLAUDE_DIR/$f"
    if [ -f "$src" ] && should_restore "$f"; then
        if $DRY_RUN; then
            echo "  [DRY RUN] would copy: $f"
        else
            cp "$src" "$dst"
            echo "  restored: $f"
        fi
    fi
done

# --- Restore directories ---
echo "==> Restoring directories..."
for d in "${SYNC_DIRS[@]}"; do
    src="$STAGING_DIR/$d/"
    dst="$CLAUDE_DIR/$d/"
    if [ -d "$src" ] && should_restore "$d"; then
        if $DRY_RUN; then
            echo "  [DRY RUN] would sync: $d/"
        else
            mkdir -p "$dst"
            rsync -a "$src" "$dst"
            echo "  restored: $d/"
        fi
    fi
done

# --- Restore settings.json with merge strategy ---
if should_restore "settings.json"; then
    echo "==> Restoring settings.json (merge strategy)..."
    repo_settings="$STAGING_DIR/settings.json"
    local_settings="$CLAUDE_DIR/settings.json"

    if [ -f "$repo_settings" ]; then
        if [ -f "$local_settings" ] && ! $DRY_RUN; then
            # Merge: keep local sensitive keys, take everything else from repo
            merged=$(cat "$repo_settings")
            for key in "${SENSITIVE_KEYS[@]}"; do
                local_val=$(jq -r --arg k "$key" '.env[$k] // empty' "$local_settings")
                if [ -n "$local_val" ] && [ "$local_val" != "YOUR_TOKEN_HERE" ]; then
                    merged=$(echo "$merged" | jq --arg k "$key" --arg v "$local_val" '.env[$k] = $v')
                fi
            done
            echo "$merged" | jq '.' > "$local_settings"
            echo "  ✓ Merged settings.json (preserved local tokens)"
        elif ! $DRY_RUN; then
            cp "$repo_settings" "$local_settings"
            echo "  ✓ Copied settings.json (no local file to merge)"
            echo "  ⚠ Remember to set your ANTHROPIC_AUTH_TOKEN"
        else
            echo "  [DRY RUN] would merge settings.json (preserve local tokens)"
        fi
    fi
fi

# --- Restore plans infrastructure ---
echo "==> Restoring plans infrastructure..."
for item in "${PLANS_INFRA[@]}"; do
    src="$STAGING_DIR/$item"
    dst="$CLAUDE_DIR/$item"
    if should_restore "plans"; then
        if [ -f "$src" ]; then
            if $DRY_RUN; then
                echo "  [DRY RUN] would copy: $item"
            else
                mkdir -p "$(dirname "$dst")"
                cp "$src" "$dst"
                echo "  restored: $item"
            fi
        elif [ -d "$src" ]; then
            if $DRY_RUN; then
                echo "  [DRY RUN] would sync: $item/"
            else
                mkdir -p "$dst"
                rsync -a "$src/" "$dst/"
                echo "  restored: $item/"
            fi
        fi
    fi
done

# --- Restore plugin manifest ---
echo "==> Restoring plugin manifest..."
for item in "${PLUGIN_MANIFEST[@]}"; do
    src="$STAGING_DIR/$item"
    dst="$CLAUDE_DIR/$item"
    if [ -f "$src" ] && should_restore "plugins"; then
        if $DRY_RUN; then
            echo "  [DRY RUN] would copy: $item"
        else
            mkdir -p "$(dirname "$dst")"
            cp "$src" "$dst"
            echo "  restored: $item"
        fi
    fi
done

# --- Clone third-party skills from skill-sources.json ---
echo "==> Restoring third-party skills..."
sources_file="$STAGING_DIR/$SKILL_SOURCES_FILE"
if [ -f "$sources_file" ] && should_restore "skills"; then
    while IFS= read -r skill_name; do
        skill_url=$(jq -r --arg n "$skill_name" '.[$n].url' "$sources_file")
        skill_path=$(jq -r --arg n "$skill_name" '.[$n].path' "$sources_file")
        target="$CLAUDE_DIR/$skill_path"

        if [ -d "$target/.git" ]; then
            echo "  already exists: $skill_path (skipping)"
        elif $DRY_RUN; then
            echo "  [DRY RUN] would clone: $skill_url → $skill_path"
        else
            echo "  cloning: $skill_url → $skill_path"
            git clone "$skill_url" "$target" --quiet
            echo "  ✓ cloned: $skill_name"
        fi
    done < <(jq -r 'keys[]' "$sources_file")
else
    echo "  no skill-sources.json found (skipping)"
fi

# --- Fix permissions ---
if ! $DRY_RUN && should_restore "hooks"; then
    echo "==> Fixing hook permissions..."
    chmod +x "$CLAUDE_DIR/hooks/"*.sh 2>/dev/null || true
    echo "  ✓ chmod +x hooks/*.sh"
fi

# --- Restore sync scripts themselves ---
if ! $DRY_RUN; then
    echo "==> Restoring sync scripts..."
    for script in sync-config.sh sync-to-remote.sh restore-from-remote.sh; do
        src="$STAGING_DIR/$script"
        dst="$CLAUDE_DIR/$script"
        if [ -f "$src" ]; then
            cp "$src" "$dst"
            chmod +x "$dst"
            echo "  restored: $script"
        fi
    done
fi

# --- Summary ---
echo ""
echo "=== Restore Summary ==="
if $DRY_RUN; then
    echo "[DRY RUN] No changes were made."
else
    echo "✓ Config restored from $REPO_URL"
    if [ -n "${BACKUP_DIR:-}" ]; then
        echo "  Backup at: $BACKUP_DIR"
    fi
fi

# --- Plugin install reminder ---
if should_restore "plugins"; then
    echo ""
    echo "=== Plugin Installation ==="
    manifest="$CLAUDE_DIR/plugins/installed_plugins.json"
    if [ -f "$manifest" ]; then
        echo "Installed plugins manifest restored. To reinstall plugins:"
        echo "  cat ~/.claude/plugins/installed_plugins.json"
        echo ""
        echo "Then run 'claude plugin install <name>' for each plugin."
    fi
fi

echo ""
echo "Done. Run 'claude' to verify your setup."
