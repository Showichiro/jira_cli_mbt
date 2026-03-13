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

///|
extern "js" fn ffi_file_exists(path : String) -> @core.Promise[Bool] =
  #|async (p) => { const fs = await import("node:fs/promises"); try { await fs.access(p); return true; } catch { return false; } }

///|
async fn file_exists(path : String) -> Bool {
  ffi_file_exists(path).wait()
}

///|
extern "js" fn ffi_get_env(name : String) -> String =
  #|(name) => { const value = process.env[name]; return value == null ? "" : String(value); }

///|
fn get_env(name : String) -> String {
  ffi_get_env(name)
}

///|
extern "js" fn ffi_read_stdin() -> @core.Promise[String] =
  #|async () => {
  #|  const chunks = [];
  #|  for await (const chunk of process.stdin) {
  #|    chunks.push(typeof chunk === "string" ? Buffer.from(chunk) : chunk);
  #|  }
  #|  return Buffer.concat(chunks).toString("utf-8");
  #|}

///|
async fn read_stdin() -> String {
  ffi_read_stdin().wait()
}
