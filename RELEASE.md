# Release Process

Concise steps to cut a release. Uses GitHub CLI (`gh`) and Xcode + SwiftPM.

1) Create a release branch
- Name: `release/vX.Y.Z`
- Commands:
  - `git switch -c release/vX.Y.Z`

2) Bump version + changelog
- Update versions in:
  - `xcode/Info.plist` (CFBundleShortVersionString, CFBundleVersion)
  - `xcode/project.yml` (marketing/build if applicable)
- CHANGELOG:
  - Add a new `## vX.Y.Z - YYYY-MM-DD` section with highlights.
- Commit:
  - `git add -A && git commit -m "chore(version): bump to X.Y.Z; update changelog" && git push -u origin HEAD`

3) Open PR and ensure CI is green
- `gh pr create --fill` (or `-t <title> -b <body>`)
- CI (self-hosted): Xcode Build/Test + Lint must pass.
- Update PR body with highlights and a short checklist.

4) Merge via squash
- `gh pr merge --squash --delete-branch` (into `main`)

5) Tag and publish release
- Tag: `git checkout main && git pull --ff-only && git tag -a vX.Y.Z -m "vX.Y.Z" && git push origin vX.Y.Z`
- Release notes:
  - `gh release create vX.Y.Z --notes-file <notes.md>` (or `--generate-notes`)

6) Post-release
- Start next dev cycle:
  - `git switch -c release/vX.Y.(Z+1)` and repeat step 2 (bump to next version, add Unreleased section in CHANGELOG).
- Update `implementationplan.md` and close out completed items with PR/commit links.

Notes
- Use `gh auth login` once to set up GitHub CLI.
- Self-hosted CI runs on `runs-on: self-hosted`. The SwiftPM job is disabled to avoid toolchain cache issues; Xcode jobs are the source of truth for app validation.
