# Routing: Issuer-Worker Authority Separation

## Route

- Project type: other
- System: shared AI workflow authority
- Lead skill: codex-project-router
- Supporting skills: writing-plans, test-driven-development, systematic-debugging, verification-before-completion
- Collaboration mode: Codex issuer direct implementation

## Quality Gate

- Default quality level: Mature production-grade
- MVP/prototype requested by user: no
- Mature Solution Evidence: analysis.md#Mature-Solution-Evidence
- Rejected shortcuts reviewed: yes
- User confirmation must include quality level: yes

## Work Package Policy

- External workers: no
- Task packet root: .trae/tasks/_shared/2026-06-19-issuer-worker-authority-separation
- Work packages required: no
- Claim files required: no
- Worker reports required before merge: no

## Authority Policy

- Authority profile: issuer-worker-v1
- Issuer identity: Windows SID plus non-exportable CNG key
- Worker identity: separate Windows SID
- Packet mutation authority: issuer only
- Review authority: original issuer only
- Verify authority: original issuer only
- Archive authority: original issuer only
- Verify auto-archive: forbidden
- Legacy unsigned trust: forbidden

## Confirmed Design

- Selected mature path: signed capability workflow with OS identity separation
- Rejected shortcut: model-name or command-line actor fields as identity
- Rejected shortcut: same-process self-review
- Rejected shortcut: Verify implicitly setting Archive
- Completeness: signing, packet seal, worker submission, review, archive, repair ownership, migration, tests, and docs
