///|
test "decode_config: valid content" {
  let config = decode_config(
    "{\"base_url\":\"https://x.atlassian.net\",\"email\":\"a@b.com\",\"api_token\":\"tok\"}",
  ).unwrap()
  assert_eq(config.base_url, "https://x.atlassian.net")
  assert_eq(config.email, "a@b.com")
  assert_eq(config.api_token, "tok")
}

///|
test "decode_config: invalid json" {
  inspect(
    decode_config("{"),
    content="Err(\"Failed to parse config JSON: Unexpected end of file\")",
  )
}

///|
test "decode_config: invalid schema" {
  let message = match
    decode_config("{\"base_url\":\"https://x.atlassian.net\"}") {
    Err(message) => message
    Ok(_) => ""
  }
  assert_true(message.contains("Invalid config schema"))
}
