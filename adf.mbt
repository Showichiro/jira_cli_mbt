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
