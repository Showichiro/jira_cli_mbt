///|
test "format_usage: contains all commands" {
  let usage = @formatter.format_usage()
  assert_true(usage.contains("--format"))
  assert_true(usage.contains("issues"))
  assert_true(usage.contains("config"))
  assert_true(usage.contains("search"))
  assert_true(usage.contains("projects"))
  assert_true(usage.contains("transition"))
  assert_true(usage.contains("comment"))
  assert_true(usage.contains("assign"))
  assert_true(usage.contains("update"))
  assert_true(usage.contains("describe"))
}

///|
test "format_command_description_for_output: json includes self description" {
  let spec = @types.require_command_spec("issue").unwrap()
  let formatted = @formatter.format_command_description_for_output(
    spec,
    @types.Json,
  )
  assert_true(formatted.contains("\"kind\":\"command_description\""))
  assert_true(formatted.contains("\"name\":\"issue\""))
  assert_true(formatted.contains("\"usage\":\"jira-cli issue <key>"))
  assert_true(
    formatted.contains("\"output_formats\":[\"table\",\"tsv\",\"json\"]"),
  )
}
