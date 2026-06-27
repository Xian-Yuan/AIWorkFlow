# Spec: GitHub SSH Publish Workflow

## GIVEN
- The root repository can contain parallel uncommitted work.
- `origin` is protected from pushes.
- GitHub account `Xian-Yuan` owns `Xian-Yuan/AIWorkFlow`.
- The machine has an Ed25519 SSH key configured for GitHub over port 443.

## WHEN
- An Issuer or maintainer needs to publish a reviewed branch and integrate it into `main`.

## THEN

### S01: Authentication and remote safety
**Status**: [x]
- SSH authentication is checked without exposing private key material.
- `origin` remains protected and `gh` is the explicit writable remote.

### S02: Dirty workspace isolation
**Status**: [x]
- Publication runs from a clean ignored worktree when unrelated edits exist.

### S03: Branch and main publication
**Status**: [x]
- The reviewed branch and integrated `main` are pushed explicitly.
- Remote SHAs are compared with local SHAs.

### S04: Failure recovery
**Status**: [x]
- The procedure diagnoses HTTPS credentials, missing GitHub CLI, missing SSH agent, host key, and non-fast-forward failures.

## Acceptance Criteria

| AC# | Description | Verification Command | Expected Output |
|-----|-------------|---------------------|-----------------|
| AC01 | No secrets are committed | Content inspection | Only public configuration examples |
| AC02 | Parallel edits are preserved | Worktree procedure inspection | No in-place switch requirement |
| AC03 | Publication is verifiable | Command inspection | Local and remote SHA comparison |
| AC04 | Failures have recovery guidance | Troubleshooting inspection | Required cases present |
| AC05 | Document is discoverable | Docs index checks | Document 42 indexed |

## Quality Checklist
- [x] [OK] All known publishing requirements are covered.
- [x] [OK] Commands identify exact remotes and refs.
- [x] [OK] Git, SSH, GitHub, and local-config terms are explicit.
- [x] [OK] Main, edge, and failure paths are represented.
- [x] [OK] No secret material is required in repository files.

## Progress Summary
| Phase | Status | Key Decision |
|-------|--------|--------------|
| Plan | Complete | SSH port 443 + protected origin + writable gh |
| Implement | Complete | Documentation and indexes synchronized |
| Review | Pending | Issuer direct review |
| Verify | Pending | Automated checks complete; awaiting signed approval |

## Non-Goals
- Installing GitHub CLI.
- Managing GitHub repository permissions.
- Publishing child project repositories.
