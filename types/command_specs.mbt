///|
pub(all) struct CommandPositionalSpec {
  name : String
  description : String
  required : Bool
} derive(Show)

///|
pub(all) struct CommandFlagSpec {
  name : String
  value_name : String
  description : String
  required : Bool
  repeatable : Bool
  default_value : String
  aliases : Array[String]
} derive(Show)

///|
pub(all) struct CommandSpec {
  name : String
  summary : String
  usage : String
  aliases : Array[String]
  positionals : Array[CommandPositionalSpec]
  flags : Array[CommandFlagSpec]
  output_formats : Array[OutputFormat]
  notes : Array[String]
  examples : Array[String]
} derive(Show)

///|
fn global_output_formats() -> Array[OutputFormat] {
  [Table, Tsv, Json]
}

///|
fn issues_field_note() -> String {
  "Accepted fields: key,summary,status,assignee,type,priority,description,customfield_<id>"
}

///|
fn issue_field_alias_note() -> String {
  "Field aliases: type, issue_type, issuetype"
}

///|
fn pagination_limit_flag(default_value : String) -> CommandFlagSpec {
  {
    name: "--limit",
    value_name: "n",
    description: "Maximum number of items to return",
    required: false,
    repeatable: false,
    default_value,
    aliases: [],
  }
}

///|
fn pagination_start_at_flag() -> CommandFlagSpec {
  {
    name: "--start-at",
    value_name: "n",
    description: "Zero-based result offset",
    required: false,
    repeatable: false,
    default_value: "0",
    aliases: [],
  }
}

///|
fn pagination_all_flag() -> CommandFlagSpec {
  {
    name: "--all",
    value_name: "",
    description: "Return all remaining items from the offset",
    required: false,
    repeatable: false,
    default_value: "false",
    aliases: [],
  }
}

///|
fn issue_group_spec() -> CommandSpec {
  {
    name: "issue",
    summary: "Issue operations",
    usage: "issue <subcommand> [options]",
    aliases: [],
    positionals: [
      {
        name: "subcommand",
        description: "One of list, get, create, update, transition, comment, assign, search",
        required: true,
      },
    ],
    flags: [],
    output_formats: [],
    notes: [
      "Canonical subcommands: list, get, create, update, transition, comment, assign, search",
      "Legacy aliases remain available during the migration",
    ],
    examples: [
      "jira-cli issue list --format json", "jira-cli issue get PROJ-123", "jira-cli help issue",
    ],
  }
}

///|
fn project_group_spec() -> CommandSpec {
  {
    name: "project",
    summary: "Project operations",
    usage: "project <subcommand> [options]",
    aliases: [],
    positionals: [
      { name: "subcommand", description: "Currently only list", required: true },
    ],
    flags: [],
    output_formats: [],
    notes: ["Canonical subcommand: list"],
    examples: ["jira-cli project list --format json", "jira-cli help project"],
  }
}

///|
fn field_group_spec() -> CommandSpec {
  {
    name: "field",
    summary: "Field operations",
    usage: "field <subcommand> [options]",
    aliases: [],
    positionals: [
      { name: "subcommand", description: "One of list or get", required: true },
    ],
    flags: [],
    output_formats: [],
    notes: ["Canonical subcommands: list, get"],
    examples: [
      "jira-cli field list --format json", "jira-cli field get customfield_10001",
    ],
  }
}

