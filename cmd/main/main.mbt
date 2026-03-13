///|
fn write_stderr(message : String) -> Unit {
  let process = @core.global_this()._get("process")
  let stderr = process._get("stderr")
  let _ = stderr._call("write", [@core.any(message + "\n")])
}

///|
fn main {
  @core.run_async(async fn() noraise {
    try {
      let result = @jira_cli_mbt.run(@process.argv()[2:])
      if result.stdout.length() > 0 {
        println(result.stdout)
      }
      if result.stderr.length() > 0 {
        write_stderr(result.stderr)
      }
      @process.exit(result.exit_code)
    } catch {
      e => {
        write_stderr("Error: \{e}")
        @process.exit(1)
      }
    }
  })
}
