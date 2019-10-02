warning("LockLevel", off)

switch("threads", "on")
when defined(windows):
  switch("tlsEmulation", "off")
  switch("passL", "-static")
elif defined(linux):
  from os import splitPath
  switch("passC", "-include " & currentSourcePath().splitPath().head &
                  "/ext/force_link_glibc_2.23.h")
