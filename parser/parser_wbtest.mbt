///|
test "parse_flags: basic" {
  let flags = parse_flags(["--key", "PROJ-1", "--status", "Done"][:], {})
  inspect(flags, content="Ok({\"key\": \"PROJ-1\", \"status\": \"Done\"})")
}

///|
test "parse_flags: empty" {
  inspect(parse_flags([][:], {}), content="Ok({})")
}

///|
test "parse_flags: unknown flag" {
  inspect(
    parse_flags(["--nope", "x"][:], {}),
    content="Err(\"Unknown flag or unexpected argument: --nope\")",
  )
}

///|
test "parse_flags: missing value" {
  inspect(
    parse_flags(["--key"][:], {}),
    content="Err(\"Missing value for flag: --key\")",
  )
}
