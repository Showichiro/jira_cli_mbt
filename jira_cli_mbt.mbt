///|
pub fn parse_args(args : ArrayView[String]) -> Result[@types.Command, String] {
  @parser.parse_args(args)
}

///|
fn issue_type_selection_message(
  project : String,
  types : Array[(String, String)],
) -> String {
  if types.is_empty() {
    "No issue types found for project '\{project}'. Verify the project key is correct."
  } else {
    let type_list = types.map(fn(t) { "  - " + t.1 }).join("\n")
    "Please specify --type. Available issue types for \{project}:\n" + type_list
  }
}

///|
pub async fn execute(cmd : Result[@types.Command, String]) -> String {
  match cmd {
    Err(msg) => @formatter.format_usage() + "\n\nError: " + msg
    Ok(@types.Help) => @formatter.format_usage()
    Ok(@types.Config(base_url~, email~, api_token~)) => {
      @config.save_config({ base_url, email, api_token })
      "Configuration saved to ~/.config/jira_cli_mbt/config.json"
    }
    Ok(@types.ListIssues(jql~, fields~)) => {
      let config = @config.load_config()
      @formatter.format_issue_list(
        @api.list_issues(config, jql, fields),
        fields,
      )
    }
    Ok(@types.GetIssue(key~, fields~)) => {
      let config = @config.load_config()
      @formatter.format_issue_detail(
        @api.get_issue(config, key, fields),
        fields,
      )
    }
    Ok(
      @types.CreateIssue(
        project~,
        summary~,
        issue_type~,
        description~,
        custom_fields~
      )
    ) => {
      let config = @config.load_config()
      let key = @api.create_issue(
        config, project, summary, issue_type, description, custom_fields,
      )
      "Issue created: \{key}"
    }
    Ok(
      @types.UpdateIssue(
        key~,
        summary~,
        description~,
        priority~,
        issue_type~,
        labels~,
        assignee~,
        custom_fields~
      )
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
    Ok(@types.Transition(key~, status~)) => {
      let config = @config.load_config()
      @api.transition_issue(config, key, status)
      "Issue \{key} transitioned to '\{status}'"
    }
    Ok(@types.Comment(key~, text~)) => {
      let config = @config.load_config()
      @api.add_comment(config, key, text)
      "Comment added to \{key}"
    }
    Ok(@types.Assign(key~, email~)) => {
      let config = @config.load_config()
      @api.assign_issue(config, key, email)
      "Issue \{key} assigned to \{email}"
    }
    Ok(@types.Search(jql~)) => {
      let config = @config.load_config()
      let fields = @types.default_list_issue_fields()
      @formatter.format_issue_list(
        @api.list_issues(config, jql, fields),
        fields,
      )
    }
    Ok(@types.ListProjects) => {
      let config = @config.load_config()
      @formatter.format_projects(@api.list_projects(config))
    }
    Ok(@types.ListFields) => {
      let config = @config.load_config()
      @formatter.format_fields(@api.list_fields(config))
    }
    Ok(@types.GetField(field_id~, project~, issue_type~)) => {
      let config = @config.load_config()
      if project.length() > 0 && issue_type.length() == 0 {
        let types = @api.list_issue_types(config, project)
        issue_type_selection_message(project, types)
      } else {
        @formatter.format_field_detail(
          @api.get_field_detail(config, field_id, project, issue_type),
        )
      }
    }
  }
}
