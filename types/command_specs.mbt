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
fn config_command_spec() -> CommandSpec {
  {
    name: "config",
    summary: "Set Jira configuration",
    usage: "config --base-url <url> --email <email> --api-token <token>",
    aliases: [],
    positionals: [],
    flags: [
      {
        name: "--base-url",
        value_name: "url",
        description: "Jira base URL (for example https://your-site.atlassian.net)",
        required: true,
        repeatable: false,
        default_value: "",
        aliases: [],
      },
      {
        name: "--email",
        value_name: "email",
        description: "Atlassian account email",
        required: true,
        repeatable: false,
        default_value: "",
        aliases: [],
      },
      {
        name: "--api-token",
        value_name: "token",
        description: "Atlassian API token",
        required: true,
        repeatable: false,
        default_value: "",
        aliases: [],
      },
    ],
    output_formats: [],
    notes: ["Configuration is saved to ~/.config/jira_cli_mbt/config.json"],
    examples: [
      "jira-cli config --base-url https://your-site.atlassian.net --email you@example.com --api-token <token>",
    ],
  }
}

///|
fn issues_command_spec() -> CommandSpec {
  {
    name: "issues",
    summary: "List assigned issues (default JQL)",
    usage: "issues [--jql <jql>] [--fields <field,...>] [--format <table|tsv|json>]",
    aliases: [],
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
    ],
    output_formats: global_output_formats(),
    notes: [issues_field_note(), issue_field_alias_note()],
    examples: [
      "jira-cli issues", "jira-cli issues --jql \"project = APP AND status = Open\" --format json",
    ],
  }
}

///|
fn issue_command_spec() -> CommandSpec {
  {
    name: "issue",
    summary: "Get issue details",
    usage: "issue <key> [--fields <field,...>] [--format <table|tsv|json>]",
    aliases: [],
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
      "jira-cli issue PROJ-123", "jira-cli issue PROJ-123 --fields key,status,assignee,summary --format json",
    ],
  }
}

///|
fn create_command_spec() -> CommandSpec {
  {
    name: "create",
    summary: "Create a new issue",
    usage: "create --project <key> --summary <text> [--type <type>] [--description <text>] [--set <field=value>]...",
    aliases: [],
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
    ],
    output_formats: [],
    notes: [
      "--set only accepts customfield_* keys", "If a --set value is all digits, Jira receives it as an option id object",
    ],
    examples: [
      "jira-cli create --project APP --summary \"Fix login bug\" --type Bug", "jira-cli create --project APP --summary \"Provision access\" --set customfield_10001=10401",
    ],
  }
}

///|
fn update_command_spec() -> CommandSpec {
  {
    name: "update",
    summary: "Update an existing issue",
    usage: "update <key> [--summary <text>] [--description <text>] [--priority <name>] [--type <name>] [--labels <label1,label2>] [--assignee <email>] [--set <field=value>]...",
    aliases: [],
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
    ],
    output_formats: [],
    notes: [
      "At least one update field is required", "update may partially succeed if assignee changes fail after field updates",
    ],
    examples: [
      "jira-cli update APP-123 --priority High --labels backend,urgent", "jira-cli update APP-123 --summary \"Refine rollout plan\" --set customfield_10001=10401",
    ],
  }
}

///|
fn transition_command_spec() -> CommandSpec {
  {
    name: "transition",
    summary: "Transition issue status",
    usage: "transition --key <key> --status <status>",
    aliases: [],
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
    examples: ["jira-cli transition --key APP-123 --status \"In Progress\""],
  }
}

///|
fn comment_command_spec() -> CommandSpec {
  {
    name: "comment",
    summary: "Add comment to issue",
    usage: "comment --key <key> --text <text>",
    aliases: [],
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
      "jira-cli comment --key APP-123 --text \"Investigating the root cause\"",
    ],
  }
}

///|
fn assign_command_spec() -> CommandSpec {
  {
    name: "assign",
    summary: "Assign issue to user",
    usage: "assign --key <key> --email <email>",
    aliases: [],
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
    examples: ["jira-cli assign --key APP-123 --email user@example.com"],
  }
}

///|
fn search_command_spec() -> CommandSpec {
  {
    name: "search",
    summary: "Search issues with JQL",
    usage: "search --jql <jql> [--format <table|tsv|json>]",
    aliases: [],
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
    ],
    output_formats: global_output_formats(),
    notes: ["search requires an explicit JQL query"],
    examples: [
      "jira-cli search --jql \"text ~ \\\"outage\\\" AND project = APP\"", "jira-cli search --jql \"project = APP\" --format json",
    ],
  }
}

///|
fn projects_command_spec() -> CommandSpec {
  {
    name: "projects",
    summary: "List all projects",
    usage: "projects [--format <table|tsv|json>]",
    aliases: [],
    positionals: [],
    flags: [],
    output_formats: global_output_formats(),
    notes: [],
    examples: ["jira-cli projects --format json"],
  }
}

///|
fn fields_command_spec() -> CommandSpec {
  {
    name: "fields",
    summary: "List custom fields or inspect one field",
    usage: "fields [customfield_<id>] [--project <key>] [--type <type>] [--format <table|tsv|json>]",
    aliases: [],
    positionals: [
      {
        name: "customfield_<id>",
        description: "Optional custom field id to inspect",
        required: false,
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
    ],
    examples: [
      "jira-cli fields", "jira-cli fields customfield_10001 --project APP --type Bug --format json",
    ],
  }
}

///|
fn help_command_spec() -> CommandSpec {
  {
    name: "help",
    summary: "Show general help or help for one command",
    usage: "help [command]",
    aliases: ["--help", "-h"],
    positionals: [
      {
        name: "command",
        description: "Optional command name to inspect",
        required: false,
      },
    ],
    flags: [],
    output_formats: [],
    notes: ["<command> --help is also supported"],
    examples: ["jira-cli help issue", "jira-cli issue --help"],
  }
}

///|
fn describe_command_spec() -> CommandSpec {
  {
    name: "describe",
    summary: "Describe one command for humans or agents",
    usage: "describe <command> [--format <table|tsv|json>]",
    aliases: [],
    positionals: [
      {
        name: "command",
        description: "Command name to describe",
        required: true,
      },
    ],
    flags: [],
    output_formats: global_output_formats(),
    notes: ["Use --format json for stable machine-readable output"],
    examples: ["jira-cli describe issue --format json"],
  }
}

///|
pub fn command_specs() -> Array[CommandSpec] {
  [
    config_command_spec(),
    issues_command_spec(),
    issue_command_spec(),
    create_command_spec(),
    update_command_spec(),
    transition_command_spec(),
    comment_command_spec(),
    assign_command_spec(),
    search_command_spec(),
    projects_command_spec(),
    fields_command_spec(),
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
