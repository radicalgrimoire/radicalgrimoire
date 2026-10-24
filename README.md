# radicalgrimoire

I’m souhei-ueno. A degenerate piece of shit with zero control over his libido, making questionable life choices and somehow still pursuing engineering. That’s who I am.

## Docker Helixcore  
p4 — apparently, “before” was just too much work to type.

### Reusable Docker workflows

The following definitions are called by
[docker-helix-p4](https://github.com/radicalgrimoire/docker-helix-p4) at `@main`:

- [build.yml](.github/workflows/build.yml): Build, test, and upload an image artifact.
- [get-version.yml](.github/workflows/get-version.yml): Extract image version outputs.
- [delete-image.yml](.github/workflows/delete-image.yml): Delete existing GHCR image versions with the exact version tag.
- [publish.yml](.github/workflows/publish.yml): Publish the image to GHCR.
- [scan.yml](.github/workflows/scan.yml): Scan the image artifact with Trivy.

These are `workflow_call` definitions, not standalone entry points. They expect
the caller's `build/<build_path>` configuration and scripts; the scan also uses
the caller's `scripts/summarize_trivy.py`. Checkout intentionally targets the
calling repository at `source_ref`, not this repository. Runs, artifacts,
`GITHUB_TOKEN` permissions, secrets, variables, and the GHCR image namespace
remain associated with the caller.

Publishing uses the version tag without a workflow run number, plus `latest`
and, for scheduled runs, `nightly`. The caller runs `get-version.yml`, then
`delete-image.yml`, then `publish.yml`. Deletion is separate from publishing and
only runs once the version is available and the required scan succeeds (or is
skipped for services without a scan). It removes any existing GHCR image version
carrying the exact version tag. This removes
all tags attached to that image version, not just the version tag; tags are
recreated by the subsequent pushes and can remain absent if publishing fails.
The caller's `GITHUB_TOKEN` needs package admin access to delete versions
(automatically granted for packages created by that repository's workflow),
in addition to `packages: write`. Public versions with more than 5,000 downloads
cannot be deleted through the API; deletion errors stop publication. The caller
serializes builds for the same repository and build path across deletion and
publication; other callers should provide equivalent concurrency control.

Temporary deletion test: publishing currently uses `VERSION.GITHUB_RUN_NUMBER`
and adds a run-specific image label to ensure a distinct digest. The caller
bypasses deletion while this second image version is created. Restore the
unnumbered tag, remove the test label step, and reconnect deletion after verifying
that both image versions exist.

Deploy these files to this repository's `main` branch before switching the
`docker-helix-p4` callers and removing their local copies.

## radicalgrimoire.github.io  
bad ideas deserve documentation.

## GitHub UI Toolkit  
GitHub Alerts don't work. When do we make them work? Now.

## Cal Toolkit  
Faith changes form, and in time becomes universal.
