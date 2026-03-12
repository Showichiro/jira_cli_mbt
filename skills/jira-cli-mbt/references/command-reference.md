# Jira CLI Command Reference

Use `jira-cli` in the examples below. If that binary is unavailable, substitute `jira-cli-mbt`, `node dist/cli.mjs`, or `moon run --target js cmd/main --`.

## Setup

Configure Jira access:

```sh
jira-cli config --base-url https://your-site.atlassian.net --email you@example.com --api-token <token>
```

The config file lives at `~/.config/jira_cli_mbt/config.json`.

## Read-Only Commands

List the current user's recently updated issues:

```sh
jira-cli issues
```

List issues for a custom JQL query:

```sh
jira-cli issues --jql "project = APP AND status = Open ORDER BY priority DESC"
```

Select list columns with `--fields`:

```sh
jira-cli issues --fields key,assignee,summary,customfield_10001
```

Get one issue:

```sh
jira-cli issue APP-123
jira-cli issue APP-123 --fields key,status,assignee,summary,description
```

Search requires explicit JQL:

```sh
jira-cli search --jql "text ~ \"outage\" AND project = APP"
```

List projects:

```sh
jira-cli projects
```

List custom fields:

```sh
jira-cli fields
```

Inspect a custom field:

```sh
jira-cli fields customfield_10001
```

Inspect a custom field for a project and issue type so the CLI can show allowed options:

```sh
jira-cli fields customfield_10001 --project APP --type Bug
```

If the project is known but the issue type is not, call:

```sh
jira-cli fields customfield_10001 --project APP
```

The CLI responds with the available issue types for that project.

## Mutating Commands

Create an issue:

```sh
jira-cli create --project APP --summary "Fix login bug" --type Bug --description "Login fails on Safari"
```

Create an issue with custom fields:

```sh
jira-cli create --project APP --summary "Provision access" --set customfield_10001=10401 --set customfield_10002="Platform Team"
```

Update an issue:

```sh
jira-cli update APP-123 --priority High --labels backend,urgent
```

Update summary, description, assignee, and custom fields:

```sh
jira-cli update APP-123 --summary "Refine rollout plan" --description "Updated details" --assignee user@example.com --set customfield_10001=10401
```

Transition an issue:

```sh
jira-cli transition --key APP-123 --status "In Progress"
```

Add a comment:

```sh
jira-cli comment --key APP-123 --text "Investigating the root cause"
```

Assign an issue:

```sh
jira-cli assign --key APP-123 --email user@example.com
```

## Option Behavior

- `issue` and `issues` accept `key`, `summary`, `status`, `assignee`, `type`, `priority`, `description`, and `customfield_<id>` in `--fields`.
- `type`, `issue_type`, and `issuetype` are equivalent field aliases.
- Duplicate entries in `--fields` are de-duplicated.
- `issues` and `search` currently request up to 20 results.
- Multi-word values are accepted for flags, but quote them in shell commands to avoid accidental word splitting or glob expansion.
- `--set` only accepts `customfield_*` keys. Duplicate `--set` keys are allowed and the last value wins.
- If a `--set` value is all digits, the CLI sends `{ "id": "<value>" }` to Jira. Use this for select-like fields when `fields <id> --project <KEY> --type <NAME>` returns option IDs.
- Descriptions and comments are sent as Jira ADF text generated from plain text input.

## Recovery Notes

- `update` may partially succeed if field updates succeed but assignee assignment fails afterward. Re-fetch the issue before retrying.
- If `transition` fails with "Transition '<name>' not found", inspect the issue in Jira or try the exact visible status name.
- If Jira returns a field validation error, use `fields` and `fields <id> --project <KEY> --type <NAME>` to confirm the expected field ID and allowed option values.
