///|
test "pad_right: shorter than width" {
  inspect(pad_right("ab", 5), content="ab   ")
}

///|
test "pad_right: equal to width" {
  inspect(pad_right("abcde", 5), content="abcde")
}

///|
test "pad_right: longer than width" {
  inspect(pad_right("abcdef", 5), content="abcdef")
}

///|
test "truncate: shorter than max" {
  inspect(truncate("hello", 10), content="hello")
}

///|
test "truncate: exactly max" {
  inspect(truncate("hello", 5), content="hello")
}

///|
test "truncate: longer than max" {
  inspect(truncate("hello world", 8), content="hello...")
}

///|
test "truncate: unicode safe" {
  inspect(truncate("こんにちは世界", 6), content="こんに...")
}

///|
test "format_issue_list: empty" {
  inspect(
    format_issue_list([], @types.default_list_issue_fields()),
    content="No issues found.",
  )
}

///|
test "format_issue_list: single issue" {
  let issues : Array[@types.JiraIssue] = [
    {
      key: "PROJ-1",
      summary: "Fix bug",
      status: "Open",
      assignee: "Alice",
      issue_type: "Bug",
      priority: "High",
      description: "",
      custom_fields: {},
    },
  ]
  inspect(
    format_issue_list(issues, @types.default_list_issue_fields()),
    content=(
      #|KEY           TYPE          STATUS           PRIORITY    SUMMARY                                 
      #|------------  ------------  ---------------  ----------  ----------------------------------------
      #|PROJ-1        Bug           Open             High        Fix bug                                 
    ),
  )
}

///|
test "format_issue_detail" {
  let issue : @types.JiraIssue = {
    key: "PROJ-1",
    summary: "Fix bug",
    status: "Open",
    assignee: "Alice",
    issue_type: "Bug",
    priority: "High",
    description: "Some description",
    custom_fields: {},
  }
  inspect(
    format_issue_detail(issue, @types.default_detail_issue_fields()),
    content=(
      #|Key:         PROJ-1
      #|Type:        Bug
      #|Status:      Open
      #|Priority:    High
      #|Assignee:    Alice
      #|Summary:     Fix bug
      #|Description: Some description
    ),
  )
}

///|
test "format_issue_list: custom fields" {
  let issues : Array[@types.JiraIssue] = [
    {
      key: "PROJ-1",
      summary: "Fix bug",
      status: "Open",
      assignee: "Alice",
      issue_type: "Bug",
      priority: "High",
      description: "",
      custom_fields: {},
    },
  ]
  inspect(
    format_issue_list(issues, [@types.Key, @types.Assignee, @types.Summary]),
    content=(
      #|KEY           ASSIGNEE              SUMMARY                                 
      #|------------  --------------------  ----------------------------------------
      #|PROJ-1        Alice                 Fix bug                                 
    ),
  )
}

///|
test "format_issue_detail: custom field" {
  let issue : @types.JiraIssue = {
    key: "PROJ-1",
    summary: "Fix bug",
    status: "Open",
    assignee: "Alice",
    issue_type: "Bug",
    priority: "High",
    description: "",
    custom_fields: { "customfield_10001": "Platform Team" },
  }
  inspect(
    format_issue_detail(issue, [@types.Key, @types.Custom("customfield_10001")]),
    content=(
      #|Key:         PROJ-1
      #|customfield_10001: Platform Team
    ),
  )
}

///|
test "format_fields: empty" {
  inspect(format_fields([]), content="No custom fields found.")
}

///|
test "format_fields: single field" {
  let fields : Array[@types.JiraField] = [
    {
      id: "customfield_10001",
      name: "Team",
      custom: true,
      schema_type: "option",
      schema_custom: "com.atlassian.jira.plugin.system.customfieldtypes:select",
    },
  ]
  inspect(
    format_fields(fields),
    content=(
      #|ID                         NAME                            TYPE             CUSTOM TYPE                             
      #|-------------------------  ------------------------------  ---------------  ----------------------------------------
      #|customfield_10001          Team                            option           com.atlassian.jira.plugin.system.cust...
    ),
  )
}

///|
test "format_field_detail: no options" {
  let detail : @types.JiraFieldDetail = {
    field: {
      id: "customfield_10001",
      name: "Team",
      custom: true,
      schema_type: "string",
      schema_custom: "",
    },
    options: [],
  }
  inspect(
    format_field_detail(detail),
    content=(
      #|ID:          customfield_10001
      #|Name:        Team
      #|Type:        string
      #|Custom Type: 
      #|
      #|No options available for this field.
    ),
  )
}

///|
test "format_field_detail: with options" {
  let detail : @types.JiraFieldDetail = {
    field: {
      id: "customfield_10001",
      name: "Team",
      custom: true,
      schema_type: "option",
      schema_custom: "com.atlassian.jira.plugin.system.customfieldtypes:select",
    },
    options: [{ id: "1", value: "Frontend" }, { id: "2", value: "Backend" }],
  }
  inspect(
    format_field_detail(detail),
    content=(
      #|ID:          customfield_10001
      #|Name:        Team
      #|Type:        option
      #|Custom Type: com.atlassian.jira.plugin.system.customfieldtypes:select
      #|
      #|Options:
      #|ID          VALUE                         
      #|----------  ------------------------------
      #|1           Frontend                      
      #|2           Backend                       
    ),
  )
}

///|
test "format_projects: empty" {
  inspect(format_projects([]), content="No projects found.")
}

///|
test "format_projects: single project" {
  let projects : Array[@types.JiraProject] = [
    { key: "PROJ", name: "My Project", project_type: "software" },
  ]
  inspect(
    format_projects(projects),
    content=(
      #|KEY           NAME                            TYPE           
      #|------------  ------------------------------  ---------------
      #|PROJ          My Project                      software       
    ),
  )
}
