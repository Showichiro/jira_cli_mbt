///|
test "parse_flags: basic" {
  let flags = parse_flags(["--key", "PROJ-1", "--status", "Done"][:], {})
  inspect(flags.get("key"), content="Some(\"PROJ-1\")")
  inspect(flags.get("status"), content="Some(\"Done\")")
}

///|
test "parse_flags: empty" {
  let flags = parse_flags([][:], {})
  inspect(flags.length(), content="0")
}
