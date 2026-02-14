#!/usr/bin/env bash
# sync-config.sh — Shared configuration for Claude config sync scripts
# Sourced by sync-to-remote.sh and restore-from-remote.sh

CLAUDE_DIR="$HOME/.claude"
REPO_URL="git@github.com:Mixiaomiupup/claude-config.git"
STAGING_DIR="/private/tmp/claude-config-staging"
BRANCH="main"
LOCK_FILE="/private/tmp/claude-config-sync.lock"

# Files to sync directly (relative to CLAUDE_DIR)
SYNC_FILES=(
    "CLAUDE.md"
    "AUTO_APPROVE_GUIDE.md"
    "CONFIG_PACKAGE_GUIDE.md"
    "settings.local.json"
    "sync-config.sh"
    "sync-to-remote.sh"
    "restore-from-remote.sh"
)

# Directories to sync via rsync (relative to CLAUDE_DIR)
SYNC_DIRS=(
    "hooks"
    "skills"
    "agents"
    "commands"
    "output-styles"
)

# Files requiring sanitization before sync
SANITIZE_FILES=("settings.json")

# Plans infrastructure (specific files/dirs, not entire plans/)
PLANS_INFRA=(
    "plans/README.md"
    "plans/PLANS_INDEX.md"
    "plans/templates"
)

# Plugin manifest
PLUGIN_MANIFEST=("plugins/installed_plugins.json")

# Sensitive keys to replace with placeholder in settings.json
SENSITIVE_KEYS=("ANTHROPIC_AUTH_TOKEN")

# Fields to strip entirely from settings.json
STRIP_FIELDS=("model")

# Directories to exclude within synced dirs (relative paths within SYNC_DIRS)
EXCLUDE_WITHIN=("skills/baoyu-skills")

# Third-party skill sources file (generated in repo root)
SKILL_SOURCES_FILE="skill-sources.json"
