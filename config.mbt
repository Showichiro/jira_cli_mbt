///|
fn config_dir() -> String {
  @path.join([@os.homedir(), ".config", "jira_cli_mbt"])
}

///|
fn config_path() -> String {
  @path.join2(config_dir(), "config.json")
}

///|
pub async fn load_config() -> JiraConfig {
  let content = @fs_promises.readFile(config_path())
  let json : Json = @json.parse(content)
  @json.from_json(json)
}

///|
pub async fn save_config(config : JiraConfig) -> Unit {
  @fs_promises.mkdir(config_dir(), recursive=true)
  let json = config.to_json().stringify()
  @fs_promises.writeFile(config_path(), json)
}
