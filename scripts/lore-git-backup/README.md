# Lore-to-Git backup

`backup.sh` copies every unrecorded Lore revision on one configured branch into
one Git commit, oldest first. It is a one-way backup: Git never writes to Lore.

The conversion was tested with a Lore revision from `lore-test` and a new clone
of its GitHub destination. The test confirmed that the content and the Lore
revision metadata can be restored using Git alone.

## What each Git commit records

For every Lore revision, the script:

1. syncs the dedicated Lore worktree to that exact revision;
2. mirrors the materialized files into a separate Git worktree;
3. creates a Git commit, including an empty Git commit when the Lore revision
   changed only metadata; and
4. pushes the completed Git history after every unrecorded revision was
   converted successfully.

The Git author comes from the Lore revision creator. The currently configured
Lore authentication bridge resolves the user ID to an email address, so the
email is used for both the Git author name and email. The Git committer is the
backup bot, making clear that the commit was created by the scheduled
conversion.

Each commit body includes:

```text
Lore-Revision: <full Lore revision signature>
Lore-Branch: <source branch>
Lore-Creator: <resolved creator email>
Lore-Committer: <resolved Lore committer email>
```

The full revision signature is the idempotency key. On a later run, a revision
already recorded in any Git ref is skipped. If a run commits some revisions but
fails before `git push`, the next successful run skips those local commits and
pushes them with the remaining revisions.

## Scope and limitations

* This is a withdrawal backup, not a bidirectional Lore/Git bridge.
* It backs up one Lore branch into one linear Git branch. It does not recreate
  Lore branches or merge topology.
* It requires a full materialized Lore worktree. Do not add a Lore sparse view
  to this backup clone.
* It excludes only the top-level `.lore` and `.git` management directories.
  Project files, including hidden files, are copied.
* Git LFS is intentionally out of scope for this first implementation. Add
  LFS tracking and a successful `git lfs push` verification before using this
  with large binary assets.
* This does not replace the server-store backup described in
  [LORE Server の構築・運用](../../tech/lore-server.md).

## Prerequisites

Install the following on the host that runs the timer:

* Bash 4 or later
* `lore` CLI, logged in as the operating-system service account
* Git
* `jq`
* `rsync`
* `flock` and GNU `date`
* a non-interactive, write-capable Git authentication method

Use a dedicated backup host where possible. If the Lore Server also runs this
job, the Git remote must be in a separate failure domain.

Before enabling the systemd job, log in as `mgs` and verify that it can read
the source repository:

```bash
sudo -u mgs -H /datadrive/lore/bin/lore auth login \
  lore://172.20.12.193:41337
sudo -u mgs -H /datadrive/lore/bin/lore repository list \
  lore://172.20.12.193:41337 --remote --no-pager
```

Configure Git authentication outside this repository. For example, use a
write-capable GitHub deploy key readable only by `mgs`, or an existing
non-interactive credential helper. Do not put a GitHub token or private key in
`config.env`.

## Installation

The following commands only install the backup job. They do not modify
`lore.service`, `lore-auth-bridge.service`, or the Lore store.

```bash
sudo install -d -o root -g root -m 0755 \
  /usr/local/libexec/lore-git-backup \
  /etc/lore-git-backup
sudo install -d -o mgs -g mgs -m 0700 /datadrive/lore-git-backup

sudo install -o root -g root -m 0755 backup.sh \
  /usr/local/libexec/lore-git-backup/backup.sh
sudo install -o root -g root -m 0644 lore-git-backup.service \
  /etc/systemd/system/lore-git-backup.service
sudo install -o root -g root -m 0644 lore-git-backup.timer \
  /etc/systemd/system/lore-git-backup.timer
sudo install -o root -g root -m 0640 config.env.example \
  /etc/lore-git-backup/config.env

sudoedit /etc/lore-git-backup/config.env
```

Set `GIT_REMOTE` to the actual backup repository before running the script.
Restrict the configuration file so only root and the service account can read
it:

```bash
sudo chown root:mgs /etc/lore-git-backup/config.env
sudo chmod 0640 /etc/lore-git-backup/config.env
```

Run the first backup manually and inspect the Git history:

```bash
sudo -u mgs -H /usr/local/libexec/lore-git-backup/backup.sh \
  --config /etc/lore-git-backup/config.env

git clone <GIT_REMOTE> /tmp/lore-git-backup-restore-check
git -C /tmp/lore-git-backup-restore-check log --format=fuller
```

After the manual run and restore check succeed, enable the schedule:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now lore-git-backup.timer
systemctl list-timers lore-git-backup.timer
```

## Operations

Run an immediate backup:

```bash
sudo systemctl start lore-git-backup.service
sudo journalctl -u lore-git-backup.service -n 100 --no-pager
```

Confirm the timer:

```bash
systemctl status lore-git-backup.timer --no-pager
systemctl list-timers lore-git-backup.timer
```

If the job fails, fix the reported issue and run it again. Do not delete either
worktree to work around an error: the Git worktree may contain commits that
have not yet been pushed. If a clean rebuild is required, first preserve the
Git worktree and compare it with the remote.

## Restore test

At least monthly, restore without Lore and verify the result:

```bash
git clone <GIT_REMOTE> /tmp/lore-git-restore-$(date +%Y%m%d)
```

For an Unreal project, run the project-specific build and open representative
assets from that clone. A successful Git clone alone does not prove that the
project can be resumed without Lore.
