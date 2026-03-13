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
}
