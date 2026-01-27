# Stop Hook Path Translation Fix

## Problem

Stop hook runs in a POSIX shell but receives a Windows-style `CLAUDE_PLUGIN_ROOT` path, leading to:

```
/bin/bash: C:\Users\...\hooks\stop-hook-router.sh: No such file or directory
```

## Root Cause

The hook command for `darwin/linux` invokes `bash` directly with a Windows path. When `bash` resolves to WSL or Git Bash, it expects POSIX paths. The command fails before the router script can run.

## Fix Summary

- Add path translation (`wslpath` or `cygpath`) before invoking `stop-hook-router.sh`.
- Update PowerShell router to convert Windows paths when dispatching POSIX hooks.
- Update real-scenario hook test to match the new invocation.

## Environment Considerations

### Windows Terminals
- PowerShell 5.1 and PowerShell 7+ (pwsh)
- Windows Terminal, cmd.exe, legacy PowerShell host

### Windows Platforms
- Windows 10 with WSL1 or WSL2
- Windows 11 with WSL2
- Docker Desktop (WSL2 integration enabled)

### Other Platforms
- macOS (bash/zsh)
- Linux (bash)
- Git Bash, Cygwin on Windows

## Test Matrix (Manual)

1. Windows PowerShell (pwsh)
   - `.\hooks\stop-hook-router.ps1`
   - Expect: uses PowerShell hook, no bash path error.
2. Windows + WSL bash
   - `bash -lc 'ROOT="$CLAUDE_PLUGIN_ROOT"; ...; exec bash "$ROOT/hooks/stop-hook-router.sh"'`
   - Expect: Windows path is converted via `wslpath`.
3. Git Bash
   - Same command as above, expect `cygpath` conversion.
4. WSL1/WSL2 inside Linux shell
   - `bash ./hooks/stop-hook-router.sh`
   - Expect: POSIX router uses `stop-hook-posix.sh`.
5. macOS/Linux native
   - `bash ./hooks/stop-hook-router.sh`
   - Expect: POSIX router uses `stop-hook.sh` (bash) or `stop-hook-posix.sh` fallback.

## Files Updated

- `hooks/hooks.json`
- `hooks/hooks-enhanced.json`
- `hooks/stop-hook-router.ps1`
- `tests/validate-hooks-fix.ps1`
- `tests/test-real-hook-call.sh`

