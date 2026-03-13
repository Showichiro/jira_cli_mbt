///|
fn config_dir() -> String {
  @path.join2(@path.join2(@os.homedir(), ".config"), "jira_cli_mbt")
}

///|
fn config_path() -> String {
  @path.join2(config_dir(), "config.json")
}

///|
let env_base_url_key : String = "JIRA_BASE_URL"

///|
let env_email_key : String = "JIRA_EMAIL"

///|
let env_api_token_key : String = "JIRA_API_TOKEN"

///|
fn decode_config(content : String) -> Result[@types.JiraConfig, String] {
  let json : Json = @json.parse(content) catch {
    e => return Err("Failed to parse config JSON: \{e}")
  }
  let config : @types.JiraConfig = @json.from_json(json) catch {
    e => return Err("Invalid config schema: \{e}")
  }
  Ok(config)
}

///|
fn normalized_config_value(value : String) -> String {
  value.trim().to_string()
}

///|
fn env_config() -> @types.JiraConfig {
  {
    base_url: normalized_config_value(get_env(env_base_url_key)),
    email: normalized_config_value(get_env(env_email_key)),
    api_token: normalized_config_value(get_env(env_api_token_key)),
  }
}

///|
fn empty_config() -> @types.JiraConfig {
  { base_url: "", email: "", api_token: "" }
}

///|
fn resolve_config_value(
  primary : String,
  env : String,
  saved : String,
) -> String {
  if primary.length() > 0 {
    primary
  } else if env.length() > 0 {
    env
  } else {
    saved
  }
}

///|
fn missing_config_fields(config : @types.JiraConfig) -> Array[String] {
  let missing : Array[String] = []
  if config.base_url.length() == 0 {
    missing.push("base_url")
  }
  if config.email.length() == 0 {
    missing.push("email")
  }
  if config.api_token.length() == 0 {
    missing.push("api_token")
  }
  missing
}

///|
fn missing_config_message(
  missing : Array[String],
  resolution_order : String,
) -> String {
  let path = config_path()
  let missing_text = missing.join(", ")
  "Could not resolve Jira configuration. Missing: \{missing_text}. Resolution order: \{resolution_order}. Env vars: \{env_base_url_key}, \{env_email_key}, \{env_api_token_key}. Config path: \{path}."
}

///|
fn resolved_config_or_error(
  base_url : String,
  email : String,
  api_token : String,
  resolution_order : String,
) -> @types.JiraConfig raise {
  let config : @types.JiraConfig = { base_url, email, api_token }
  let missing = missing_config_fields(config)
  guard missing.is_empty() else {
    raise ConfigError(missing_config_message(missing, resolution_order))
  }
  config
}

///|
async fn load_saved_config_optional() -> @types.JiraConfig? {
  let path = config_path()
  guard file_exists(path) else { return None }
  let content = read_file(path) catch {
    e => raise ConfigError("Failed to read config at \{path}. Details: \{e}")
  }
  match decode_config(content) {
    Ok(config) => Some(config)
    Err(message) => raise ConfigError("\{message} (\{path})")
  }
}

///|
fn config_or_empty(config : @types.JiraConfig?) -> @types.JiraConfig {
  match config {
    Some(config) => config
    None => empty_config()
  }
}

///|
fn resolve_runtime_config_from(
  env : @types.JiraConfig,
  saved_config : @types.JiraConfig,
) -> @types.JiraConfig raise {
  resolved_config_or_error(
    resolve_config_value("", env.base_url, saved_config.base_url),
    resolve_config_value("", env.email, saved_config.email),
    resolve_config_value("", env.api_token, saved_config.api_token),
    "env > config",
  )
}

///|
fn resolve_config_for_save_from(
  base_url : String,
  email : String,
  api_token : String,
  stdin_token : String,
  env : @types.JiraConfig,
  saved_config : @types.JiraConfig,
) -> @types.JiraConfig raise {
  resolved_config_or_error(
    resolve_config_value(
      normalized_config_value(base_url),
      env.base_url,
      saved_config.base_url,
    ),
    resolve_config_value(
      normalized_config_value(email),
      env.email,
      saved_config.email,
    ),
    resolve_config_value(
      if stdin_token.length() > 0 {
        stdin_token
      } else {
        normalized_config_value(api_token)
      },
      env.api_token,
      saved_config.api_token,
    ),
    "flag > env > config",
  )
}

///|
pub async fn load_config() -> @types.JiraConfig {
  let saved_config = config_or_empty(load_saved_config_optional())
  let env = env_config()
  resolve_runtime_config_from(env, saved_config)
}

///|
pub async fn resolve_config_for_save(
  base_url : String,
  email : String,
  api_token : String,
  api_token_stdin : Bool,
) -> @types.JiraConfig {
  guard not(api_token_stdin && api_token.length() > 0) else {
    raise ConfigError("--api-token and --api-token-stdin cannot be combined")
  }
  let saved_config = config_or_empty(load_saved_config_optional())
  let env = env_config()
  let stdin_token = if api_token_stdin {
    normalized_config_value(read_stdin())
  } else {
    ""
  }
  if api_token_stdin && stdin_token.length() == 0 {
    raise ConfigError(
      "Received empty API token from stdin. Pipe the token or use --api-token.",
    )
  }
  resolve_config_for_save_from(
    base_url, email, api_token, stdin_token, env, saved_config,
  )
}

///|
pub async fn save_config(config : @types.JiraConfig) -> Unit {
  mkdir_recursive(config_dir())
  let json = config.to_json().stringify()
  write_file(config_path(), json)
}
