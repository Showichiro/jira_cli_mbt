///|
test "format_usage: contains all commands" {
  let usage = @formatter.format_usage()
  assert_true(usage.contains("--format"))
  assert_true(usage.contains("issue list"))
  assert_true(usage.contains("issue get"))
  assert_true(usage.contains("config"))
  assert_true(usage.contains("issue search"))
  assert_true(usage.contains("project list"))
  assert_true(usage.contains("issue transition"))
  assert_true(usage.contains("issue comment"))
  assert_true(usage.contains("issue assign"))
  assert_true(usage.contains("issue update"))
  assert_true(usage.contains("field get"))
  assert_true(usage.contains("describe"))
}

///|
test "format_command_description_for_output: json includes self description" {
  let spec = @types.require_command_spec("issue get").unwrap()
  let formatted = @formatter.format_command_description_for_output(
    spec,
    @types.Json,
  )
  assert_true(formatted.contains("\"kind\":\"command_description\""))
  assert_true(formatted.contains("\"name\":\"issue get\""))
  assert_true(
    formatted.contains(
      "\"usage\":\"jira-cli issue get <key> [--fields <field,...>] [--format <table|tsv|json>]\"",
    ),
  )
  assert_true(
    formatted.contains(
      "\"default_value\":\"key,type,status,priority,assignee,summary,description\"",
    ),
  )
  assert_true(
    formatted.contains("\"output_formats\":[\"table\",\"tsv\",\"json\"]"),
  )
}

///|
test "format_command_description_for_output: json preserves unset defaults as null" {
  let spec = @types.require_command_spec("issue create").unwrap()
  let formatted = @formatter.format_command_description_for_output(
    spec,
    @types.Json,
  )
  assert_true(formatted.contains("\"name\":\"--summary\""))
  assert_true(formatted.contains("\"default_value\":null"))
  assert_true(formatted.contains("\"default_value\":\"Task\""))
}
