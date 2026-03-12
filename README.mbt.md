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

## Configuration

Before using any Jira commands, configure your connection:

```sh
jira-cli config --base-url <url> --email <email> --api-token <token>
```

- `--base-url` — Your Jira instance URL (e.g. `https://yoursite.atlassian.net`)
- `--email` — Your Atlassian account email
- `--api-token` — Your Jira API token ([create one here](https://id.atlassian.com/manage-profile/security/api-tokens))

The configuration is saved to `~/.config/jira_cli_mbt/config.json`.

## Commands

### help

Show help message.

```sh
jira-cli help
jira-cli --help
jira-cli -h
```

### config

Set up Jira connection credentials.

```sh
jira-cli config --base-url <url> --email <email> --api-token <token>
```

All three flags are required.

### issues

List issues matching a JQL query.

```sh
jira-cli issues [--jql <query>] [--fields <field1,field2,...>]
```

- `--jql` — JQL query (default: `assignee = currentUser() ORDER BY updated DESC`)
- `--fields` — Comma-separated list of fields to display (default: `key,type,status,priority,summary`)

Example:

```sh
jira-cli issues --jql "project = MYPROJ AND status = Open" --fields key,summary,status
```

### issue

Show details of a single issue.

```sh
jira-cli issue <key> [--fields <field1,field2,...>]
```

- `<key>` — Issue key (e.g. `PROJ-123`)
- `--fields` — Comma-separated list of fields (default: `key,type,status,priority,assignee,summary,description`)

Example:

```sh
jira-cli issue PROJ-123
```

### create

Create a new issue.

```sh
jira-cli create --project <key> --summary <text> [--type <type>] [--description <text>] [--set <field=value>]...
```

- `--project` — Project key (required)
- `--summary` — Issue summary (required)
- `--type` — Issue type (default: `Task`)
- `--description` — Issue description
- `--set` — Set a custom field value (repeatable, format: `customfield_xxxxx=value`)

Example:

```sh
jira-cli create --project MYPROJ --summary "Fix login bug" --type Bug --description "Login fails on Safari"
```

### update

Update an existing issue.

```sh
jira-cli update <key> [--summary <text>] [--description <text>] [--priority <name>] [--type <name>] [--labels <label1,label2>] [--assignee <email>] [--set <field=value>]...
```

- `<key>` — Issue key (required)
- `--summary` — New summary
- `--description` — New description
- `--priority` — Priority name
- `--type` — Issue type name
- `--labels` — Comma-separated labels
- `--assignee` — Assignee email
- `--set` — Set a custom field value (repeatable, format: `customfield_xxxxx=value`)

At least one field must be specified.

Example:

```sh
jira-cli update PROJ-123 --priority High --labels "backend,urgent"
```

### transition

Change the status of an issue.

```sh
jira-cli transition --key <key> --status <status>
```

- `--key` — Issue key (required)
- `--status` — Target status name (required)

Example:

```sh
jira-cli transition --key PROJ-123 --status "In Progress"
```

### comment

Add a comment to an issue.

```sh
jira-cli comment --key <key> --text <text>
```

- `--key` — Issue key (required)
- `--text` — Comment text (required)

Example:

```sh
jira-cli comment --key PROJ-123 --text "Investigating the root cause"
```

### assign

Assign an issue to a user.

```sh
jira-cli assign --key <key> --email <email>
```

- `--key` — Issue key (required)
- `--email` — Assignee's email (required)

Example:

```sh
jira-cli assign --key PROJ-123 --email alice@example.com
```

### search

Search for issues using JQL. Returns issue keys and summaries.

```sh
jira-cli search --jql <query>
```

- `--jql` — JQL query (required)

Example:

```sh
jira-cli search --jql "text ~ 'performance' AND project = MYPROJ"
```

### projects

List all accessible Jira projects.

```sh
jira-cli projects
```

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
moon fmt && moon info --target js
```
