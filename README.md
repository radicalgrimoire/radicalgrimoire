# radicalgrimoire

I’m souhei-ueno. A degenerate piece of shit with zero control over his libido, making questionable life choices and somehow still pursuing engineering. That’s who I am.

## Docker Helixcore  
p4 — apparently, “before” was just too much work to type.

### Reusable Docker workflows

The following definitions are called by
[docker-helix-p4](https://github.com/radicalgrimoire/docker-helix-p4) at `@main`:

- [build.yml](.github/workflows/build.yml): Build, test, and upload an image artifact.
- [get-version.yml](.github/workflows/get-version.yml): Extract image version outputs.
- [publish.yml](.github/workflows/publish.yml): Publish the image to GHCR.
- [scan.yml](.github/workflows/scan.yml): Scan the image artifact with Trivy.

These are `workflow_call` definitions, not standalone entry points. They expect
the caller's `build/<build_path>` configuration and scripts; the scan also uses
the caller's `scripts/summarize_trivy.py`. Checkout intentionally targets the
calling repository at `source_ref`, not this repository. Runs, artifacts,
`GITHUB_TOKEN` permissions, secrets, variables, and the GHCR image namespace
remain associated with the caller.

Deploy these files to this repository's `main` branch before switching the
`docker-helix-p4` callers and removing their local copies.

## radicalgrimoire.github.io  
bad ideas deserve documentation.

## GitHub UI Toolkit  
GitHub Alerts don't work. When do we make them work? Now.

## Cal Toolkit  
Faith changes form, and in time becomes universal.
