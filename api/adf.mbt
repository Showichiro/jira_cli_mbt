///|
fn build_adf_text(text : String) -> @core.Any {
  @core.from_entries([
    ("type", @core.any("doc")),
    ("version", @core.any(1)),
    (
      "content",
      @core.any([
        @core.from_entries([
          ("type", @core.any("paragraph")),
          (
            "content",
            @core.any([
              @core.from_entries([
                ("type", @core.any("text")),
                ("text", @core.any(text)),
              ]),
            ]),
          ),
        ]),
      ]),
    ),
  ])
}

///|
fn adf_string_field(node : @core.Any, key : String) -> String {
  if @core.is_nullish(node) {
    return ""
  }
  let value = node._get(key)
  if @core.is_nullish(value) {
    ""
  } else {
    value.to_string()
  }
}

///|
fn join_adf_children(node : @core.Any) -> String {
  let content = node._get("content")
  if @core.is_nullish(content) {
    return ""
  }
  let children = @core.array_from(content)
  let buf = StringBuilder::new()
  for child in children {
    buf.write_string(extract_adf_text(child))
  }
  buf.to_string()
}

///|
fn join_adf_blocks(node : @core.Any) -> String {
  let content = node._get("content")
  if @core.is_nullish(content) {
    return ""
  }
  let blocks = @core.array_from(content)
  let parts : Array[String] = []
  for block in blocks {
    let text = extract_adf_text(block)
    if text.length() > 0 {
      parts.push(text)
    }
  }
  parts.join("\n\n")
}

///|
fn extract_adf_text(node : @core.Any) -> String {
  match adf_string_field(node, "type") {
    "doc" => join_adf_blocks(node)
    "paragraph" => join_adf_children(node)
    "text" => adf_string_field(node, "text")
    "hardBreak" => "\n"
    "" => {
      let raw = node.to_string()
      if raw == "[object Object]" || raw == "undefined" || raw == "null" {
        ""
      } else {
        raw
      }
    }
    _ => join_adf_children(node)
  }
}
