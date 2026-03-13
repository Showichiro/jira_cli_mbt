///|
test "classify_api_error maps stable categories" {
  assert_eq(classify_api_error(400, "bad request"), @types.Validation)
  assert_eq(classify_api_error(401, "unauthorized"), @types.Auth)
  assert_eq(classify_api_error(403, "forbidden"), @types.Auth)
  assert_eq(classify_api_error(404, "missing"), @types.NotFound)
  assert_eq(classify_api_error(409, "conflict"), @types.Validation)
  assert_eq(classify_api_error(500, "boom"), @types.General)
}

///|
test "failure_result returns structured json error" {
  let result = failure_result(
    @types.Usage,
    "Unknown command: nope",
    @types.Json,
    discovery_hint={
      message: "Unknown command: nope",
      candidates: [
        { value: "issue list", label: "issue list", description: "" },
      ],
      required_args: [],
      next_step: "Run `jira-cli help issue`.",
    },
  )
  assert_eq(result.stdout, "")
  assert_eq(result.exit_code, 2)
  assert_true(result.stderr.contains("\"category\":\"usage\""))
  assert_true(result.stderr.contains("\"exit_code\":2"))
  assert_true(result.stderr.contains("\"candidates\":["))
  assert_true(
    result.stderr.contains("\"next_step\":\"Run `jira-cli help issue`.\""),
  )
}

///|
test "failure_result returns text usage for table output" {
  let result = failure_result(
    @types.Usage,
    "Unknown command: nope",
    @types.Table,
    usage="Usage: jira-cli <command> [options]",
  )
  assert_eq(result.stdout, "")
  assert_eq(result.exit_code, 2)
  assert_true(result.stderr.contains("Usage: jira-cli <command> [options]"))
  assert_true(result.stderr.contains("Error: Unknown command: nope"))
}
