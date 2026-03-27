# AI-Assisted Development

Development practices for projects using AI coding assistants.

## The Confidence Gap

Developers using AI assistants believe their code is more secure while studies show it is less secure. Research shows AI-generated code contains 1.7-2.74x more vulnerabilities than human-written code, with the most dangerous finding being that developers using AI assistants produce less secure code while believing it is more secure.

This confidence gap creates systematic under-investment in review. The antidote is treating AI output the same as any other code contribution: it gets reviewed, tested, and scanned before acceptance.

## Code Review Practices

Review AI-generated code with the same rigor as human code. Pay extra attention to common vulnerability patterns:

| CWE | Vulnerability Type | What to Look For |
|-----|-------------------|------------------|
| CWE-79 | Cross-Site Scripting (XSS) | Unescaped user input in HTML/JavaScript output, DOM manipulation without sanitization |
| CWE-89 | SQL Injection | String concatenation in SQL queries, missing parameterized queries |
| CWE-78 | OS Command Injection | Unsanitized input passed to shell commands, subprocess calls without validation |
| CWE-22 | Path Traversal | User-controlled file paths without canonicalization, missing path boundary checks |
| CWE-798 | Hardcoded Credentials | API keys, passwords, tokens embedded in source code |
| CWE-502 | Unsafe Deserialization | Deserialization of untrusted data, JSON parsing without schema validation |
| CWE-20 | Improper Input Validation | Missing boundary checks, type validation, or sanitization at system boundaries |
| CWE-117 | Log Injection | User input written to logs without escaping newlines or control characters |

AI-generated code has an 86-88% insecurity rate for XSS and log injection, making these the highest-priority review targets.

**Review focus areas:**

- Input validation at all system boundaries (HTTP, CLI, file I/O)
- Authentication and authorization logic
- Error handling and logging (check for information exposure)
- Dependency additions (see [Dependency Management](dependencies.md))

## Static Analysis Feedback Loop

Iterative feedback loops reduce vulnerability rates from 40% to 7%. Feeding SAST tool results back to the AI during development is more effective than running scans only in CI.

**Recommended workflow:**

1. AI generates code
2. Run static analysis (Bandit for Python, Semgrep cross-language)
3. Feed results back to AI with request to fix
4. Repeat until clean
5. Human review focuses on logic correctness, not common patterns

**Tool recommendations:**

| Language | Tool | Strengths |
|----------|------|-----------|
| Python | Bandit | 47 checks including AI/ML supply chain (torch.load, HuggingFace downloads) |
| Python | Semgrep | 2,000+ community rules, 20,000+ proprietary, AI-augmented triage |
| JavaScript/TypeScript | ESLint + security plugins | eslint-plugin-security (14 rules), eslint-plugin-no-unsanitized (DOM XSS) |
| Cross-language | Semgrep | 30+ languages, pattern-based rules, low false positive rate |

Integrate scanning into development cycle, not just CI. Run tools after every file write/edit when working with AI assistance.

## Test Quality

AI-generated tests achieve broader code coverage (75% vs 60% for human tests) but shallower fault detection (80% vs 90% bug detection rate). Critical failure modes:

| Failure Mode | Description | Detection Method |
|-------------|-------------|------------------|
| Tautological assertions | Tests assert what the code does, not what it should do | Mutation testing |
| Coverage without quality | 100% coverage can coexist with 4% mutation score | Mutation testing |
| Circular validation | AI writes both code and tests — bugs in logic are mirrored in tests | Independent test review, mutation testing |
| Pass-by-construction | Assertions guaranteed true regardless of behavior | Code review, mutation testing |

**Key finding:** Coverage numbers from AI-generated test suites deserve more skepticism than human-written ones. Statement coverage alone detects only 10% of faults.

**Mitigation:**

- Use mutation testing to verify test quality (see [python/testing.md](../python/testing.md) for mutation testing details)
- Set mutation score thresholds (e.g., >60%) as quality gates
- Review tests for behavioral assertions (not implementation coupling)
- Derive tests from requirements and acceptance criteria, not from implementation code

**Review checklist for AI-generated tests:**

1. Does the test validate behavior, not implementation?
2. Can the assertion be satisfied by a wrong implementation?
3. Are edge cases (null, empty, boundary, error) tested?
4. Would a mutation in the code cause an assertion to fail?
5. Are assertions meaningful (not just `assertNotNull`)?

When AI generates both code and tests in the same session, apply extra scrutiny. The AI has no independent source of truth.

## What This Standard Does NOT Cover

This standard addresses development practices for AI-assisted coding. It does not cover:

- Hook configuration for AI coding assistants
- MCP server security and trust
- AI tooling setup and access control
- Organizational governance for AI tool adoption
- OS-level sandboxing and permission systems

Those topics belong in environment and tooling configuration documentation.
