///|
test "parse_flags: basic" {
  let flags = parse_flags(
    ["--key", "PROJ-1", "--status", "Done"][:],
    transition_flags,
    {},
  )
  inspect(flags, content="Ok({\"key\": \"PROJ-1\", \"status\": \"Done\"})")
}

///|
test "parse_flags: empty" {
  inspect(parse_flags([][:], issues_flags, {}), content="Ok({})")
}

///|
test "parse_flags: unknown flag" {
  inspect(
    parse_flags(["--nope", "x"][:], issues_flags, {}),
    content="Err(\"Unknown flag or unexpected argument: --nope\")",
  )
}

///|
test "parse_flags: missing value" {
  inspect(
    parse_flags(["--key"][:], transition_flags, {}),
    content="Err(\"Missing value for flag: --key\")",
  )
}

///|
test "parse_flags: reject globally known but disallowed flag" {
  inspect(
    parse_flags(["--email", "a@b.com"][:], issues_flags, {}),
    content="Err(\"Unknown flag or unexpected argument: --email\")",
  )
}

///|
test "parse_issue_fields: trims aliases and dedups" {
  inspect(
    parse_issue_fields(" summary, type ,summary "),
    content="Ok([Summary, IssueType])",
  )
}

///|
test "parse_issue_fields: accepts custom jira fields" {
  inspect(
    parse_issue_fields("customfield_12345, customfield_12345"),
    content="Ok([Custom(\"customfield_12345\")])",
  )
}

///|
test "parse_issue_fields: empty list" {
  inspect(
    parse_issue_fields(" , "),
    content="Err(\"Field list must not be empty\")",
  )
}
