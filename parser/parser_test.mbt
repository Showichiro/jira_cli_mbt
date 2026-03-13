///|
test "parse_args: help command" {
  inspect(
    @parser.parse_args(["help"][:]),
    content="Ok(Help(command_name=\"\"))",
  )
}

///|
test "parse_args: --help flag" {
  inspect(
    @parser.parse_args(["--help"][:]),
    content="Ok(Help(command_name=\"\"))",
  )
}

///|
test "parse_args: empty args shows help" {
  inspect(@parser.parse_args([][:]), content="Ok(Help(command_name=\"\"))")
}

///|
test "parse_args: help for one command" {
  inspect(
    @parser.parse_args(["help", "issue"][:]),
    content="Ok(Help(command_name=\"issue\"))",
  )
}

///|
test "parse_args: help for noun-verb command" {
  inspect(
    @parser.parse_args(["help", "issue", "get"][:]),
    content="Ok(Help(command_name=\"issue get\"))",
  )
}

///|
test "parse_args: group --help resolves to group help" {
  inspect(
    @parser.parse_args(["issue", "--help"][:]),
    content="Ok(Help(command_name=\"issue\"))",
  )
}

///|
test "parse_args: noun-verb --help resolves to command help" {
  inspect(
    @parser.parse_args(["issue", "get", "--help"][:]),
    content="Ok(Help(command_name=\"issue get\"))",
  )
}

///|
test "parse_args: describe noun group" {
  inspect(
    @parser.parse_args(["describe", "issue"][:]),
    content="Ok(Describe(command_name=\"issue\"))",
  )
}

///|
test "parse_args: describe noun-verb command" {
  inspect(
    @parser.parse_args(["describe", "issue", "get"][:]),
    content="Ok(Describe(command_name=\"issue get\"))",
  )
}

///|
test "parse_args: describe requires one command name" {
  inspect(
    @parser.parse_args(["describe"][:]),
    content="Err(\"Usage: describe <command>\")",
  )
}

///|
test "parse_args: issue list with default jql" {
  inspect(
    @parser.parse_args(["issue", "list"][:]),
    content="Ok(ListIssues(jql=\"assignee = currentUser() ORDER BY updated DESC\", fields=[Key, IssueType, Status, Priority, Summary], page_request={limit: 20, start_at: 0, fetch_all: false}))",
  )
}

///|
test "parse_args: legacy issues alias with default jql" {
  inspect(
    @parser.parse_args(["issues"][:]),
    content="Ok(ListIssues(jql=\"assignee = currentUser() ORDER BY updated DESC\", fields=[Key, IssueType, Status, Priority, Summary], page_request={limit: 20, start_at: 0, fetch_all: false}))",
  )
}

///|
test "parse_args: list issues with custom jql" {
  inspect(
    @parser.parse_args(["issues", "--jql", "project = TEST"][:]),
    content="Ok(ListIssues(jql=\"project = TEST\", fields=[Key, IssueType, Status, Priority, Summary], page_request={limit: 20, start_at: 0, fetch_all: false}))",
  )
}

///|
test "parse_args: list issues with custom fields" {
  inspect(
    @parser.parse_args(["issues", "--fields", "key,assignee,summary"][:]),
    content="Ok(ListIssues(jql=\"assignee = currentUser() ORDER BY updated DESC\", fields=[Key, Assignee, Summary], page_request={limit: 20, start_at: 0, fetch_all: false}))",
  )
}

///|
test "parse_args: list issues with custom jira field" {
  inspect(
    @parser.parse_args(["issues", "--fields", "key,customfield_12345"][:]),
    content="Ok(ListIssues(jql=\"assignee = currentUser() ORDER BY updated DESC\", fields=[Key, Custom(\"customfield_12345\")], page_request={limit: 20, start_at: 0, fetch_all: false}))",
  )
}

