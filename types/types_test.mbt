///|
test "parse_issue_field supports aliases" {
  inspect(@types.parse_issue_field("type"), content="Ok(IssueType)")
  inspect(@types.parse_issue_field("issuetype"), content="Ok(IssueType)")
  inspect(
    @types.parse_issue_field("customfield_12345"),
    content="Ok(Custom(\"customfield_12345\"))",
  )
}

///|
test "default issue field sets stay stable" {
  inspect(
    @types.default_list_issue_fields(),
    content="[Key, IssueType, Status, Priority, Summary]",
  )
  inspect(
    @types.default_detail_issue_fields(),
    content="[Key, IssueType, Status, Priority, Assignee, Summary, Description]",
  )
}

///|
test "parse_output_format supports stable names" {
  inspect(@types.parse_output_format("table"), content="Ok(Table)")
  inspect(@types.parse_output_format("tsv"), content="Ok(Tsv)")
  inspect(@types.parse_output_format("json"), content="Ok(Json)")
  inspect(
    @types.parse_output_format("yaml"),
    content="Err(\"Unsupported output format: yaml\")",
  )
}

///|
test "cli error categories map to stable exit codes" {
  assert_eq(@types.Usage.exit_code(), 2)
  assert_eq(@types.CliErrorCategory::Config.exit_code(), 4)
  assert_eq(@types.Auth.exit_code(), 4)
  assert_eq(@types.NotFound.exit_code(), 3)
  assert_eq(@types.Validation.exit_code(), 5)
  assert_eq(@types.General.exit_code(), 1)
}

///|
test "jira issue field_value reads requested field" {
  let issue : @types.JiraIssue = {
    key: "PROJ-1",
    summary: "Fix bug",
    status: "Open",
    assignee: "Alice",
    issue_type: "Bug",
    priority: "High",
    description: "Details",
    custom_fields: { "customfield_12345": "Platform Team" },
  }
  assert_eq(issue.field_value(@types.Assignee), "Alice")
  assert_eq(issue.field_value(@types.Description), "Details")
  assert_eq(
    issue.field_value(@types.Custom("customfield_12345")),
    "Platform Team",
  )
}

///|
test "custom field input helpers expose explicit and convenience shapes" {
  assert_eq(
    @types.custom_field_input_from_set_value("hello").display_value(),
    "hello",
  )
  assert_eq(
    @types.custom_field_input_from_set_value("10401").display_value(),
    "{\"id\":\"10401\"}",
  )
  assert_eq(
    @types.custom_field_input_json(Json::object({ "id": Json::string("1") })).display_value(),
    "{\"id\":\"1\"}",
  )
}

///|
test "command specs resolve canonical names and aliases" {
  let help_spec = @types.require_command_spec("--help").unwrap()
  assert_eq(help_spec.name, "help")

  let describe_spec = @types.require_command_spec("describe").unwrap()
  assert_eq(describe_spec.name, "describe")
  assert_eq(
    describe_spec.output_formats.map(fn(format) { format.name() }).join(","),
    "table,tsv,json",
  )

  let issues_spec = @types.require_command_spec("issues").unwrap()
  assert_eq(issues_spec.name, "issue list")

  let issue_alias_spec = @types.require_command_spec("issue PROJ-123").unwrap()
  assert_eq(issue_alias_spec.name, "issue get")

  let field_alias_spec = @types.require_command_spec("fields customfield_10001").unwrap()
  assert_eq(field_alias_spec.name, "field get")

  let config_spec = @types.require_command_spec("config").unwrap()
  assert_true(
    config_spec.flags.any(fn(flag) { flag.name == "--api-token-stdin" }),
  )
  assert_true(
    config_spec.notes.any(fn(note) {
      note.contains("api_token uses flag > config > env")
    }),
  )

  let create_spec = @types.require_command_spec("create").unwrap()
  assert_eq(create_spec.name, "issue create")
  assert_eq(
    create_spec.output_formats.map(fn(format) { format.name() }).join(","),
    "table,tsv,json",
  )
  assert_true(create_spec.flags.any(fn(flag) { flag.name == "--dry-run" }))
  assert_true(create_spec.flags.any(fn(flag) { flag.name == "--set-json" }))

  let issue_group_spec = @types.require_command_spec("issue").unwrap()
  assert_eq(issue_group_spec.name, "issue")

  let update_spec = @types.require_command_spec("issue update").unwrap()
  assert_eq(
    update_spec.output_formats.map(fn(format) { format.name() }).join(","),
    "table,tsv,json",
  )
  assert_true(update_spec.flags.any(fn(flag) { flag.name == "--dry-run" }))
  assert_true(update_spec.flags.any(fn(flag) { flag.name == "--set-json" }))
}
