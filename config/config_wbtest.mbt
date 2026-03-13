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

///|
test "resolve_runtime_config_from prefers env over saved config" {
  let resolved = resolve_runtime_config_from(
    {
      base_url: "https://env.atlassian.net",
      email: "env@example.com",
      api_token: "env-token",
    },
    {
      base_url: "https://saved.atlassian.net",
      email: "saved@example.com",
      api_token: "saved-token",
    },
  )
  assert_eq(resolved.base_url, "https://env.atlassian.net")
  assert_eq(resolved.email, "env@example.com")
  assert_eq(resolved.api_token, "env-token")
}

///|
test "resolve_config_for_save_from prefers flag over env over config" {
  let resolved = resolve_config_for_save_from(
    "https://flag.atlassian.net",
    "",
    "",
    "",
    {
      base_url: "https://env.atlassian.net",
      email: "env@example.com",
      api_token: "env-token",
    },
    {
      base_url: "https://saved.atlassian.net",
      email: "saved@example.com",
      api_token: "saved-token",
    },
  )
  assert_eq(resolved.base_url, "https://flag.atlassian.net")
  assert_eq(resolved.email, "env@example.com")
  assert_eq(resolved.api_token, "env-token")
}

///|
test "resolve_config_for_save_from uses stdin token ahead of env and config" {
  let resolved = resolve_config_for_save_from(
    "",
    "",
    "",
    "stdin-token",
    {
      base_url: "https://env.atlassian.net",
      email: "env@example.com",
      api_token: "env-token",
    },
    {
      base_url: "https://saved.atlassian.net",
      email: "saved@example.com",
      api_token: "saved-token",
    },
  )
  assert_eq(resolved.base_url, "https://env.atlassian.net")
  assert_eq(resolved.email, "env@example.com")
  assert_eq(resolved.api_token, "stdin-token")
}