///|
test "parse_args: issue list with limit and start-at" {
  inspect(
    @parser.parse_args(["issue", "list", "--limit", "5", "--start-at", "10"][:]),
    content="Ok(ListIssues(jql=\"assignee = currentUser() ORDER BY updated DESC\", fields=[Key, IssueType, Status, Priority, Summary], page_request={limit: 5, start_at: 10, fetch_all: false}))",
  )
}

///|
test "parse_args: issue list with --all" {
  inspect(
    @parser.parse_args(["issue", "list", "--all"][:]),
    content="Ok(ListIssues(jql=\"assignee = currentUser() ORDER BY updated DESC\", fields=[Key, IssueType, Status, Priority, Summary], page_request={limit: 0, start_at: 0, fetch_all: true}))",
  )
}

///|
test "parse_args: list issues rejects unknown field" {
  inspect(
    @parser.parse_args(["issues", "--fields", "key,unknown"][:]),
    content="Err(\"Unsupported issue field: unknown\")",
  )
}

///|
test "parse_args: issue get" {
  inspect(
    @parser.parse_args(["issue", "get", "PROJ-123"][:]),
    content="Ok(GetIssue(key=\"PROJ-123\", fields=[Key, IssueType, Status, Priority, Assignee, Summary, Description]))",
  )
}

///|
test "parse_args: legacy issue get shorthand" {
  inspect(
    @parser.parse_args(["issue", "PROJ-123"][:]),
    content="Ok(GetIssue(key=\"PROJ-123\", fields=[Key, IssueType, Status, Priority, Assignee, Summary, Description]))",
  )
}

///|
test "parse_args: get issue with custom fields" {
  inspect(
    @parser.parse_args(
      ["issue", "PROJ-123", "--fields", "summary, type, summary"][:],
    ),
    content="Ok(GetIssue(key=\"PROJ-123\", fields=[Summary, IssueType]))",
  )
}

///|
test "parse_args: issue without subcommand shows group help" {
  inspect(
    @parser.parse_args(["issue"][:]),
    content="Ok(Help(command_name=\"issue\"))",
  )
}

///|
test "parse_args: issue get missing key" {
  inspect(
    @parser.parse_args(["issue", "get"][:]),
    content="Err(\"Usage: issue get <key>\")",
  )
}

///|
test "parse_args: config with all flags" {
  inspect(
    @parser.parse_args(
      [
        "config", "--base-url", "https://x.atlassian.net", "--email", "a@b.com",
        "--api-token", "tok",
      ][:],
    ),
    content="Ok(Config(base_url=\"https://x.atlassian.net\", email=\"a@b.com\", api_token=\"tok\", api_token_stdin=false))",
  )
}

///|
test "parse_args: config allows partial overrides" {
  inspect(
    @parser.parse_args(["config", "--base-url", "https://x.atlassian.net"][:]),
    content="Ok(Config(base_url=\"https://x.atlassian.net\", email=\"\", api_token=\"\", api_token_stdin=false))",
  )
}

///|
test "parse_args: config reads token from stdin" {
  inspect(
    @parser.parse_args(["config", "--api-token-stdin"][:]),
    content="Ok(Config(base_url=\"\", email=\"\", api_token=\"\", api_token_stdin=true))",
  )
}

///|
test "parse_args: config rejects token flag and stdin together" {
  inspect(
    @parser.parse_args(["config", "--api-token", "tok", "--api-token-stdin"][:]),
    content="Err(\"--api-token and --api-token-stdin cannot be combined\")",
  )
}

///|
fn assert_custom_field_display_values(
  actual : Map[String, @types.CustomFieldInput],
  expected : Map[String, String],
) -> Unit raise {
  assert_eq(actual.length(), expected.length())
  for entry in expected {
    assert_eq(actual.get(entry.0).unwrap().display_value(), entry.1)
  }
}

