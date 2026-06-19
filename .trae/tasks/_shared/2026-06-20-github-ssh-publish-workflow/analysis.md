# Analysis: GitHub SSH Publish Workflow

## Architecture Context

### System boundaries
- The root Git repository owns workflow source, documentation, task packets, and root-level release history.
- GitHub repository `Xian-Yuan/AIWorkFlow` is the publication target.
- Project child repositories remain outside this root publishing procedure.

### Dependency map
- Local root repository -> Git remote `gh` -> GitHub SSH endpoint.
- Windows OpenSSH reads `~/.ssh/config` and `~/.ssh/id_ed25519`.
- Workspace policy keeps `origin.pushurl` disabled while `gh` is the explicit writable remote.
- Dirty parallel work is isolated from release operations with `git worktree`.

### Data and state ownership
- Git commits and refs own publishable repository state.
- `~/.ssh` owns machine-local credentials and is never committed.
- `.git/config` owns machine-local remote aliases and is never treated as portable repository configuration.
- This document owns the portable procedure and troubleshooting contract.

### Integration points
- `ssh -T git@github.com` validates account authentication.
- `git fetch gh --prune` refreshes remote state before integration.
- `git push gh <branch>` publishes explicit refs.
- `git ls-remote gh refs/heads/<branch>` provides post-push SHA evidence.

## Mature Solution Evidence

### Project-local evidence
- `Docs/AI/39-Root-Git-Workspace-Boundary.md` defines root repository boundaries and push protection.
- Local Git config uses `origin` as fetch-only/protected and `gh` as the writable remote.
- The current workspace contains parallel uncommitted Hermes work, proving that in-place branch switching is unsafe.

### Official/framework evidence
- Git supports multiple named remotes and explicit refspec pushes.
- OpenSSH supports per-host aliases, explicit identity files, and GitHub SSH over port 443.

### External mature references
- GitHub SSH authentication uses the `git` SSH user and repository path `owner/repository.git`.
- GitHub returns a successful authentication message while intentionally denying shell access.

### Options compared
| Option | Pros | Cons | Decision |
|---|---|---|---|
| HTTPS with credential helper | Familiar URL | Current machine has no usable HTTPS credential and `gh` CLI is absent | Reject |
| SSH through `ssh.github.com:443` | Existing key works, no token in files, survives blocked port 22 | Requires machine-local SSH config | Select |
| Change protected `origin` to writable | Fewer remote names | Removes workspace push safety | Reject |
| Keep protected `origin`, write through `gh` | Explicit intent and safer automation | One extra remote name | Select |

### Rejected shortcuts
- Do not use `git add -A` in a mixed worktree.
- Do not switch `main` inside a dirty worktree.
- Do not copy private keys or tokens into repository files.
- Do not treat a successful local push command as sufficient without remote SHA verification.
- Do not bypass the protected `origin` push URL.

### Selected mature path
- Authenticate with the existing Ed25519 key through SSH port 443.
- Keep `origin` protected and use `gh` as the explicit writable remote.
- Integrate from a clean ignored worktree.
- Push explicit source and destination refs.
- Compare local and remote commit SHAs after every push.
- Store the portable procedure in `Docs/AI/42-GitHub-SSH-Publish-Workflow.md`.

## Acceptance Criteria
- AC01: The document records repository identity, remote roles, and SSH port 443 configuration without secrets.
- AC02: The document defines clean-worktree integration and preserves unrelated changes.
- AC03: The document provides branch and main push commands with post-push SHA verification.
- AC04: The document covers missing `gh` CLI, HTTPS credential failure, SSH-agent absence, and protected-origin behavior.
- AC05: Global workflow indexes include document 42.

## Automated Verification Plan
- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\test-doc-guard.ps1`
- Expected: all documentation governance tests pass.
- Command: `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\update-docs-tree.ps1 -Mode check`
- Expected: docs-tree check passes.
- Command: `Select-String` assertions over document 42.
- Expected: repository, SSH, worktree, push, and SHA verification sections exist.