///|
fn config_command_spec() -> CommandSpec {
  {
    name: "config",
    summary: "Set Jira configuration",
    usage: "config [--base-url <url>] [--email <email>] [--api-token <token> | --api-token-stdin]",
    aliases: [],
    positionals: [],
    flags: [
      {
        name: "--base-url",
        value_name: "url",
        description: "Jira base URL (for example https://your-site.atlassian.net)",
        required: false,
        repeatable: false,
        default_value: "",
        aliases: [],
      },
      {
        name: "--email",
        value_name: "email",
        description: "Atlassian account email",
        required: false,
        repeatable: false,
        default_value: "",
        aliases: [],
      },
      {
        name: "--api-token",
        value_name: "token",
        description: "Atlassian API token",
        required: false,
        repeatable: false,
        default_value: "",
        aliases: [],
      },
      {
        name: "--api-token-stdin",
        value_name: "",
        description: "Read the API token from stdin",
        required: false,
        repeatable: false,
        default_value: "false",
        aliases: [],
      },
    ],
    output_formats: [],
    notes: [
      "Resolution order for `jira-cli config`: flag > env > config", "Runtime credential resolution order: env > config",
      "Configuration is saved to ~/.config/jira_cli_mbt/config.json",
    ],
    examples: [
      "jira-cli config --base-url https://your-site.atlassian.net --email you@example.com --api-token <token>",
      "printf %s \"$JIRA_API_TOKEN\" | jira-cli config --base-url https://your-site.atlassian.net --email you@example.com --api-token-stdin",
      "JIRA_BASE_URL=https://your-site.atlassian.net JIRA_EMAIL=you@example.com JIRA_API_TOKEN=token jira-cli config",
    ],
  }
}

///|
fn issues_command_spec() -> CommandSpec {
  {
    name: "issue list",
    summary: "List assigned issues (default JQL)",
    usage: "issue list [--jql <jql>] [--fields <field,...>] [--limit <n>] [--start-at <n>] [--all] [--format <table|tsv|json>]",
    aliases: ["issues"],
    positionals: [],
    flags: [
      {
        name: "--jql",
        value_name: "jql",
        description: "JQL query to run instead of the default assignee filter",
        required: false,
        repeatable: false,
        default_value: "assignee = currentUser() ORDER BY updated DESC",
        aliases: [],
      },
      {
        name: "--fields",
        value_name: "field,...",
        description: "Comma-separated list of fields to display",
        required: false,
        repeatable: false,
        default_value: "key,type,status,priority,summary",
        aliases: [],
      },
      pagination_limit_flag("20"),
      pagination_start_at_flag(),
      pagination_all_flag(),
    ],
    output_formats: global_output_formats(),
    notes: [
      issues_field_note(),
      issue_field_alias_note(),
      "Default result count is 20",
      "--all cannot be combined with --limit",
    ],
    examples: [
      "jira-cli issue list", "jira-cli issue list --limit 5 --start-at 10", "jira-cli issue list --jql \"project = APP AND status = Open\" --format json",
    ],
  }
}

///|
fn issue_command_spec() -> CommandSpec {
  {
    name: "issue get",
    summary: "Get issue details",
    usage: "issue get <key> [--fields <field,...>] [--format <table|tsv|json>]",
    aliases: ["issue <key>"],
    positionals: [
      {
        name: "key",
        description: "Issue key (for example PROJ-123)",
        required: true,
      },
    ],
    flags: [
      {
        name: "--fields",
        value_name: "field,...",
        description: "Comma-separated list of fields to display",
        required: false,
        repeatable: false,
        default_value: "key,type,status,priority,assignee,summary,description",
        aliases: [],
      },
    ],
    output_formats: global_output_formats(),
    notes: [issues_field_note(), issue_field_alias_note()],
    examples: [
      "jira-cli issue get PROJ-123", "jira-cli issue get PROJ-123 --fields key,status,assignee,summary --format json",
    ],
  }
}

