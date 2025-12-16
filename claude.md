# Meeting Recorder - AI Development Guidelines

## ⚠️ **CRITICAL: TEST-DRIVEN DEVELOPMENT (TDD) MANDATORY** ⚠️

**🚨 THIS PROJECT USES TDD - NO EXCEPTIONS 🚨**

### **ABSOLUTE REQUIREMENTS:**

1. **TESTS MUST BE WRITTEN FIRST** - Before writing ANY feature code
2. **TESTS WILL FAIL INITIALLY** - This is expected and correct
3. **IMPLEMENTATION FOLLOWS TESTS** - Only after tests are complete
4. **NO PR WITHOUT PASSING TESTS** - PRs cannot be raised until all tests pass

### **TDD Workflow (MANDATORY):**

```
1. Write tests FIRST (they will fail - this is correct)
2. Run tests to verify they fail as expected
3. Implement the minimal code to make tests pass
4. Run tests again - they must pass
5. Refactor if needed (tests must still pass)
6. Only then create PR with passing tests
```

### **What This Means:**

- ❌ **NEVER** write feature code before writing tests
- ❌ **NEVER** create a PR with failing tests
- ❌ **NEVER** skip writing tests "to save time"
- ❌ **NEVER** modify a test once it's been committed in order to pass an incomplete or failing feature.
- ✅ **ALWAYS** write comprehensive tests first
- ✅ **ALWAYS** ensure tests fail initially (proves they work)
- ✅ **ALWAYS** commit failing tests before progressing to feature development
- ✅ **ALWAYS** verify all tests pass before PR

### **Example TDD Cycle:**

Step 1: Write test FIRST
Step 2: Run test - IT WILL FAIL
Step 3: Commit test before proceeding to feature implementation
Step 4: Implement feature to make test pass
Step 5: Run test again - IT MUST PASS
Step 6: Refactor if needed, tests still pass
Step 7: Create PR with passing tests

### **Documenting TDD in Pull Requests:**

To verify TDD methodology was followed, PRs **MUST** include the following:

1. **Commit History Approach**:
   - Separate commits showing test-first development
   - Commit sequence like: `test: add channel creation tests` → `feat: implement channel creation`
   - This provides clear evidence of TDD workflow

**Example commit sequence:**
```
✅ test: add tests for channel creation endpoint
✅ feat: implement channel creation to pass tests
✅ test: add tests for channel member management
✅ feat: implement channel member functionality
```

**Why this matters:** Without evidence of test-first development, reviewers cannot verify that TDD was actually followed. This accountability ensures the methodology is respected.

**If you find yourself writing feature code without tests already written, STOP IMMEDIATELY and write the tests first.**
