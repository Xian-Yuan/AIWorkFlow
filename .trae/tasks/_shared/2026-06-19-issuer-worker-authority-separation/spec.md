# Spec: Issuer-Worker Authority Separation

### S01: Non-exportable issuer identity
**Status**: [x]

The issuer creates a user-owned CNG signing key whose private material cannot be exported.

### S02: Signed packet seal
**Status**: [x]

The issuer seals the exact authoritative packet files and work packages with a signed manifest and monotonically increasing version.

### S03: Separate worker identity
**Status**: [x]

Strong-mode capability issuance fails when worker SID equals issuer SID.

### S04: Worker core mutation denied
**Status**: [x]

The worker cannot modify task state, specification, task list, routing, analysis, work packages, approvals, or evidence.

### S05: Signed bounded capability
**Status**: [x]

The worker receives one signed attempt capability with exact source paths, progress directory, result path, packet hash, work-package hash, expiry, and nonce.

### S06: Append-only submission
**Status**: [x]

The worker may append progress and create one result but cannot overwrite either artifact or claim acceptance authority.

### S07: Issuer-only review
**Status**: [x]

Only the original issuer SID/key can sign accept or reject decisions from a fresh review context.

### S08: Approval invalidation
**Status**: [x]

Packet, source diff, evidence, work-package, or acceptance-criteria changes invalidate an earlier approval.

### S09: Issuer-only repair
**Status**: [x]

Only the issuer can record a failed review, update the packet, publish a repair package, or resolve repair state.

### S10: Explicit archive
**Status**: [x]

Verify never archives; only a separate issuer command with valid accepted approval can archive.

### S11: No role spoofing
**Status**: [x]

Model names, prompt roles, command-line actor fields, and ordinary environment variables grant no authority.

### S12: Legacy migration
**Status**: [x]

Unsigned legacy tasks become `legacy_untrusted`; contradictory task states become `migration_required`; no historical signature is fabricated.

### S13: Cross-IDE protocol
**Status**: [x]

Codex, OpenCode, Trae, and DS4 consume the same artifacts and identity rules.

### S14: Full regression
**Status**: [x]

Focused authority tests, repair tests, shared workflow regression, parser checks, and documentation checks pass.

## Acceptance Criteria

See `analysis.md` AC01-AC14. Each scenario maps one-to-one to the corresponding authority behavior.

## Progress Summary

| Phase | Status |
|---|---|
| Plan | Complete |
| Implement | Complete |
| Review | Complete - issuer security review and hardening |
| Verify | Complete - signed evidence and full regression |
