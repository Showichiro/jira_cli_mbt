# jira_cli_mbt

A Jira CLI tool written in [MoonBit](https://www.moonbitlang.com/) (JS backend). Interact with Jira from your terminal.

Licensed under Apache-2.0.

## Installation

### From npm

```sh
npm install -g @showichiro/jira-cli
```

### As a skill

Install the bundled `jira-cli-mbt` skill with a `skills.sh` compatible CLI:

```sh
npx skills add Showichiro/jira_cli_mbt
```

This installs the repository's Jira CLI skill so an agent can use the documented command workflows directly.

If you want to pin the skill name explicitly, or your skill manager requires an explicit target agent, add options as needed, for example:

```sh
npx skills add Showichiro/jira_cli_mbt --skill jira-cli-mbt -a codex
```

### From source

Requires [MoonBit toolchain](https://www.moonbitlang.com/download/) and Node.js >= 20.20.0.

```sh
npm run build
```

Run the CLI:

```sh
jira-cli <command> [options]
```

Or via `moon run` during development:

```sh
moon run --target js cmd/main -- <command> [options]
```

## Output formats

Read-only commands, `issue create`, `issue update`, and `describe` support a global `--format` option:

```sh
jira-cli --format json issue list
jira-cli issue get PROJ-123 --format tsv
```

- `table` — human-friendly default
- `tsv` — tab-separated rows for shell pipelines
- `json` — stable machine-readable output for agents and automation

Supported commands: `issue list`, `issue get`, `issue create`, `issue update`, `issue search`, `project list`, `field list`, `field get`, `describe`.

## Exit codes

The CLI now uses stable non-zero exit codes so automation can branch on failures without parsing prose.

| Exit code | Meaning |
|-----------|---------|
| `0` | Success |
| `1` | General failure |
| `2` | Usage / parse error |
| `3` | Not found |
| `4` | Config or authentication error |
| `5` | Validation / conflict error |

Successful output is written to stdout. Errors are written to stderr. When `--format json` is requested, error output on stderr is also JSON and includes recovery fields such as `candidates`, `required_args`, and `next_step` when the CLI can suggest a retry. `issue create` and `issue update` return a stable `mutation_result` envelope on stdout for applied and dry-run results, and partial-success `issue update` results use the same envelope on stderr. Paginated read-only JSON responses also include a `page` object with `start_at`, `limit`, `returned`, `total`, `fetch_all`, and `is_last`.

## Configuration

Before using any Jira commands, configure your connection:

```sh
jira-cli config [--base-url <url>] [--email <email>] [--api-token <token> | --api-token-stdin]
```

- `--base-url` — Your Jira instance URL (e.g. `https://yoursite.atlassian.net`)
- `--email` — Your Atlassian account email
- `--api-token` — Your Jira API token ([create one here](https://id.atlassian.com/manage-profile/security/api-tokens))
- `--api-token-stdin` — Read the API token from stdin instead of argv

The configuration is saved to `~/.config/jira_cli_mbt/config.json`.

Resolution order:

- `jira-cli config`: `flag > env > config`
- other Jira commands: `env > config`

Supported environment variables: `JIRA_BASE_URL`, `JIRA_EMAIL`, `JIRA_API_TOKEN`

## Commands

### help

Show general help or help for one command.

```sh
jira-cli help
jira-cli help issue
jira-cli help issue get
jira-cli issue --help
jira-cli issue get --help
jira-cli --help
jira-cli -h
```

### describe

Return the CLI's self-description for one command.

```sh
jira-cli describe <command...> [--format <table|tsv|json>]
```

- `<command>` — Command name or noun-verb path to describe
- `--format` — Output format (default: `table`; use `json` for automation)

Example:

```sh
jira-cli describe issue get --format json
```

### config

Set up Jira connection credentials.

```sh
jira-cli config [--base-url <url>] [--email <email>] [--api-token <token> | --api-token-stdin]
```

Examples:

```sh
jira-cli config --base-url https://your-site.atlassian.net --email you@example.com --api-token <token>
printf %s "$JIRA_API_TOKEN" | jira-cli config --base-url https://your-site.atlassian.net --email you@example.com --api-token-stdin
JIRA_BASE_URL=https://your-site.atlassian.net JIRA_EMAIL=you@example.com JIRA_API_TOKEN=token jira-cli config
```

Missing values are resolved with `flag > env > config`, so you can update only one field while reusing the saved config.

Canonical command forms use `noun verb` names such as `issue list` and `field get`. Legacy aliases such as `issues`, `create`, `projects`, and `fields` continue to work during the migration period.

### issue

Issue operations are grouped under `issue`:

```sh
jira-cli issue <subcommand> [options]
```

Subcommands: `list`, `get`, `create`, `update`, `transition`, `comment`, `assign`, `search`

### issue list

List issues matching a JQL query.

```sh
jira-cli issue list [--jql <query>] [--fields <field1,field2,...>] [--limit <n>] [--start-at <n>] [--all] [--format <table|tsv|json>]
```

- `--jql` — JQL query (default: `assignee = currentUser() ORDER BY updated DESC`)
- `--fields` — Comma-separated list of fields to display (default: `key,type,status,priority,summary`)
- `--limit` — Maximum number of issues to return (default: `20`)
- `--start-at` — Zero-based offset
- `--all` — Return all remaining issues from the offset (cannot be combined with `--limit`)

Example:

```sh
jira-cli issue list --jql "project = MYPROJ AND status = Open" --fields key,summary,status
jira-cli issue list --limit 5 --start-at 10
jira-cli issue list --format json
```

Legacy alias: `jira-cli issues`

### issue get

Show details of a single issue.

```sh
jira-cli issue get <key> [--fields <field1,field2,...>] [--format <table|tsv|json>]
```

- `<key>` — Issue key (e.g. `PROJ-123`)
- `--fields` — Comma-separated list of fields (default: `key,type,status,priority,assignee,summary,description`)

Example:

```sh
jira-cli issue get PROJ-123
jira-cli issue get PROJ-123 --format json
```

Legacy alias: `jira-cli issue PROJ-123`

### issue create

Create a new issue.

```sh
jira-cli issue create --project <key> --summary <text> [--type <type>] [--description <text>] [--set <field=value>]... [--dry-run] [--format <table|tsv|json>]
```

- `--project` — Project key (required)
- `--summary` — Issue summary (required)
- `--type` — Issue type (default: `Task`)
- `--description` — Issue description
- `--set` — Set a custom field value (repeatable, format: `customfield_xxxxx=value`)
- `--dry-run` — Preview the request without calling Jira
- `--format` — Output the preview or result as `table`, `tsv`, or `json`

Example:

```sh
jira-cli issue create --project MYPROJ --summary "Fix login bug" --type Bug --description "Login fails on Safari"
jira-cli issue create --project MYPROJ --summary "Fix login bug" --dry-run --format json
```

Legacy alias: `jira-cli create`

### issue update

Update an existing issue.

```sh
jira-cli issue update <key> [--summary <text>] [--description <text>] [--priority <name>] [--type <name>] [--labels <label1,label2>] [--assignee <email>] [--set <field=value>]... [--dry-run] [--format <table|tsv|json>]
```

- `<key>` — Issue key (required)
- `--summary` — New summary
- `--description` — New description
- `--priority` — Priority name
- `--type` — Issue type name
- `--labels` — Comma-separated labels
- `--assignee` — Assignee email
- `--set` — Set a custom field value (repeatable, format: `customfield_xxxxx=value`)
- `--dry-run` — Preview the update without calling Jira
- `--format` — Output the preview or result as `table`, `tsv`, or `json`

At least one field must be specified.

Example:

```sh
jira-cli issue update PROJ-123 --priority High --labels "backend,urgent"
jira-cli issue update PROJ-123 --summary "Refine rollout plan" --assignee user@example.com --dry-run --format json
```

Legacy alias: `jira-cli update`

### issue transition

Change the status of an issue.

```sh
jira-cli issue transition --key <key> --status <status>
```

- `--key` — Issue key (required)
- `--status` — Target status name (required)

Example:

```sh
jira-cli issue transition --key PROJ-123 --status "In Progress"
```

Legacy alias: `jira-cli transition`

### issue comment

Add a comment to an issue.

```sh
jira-cli issue comment --key <key> --text <text>
```

- `--key` — Issue key (required)
- `--text` — Comment text (required)

Example:

```sh
jira-cli issue comment --key PROJ-123 --text "Investigating the root cause"
```

Legacy alias: `jira-cli comment`

### issue assign

Assign an issue to a user.

```sh
jira-cli issue assign --key <key> --email <email>
```

- `--key` — Issue key (required)
- `--email` — Assignee's email (required)

Example:

```sh
jira-cli issue assign --key PROJ-123 --email alice@example.com
```

Legacy alias: `jira-cli assign`

### issue search

Search for issues using JQL. Returns issue keys and summaries.

```sh
jira-cli issue search --jql <query> [--limit <n>] [--start-at <n>] [--all] [--format <table|tsv|json>]
```

- `--jql` — JQL query (required)
- `--limit` — Maximum number of issues to return (default: `20`)
- `--start-at` — Zero-based offset
- `--all` — Return all remaining issues from the offset (cannot be combined with `--limit`)

Example:

```sh
jira-cli issue search --jql "text ~ 'performance' AND project = MYPROJ"
jira-cli issue search --jql "project = MYPROJ" --limit 10 --start-at 20
jira-cli issue search --jql "text ~ 'performance' AND project = MYPROJ" --format json
```

Legacy alias: `jira-cli search`

### project

Project operations are grouped under `project`:

```sh
jira-cli project <subcommand> [options]
```

Currently supported subcommand: `list`

### project list

List all accessible Jira projects.

```sh
jira-cli project list [--limit <n>] [--start-at <n>] [--all] [--format <table|tsv|json>]
```

- `--limit` — Maximum number of projects to return
- `--start-at` — Zero-based offset
- `--all` — Return all remaining projects from the offset (cannot be combined with `--limit`, default)

Example:

```sh
jira-cli project list --limit 20
jira-cli project list --format json
```

Legacy alias: `jira-cli projects`

### field

Field operations are grouped under `field`:

```sh
jira-cli field <subcommand> [options]
```

Subcommands: `list`, `get`

### field list

List custom fields.

```sh
jira-cli field list [--limit <n>] [--start-at <n>] [--all] [--format <table|tsv|json>]
```

- `--limit` — Maximum number of custom fields to return
- `--start-at` — Zero-based offset
- `--all` — Return all remaining custom fields from the offset (cannot be combined with `--limit`, default)

Example:

```sh
jira-cli field list --limit 50
jira-cli field list --format json
```

Legacy alias: `jira-cli fields`

### field get

Inspect one field in detail.

```sh
jira-cli field get <customfield_<id>> [--project <key>] [--type <name>] [--format <table|tsv|json>]
```

Examples:

```sh
jira-cli field get customfield_10001 --format json
jira-cli field get customfield_10001 --project APP --type Bug --format json
jira-cli field get customfield_10001 --project APP --format json
```

When `--project` is provided without `--type`, the CLI returns the project's issue types. In `--format json`, that discovery response includes `candidates`, `required_args`, and `next_step` so an agent can retry without parsing prose.

Legacy alias: `jira-cli fields <customfield_<id>>`

## Available Fields

The `--fields` flag accepts the following field names (case-insensitive):

| Field | Description |
|-------|-------------|
| `key` | Issue key (e.g. PROJ-123) |
| `summary` | Issue summary |
| `status` | Current status |
| `priority` | Priority level |
| `type` | Issue type (aliases: `issue_type`, `issuetype`) |
| `assignee` | Assigned user |
| `description` | Issue description |
| `customfield_*` | Any custom field by ID (e.g. `customfield_10001`) |

## Development

```sh
# Check for errors
moon check --target js

# Build
moon build --target js

# Run tests
moon test --target js

# Update test snapshots
moon test --target js --update

# Format code and update package info
moon info --target js && moon fmt
```
