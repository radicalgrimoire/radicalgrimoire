#!/usr/bin/env bash
#
# Copy one Lore revision at a time into a Git backup repository.
#
set -Eeuo pipefail
IFS=$'\n\t'
umask 077

readonly SCRIPT_NAME="${0##*/}"
CONFIG_FILE=""

usage() {
    cat <<EOF
Usage: $SCRIPT_NAME --config <path>

Copy unrecorded Lore revisions from the configured branch into Git commits.
EOF
}

fail() {
    printf '%s: %s\n' "$SCRIPT_NAME" "$*" >&2
    exit 1
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || fail "Required command was not found: $1"
}

while (($# > 0)); do
    case "$1" in
        --config)
            (($# >= 2)) || fail "--config requires a path."
            CONFIG_FILE="$2"
            shift 2
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            fail "Unknown argument: $1"
            ;;
    esac
done

[[ -n "$CONFIG_FILE" ]] || fail "--config is required."
[[ -r "$CONFIG_FILE" ]] || fail "Configuration file is not readable: $CONFIG_FILE"

# shellcheck disable=SC1090
source "$CONFIG_FILE"

: "${LORE_REMOTE:?LORE_REMOTE must be set.}"
: "${LORE_BRANCH:=main}"
: "${LORE_BIN:=lore}"
: "${GIT_REMOTE:?GIT_REMOTE must be set.}"
: "${GIT_BRANCH:=main}"
: "${BACKUP_ROOT:?BACKUP_ROOT must be set.}"
: "${GIT_COMMITTER_NAME:=Lore Backup Bot}"
: "${GIT_COMMITTER_EMAIL:?GIT_COMMITTER_EMAIL must be set.}"
: "${MAX_HISTORY:=100000}"

require_command "$LORE_BIN"
require_command git
require_command jq
require_command rsync
require_command flock
require_command date
require_command realpath
require_command tac

LORE_WORKTREE="$BACKUP_ROOT/lore-worktree"
GIT_WORKTREE="$BACKUP_ROOT/git-mirror"
LOCK_FILE="$BACKUP_ROOT/backup.lock"
MESSAGE_FILE=""

cleanup() {
    [[ -z "$MESSAGE_FILE" ]] || rm -f -- "$MESSAGE_FILE"
}
trap cleanup EXIT

ensure_distinct_worktrees() {
    local lore_path git_path
    lore_path="$(realpath -m -- "$LORE_WORKTREE")"
    git_path="$(realpath -m -- "$GIT_WORKTREE")"

    [[ "$lore_path" != "$git_path" ]] ||
        fail "LORE and Git worktrees must be different directories."
    [[ "$lore_path" != "$git_path/"* && "$git_path" != "$lore_path/"* ]] ||
        fail "LORE and Git worktrees must not contain one another."
}

ensure_lore_worktree() {
    if [[ -d "$LORE_WORKTREE/.lore" ]]; then
        return
    fi

    [[ ! -e "$LORE_WORKTREE" ]] ||
        fail "Lore worktree exists but is not a Lore repository: $LORE_WORKTREE"

    mkdir -p -- "$BACKUP_ROOT"
    "$LORE_BIN" repository clone \
        "$LORE_REMOTE" \
        "$LORE_WORKTREE" \
        --branch "$LORE_BRANCH"
}

ensure_git_worktree() {
    mkdir -p -- "$BACKUP_ROOT"

    if [[ ! -d "$GIT_WORKTREE/.git" ]]; then
        [[ ! -e "$GIT_WORKTREE" ]] ||
            fail "Git worktree exists but is not a Git repository: $GIT_WORKTREE"
        git clone "$GIT_REMOTE" "$GIT_WORKTREE"
    fi

    local configured_remote
    configured_remote="$(git -C "$GIT_WORKTREE" remote get-url origin)" ||
        fail "Git worktree has no origin remote: $GIT_WORKTREE"
    [[ "$configured_remote" == "$GIT_REMOTE" ]] ||
        fail "Git origin differs from GIT_REMOTE; refusing to use $GIT_WORKTREE"

    git -C "$GIT_WORKTREE" fetch --prune origin

    if git -C "$GIT_WORKTREE" show-ref --verify --quiet "refs/heads/$GIT_BRANCH"; then
        git -C "$GIT_WORKTREE" switch "$GIT_BRANCH"
        if git -C "$GIT_WORKTREE" show-ref --verify --quiet "refs/remotes/origin/$GIT_BRANCH"; then
            git -C "$GIT_WORKTREE" merge --ff-only "origin/$GIT_BRANCH"
        fi
    elif git -C "$GIT_WORKTREE" show-ref --verify --quiet "refs/remotes/origin/$GIT_BRANCH"; then
        git -C "$GIT_WORKTREE" switch --track -c "$GIT_BRANCH" "origin/$GIT_BRANCH"
    else
        git -C "$GIT_WORKTREE" switch -c "$GIT_BRANCH"
    fi

    [[ -z "$(git -C "$GIT_WORKTREE" status --porcelain)" ]] ||
        fail "Git worktree has uncommitted changes: $GIT_WORKTREE"
}

is_revision_backed_up() {
    local revision="$1"

    git -C "$GIT_WORKTREE" log --all --format=%B |
        grep -Fqx "Lore-Revision: $revision"
}

sync_revision_to_git() {
    local revision="$1"
    local info_json creator_id committer_id author_email committer_email author_date message

    "$LORE_BIN" revision sync \
        --repository "$LORE_WORKTREE" \
        --remote \
        --reset \
        "$revision"

    info_json="$(
        "$LORE_BIN" --json revision info \
            --repository "$LORE_WORKTREE" \
            --remote \
            "$revision"
    )"

    creator_id="$(jq -r '
        select(.tagName == "metadata" and .data.key == "created-by")
        | .data.value.data
    ' <<<"$info_json" | head -n 1)"
    [[ -n "$creator_id" && "$creator_id" != "null" ]] ||
        fail "Revision $revision has no created-by metadata."

    committer_id="$(jq -r '
        select(.tagName == "metadata" and .data.key == "committed-by")
        | .data.value.data
    ' <<<"$info_json" | head -n 1)"
    [[ -n "$committer_id" && "$committer_id" != "null" ]] ||
        fail "Revision $revision has no committed-by metadata."

    author_email="$(jq -r --arg creator_id "$creator_id" '
        select(.tagName == "authUserInfo" and .data.id == $creator_id)
        | .data.name
    ' <<<"$info_json" | head -n 1)"
    [[ "$author_email" =~ ^[^[:space:]@]+@[^[:space:]@]+$ ]] ||
        fail "Revision $revision author is not an email address: ${author_email:-<empty>}"

    committer_email="$(jq -r --arg committer_id "$committer_id" '
        select(.tagName == "authUserInfo" and .data.id == $committer_id)
        | .data.name
    ' <<<"$info_json" | head -n 1)"
    [[ "$committer_email" =~ ^[^[:space:]@]+@[^[:space:]@]+$ ]] ||
        fail "Revision $revision committer is not an email address: ${committer_email:-<empty>}"

    author_date="$(jq -r '
        select(.tagName == "metadata" and .data.key == "timestamp")
        | .data.value.data
    ' <<<"$info_json" | head -n 1)"
    [[ "$author_date" =~ ^[0-9]+$ ]] ||
        fail "Revision $revision has no valid timestamp metadata."
    author_date="$(date --utc --date="@${author_date:0:${#author_date}-3}" --iso-8601=seconds)"

    message="$(jq -r '
        select(.tagName == "metadata" and .data.key == "message")
        | .data.value.data
    ' <<<"$info_json" | head -n 1)"
    [[ -n "$message" && "$message" != "null" ]] ||
        fail "Revision $revision has no commit message."

    rsync -a --delete \
        --exclude='/.lore/' \
        --exclude='/.git/' \
        "$LORE_WORKTREE/" "$GIT_WORKTREE/"

    git -C "$GIT_WORKTREE" add --all

    MESSAGE_FILE="$(mktemp "$BACKUP_ROOT/commit-message.XXXXXX")"
    {
        printf '%s\n\n' "$message"
        printf 'Lore-Revision: %s\n' "$revision"
        printf 'Lore-Branch: %s\n' "$LORE_BRANCH"
        printf 'Lore-Creator: %s\n' "$author_email"
        printf 'Lore-Committer: %s\n' "$committer_email"
    } >"$MESSAGE_FILE"

    GIT_AUTHOR_NAME="$author_email" \
    GIT_AUTHOR_EMAIL="$author_email" \
    GIT_AUTHOR_DATE="$author_date" \
    GIT_COMMITTER_NAME="$GIT_COMMITTER_NAME" \
    GIT_COMMITTER_EMAIL="$GIT_COMMITTER_EMAIL" \
        git -C "$GIT_WORKTREE" commit --allow-empty -F "$MESSAGE_FILE"

    rm -f -- "$MESSAGE_FILE"
    MESSAGE_FILE=""
}

main() {
    mkdir -p -- "$BACKUP_ROOT"
    ensure_distinct_worktrees

    exec 9>"$LOCK_FILE"
    flock -n 9 || fail "Another backup is already running."

    ensure_lore_worktree
    ensure_git_worktree

    local history_json
    history_json="$(
        "$LORE_BIN" --json revision history \
            --repository "$LORE_WORKTREE" \
            --remote \
            --branch "$LORE_BRANCH" \
            --only-branch \
            "$MAX_HISTORY"
    )"

    local -a revisions=()
    mapfile -t revisions < <(
        jq -r '
            select(.tagName == "revisionHistoryEntry")
            | .data.revision
        ' <<<"$history_json" | tac
    )

    ((${#revisions[@]} > 0)) ||
        fail "No revisions were returned for Lore branch: $LORE_BRANCH"

    local revision copied=0
    for revision in "${revisions[@]}"; do
        if is_revision_backed_up "$revision"; then
            printf 'Already backed up: %s\n' "$revision"
            continue
        fi

        printf 'Backing up Lore revision: %s\n' "$revision"
        sync_revision_to_git "$revision"
        ((copied += 1))
    done

    git -C "$GIT_WORKTREE" push origin "HEAD:refs/heads/$GIT_BRANCH"
    printf 'Backup complete: %d Lore revision(s) copied to %s.\n' "$copied" "$GIT_BRANCH"
}

main "$@"
