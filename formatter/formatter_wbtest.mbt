///|
test "pad_right: shorter than width" {
  inspect(pad_right("ab", 5), content="ab   ")
}

///|
test "pad_right: equal to width" {
  inspect(pad_right("abcde", 5), content="abcde")
}

///|
test "pad_right: longer than width" {
  inspect(pad_right("abcdef", 5), content="abcdef")
}

///|
test "truncate: shorter than max" {
  inspect(truncate("hello", 10), content="hello")
}

///|
test "truncate: exactly max" {
  inspect(truncate("hello", 5), content="hello")
}

///|
test "truncate: longer than max" {
  inspect(truncate("hello world", 8), content="hello...")
}

///|
test "truncate: unicode safe" {
  inspect(truncate("こんにちは世界", 6), content="こんに...")
}

///|
test "format_issue_list: empty" {
  inspect(
    format_issue_list([], @types.default_list_issue_fields()),
    content="No issues found.",
  )
}

///|
test "format_issue_list: single issue" {
  let issues : Array[@types.JiraIssue] = [
    {
      key: "PROJ-1",
      summary: "Fix bug",
      status: "Open",
      assignee: "Alice",
      issue_type: "Bug",
      priority: "High",
      description: "",
      custom_fields: {},
    },
  ]
  inspect(
    format_issue_list(issues, @types.default_list_issue_fields()),
    content=(
      #|KEY           TYPE          STATUS           PRIORITY    SUMMARY                                 
      #|------------  ------------  ---------------  ----------  ----------------------------------------
      #|PROJ-1        Bug           Open             High        Fix bug                                 
    ),
  )
}

///|
test "format_issue_detail" {
  let issue : @types.JiraIssue = {
    key: "PROJ-1",
    summary: "Fix bug",
    status: "Open",
    assignee: "Alice",
    issue_type: "Bug",
    priority: "High",
    description: "Some description",
    custom_fields: {},
  }
  inspect(
    format_issue_detail(issue, @types.default_detail_issue_fields()),
    content=(
      #|Key:         PROJ-1
      #|Type:        Bug
      #|Status:      Open
      #|Priority:    High
      #|Assignee:    Alice
      #|Summary:     Fix bug
      #|Description: Some description
    ),
  )
}

///|
test "format_issue_list: custom fields" {
  let issues : Array[@types.JiraIssue] = [
    {
      key: "PROJ-1",
      summary: "Fix bug",
      status: "Open",
      assignee: "Alice",
      issue_type: "Bug",
      priority: "High",
      description: "",
      custom_fields: {},
    },
  ]
  inspect(
    format_issue_list(issues, [@types.Key, @types.Assignee, @types.Summary]),
    content=(
      #|KEY           ASSIGNEE              SUMMARY                                 
      #|------------  --------------------  ----------------------------------------
      #|PROJ-1        Alice                 Fix bug                                 
    ),
  )
}

///|
test "format_issue_detail: custom field" {
  let issue : @types.JiraIssue = {
    key: "PROJ-1",
    summary: "Fix bug",
    status: "Open",
    assignee: "Alice",
    issue_type: "Bug",
    priority: "High",
    description: "",
    custom_fields: { "customfield_10001": "Platform Team" },
  }
  inspect(
    format_issue_detail(issue, [@types.Key, @types.Custom("customfield_10001")]),
    content=(
      #|Key:         PROJ-1
      #|customfield_10001: Platform Team
    ),
  )
}

///|
test "format_fields: empty" {
  inspect(format_fields([]), content="No custom fields found.")
}

///|
test "format_fields: single field" {
  let fields : Array[@types.JiraField] = [
    {
      id: "customfield_10001",
      name: "Team",
      custom: true,
      schema_type: "option",
      schema_custom: "com.atlassian.jira.plugin.system.customfieldtypes:select",
    },
  ]
  inspect(
    format_fields(fields),
    content=(
      #|ID                         NAME                            TYPE             CUSTOM TYPE                             
      #|-------------------------  ------------------------------  ---------------  ----------------------------------------
      #|customfield_10001          Team                            option           com.atlassian.jira.plugin.system.cust...
    ),
  )
}

///|
test "format_field_detail: no options" {
  let detail : @types.JiraFieldDetail = {
    field: {
      id: "customfield_10001",
      name: "Team",
      custom: true,
      schema_type: "string",
      schema_custom: "",
    },
    options: [],
  }
  inspect(
    format_field_detail(detail),
    content=(
      #|ID:          customfield_10001
      #|Name:        Team
      #|Type:        string
      #|Custom Type: 
      #|
      #|No options available for this field.
    ),
  )
}

