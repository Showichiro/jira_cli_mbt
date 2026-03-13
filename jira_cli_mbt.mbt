///|
pub fn parse_args(args : ArrayView[String]) -> Result[@types.Command, String] {
  @parser.parse_args(args)
}

///|
pub fn parse_request(
  args : ArrayView[String],
) -> Result[@types.Invocation, String] {
  @parser.parse_request(args)
}

///|
async fn execute_command(
  command : @types.Command,
  output_format : @types.OutputFormat,
) -> String {
  match command {
    @types.Help => @formatter.format_usage()
    @types.Config(base_url~, email~, api_token~) => {
      @config.save_config({ base_url, email, api_token })
      "Configuration saved to ~/.config/jira_cli_mbt/config.json"
    }
    @types.ListIssues(jql~, fields~) => {
      let config = @config.load_config()
      @formatter.format_issue_list_for_output(
        @api.list_issues(config, jql, fields),
        fields,
        output_format,
      )
    }
    @types.GetIssue(key~, fields~) => {
      let config = @config.load_config()
      @formatter.format_issue_detail_for_output(
        @api.get_issue(config, key, fields),
        fields,
        output_format,
      )
    }
    @types.CreateIssue(
      project~,
      summary~,
      issue_type~,
      description~,
      custom_fields~
    ) => {
      let config = @config.load_config()
      let key = @api.create_issue(
        config, project, summary, issue_type, description, custom_fields,
      )
      "Issue created: \{key}"
    }
    @types.UpdateIssue(
      key~,
      summary~,
      description~,
      priority~,
      issue_type~,
      labels~,
      assignee~,
      custom_fields~
    ) => {
      let config = @config.load_config()
      @api.update_issue(
        config,
        key~,
        summary~,
        description~,
        priority~,
        issue_type~,
        labels~,
        assignee~,
        custom_fields~,
      )
      "Issue \{key} updated"
    }
    @types.Transition(key~, status~) => {
      let config = @config.load_config()
      @api.transition_issue(config, key, status)
      "Issue \{key} transitioned to '\{status}'"
    }
    @types.Comment(key~, text~) => {
      let config = @config.load_config()
      @api.add_comment(config, key, text)
      "Comment added to \{key}"
    }
    @types.Assign(key~, email~) => {
      let config = @config.load_config()
      @api.assign_issue(config, key, email)
      "Issue \{key} assigned to \{email}"
    }
    @types.Search(jql~) => {
      let config = @config.load_config()
      let fields = @types.default_list_issue_fields()
      @formatter.format_issue_list_for_output(
        @api.list_issues(config, jql, fields),
        fields,
        output_format,
        kind="search_results",
      )
    }
    @types.ListProjects => {
      let config = @config.load_config()
      @formatter.format_projects_for_output(
        @api.list_projects(config),
        output_format,
      )
    }
    @types.ListFields => {
      let config = @config.load_config()
      @formatter.format_fields_for_output(
        @api.list_fields(config),
        output_format,
      )
    }
    @types.GetField(field_id~, project~, issue_type~) => {
      let config = @config.load_config()
      if project.length() > 0 && issue_type.length() == 0 {
        @formatter.format_issue_types_for_output(
          project,
          @api.list_issue_types(config, project),
          output_format,
        )
      } else {
        @formatter.format_field_detail_for_output(
          @api.get_field_detail(config, field_id, project, issue_type),
          output_format,
        )
      }
    }
  }
}

///|
pub async fn execute(cmd : Result[@types.Command, String]) -> String {
  match cmd {
    Err(msg) => @formatter.format_usage() + "\n\nError: " + msg
    Ok(command) => execute_command(command, @types.Table)
  }
}

///|
pub async fn execute_request(
  request : Result[@types.Invocation, String],
) -> String {
  match request {
    Err(msg) => @formatter.format_usage() + "\n\nError: " + msg
    Ok(invocation) =>
      execute_command(invocation.command, invocation.output_format)
  }
}