///|
fn create_command_spec() -> CommandSpec {
  {
    name: "issue create",
    summary: "Create a new issue",
    usage: "issue create --project <key> --summary <text> [--type <type>] [--description <text>] [--set <field=value>]... [--set-json <json-object>] [--dry-run] [--format <table|tsv|json>]",
    aliases: ["create"],
    positionals: [],
    flags: [
      {
        name: "--project",
        value_name: "key",
        description: "Project key",
        required: true,
        repeatable: false,
        default_value: "",
        aliases: [],
      },
      {
        name: "--summary",
        value_name: "text",
        description: "Issue summary",
        required: true,
        repeatable: false,
        default_value: "",
        aliases: [],
      },
      {
        name: "--type",
        value_name: "type",
        description: "Issue type name",
        required: false,
        repeatable: false,
        default_value: "Task",
        aliases: [],
      },
      {
        name: "--description",
        value_name: "text",
        description: "Plain-text issue description",
        required: false,
        repeatable: false,
        default_value: "",
        aliases: [],
      },
      {
        name: "--set",
        value_name: "customfield_<id>=<value>",
        description: "Set a custom field value",
        required: false,
        repeatable: true,
        default_value: "",
        aliases: [],
      },
      {
        name: "--set-json",
        value_name: "json-object",
        description: "Merge custom field values from a JSON object",
        required: false,
        repeatable: true,
        default_value: "",
        aliases: [],
      },
      {
        name: "--dry-run",
        value_name: "",
        description: "Preview the create request without calling Jira",
        required: false,
        repeatable: false,
        default_value: "false",
        aliases: [],
      },
    ],
    output_formats: global_output_formats(),
    notes: [
      "--set only accepts customfield_* keys and remains a convenience shortcut",
      "--set-json accepts a JSON object mapping customfield_* keys to JSON values",
      "Prefer --set-json for explicit typed values such as {\"id\":\"10401\"}", "If a --set value is all digits, the CLI preserves the legacy convenience behavior and sends it as an option id object",
      "--dry-run returns a structured preview and does not require Jira config",
    ],
    examples: [
      "jira-cli issue create --project APP --summary \"Fix login bug\" --type Bug",
      "jira-cli issue create --project APP --summary \"Provision access\" --set customfield_10001=10401",
      "jira-cli issue create --project APP --summary \"Provision access\" --set-json '{\"customfield_10001\":{\"id\":\"10401\"},\"customfield_10002\":\"Platform Team\"}'",
      "jira-cli issue create --project APP --summary \"Provision access\" --dry-run --format json",
    ],
  }
}

///|
fn update_command_spec() -> CommandSpec {
  {
    name: "issue update",
    summary: "Update an existing issue",
    usage: "issue update <key> [--summary <text>] [--description <text>] [--priority <name>] [--type <name>] [--labels <label1,label2>] [--assignee <email>] [--set <field=value>]... [--set-json <json-object>] [--dry-run] [--format <table|tsv|json>]",
    aliases: ["update"],
    positionals: [
      { name: "key", description: "Issue key to update", required: true },
    ],
    flags: [
      {
        name: "--summary",
        value_name: "text",
        description: "New issue summary",
        required: false,
        repeatable: false,
        default_value: "",
        aliases: [],
      },
      {
        name: "--description",
        value_name: "text",
        description: "New plain-text issue description",
        required: false,
        repeatable: false,
        default_value: "",
        aliases: [],
      },
      {
        name: "--priority",
        value_name: "name",
        description: "Priority name",
        required: false,
        repeatable: false,
        default_value: "",
        aliases: [],
      },
      {
        name: "--type",
        value_name: "name",
        description: "Issue type name",
        required: false,
        repeatable: false,
        default_value: "",
        aliases: [],
      },
      {
        name: "--labels",
        value_name: "label1,label2",
        description: "Comma-separated labels",
        required: false,
        repeatable: false,
        default_value: "",
        aliases: [],
      },
      {
        name: "--assignee",
        value_name: "email",
        description: "Assignee email address",
        required: false,
        repeatable: false,
        default_value: "",
        aliases: [],
      },
      {
        name: "--set",
        value_name: "customfield_<id>=<value>",
        description: "Set a custom field value",
        required: false,
        repeatable: true,
        default_value: "",
        aliases: [],
      },
      {
        name: "--set-json",
        value_name: "json-object",
        description: "Merge custom field values from a JSON object",
        required: false,
        repeatable: true,
        default_value: "",
        aliases: [],
      },
      {
        name: "--dry-run",
        value_name: "",
        description: "Preview the update request without calling Jira",
        required: false,
        repeatable: false,
        default_value: "false",
        aliases: [],
      },
    ],
    output_formats: global_output_formats(),
    notes: [
      "At least one update field is required", "update may partially succeed if assignee changes fail after field updates",
      "--set only accepts customfield_* keys and remains a convenience shortcut",
      "--set-json accepts a JSON object mapping customfield_* keys to JSON values",
      "Prefer --set-json for explicit typed values such as {\"id\":\"10401\"}", "--dry-run returns a structured preview and does not require Jira config",
    ],
    examples: [
      "jira-cli issue update APP-123 --priority High --labels backend,urgent", "jira-cli issue update APP-123 --summary \"Refine rollout plan\" --set customfield_10001=10401",
      "jira-cli issue update APP-123 --set-json '{\"customfield_10001\":{\"id\":\"10401\"},\"customfield_10002\":[\"Backend\",\"Urgent\"]}'",
      "jira-cli issue update APP-123 --summary \"Refine rollout plan\" --assignee user@example.com --dry-run --format json",
    ],
  }
}