///|
fn assert_create_issue_result(
  result : Result[@types.Command, String],
  project : String,
  summary : String,
  issue_type : String,
  description : String,
  custom_fields : Map[String, String],
  dry_run : Bool,
) -> Unit raise {
  match result {
    Ok(
      @types.CreateIssue(
        project=actual_project,
        summary=actual_summary,
        issue_type=actual_issue_type,
        description=actual_description,
        custom_fields=actual_custom_fields,
        dry_run=actual_dry_run
      )
    ) => {
      assert_eq(actual_project, project)
      assert_eq(actual_summary, summary)
      assert_eq(actual_issue_type, issue_type)
      assert_eq(actual_description, description)
      assert_eq(actual_dry_run, dry_run)
      assert_custom_field_display_values(actual_custom_fields, custom_fields)
    }
    _ => assert_false(true)
  }
}

///|
fn assert_update_issue_result(
  result : Result[@types.Command, String],
  key : String,
  summary : String,
  description : String,
  priority : String,
  issue_type : String,
  labels : String,
  assignee : String,
  custom_fields : Map[String, String],
  dry_run : Bool,
) -> Unit raise {
  match result {
    Ok(
      @types.UpdateIssue(
        key=actual_key,
        summary=actual_summary,
        description=actual_description,
        priority=actual_priority,
        issue_type=actual_issue_type,
        labels=actual_labels,
        assignee=actual_assignee,
        custom_fields=actual_custom_fields,
        dry_run=actual_dry_run
      )
    ) => {
      assert_eq(actual_key, key)
      assert_eq(actual_summary, summary)
      assert_eq(actual_description, description)
      assert_eq(actual_priority, priority)
      assert_eq(actual_issue_type, issue_type)
      assert_eq(actual_labels, labels)
      assert_eq(actual_assignee, assignee)
      assert_eq(actual_dry_run, dry_run)
      assert_custom_field_display_values(actual_custom_fields, custom_fields)
    }
    _ => assert_false(true)
  }
}

///|
test "parse_args: noun-verb issue create" {
  assert_create_issue_result(
    @parser.parse_args(
      ["issue", "create", "--project", "PROJ", "--summary", "Fix bug"][:],
    ),
    "PROJ",
    "Fix bug",
    "Task",
    "",
    {},
    false,
  )
}

///|
test "parse_args: legacy create issue" {
  assert_create_issue_result(
    @parser.parse_args(
      ["create", "--project", "PROJ", "--summary", "Fix bug"][:],
    ),
    "PROJ",
    "Fix bug",
    "Task",
    "",
    {},
    false,
  )
}

///|
test "parse_args: create with type and description" {
  assert_create_issue_result(
    @parser.parse_args(
      [
        "create", "--project", "PROJ", "--summary", "Fix bug", "--type", "Bug", "--description",
        "Details",
      ][:],
    ),
    "PROJ",
    "Fix bug",
    "Bug",
    "Details",
    {},
    false,
  )
}

///|
test "parse_args: create with one --set flag" {
  assert_create_issue_result(
    @parser.parse_args(
      [
        "create", "--project", "PROJ", "--summary", "Fix bug", "--set", "customfield_12345=High",
      ][:],
    ),
    "PROJ",
    "Fix bug",
    "Task",
    "",
    { "customfield_12345": "High" },
    false,
  )
}

///|
test "parse_args: create with multiple --set flags" {
  assert_create_issue_result(
    @parser.parse_args(
      [
        "create", "--project", "PROJ", "--summary", "Fix bug", "--set", "customfield_12345=High",
        "--set", "customfield_67890=Team A",
      ][:],
    ),
    "PROJ",
    "Fix bug",
    "Task",
    "",
    { "customfield_12345": "High", "customfield_67890": "Team A" },
    false,
  )
}

///|
test "parse_args: create --set value contains equals sign" {
  assert_create_issue_result(
    @parser.parse_args(
      [
        "create", "--project", "PROJ", "--summary", "Fix bug", "--set", "customfield_123=a=b",
      ][:],
    ),
    "PROJ",
    "Fix bug",
    "Task",
    "",
    { "customfield_123": "a=b" },
    false,
  )
}

