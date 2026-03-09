///|
fn config_dir() -> String {
  @path.join2(@path.join2(@os.homedir(), ".config"), "jira_cli_mbt")
}

///|
fn config_path() -> String {
  @path.join2(config_dir(), "config.json")
}

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
pub async fn load_config() -> @types.JiraConfig {
  let path = config_path()
  let content = read_file(path) catch {
    e =>
      raise ConfigError(
        "Failed to read config at \{path}. Run: jira config --base-url <url> --email <email> --api-token <token>. Details: \{e}",
      )
  }
  match decode_config(content) {
    Ok(config) => config
    Err(message) => raise ConfigError("\{message} (\{path})")
  }
}

///|
pub async fn save_config(config : @types.JiraConfig) -> Unit {
  mkdir_recursive(config_dir())
  let json = config.to_json().stringify()
  write_file(config_path(), json)
}