///|
fn transition_command_spec() -> CommandSpec {
  {
    name: "issue transition",
    summary: "Transition issue status",
    usage: "issue transition --key <key> --status <status>",
    aliases: ["transition"],
    positionals: [],
    flags: [
      {
        name: "--key",
        value_name: "key",
        description: "Issue key",
        required: true,
        repeatable: false,
        default_value: "",
        aliases: [],
      },
      {
        name: "--status",
        value_name: "status",
        description: "Visible Jira transition name",
        required: true,
        repeatable: false,
        default_value: "",
        aliases: [],
      },
    ],
    output_formats: [],
    notes: ["Status names must match Jira transition names exactly"],
    examples: [
      "jira-cli issue transition --key APP-123 --status \"In Progress\"",
    ],
  }
}

///|
fn comment_command_spec() -> CommandSpec {
  {
    name: "issue comment",
    summary: "Add comment to issue",
    usage: "issue comment --key <key> --text <text>",
    aliases: ["comment"],
    positionals: [],
    flags: [
      {
        name: "--key",
        value_name: "key",
        description: "Issue key",
        required: true,
        repeatable: false,
        default_value: "",
        aliases: [],
      },
      {
        name: "--text",
        value_name: "text",
        description: "Plain-text comment body",
        required: true,
        repeatable: false,
        default_value: "",
        aliases: [],
      },
    ],
    output_formats: [],
    notes: ["Comments are sent to Jira as ADF text converted from plain text"],
    examples: [
      "jira-cli issue comment --key APP-123 --text \"Investigating the root cause\"",
    ],
  }
}

///|
fn assign_command_spec() -> CommandSpec {
  {
    name: "issue assign",
    summary: "Assign issue to user",
    usage: "issue assign --key <key> --email <email>",
    aliases: ["assign"],
    positionals: [],
    flags: [
      {
        name: "--key",
        value_name: "key",
        description: "Issue key",
        required: true,
        repeatable: false,
        default_value: "",
        aliases: [],
      },
      {
        name: "--email",
        value_name: "email",
        description: "Assignee email address",
        required: true,
        repeatable: false,
        default_value: "",
        aliases: [],
      },
    ],
    output_formats: [],
    notes: [],
    examples: ["jira-cli issue assign --key APP-123 --email user@example.com"],
  }
}

///|
fn search_command_spec() -> CommandSpec {
  {
    name: "issue search",
    summary: "Search issues with JQL",
    usage: "issue search --jql <jql> [--limit <n>] [--start-at <n>] [--all] [--format <table|tsv|json>]",
    aliases: ["search"],
    positionals: [],
    flags: [
      {
        name: "--jql",
        value_name: "jql",
        description: "JQL query to execute",
        required: true,
        repeatable: false,
        default_value: "",
        aliases: [],
      },
      pagination_limit_flag("20"),
      pagination_start_at_flag(),
      pagination_all_flag(),
    ],
    output_formats: global_output_formats(),
    notes: [
      "search requires an explicit JQL query", "Default result count is 20", "--all cannot be combined with --limit",
    ],
    examples: [
      "jira-cli issue search --jql \"text ~ \\\"outage\\\" AND project = APP\"",
      "jira-cli issue search --jql \"project = APP\" --limit 10 --start-at 20", "jira-cli issue search --jql \"project = APP\" --format json",
    ],
  }
}

///|
fn project_list_command_spec() -> CommandSpec {
  {
    name: "project list",
    summary: "List all projects",
    usage: "project list [--limit <n>] [--start-at <n>] [--all] [--format <table|tsv|json>]",
    aliases: ["projects"],
    positionals: [],
    flags: [
      pagination_limit_flag(""),
      pagination_start_at_flag(),
      pagination_all_flag(),
    ],
    output_formats: global_output_formats(),
    notes: [
      "By default project list returns all visible projects", "--all cannot be combined with --limit",
    ],
    examples: [
      "jira-cli project list --limit 20", "jira-cli project list --format json",
    ],
  }
}