///|
test "parse_args: create --set without customfield_ prefix errors" {
  inspect(
    @parser.parse_args(
      [
        "create", "--project", "PROJ", "--summary", "Fix bug", "--set", "priority=High",
      ][:],
    ),
    content="Err(\"Only customfield_* fields are allowed with --set, got: 'priority'\")",
  )
}

///|
test "parse_args: create --set without equals sign errors" {
  inspect(
    @parser.parse_args(
      [
        "create", "--project", "PROJ", "--summary", "Fix bug", "--set", "customfield_12345",
      ][:],
    ),
    content="Err(\"Invalid --set format: 'customfield_12345'. Expected 'customfield_<id>=<value>'\")",
  )
}

///|
test "parse_args: create --set duplicate key last wins" {
  assert_create_issue_result(
    @parser.parse_args(
      [
        "create", "--project", "PROJ", "--summary", "Fix bug", "--set", "customfield_123=first",
        "--set", "customfield_123=second",
      ][:],
    ),
    "PROJ",
    "Fix bug",
    "Task",
    "",
    { "customfield_123": "second" },
    false,
  )
}

///|
test "parse_args: create --set empty value errors" {
  inspect(
    @parser.parse_args(
      [
        "create", "--project", "PROJ", "--summary", "Fix bug", "--set", "customfield_12345=",
      ][:],
    ),
    content="Err(\"Empty value for --set field 'customfield_12345'. Expected 'customfield_<id>=<value>'\")",
  )
}

///|
test "parse_args: create --set customfield_ without id errors" {
  inspect(
    @parser.parse_args(
      [
        "create", "--project", "PROJ", "--summary", "Fix bug", "--set", "customfield_=High",
      ][:],
    ),
    content="Err(\"Only customfield_* fields are allowed with --set, got: 'customfield_'\")",
  )
}

///|
test "parse_args: create --set multi-word value" {
  assert_create_issue_result(
    @parser.parse_args(
      [
        "create", "--project", "PROJ", "--summary", "Fix bug", "--set", "customfield_123=hello",
        "world",
      ][:],
    ),
    "PROJ",
    "Fix bug",
    "Task",
    "",
    { "customfield_123": "hello world" },
    false,
  )
}

///|
test "parse_args: create --set multi-word value followed by another flag" {
  assert_create_issue_result(
    @parser.parse_args(
      [
        "create", "--project", "PROJ", "--summary", "Fix bug", "--set", "customfield_123=hello",
        "world", "--set", "customfield_456=bar",
      ][:],
    ),
    "PROJ",
    "Fix bug",
    "Task",
    "",
    { "customfield_123": "hello world", "customfield_456": "bar" },
    false,
  )
}

///|
test "parse_args: create with --set-json supports multiple fields" {
  assert_create_issue_result(
    @parser.parse_args(
      [
        "issue", "create", "--project", "PROJ", "--summary", "Fix bug", "--set-json",
        "{\"customfield_12345\":{\"id\":\"10401\"},\"customfield_67890\":[\"Backend\",\"Urgent\"]}",
      ][:],
    ),
    "PROJ",
    "Fix bug",
    "Task",
    "",
    {
      "customfield_12345": "{\"id\":\"10401\"}",
      "customfield_67890": "[\"Backend\",\"Urgent\"]",
    },
    false,
  )
}

///|
test "parse_args: create with --set-json invalid json errors" {
  inspect(
    @parser.parse_args(
      [
        "issue", "create", "--project", "PROJ", "--summary", "Fix bug", "--set-json",
        "{\"customfield_12345\":",
      ][:],
    ),
    content="Err(\"Invalid JSON for --set-json: Unexpected end of file\")",
  )
}

///|
test "parse_args: create with --set-json requires object" {
  inspect(
    @parser.parse_args(
      [
        "issue", "create", "--project", "PROJ", "--summary", "Fix bug", "--set-json",
        "[1,2,3]",
      ][:],
    ),
    content="Err(\"--set-json expects a JSON object like '{\\\"customfield_10001\\\":{\\\"id\\\":\\\"10401\\\"}}'\")",
  )
}

