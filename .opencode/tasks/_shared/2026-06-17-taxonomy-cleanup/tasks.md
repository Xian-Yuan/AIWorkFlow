# Tasks: Taxonomy Cleanup

- [x] 1. Read Docs/AI/document-taxonomy-inventory.md to locate all legacy-project-mirror-candidate references for airpgweb, characterdesigntool, rts
- [x] 2. Update labels:
  - Docs/airpgweb/ → legacy-project-mirror-redirects
  - Docs/characterdesigntool/ → legacy-project-mirror-redirects
  - Docs/rts/ → legacy-project-mirror-empty
- [x] 3. Update any prose text that describes these dirs as "candidates" or "not yet migrated"
- [x] 4. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\.trae\scripts\update-docs-tree.ps1 -Mode check` to verify
- [x] 5. Run `rg "legacy-project-mirror-candidate" "Docs/AI/document-taxonomy-inventory.md"` to confirm zero matches for the three dirs
- [x] 6. Mark this task complete in .task.yaml
