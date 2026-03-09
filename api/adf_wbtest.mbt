///|
test "build_adf_text" {
  let adf = build_adf_text("hello")
  let json_str = @core.json_stringify_pretty(adf, 2)
  inspect(
    json_str,
    content=(
      #|{
      #|  "type": "doc",
      #|  "version": 1,
      #|  "content": [
      #|    {
      #|      "type": "paragraph",
      #|      "content": [
      #|        {
      #|          "type": "text",
      #|          "text": "hello"
      #|        }
      #|      ]
      #|    }
      #|  ]
      #|}
    ),
  )
}

///|
test "extract_adf_text with paragraphs and hard break" {
  let adf = @core.from_entries([
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
                ("text", @core.any("hello")),
              ]),
              @core.from_entries([("type", @core.any("hardBreak"))]),
              @core.from_entries([
                ("type", @core.any("text")),
                ("text", @core.any("world")),
              ]),
            ]),
          ),
        ]),
        @core.from_entries([
          ("type", @core.any("paragraph")),
          (
            "content",
            @core.any([
              @core.from_entries([
                ("type", @core.any("text")),
                ("text", @core.any("next")),
              ]),
            ]),
          ),
        ]),
      ]),
    ),
  ])
  inspect(extract_adf_text(adf), content="hello\nworld\n\nnext")
}
