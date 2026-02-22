#!/usr/bin/env bash
# sync-config.sh — Shared configuration for Claude config sync scripts
# Sourced by cc-sync (and legacy scripts for backward compat)

CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"

# ---- Config repo (GitHub primary) ----
CONFIG_GITHUB_URL="git@github.com:Mixiaomiupup/claude-config.git"
CONFIG_GITHUB_BRANCH="main"
CONFIG_YUNXIAO_URL="git@codeup.aliyun.com:696f3f56b28d0aba0f5e4371/Innovation-Project/dade-flexible-welding/claude_config.git"
CONFIG_YUNXIAO_BRANCH="master"

# ---- Skills repo (dual-mirror) ----
SKILLS_GITHUB_URL="git@github.com:Mixiaomiupup/claude-skills.git"
SKILLS_GITHUB_BRANCH="main"
SKILLS_YUNXIAO_URL="git@codeup.aliyun.com:696f3f56b28d0aba0f5e4371/Innovation-Project/dade-flexible-welding/claude_skills.git"
SKILLS_YUNXIAO_BRANCH="master"

# ---- Staging directories ----
CONFIG_STAGING_DIR="/private/tmp/claude-config-staging"
SKILLS_STAGING_DIR="/private/tmp/claude-skills-staging"

# ---- Lock file ----
LOCK_FILE="/private/tmp/claude-config-sync.lock"

# ---- Backward compat aliases (used by legacy scripts if still present) ----
REPO_URL="$CONFIG_GITHUB_URL"
STAGING_DIR="$CONFIG_STAGING_DIR"
BRANCH="$CONFIG_GITHUB_BRANCH"

# Files to sync directly for config repo (relative to CLAUDE_DIR)
SYNC_FILES=(
    "README.md"
    "CLAUDE.md"
    "AUTO_APPROVE_GUIDE.md"
    "CONFIG_PACKAGE_GUIDE.md"
    "settings.local.json"
    "sync-config.sh"
    "cc-sync"
    "component-manifest.json"
)

# Directories to sync via rsync for config repo (relative to CLAUDE_DIR)
# NOTE: "skills" removed — skills are synced independently via push_skills
SYNC_DIRS=(
    "hooks"
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

# ---- Skills exclude list ----
EXCLUDE_SKILLS=("baoyu-skills")

# Legacy compat
EXCLUDE_WITHIN=("skills/baoyu-skills")
SKILL_SOURCES_FILE="skill-sources.json"
