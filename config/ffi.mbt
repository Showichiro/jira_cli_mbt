///|
extern "js" fn ffi_read_file(path : String) -> @core.Promise[String] =
  #|async (p) => { const fs = await import("node:fs/promises"); return await fs.readFile(p, "utf-8"); }

///|
async fn read_file(path : String) -> String {
  ffi_read_file(path).wait()
}

///|
extern "js" fn ffi_mkdir_recursive(path : String) -> @core.Promise[Unit] =
  #|async (p) => { const fs = await import("node:fs/promises"); await fs.mkdir(p, { recursive: true }); }

///|
async fn mkdir_recursive(path : String) -> Unit {
  ffi_mkdir_recursive(path).wait()
}

///|
extern "js" fn ffi_write_file(
  path : String,
  content : String,
) -> @core.Promise[Unit] =
  #|async (p, c) => { const fs = await import("node:fs/promises"); await fs.writeFile(p, c, "utf-8"); }

///|
async fn write_file(path : String, content : String) -> Unit {
  ffi_write_file(path, content).wait()
}