///|
test "format_field_detail: with options" {
  let detail : @types.JiraFieldDetail = {
    field: {
      id: "customfield_10001",
      name: "Team",
      custom: true,
      schema_type: "option",
      schema_custom: "com.atlassian.jira.plugin.system.customfieldtypes:select",
    },
    options: [{ id: "1", value: "Frontend" }, { id: "2", value: "Backend" }],
  }
  inspect(
    format_field_detail(detail),
    content=(
      #|ID:          customfield_10001
      #|Name:        Team
      #|Type:        option
      #|Custom Type: com.atlassian.jira.plugin.system.customfieldtypes:select
      #|
      #|Options:
      #|ID          VALUE                         
      #|----------  ------------------------------
      #|1           Frontend                      
      #|2           Backend                       
    ),
  )
}

///|
test "format_projects: empty" {
  inspect(format_projects([]), content="No projects found.")
}

///|
test "format_projects: single project" {
  let projects : Array[@types.JiraProject] = [
    { key: "PROJ", name: "My Project", project_type: "software" },
  ]
  inspect(
    format_projects(projects),
    content=(
      #|KEY           NAME                            TYPE           
      #|------------  ------------------------------  ---------------
      #|PROJ          My Project                      software       
    ),
  )
}

///|
test "format_usage: shows installed binary names" {
  inspect(
    format_usage(),
    content=(
      #|Jira CLI (MoonBit)
      #|
      #|Usage: jira-cli <command> [options]
      #|Alias: jira-cli-mbt <command> [options]
      #|
      #|Global options:
      #|  --format    table | tsv | json (supported by read-only commands and describe, default: table)
      #|
      #|Commands:
      #|  config           Set Jira configuration
      #|                   config --base-url <url> --email <email> --api-token <token>
      #|  issue            Issue operations
      #|                   issue <subcommand> [options]
      #|  issue list       List assigned issues (default JQL)
      #|                   issue list [--jql <jql>] [--fields <field,...>] [--format <table|tsv|json>]
      #|  issue get        Get issue details
      #|                   issue get <key> [--fields <field,...>] [--format <table|tsv|json>]
      #|  issue create     Create a new issue
      #|                   issue create --project <key> --summary <text> [--type <type>] [--description <text>] [--set <field=value>]...
      #|  issue update     Update an existing issue
      #|                   issue update <key> [--summary <text>] [--description <text>] [--priority <name>] [--type <name>] [--labels <label1,label2>] [--assignee <email>] [--set <field=value>]...
      #|  issue transition Transition issue status
      #|                   issue transition --key <key> --status <status>
      #|  issue comment    Add comment to issue
      #|                   issue comment --key <key> --text <text>
      #|  issue assign     Assign issue to user
      #|                   issue assign --key <key> --email <email>
      #|  issue search     Search issues with JQL
      #|                   issue search --jql <jql> [--format <table|tsv|json>]
      #|  project          Project operations
      #|                   project <subcommand> [options]
      #|  project list     List all projects
      #|                   project list [--format <table|tsv|json>]
      #|  field            Field operations
      #|                   field <subcommand> [options]
      #|  field list       List custom fields
      #|                   field list [--format <table|tsv|json>]
      #|  field get        Inspect one custom field
      #|                   field get <customfield_<id>> [--project <key>] [--type <type>] [--format <table|tsv|json>]
      #|  help             Show general help or help for one command
      #|                   help [command...]
      #|  describe         Describe one command for humans or agents
      #|                   describe <command...> [--format <table|tsv|json>]
      #|
      #|Run `jira-cli help <command>` for per-command help.
      #|Run `jira-cli describe <command> --format json` for machine-readable metadata.
    ),
  )
}

///|
test "format_command_help: issue group shows subcommands" {
  inspect(
    format_command_help(@types.require_command_spec("issue").unwrap()),
    content=(
      #|issue - Issue operations
      #|
      #|Usage:
      #|  jira-cli issue <subcommand> [options]
      #|
      #|Positional arguments:
      #|NAME                REQUIRED  DESCRIPTION                                             
      #|------------------  --------  --------------------------------------------------------
      #|subcommand          yes       One of list, get, create, update, transition, comment...
      #|
      #|Notes:
      #|  - Canonical subcommands: list, get, create, update, transition, comment, assign, search
      #|  - Legacy aliases remain available during the migration
      #|
      #|Examples:
      #|  jira-cli issue list --format json
      #|  jira-cli issue get PROJ-123
      #|  jira-cli help issue
    ),
  )
}

