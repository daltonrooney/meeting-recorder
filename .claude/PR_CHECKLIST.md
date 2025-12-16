# Pre-PR and Pre-Commit Checklist

## Before Creating ANY Pull Request

- [ ] Re-read CLAUDE.md requirements for PRs
- [ ] Verify NO "Generated with Claude Code" footer
- [ ] Verify NO "Co-Authored-By: Claude" line
- [ ] Verify TDD evidence in commit history (test commits before feature commits)
- [ ] Verify all tests pass
- [ ] Verify PR description includes:
  - Summary of changes
  - Test coverage details
  - TDD evidence (commit sequence)
  - Clear verification steps

## Before Creating ANY Commit

- [ ] Re-read CLAUDE.md Git Safety Protocol
- [ ] Verify NO "Generated with Claude Code" footer in message
- [ ] Verify NO "Co-Authored-By: Claude Sonnet" line in message
- [ ] Verify commit message follows conventional commits format
- [ ] For test commits: Use `test:` prefix and mention they will fail (if TDD)
- [ ] For feature commits: Use `feat:` prefix and reference issue number
- [ ] Verify commit follows project conventions

## TDD-Specific Checks

- [ ] Tests written FIRST (separate commit)
- [ ] Test commit includes note that tests will fail
- [ ] Implementation commit comes AFTER test commit
- [ ] All tests passing before creating PR
- [ ] Commit history clearly shows test-first approach

## Project-Specific Checks

- [ ] Follows Swift 6 conventions
- [ ] No unnecessary comments or docstrings added to unchanged code
- [ ] No backwards-compatibility shims unless required
- [ ] No over-engineering beyond current requirements