///|
test "parse_args: create with mixed --set and --set-json keeps last value" {
  assert_create_issue_result(
    @parser.parse_args(
      [
        "issue", "create", "--project", "PROJ", "--summary", "Fix bug", "--set",
        "customfield_123=legacy", "--set-json", "{\"customfield_123\":{\"id\":\"10401\"},\"customfield_456\":\"Backend\"}",
      ][:],
    ),
    "PROJ",
    "Fix bug",
    "Task",
    "",
    { "customfield_123": "{\"id\":\"10401\"}", "customfield_456": "Backend" },
    false,
  )
}

///|
test "parse_args: create with dry-run" {
  assert_create_issue_result(
    @parser.parse_args(
      [
        "issue", "create", "--project", "PROJ", "--summary", "Fix bug", "--dry-run",
      ][:],
    ),
    "PROJ",
    "Fix bug",
    "Task",
    "",
    {},
    true,
  )
}

///|
test "parse_args: transition" {
  inspect(
    @parser.parse_args(["transition", "--key", "PROJ-1", "--status", "Done"][:]),
    content="Ok(Transition(key=\"PROJ-1\", status=\"Done\"))",
  )
}

///|
test "parse_args: comment" {
  inspect(
    @parser.parse_args(["comment", "--key", "PROJ-1", "--text", "hello"][:]),
    content="Ok(Comment(key=\"PROJ-1\", text=\"hello\"))",
  )
}

///|
test "parse_args: assign" {
  inspect(
    @parser.parse_args(["assign", "--key", "PROJ-1", "--email", "a@b.com"][:]),
    content="Ok(Assign(key=\"PROJ-1\", email=\"a@b.com\"))",
  )
}

///|
test "parse_args: search" {
  inspect(
    @parser.parse_args(["search", "--jql", "status = Open"][:]),
    content="Ok(Search(jql=\"status = Open\", page_request={limit: 20, start_at: 0, fetch_all: false}))",
  )
}

///|
test "parse_args: noun-verb issue search" {
  inspect(
    @parser.parse_args(["issue", "search", "--jql", "status = Open"][:]),
    content="Ok(Search(jql=\"status = Open\", page_request={limit: 20, start_at: 0, fetch_all: false}))",
  )
}

///|
test "parse_args: noun-verb project list" {
  inspect(
    @parser.parse_args(["project", "list"][:]),
    content="Ok(ListProjects(page_request={limit: 0, start_at: 0, fetch_all: true}))",
  )
}

///|
test "parse_args: legacy projects alias" {
  inspect(
    @parser.parse_args(["projects"][:]),
    content="Ok(ListProjects(page_request={limit: 0, start_at: 0, fetch_all: true}))",
  )
}

///|
test "parse_args: project list with limit" {
  inspect(
    @parser.parse_args(["project", "list", "--limit", "2"][:]),
    content="Ok(ListProjects(page_request={limit: 2, start_at: 0, fetch_all: false}))",
  )
}

///|
test "parse_args: project list rejects --all with --limit" {
  inspect(
    @parser.parse_args(["project", "list", "--all", "--limit", "2"][:]),
    content="Err(\"--all cannot be combined with --limit\\nUsage: project list [--limit <n>] [--start-at <n>] [--all]\")",
  )
}

///|
test "parse_args: unknown command" {
  assert_true(@parser.parse_args(["unknown"][:]) is Err(_))
}

///|
test "parse_args: unknown flag returns error" {
  inspect(
    @parser.parse_args(
      ["issues", "--unknown", "x", "--jql", "project = TEST"][:],
    ),
    content="Err(\"Unknown flag or unexpected argument: --unknown\")",
  )
}

///|
test "parse_args: missing value returns error" {
  inspect(
    @parser.parse_args(["create", "--project", "PROJ", "--summary"][:]),
    content="Err(\"Missing value for flag: --summary\")",
  )
}