///|
test "format_command_help: issue get includes output formats and notes" {
  inspect(
    format_command_help(@types.require_command_spec("issue get").unwrap()),
    content=(
      #|issue get - Get issue details
      #|
      #|Usage:
      #|  jira-cli issue get <key> [--fields <field,...>] [--format <table|tsv|json>]
      #|
      #|Aliases:
      #|  issue <key>
      #|
      #|Positional arguments:
      #|NAME                REQUIRED  DESCRIPTION                                             
      #|------------------  --------  --------------------------------------------------------
      #|key                 yes       Issue key (for example PROJ-123)                        
      #|
      #|Flags:
      #|FLAG            VALUE                     REQUIRED  REPEAT  DEFAULT                       DESCRIPTION                                 
      #|--------------  ------------------------  --------  ------  ----------------------------  --------------------------------------------
      #|--fields        <field,...>               no        no      key,type,status,priority,...  Comma-separated list of fields to display   
      #|
      #|Output formats:
      #|  table, tsv, json (default: table)
      #|
      #|Notes:
      #|  - Accepted fields: key,summary,status,assignee,type,priority,description,customfield_<id>
      #|  - Field aliases: type, issue_type, issuetype
      #|
      #|Examples:
      #|  jira-cli issue get PROJ-123
      #|  jira-cli issue get PROJ-123 --fields key,status,assignee,summary --format json
    ),
  )
}

///|
test "format_issue_list_for_output: json wrapper is stable" {
  let issues : Array[@types.JiraIssue] = [
    {
      key: "PROJ-1",
      summary: "Fix bug",
      status: "Open",
      assignee: "Alice",
      issue_type: "Bug",
      priority: "High",
      description: "Line 1\nLine 2",
      custom_fields: {},
    },
  ]
  inspect(
    format_issue_list_for_output(
      issues,
      [@types.Key, @types.IssueType, @types.Summary],
      @types.Json,
    ),
    content=(
      #|{"schema_version":"v1","kind":"issues","fields":["key","type","summary"],"items":[{"key":"PROJ-1","type":"Bug","summary":"Fix bug"}]}
    ),
  )
}

///|
test "format_issue_detail_for_output: tsv is machine readable" {
  let issue : @types.JiraIssue = {
    key: "PROJ-1",
    summary: "Fix bug",
    status: "Open",
    assignee: "Alice",
    issue_type: "Bug",
    priority: "High",
    description: "Line 1\nLine 2",
    custom_fields: {},
  }
  inspect(
    format_issue_detail_for_output(
      issue,
      [@types.Key, @types.Description],
      @types.Tsv,
    ),
    content=(
      #|field	value
      #|key	PROJ-1
      #|description	Line 1 Line 2
    ),
  )
}

///|
test "format_projects_for_output: json wrapper is stable" {
  let projects : Array[@types.JiraProject] = [
    { key: "PROJ", name: "My Project", project_type: "software" },
  ]
  inspect(
    format_projects_for_output(projects, @types.Json),
    content=(
      #|{"schema_version":"v1","kind":"projects","items":[{"key":"PROJ","name":"My Project","project_type":"software"}]}
    ),
  )
}

///|
test "format_fields_for_output: json wrapper is stable" {
  let fields : Array[@types.JiraField] = [
    {
      id: "customfield_10001",
      name: "Team",
      custom: true,
      schema_type: "option",
      schema_custom: "select",
    },
  ]
  inspect(
    format_fields_for_output(fields, @types.Json),
    content=(
      #|{"schema_version":"v1","kind":"fields","items":[{"id":"customfield_10001","name":"Team","custom":true,"type":"option","custom_type":"select"}]}
    ),
  )
}

///|
test "format_field_detail_for_output: json wrapper includes options" {
  let detail : @types.JiraFieldDetail = {
    field: {
      id: "customfield_10001",
      name: "Team",
      custom: true,
      schema_type: "option",
      schema_custom: "select",
    },
    options: [{ id: "1", value: "Frontend" }, { id: "2", value: "Backend" }],
  }
  inspect(
    format_field_detail_for_output(detail, @types.Json),
    content=(
      #|{"schema_version":"v1","kind":"field_detail","item":{"field":{"id":"customfield_10001","name":"Team","custom":true,"type":"option","custom_type":"select"},"options":[{"id":"1","value":"Frontend"},{"id":"2","value":"Backend"}]}}
    ),
  )
}

///|
test "format_issue_types_for_output: json wrapper lists choices" {
  inspect(
    format_issue_types_for_output(
      "APP",
      [("10001", "Task"), ("10002", "Bug")],
      @types.Json,
    ),
    content=(
      #|{"schema_version":"v1","kind":"issue_types","project":"APP","items":[{"id":"10001","name":"Task"},{"id":"10002","name":"Bug"}]}
    ),
  )
}

///|
test "format_error_for_output: text mode includes usage" {
  inspect(
    format_error_for_output(
      @types.Usage,
      "Unknown command: nope",
      @types.Table,
      usage="Usage: jira-cli <command> [options]",
    ),
    content=(
      #|Usage: jira-cli <command> [options]
      #|
      #|Error: Unknown command: nope
    ),
  )
}

///|
test "format_error_for_output: json mode is structured" {
  inspect(
    format_error_for_output(@types.Validation, "Invalid value", @types.Json),
    content=(
      #|{"schema_version":"v1","kind":"error","category":"validation","exit_code":5,"message":"Invalid value"}
    ),
  )
}
