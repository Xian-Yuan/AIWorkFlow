# Routing: vsummary Provider Credential Hotfix

## Router Decision
- Project: Jinli integration with the external vsummary installation.
- Project type: web.
- Main skill: web-fullstack.
- Secondary skills: systematic-debugging, test-driven-development, verification-before-completion, doc-governance.
- Collaboration mode: lead-only bounded hotfix.
- Task packet root: `.trae/tasks/jinli/2026-06-21-vsummary-provider-credential-hotfix`.

## Quality Gate
- Default quality level: Mature production-grade
- MVP/prototype requested by user: no
- Mature Solution Evidence: `analysis.md#Mature-Solution-Evidence`
- Rejected shortcuts reviewed: yes
- User confirmation must include quality level: yes

## Work Package Policy
- External workers: no
- Task packet root: .trae/tasks/jinli/2026-06-21-vsummary-provider-credential-hotfix
- Work packages required: no
- Claim files required: no
- Worker reports required before merge: no

## Fast Track Assessment
- Expected behavior is concrete: yes
- Change is bounded: yes
- Architecture or data ownership change: no
- User journey redesign: no
- Unresolved high-impact implicit requirements: none
- Verification is bounded: yes
- Fast-track reason: The failure is a confirmed invalid credential value at one configuration boundary with a focused API regression path.

## Scope
- Restore a valid provider credential without printing it.
- Add backend validation that rejects non-ASCII, masked, or explanatory placeholder values.
- Add regression tests before implementation.
- Verify provider connection and the original video generation endpoint.
- Record operational guidance in Jinli project documentation.
