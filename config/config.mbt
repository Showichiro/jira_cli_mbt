///|
fn config_dir() -> String {
  @path.join2(@path.join2(@os.homedir(), ".config"), "jira_cli_mbt")
}

///|
fn config_path() -> String {
  @path.join2(config_dir(), "config.json")
}

///|
pub async fn load_config() -> @types.JiraConfig {
  let content = read_file(config_path()) catch {
    _ =>
      raise ConfigError(
        "Config not found. Run: jira config --base-url <url> --email <email> --api-token <token>",
      )
  }
  let json : Json = @json.parse(content)
  @json.from_json(json)
}

///|
pub async fn save_config(config : @types.JiraConfig) -> Unit {
  mkdir_recursive(config_dir())
  let json = config.to_json().stringify()
  write_file(config_path(), json)
}
