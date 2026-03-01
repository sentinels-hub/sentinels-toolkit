# sentinels-toolkit

CLI toolkit for the Sentinels Hub ecosystem. Provides health monitoring, changelog generation, and contract visualization for multi-repo projects managed with the Sentinels workflow.

## Installation

### Quick install

```bash
git clone https://github.com/sentinels-hub/sentinels-toolkit.git
cd sentinels-toolkit
make install
```

This copies `bin/sentinels-toolkit` to `~/.local/bin/`. Make sure that directory is in your `PATH`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

### Manual

Just add the `bin/` directory to your `PATH`:

```bash
export PATH="/path/to/sentinels-toolkit/bin:$PATH"
```

## Dependencies

- **bash** 4.0+
- **jq** — JSON processing
- **gh** — GitHub CLI (authenticated)
- **curl** — HTTP requests
- **git** — for changelog generation

## Usage

### `sentinels-toolkit health`

Show a health dashboard for all repositories in a GitHub organization.

```bash
# Default: sentinels-hub org
sentinels-toolkit health

# Custom org
sentinels-toolkit health --org my-org
```

Displays:
- Repository name
- Open PRs count
- CI checks status (passing/failing/mixed)
- Active contract detection
- Last push date

### `sentinels-toolkit changelog`

Generate a changelog from conventional commits.

```bash
# Generate CHANGELOG.md in current repo
sentinels-toolkit changelog

# Print to stdout
sentinels-toolkit changelog --stdout

# From a specific tag
sentinels-toolkit changelog --since v1.0.0

# Different repo path
sentinels-toolkit changelog --repo /path/to/repo

# Custom output file
sentinels-toolkit changelog --output HISTORY.md
```

Supports conventional commit types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`.

Groups commits by version tags when present.

### `sentinels-toolkit contract`

View contract status from `.sentinels/contract.json` (read-only).

```bash
# Current directory
sentinels-toolkit contract

# Specific project path
sentinels-toolkit contract /path/to/project
```

Displays:
- Contract ID, status, actor
- Work package reference
- Gates with color-coded status (🟢 passed, 🔴 failed, ⚪ pending, 🟡 skipped)
- Timeline (created/updated)
- Links (evidence, PR, commit)

## Testing

```bash
# Run all tests
make test

# Or directly
bash tests/run-all.sh
```

## Linting

```bash
make lint
```

Requires [shellcheck](https://github.com/koalaman/shellcheck).

## Project Structure

```
bin/sentinels-toolkit       ← Main dispatcher (entry point)
lib/colors.sh               ← ANSI colors with TTY detection
lib/deps.sh                 ← Dependency validation
lib/table.sh                ← Table/box formatting utilities
commands/health.sh           ← Health dashboard command
commands/changelog.sh        ← Changelog generator command
commands/contract.sh         ← Contract viewer command
tests/run-all.sh            ← Test runner
tests/test-*.sh             ← Test suites
tests/fixtures/             ← Test fixtures
Makefile                    ← Build targets
.shellcheckrc               ← ShellCheck config
```

## Contributing

1. Create a branch: `feat/wp-<ID>-<description>`
2. Use conventional commits: `feat(scope): description`
3. Ensure tests pass: `make test`
4. Ensure linting passes: `make lint`

## License

Internal — Sentinels Hub
