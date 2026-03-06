///|
test "parse_args: help command" {
  inspect(@jira_cli_mbt.parse_args(["help"][:]), content="Ok(Help)")
}

///|
test "parse_args: --help flag" {
  inspect(@jira_cli_mbt.parse_args(["--help"][:]), content="Ok(Help)")
}

///|
test "parse_args: empty args shows help" {
  inspect(@jira_cli_mbt.parse_args([][:]), content="Ok(Help)")
}

///|
test "parse_args: list issues with default jql" {
  inspect(
    @jira_cli_mbt.parse_args(["issues"][:]),
    content="Ok(ListIssues(jql=\"assignee = currentUser() ORDER BY updated DESC\"))",
  )
}

///|
test "parse_args: list issues with custom jql" {
  inspect(
    @jira_cli_mbt.parse_args(["issues", "--jql", "project = TEST"][:]),
    content="Ok(ListIssues(jql=\"project = TEST\"))",
  )
}

///|
test "parse_args: get issue" {
  inspect(
    @jira_cli_mbt.parse_args(["issue", "PROJ-123"][:]),
    content="Ok(GetIssue(key=\"PROJ-123\"))",
  )
}

///|
test "parse_args: issue missing key" {
  assert_true(@jira_cli_mbt.parse_args(["issue"][:]) is Err(_))
}

///|
test "parse_args: config with all flags" {
  inspect(
    @jira_cli_mbt.parse_args(
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
  assert_true(
    @jira_cli_mbt.parse_args(["config", "--base-url", "url"][:]) is Err(_),
  )
}

///|
test "parse_args: create issue" {
  inspect(
    @jira_cli_mbt.parse_args(
      ["create", "--project", "PROJ", "--summary", "Fix bug"][:],
    ),
    content="Ok(CreateIssue(project=\"PROJ\", summary=\"Fix bug\", issue_type=\"Task\", description=\"\"))",
  )
}

///|
test "parse_args: create with type and description" {
  inspect(
    @jira_cli_mbt.parse_args(
      [
        "create", "--project", "PROJ", "--summary", "Fix bug", "--type", "Bug", "--description",
        "Details",
      ][:],
    ),
    content="Ok(CreateIssue(project=\"PROJ\", summary=\"Fix bug\", issue_type=\"Bug\", description=\"Details\"))",
  )
}

///|
test "parse_args: transition" {
  inspect(
    @jira_cli_mbt.parse_args(
      ["transition", "--key", "PROJ-1", "--status", "Done"][:],
    ),
    content="Ok(Transition(key=\"PROJ-1\", status=\"Done\"))",
  )
}

///|
test "parse_args: comment" {
  inspect(
    @jira_cli_mbt.parse_args(
      ["comment", "--key", "PROJ-1", "--text", "hello"][:],
    ),
    content="Ok(Comment(key=\"PROJ-1\", text=\"hello\"))",
  )
}

///|
test "parse_args: assign" {
  inspect(
    @jira_cli_mbt.parse_args(
      ["assign", "--key", "PROJ-1", "--email", "a@b.com"][:],
    ),
    content="Ok(Assign(key=\"PROJ-1\", email=\"a@b.com\"))",
  )
}

///|
test "parse_args: search" {
  inspect(
    @jira_cli_mbt.parse_args(["search", "--jql", "status = Open"][:]),
    content="Ok(Search(jql=\"status = Open\"))",
  )
}

///|
test "parse_args: projects" {
  inspect(@jira_cli_mbt.parse_args(["projects"][:]), content="Ok(ListProjects)")
}

///|
test "parse_args: unknown command" {
  assert_true(@jira_cli_mbt.parse_args(["unknown"][:]) is Err(_))
}

///|
test "format_usage: contains all commands" {
  let usage = @jira_cli_mbt.format_usage()
  assert_true(usage.contains("issues"))
  assert_true(usage.contains("config"))
  assert_true(usage.contains("search"))
  assert_true(usage.contains("projects"))
  assert_true(usage.contains("transition"))
  assert_true(usage.contains("comment"))
  assert_true(usage.contains("assign"))
}
