///|
test "parse_args: help command" {
  inspect(@parser.parse_args(["help"][:]), content="Ok(Help)")
}

///|
test "parse_args: --help flag" {
  inspect(@parser.parse_args(["--help"][:]), content="Ok(Help)")
}

///|
test "parse_args: empty args shows help" {
  inspect(@parser.parse_args([][:]), content="Ok(Help)")
}

///|
test "parse_args: list issues with default jql" {
  inspect(
    @parser.parse_args(["issues"][:]),
    content="Ok(ListIssues(jql=\"assignee = currentUser() ORDER BY updated DESC\", fields=[Key, IssueType, Status, Priority, Summary]))",
  )
}

///|
test "parse_args: list issues with custom jql" {
  inspect(
    @parser.parse_args(["issues", "--jql", "project = TEST"][:]),
    content="Ok(ListIssues(jql=\"project = TEST\", fields=[Key, IssueType, Status, Priority, Summary]))",
  )
}

///|
test "parse_args: list issues with custom fields" {
  inspect(
    @parser.parse_args(["issues", "--fields", "key,assignee,summary"][:]),
    content="Ok(ListIssues(jql=\"assignee = currentUser() ORDER BY updated DESC\", fields=[Key, Assignee, Summary]))",
  )
}

///|
test "parse_args: list issues with custom jira field" {
  inspect(
    @parser.parse_args(["issues", "--fields", "key,customfield_12345"][:]),
    content="Ok(ListIssues(jql=\"assignee = currentUser() ORDER BY updated DESC\", fields=[Key, Custom(\"customfield_12345\")]))",
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
test "parse_args: get issue" {
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
test "parse_args: issue missing key" {
  assert_true(@parser.parse_args(["issue"][:]) is Err(_))
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
    content="Ok(Config(base_url=\"https://x.atlassian.net\", email=\"a@b.com\", api_token=\"tok\"))",
  )
}

///|
test "parse_args: config missing flags" {
  assert_true(@parser.parse_args(["config", "--base-url", "url"][:]) is Err(_))
}

///|
test "parse_args: create issue" {
  inspect(
    @parser.parse_args(
      ["create", "--project", "PROJ", "--summary", "Fix bug"][:],
    ),
    content="Ok(CreateIssue(project=\"PROJ\", summary=\"Fix bug\", issue_type=\"Task\", description=\"\", custom_fields={}))",
  )
}

///|
test "parse_args: create with type and description" {
  inspect(
    @parser.parse_args(
      [
        "create", "--project", "PROJ", "--summary", "Fix bug", "--type", "Bug", "--description",
        "Details",
      ][:],
    ),
    content="Ok(CreateIssue(project=\"PROJ\", summary=\"Fix bug\", issue_type=\"Bug\", description=\"Details\", custom_fields={}))",
  )
}

///|
test "parse_args: create with one --set flag" {
  inspect(
    @parser.parse_args(
      [
        "create", "--project", "PROJ", "--summary", "Fix bug", "--set", "customfield_12345=High",
      ][:],
    ),
    content="Ok(CreateIssue(project=\"PROJ\", summary=\"Fix bug\", issue_type=\"Task\", description=\"\", custom_fields={\"customfield_12345\": \"High\"}))",
  )
}

///|
test "parse_args: create with multiple --set flags" {
  inspect(
    @parser.parse_args(
      [
        "create", "--project", "PROJ", "--summary", "Fix bug", "--set", "customfield_12345=High",
        "--set", "customfield_67890=Team A",
      ][:],
    ),
    content="Ok(CreateIssue(project=\"PROJ\", summary=\"Fix bug\", issue_type=\"Task\", description=\"\", custom_fields={\"customfield_12345\": \"High\", \"customfield_67890\": \"Team A\"}))",
  )
}

///|
test "parse_args: create --set value contains equals sign" {
  inspect(
    @parser.parse_args(
      [
        "create", "--project", "PROJ", "--summary", "Fix bug", "--set", "customfield_123=a=b",
      ][:],
    ),
    content="Ok(CreateIssue(project=\"PROJ\", summary=\"Fix bug\", issue_type=\"Task\", description=\"\", custom_fields={\"customfield_123\": \"a=b\"}))",
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
  inspect(
    @parser.parse_args(
      [
        "create", "--project", "PROJ", "--summary", "Fix bug", "--set", "customfield_123=first",
        "--set", "customfield_123=second",
      ][:],
    ),
    content="Ok(CreateIssue(project=\"PROJ\", summary=\"Fix bug\", issue_type=\"Task\", description=\"\", custom_fields={\"customfield_123\": \"second\"}))",
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
  inspect(
    @parser.parse_args(
      [
        "create", "--project", "PROJ", "--summary", "Fix bug", "--set", "customfield_123=hello",
        "world",
      ][:],
    ),
    content="Ok(CreateIssue(project=\"PROJ\", summary=\"Fix bug\", issue_type=\"Task\", description=\"\", custom_fields={\"customfield_123\": \"hello world\"}))",
  )
}

///|
test "parse_args: create --set multi-word value followed by another flag" {
  inspect(
    @parser.parse_args(
      [
        "create", "--project", "PROJ", "--summary", "Fix bug", "--set", "customfield_123=hello",
        "world", "--set", "customfield_456=bar",
      ][:],
    ),
    content="Ok(CreateIssue(project=\"PROJ\", summary=\"Fix bug\", issue_type=\"Task\", description=\"\", custom_fields={\"customfield_123\": \"hello world\", \"customfield_456\": \"bar\"}))",
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
    content="Ok(Search(jql=\"status = Open\"))",
  )
}

///|
test "parse_args: projects" {
  inspect(@parser.parse_args(["projects"][:]), content="Ok(ListProjects)")
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