///|
fn field_list_command_spec() -> CommandSpec {
  {
    name: "field list",
    summary: "List custom fields",
    usage: "field list [--limit <n>] [--start-at <n>] [--all] [--format <table|tsv|json>]",
    aliases: ["fields"],
    positionals: [],
    flags: [
      pagination_limit_flag(""),
      pagination_start_at_flag(),
      pagination_all_flag(),
    ],
    output_formats: global_output_formats(),
    notes: [
      "By default field list returns all custom fields", "Use `field get` to inspect one custom field",
      "--all cannot be combined with --limit",
    ],
    examples: [
      "jira-cli field list --limit 50", "jira-cli field list --format json",
    ],
  }
}

///|
fn field_get_command_spec() -> CommandSpec {
  {
    name: "field get",
    summary: "Inspect one custom field",
    usage: "field get <customfield_<id>> [--project <key>] [--type <type>] [--format <table|tsv|json>]",
    aliases: ["fields <customfield_<id>>"],
    positionals: [
      {
        name: "customfield_<id>",
        description: "Custom field id to inspect",
        required: true,
      },
    ],
    flags: [
      {
        name: "--project",
        value_name: "key",
        description: "Project key used to scope allowed options",
        required: false,
        repeatable: false,
        default_value: "",
        aliases: [],
      },
      {
        name: "--type",
        value_name: "type",
        description: "Issue type used together with --project",
        required: false,
        repeatable: false,
        default_value: "",
        aliases: [],
      },
    ],
    output_formats: global_output_formats(),
    notes: [
      "--type requires --project", "If --project is given without --type, the CLI returns available issue types",
      "JSON output includes accepted_input examples for `issue create --set-json` and `issue update --set-json`",
    ],
    examples: [
      "jira-cli field get customfield_10001", "jira-cli field get customfield_10001 --project APP --type Bug --format json",
    ],
  }
}

///|
fn help_command_spec() -> CommandSpec {
  {
    name: "help",
    summary: "Show general help or help for one command",
    usage: "help [command...]",
    aliases: ["--help", "-h"],
    positionals: [
      {
        name: "command...",
        description: "Optional command name or noun-verb path to inspect",
        required: false,
      },
    ],
    flags: [],
    output_formats: [],
    notes: ["<command> --help is also supported"],
    examples: ["jira-cli help issue get", "jira-cli issue --help"],
  }
}

///|
fn describe_command_spec() -> CommandSpec {
  {
    name: "describe",
    summary: "Describe one command for humans or agents",
    usage: "describe <command...> [--format <table|tsv|json>]",
    aliases: [],
    positionals: [
      {
        name: "command...",
        description: "Command name or noun-verb path to describe",
        required: true,
      },
    ],
    flags: [],
    output_formats: global_output_formats(),
    notes: ["Use --format json for stable machine-readable output"],
    examples: ["jira-cli describe issue get --format json"],
  }
}

///|
pub fn command_specs() -> Array[CommandSpec] {
  [
    config_command_spec(),
    issue_group_spec(),
    issues_command_spec(),
    issue_command_spec(),
    create_command_spec(),
    update_command_spec(),
    transition_command_spec(),
    comment_command_spec(),
    assign_command_spec(),
    search_command_spec(),
    project_group_spec(),
    project_list_command_spec(),
    field_group_spec(),
    field_list_command_spec(),
    field_get_command_spec(),
    help_command_spec(),
    describe_command_spec(),
  ]
}

///|
pub fn find_command_spec(name : String) -> CommandSpec? {
  let normalized = name.trim().to_string().to_lower()
  for spec in command_specs() {
    if spec.name == normalized || spec.aliases.contains(normalized) {
      return Some(spec)
    }
  }
  None
}

///|
pub fn require_command_spec(name : String) -> Result[CommandSpec, String] {
  match find_command_spec(name) {
    Some(spec) => Ok(spec)
    None => Err("Unknown command: \{name}")
  }
}
