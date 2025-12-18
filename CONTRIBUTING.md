# Contributing to Olive

Thank you for your interest in contributing to Olive! This document provides guidelines for contributing to the project.

## Test-Driven Development (TDD)

**This project strictly follows TDD methodology:**

1. **Write tests FIRST** - Before implementing any feature
2. **Tests must fail initially** - This proves they work
3. **Implement to make tests pass** - Minimal code to pass tests
4. **Refactor** - Clean up while keeping tests green
5. **No PRs without passing tests** - All tests must pass before review

## Automation Support Requirements

Olive provides automation through App Intents (Shortcuts) and AppleScript. **All new user-facing features must evaluate automation support.**

### When to Add Automation

Consider automation support for features that:
- Control recording lifecycle (start, stop, pause, resume)
- Modify app settings or configuration
- Query app state or status
- Trigger actions or workflows
- Export or process data

### Required Steps for Automated Features

1. **App Intents** (for Shortcuts/Siri support):
   - Create new `AppIntent` struct in `CallTranscription/Intents/`
   - Implement `perform()` method with `@MainActor` annotation
   - Use `nonisolated(unsafe)` for static properties
   - Return appropriate `IntentResult` types
   - Update `AppShortcutsProvider` with new shortcuts
   - Follow Swift 6 strict concurrency guidelines

2. **AppleScript** (for scripting support):
   - Add command definition to `Olive.sdef`
   - Create `NSScriptCommand` subclass in `CallTranscription/AppleScript/`
   - Use `@unchecked Sendable` ResultBox pattern for thread safety
   - Implement property accessors in `ScriptableApplication.swift` if needed
   - Use `DispatchQueue.main` for MainActor synchronization

3. **Testing**:
   - Add unit tests for all new intents/commands
   - Add integration tests for workflows
   - Manual testing in Shortcuts app
   - Manual testing in Script Editor
   - Test error handling and edge cases

4. **Documentation**:
   - Add examples to AUTOMATION.md (when created)
   - Include usage examples in PR description
   - Document parameters and return types
   - Provide sample shortcuts or scripts

### Non-Automatable Features

If a feature should NOT be automated, document the reasoning in the PR:
- UI-only interactions (preferences window)
- Visual feedback (status indicators)
- Features requiring user interaction
- Security-sensitive operations

## Swift 6 Concurrency

Olive uses Swift 6 with strict concurrency enabled. Follow these guidelines:

### MainActor Isolation
- `AppState` and `SettingsManager` are `@MainActor` isolated
- Use `@MainActor` annotations for intent `perform()` methods
- Access shared state through `AppStateContainer.shared`

### Sendable Types
- Use `@unchecked Sendable` for ResultBox patterns in AppleScript
- Mark static intent properties with `nonisolated(unsafe)`
- Ensure thread safety with `DispatchQueue.main.sync/async`

### Common Patterns
```swift
// App Intent example
@available(macOS 13.0, *)
struct MyIntent: AppIntent {
    nonisolated(unsafe) static var title: LocalizedStringResource = "My Action"

    @MainActor
    func perform() async throws -> some IntentResult {
        let appState = try AppStateContainer.shared.requireAppState()
        // Implementation
        return .result()
    }
}

// AppleScript command example
@preconcurrency @objc(MyCommand)
final class MyCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        final class ResultBox: @unchecked Sendable {
            var value: String?
        }
        let box = ResultBox()

        DispatchQueue.main.sync {
            // Access AppState/SettingsManager
            box.value = "result"
        }

        return box.value
    }
}
```

## Code Quality Standards

- Follow Swift naming conventions
- Add documentation comments for public APIs
- Keep functions focused and single-purpose
- Avoid over-engineering - implement what's needed
- No commented-out code in commits
- Use meaningful variable and function names

## Pull Request Process

1. Create a feature branch from `dev`
2. Follow TDD: write tests first, then implementation
3. Ensure all tests pass locally
4. Run build to verify no warnings
5. Fill out the PR template completely
6. Address automation checklist (if applicable)
7. Wait for automated Claude review
8. Address all review feedback
9. Squash merge after approval

## Questions?

If you're unsure about automation requirements or implementation approach:
1. Ask in the PR before implementing
2. Reference existing patterns in the codebase
3. Check AUTOMATION.md for examples (when available)
4. Review similar features for consistency

Thank you for contributing to Olive!
