///|
fn main {
  @core.run_async(async fn() noraise {
    try {
      let args = @process.argv()[2:]
      let output = @jira_cli_mbt.execute(@jira_cli_mbt.parse_args(args[:]))
      println(output)
    } catch {
      @api.JiraApiError(msg) => {
        println("Error: \{msg}")
        @process.exit(1)
      }
      @config.ConfigError(msg) => {
        println("Error: \{msg}")
        @process.exit(1)
      }
      e => {
        println("Error: \{e}")
        @process.exit(1)
      }
    }
  })
}
