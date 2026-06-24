---
domain: ai
domain_path: ai/workflow
kg_node_id: node.doc-ai-ai-42-github-ssh-publish-workflow-71e9
t13_retro_classified_at: "2026-06-24T04:47:04Z"
kg_id: doc.ai.ai.42-github-ssh-publish-workflow.71e9

---

# GitHub SSH Publish Workflow

Date: 2026-06-20
Status: Active
Scope: root repository publication to `Xian-Yuan/AIWorkFlow`

## Purpose

This document is the repeatable publication procedure for the root
`E:\UEGameDevelopment` Git repository. It preserves unrelated working changes,
keeps the protected remote protected, authenticates with SSH, and verifies the
remote commit after every push.

It does not publish independent repositories under `Project/<Name>/.git`.

## Current Machine Contract

| Setting | Value |
|---|---|
| Git author | `Xian-Yuan <xinj3968@gmail.com>` |
| GitHub repository | `Xian-Yuan/AIWorkFlow` |
| Protected fetch remote | `origin` |
| Explicit writable remote | `gh` |
| Writable URL | `git@github.com:Xian-Yuan/AIWorkFlow.git` |
| SSH identity | `~/.ssh/id_ed25519` |
| SSH endpoint | `ssh.github.com:443` |

`origin.pushurl` must remain `DISABLED_BY_WORKSPACE_POLICY`. Publication uses
`gh` so an automated command cannot accidentally bypass the root repository
boundary policy.

Machine-local SSH configuration:

```sshconfig
Host github.com
    HostName ssh.github.com
    Port 443
    User git
    IdentityFile ~/.ssh/id_ed25519
```

Never commit the private key, passphrase, token, credential-helper output, or
the contents of `~/.ssh`.

## One-Time Setup

Inspect identity and remotes:

```powershell
git config user.name
git config user.email
git remote -v
```

Configure only the explicit writable remote:

```powershell
git remote set-url gh git@github.com:Xian-Yuan/AIWorkFlow.git
```

Test authentication:

```powershell
ssh -o BatchMode=yes -T git@github.com
```

Success contains the authenticated GitHub username and the statement that
GitHub does not provide shell access. GitHub documents that this successful
test normally exits with code `1`, so judge it by the identity message rather
than by exit code alone.

Official references:

- [Testing an SSH connection](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/testing-your-ssh-connection)
- [Using SSH over port 443](https://docs.github.com/en/authentication/troubleshooting-ssh/using-ssh-over-the-https-port)
- [git-push](https://git-scm.com/docs/git-push)
- [git-worktree](https://git-scm.com/docs/git-worktree)

## Publication Gate

Before publishing:

1. Confirm the task passed its final Issuer Review, Verify, and explicit Archive.
2. Record the accepted commit SHA.
3. Run the task's full automated verification from that commit.
4. Inspect `git status -sb`.
5. Never include unrelated working-tree changes.

When the main checkout is dirty, create an ignored worktree:

```powershell
git check-ignore -v .worktrees
git worktree add E:\UEGameDevelopment\.worktrees\publish `
  -b codex/<publish-name> <accepted-commit>
```

Root-policy directories such as `Project/` and `.codex/` are intentionally not
checked out because they are ignored. If a repository verification script
needs to read them, create worktree-local junctions. Codex capability tests
also require `.agents/skills` to target the worktree's canonical `skills/`:

```powershell
$root = "E:\UEGameDevelopment"
$worktree = "E:\UEGameDevelopment\.worktrees\publish"
New-Item -ItemType Junction -Path "$worktree\Project" -Target "$root\Project"
New-Item -ItemType Junction -Path "$worktree\.codex" -Target "$root\.codex"
New-Item -ItemType Directory -Path "$worktree\.agents" -Force
New-Item -ItemType Junction -Path "$worktree\.agents\skills" `
  -Target "$worktree\skills"
```

These junctions are environment setup, not repository content. Confirm they
remain ignored with `git status -sb`.

Do not switch branches, stash, reset, or clean the dirty main checkout merely
to publish another task.

## Publish A Reviewed Branch

Refresh remote refs:

```powershell
git fetch gh --prune
```

Push the exact branch:

```powershell
$branch = git branch --show-current
git push -u gh $branch
```

Verify the remote SHA:

```powershell
$local = git rev-parse HEAD
$remote = (git ls-remote gh "refs/heads/$branch").Split("`t")[0]
if ($local -ne $remote) { throw "Remote branch SHA mismatch" }
```

## Integrate And Publish Main

Use a clean integration worktree. Fetch before merging and refuse hidden
history rewrites:

```powershell
git fetch gh --prune
git merge-base --is-ancestor gh/main HEAD
```

If the reviewed branch descends from `gh/main`, update local `main` by
fast-forward:

```powershell
git switch main
git merge --ff-only <reviewed-branch>
```

Run the complete verification again on merged `main`, then push the exact ref:

```powershell
git push gh main:main
```

Verify publication:

```powershell
$local = git rev-parse main
$remote = (git ls-remote gh refs/heads/main).Split("`t")[0]
if ($local -ne $remote) { throw "Remote main SHA mismatch" }
```

Do not delete the reviewed branch until remote `main` matches the accepted
commit and all merged verification passes.

## Pull Requests

GitHub CLI is optional for Git transport. On a machine where `gh` CLI is
installed and authenticated, a reviewed branch may be published as a draft
pull request before merging:

```powershell
gh auth status
gh pr create --draft --base main --head <branch>
```

If `gh` CLI is unavailable, SSH `git push` still works. Create the pull request
in GitHub's web UI, or perform a direct fast-forward merge only when the user
explicitly authorizes it.

## Failure Recovery

### HTTPS reports missing credentials

Symptom:

```text
SEC_E_NO_CREDENTIALS
```

Cause: the HTTPS remote has no usable Windows credential. Confirm `gh` uses the
SSH URL and retry through SSH. Do not store a token in repository files.

### `ssh-add -l` cannot connect to an agent

This does not prove SSH authentication is broken. The configured
`IdentityFile` can be loaded directly by OpenSSH. Test with:

```powershell
ssh -o BatchMode=yes -T git@github.com
```

### Host key prompt appears

Compare the displayed fingerprint with GitHub's published SSH fingerprints
before accepting it. Port 443 uses host `ssh.github.com`.

### `origin` rejects a push

This is expected workspace protection. Push to `gh`; do not remove
`origin.pushurl=DISABLED_BY_WORKSPACE_POLICY`.

### Push is non-fast-forward

Stop, fetch, and compare:

```powershell
git fetch gh --prune
git log --oneline --left-right --graph gh/main...main
```

Do not force-push `main`. Review the divergence in a clean worktree and merge
or rebase only with explicit user approval.

## Completion Evidence

A publication is complete only when all are true:

- local verification exited successfully;
- the intended branch or `main` push exited successfully;
- `git ls-remote` reports the same SHA as the local ref;
- unrelated working changes remain untouched;
- the final response names the repository, branch, commit, and verification.