///|
test "parse_args: disallowed flag returns error per subcommand" {
  inspect(
    @parser.parse_args(["issues", "--email", "a@b.com"][:]),
    content="Err(\"Unknown flag or unexpected argument: --email\")",
  )
}

///|
test "parse_args: update with summary" {
  assert_update_issue_result(
    @parser.parse_args(["update", "TEST-1", "--summary", "New title"][:]),
    "TEST-1",
    "New title",
    "",
    "",
    "",
    "",
    "",
    {},
    false,
  )
}

///|
test "parse_args: update with priority and labels" {
  assert_update_issue_result(
    @parser.parse_args(
      ["update", "TEST-1", "--priority", "High", "--labels", "bug,urgent"][:],
    ),
    "TEST-1",
    "",
    "",
    "High",
    "",
    "bug,urgent",
    "",
    {},
    false,
  )
}

///|
test "parse_args: update with assignee only" {
  assert_update_issue_result(
    @parser.parse_args(
      ["update", "TEST-1", "--assignee", "user@example.com"][:],
    ),
    "TEST-1",
    "",
    "",
    "",
    "",
    "",
    "user@example.com",
    {},
    false,
  )
}

///|
test "parse_args: update with description and custom field" {
  assert_update_issue_result(
    @parser.parse_args(
      [
        "update", "TEST-1", "--description", "New desc", "--set", "customfield_123=value",
      ][:],
    ),
    "TEST-1",
    "",
    "New desc",
    "",
    "",
    "",
    "",
    { "customfield_123": "value" },
    false,
  )
}

///|
test "parse_args: update with type only" {
  assert_update_issue_result(
    @parser.parse_args(["update", "TEST-1", "--type", "Bug"][:]),
    "TEST-1",
    "",
    "",
    "",
    "Bug",
    "",
    "",
    {},
    false,
  )
}

///|
test "parse_args: update with all flags" {
  assert_update_issue_result(
    @parser.parse_args(
      [
        "update", "TEST-1", "--summary", "title", "--description", "desc", "--priority",
        "High", "--type", "Bug", "--labels", "bug", "--assignee", "a@b.com", "--set",
        "customfield_123=val",
      ][:],
    ),
    "TEST-1",
    "title",
    "desc",
    "High",
    "Bug",
    "bug",
    "a@b.com",
    { "customfield_123": "val" },
    false,
  )
}

///|
test "parse_args: update with --set-json supports multiple fields" {
  assert_update_issue_result(
    @parser.parse_args(
      [
        "issue", "update", "TEST-1", "--set-json", "{\"customfield_123\":{\"id\":\"10401\"},\"customfield_456\":{\"value\":\"Backend\"}}",
      ][:],
    ),
    "TEST-1",
    "",
    "",
    "",
    "",
    "",
    "",
    {
      "customfield_123": "{\"id\":\"10401\"}",
      "customfield_456": "{\"value\":\"Backend\"}",
    },
    false,
  )
}

///|
test "parse_args: update with dry-run" {
  assert_update_issue_result(
    @parser.parse_args(
      ["issue", "update", "TEST-1", "--summary", "title", "--dry-run"][:],
    ),
    "TEST-1",
    "title",
    "",
    "",
    "",
    "",
    "",
    {},
    true,
  )
}

///|
test "parse_args: update missing key" {
  assert_true(@parser.parse_args(["update"][:]) is Err(_))
}

///|
test "parse_args: update no fields specified" {
  let result = @parser.parse_args(["update", "TEST-1"][:])
  assert_true(result is Err(_))
  match result {
    Err(msg) => {
      assert_true(msg.contains("At least one field must be specified"))
      assert_true(msg.contains("Usage: update"))
    }
    _ => ()
  }
}

///|
test "parse_args: update key starts with -- is treated as missing key" {
  assert_true(@parser.parse_args(["update", "--summary", "title"][:]) is Err(_))
}
