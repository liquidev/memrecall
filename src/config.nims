warning("LockLevel", off)

switch("threads", "on")
when defined(windows):
  switch("tlsEmulation", "off")
  switch("passL", "-static")
