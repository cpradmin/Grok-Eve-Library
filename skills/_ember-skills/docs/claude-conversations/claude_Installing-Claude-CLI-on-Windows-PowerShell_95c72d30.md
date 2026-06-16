# Installing Claude CLI on Windows PowerShell
*Created: 5/7/2026, 11:00:34 AM*
*Exported: 5/15/2026, 1:58:31 PM*

---

## 1. User

I need to install claide code cli on powershell on windows 11

---

## 2. AI

Here's how to install Claude Code on Windows 11 using PowerShell.

## 1. (Recommended) Install Git for Windows first

Claude Code can use Git Bash as its shell tool — without it, it falls back to PowerShell with reduced capability. Download from https://git-scm.com/downloads/win and install with defaults.

## 2. Run the installer in PowerShell

Open PowerShell (regular, **not** Administrator — it's not needed) and run:

```powershell
irm https://claude.ai/install.ps1 | iex
```

This downloads the native binary to `C:\Users\<You>\.local\bin\claude.exe` and sets up background auto-updates.

> Quick sanity check: if you see `'irm' is not recognized`, you're in CMD, not PowerShell. The PowerShell prompt starts with `PS C:\...`.

## 3. Restart your terminal, then verify

Close PowerShell completely and reopen it, then:

```powershell
claude --version
claude doctor
```

`claude doctor` runs full diagnostics on your install.

## 4. If you get "claude is not recognized"

This is the most common issue on Windows — the binary installs but `~/.local/bin` isn't on your PATH. Fix it in PowerShell:

```powershell
[Environment]::SetEnvironmentVariable("PATH", "$env:PATH;$env:USERPROFILE\.local\bin", [EnvironmentVariableTarget]::User)
$env:PATH = "$env:PATH;$env:USERPROFILE\.local\bin"
```

The first line makes it permanent; the second applies it to your current session. Then run `claude --version` again.

## 5. Log in

```powershell
claude
```

This opens a browser to authenticate. Note: Claude Code requires a **Pro, Max, Team, Enterprise, or Console** plan — the free Claude.ai tier doesn't include access.

---

**Alternative — winget**, if you prefer a package manager:

```powershell
winget install Anthropic.ClaudeCode
```

Trade-off: winget installs don't auto-update; you run `winget upgrade Anthropic.ClaudeCode` manually.

Official docs: https://code.claude.com/docs/en/setup

---

## 3. User

Windows PowerShell
Copyright (C) Microsoft Corporation. All rights reserved.
Try the new cross-platform PowerShell https://aka.ms/pscore6
PS C:\Users\Jordan Braxton> irm https://claude.ai/install.ps1 | iex
Setting up Claude Code...
√ Claude Code successfully installed!
  Version: 2.1.132
  Location: C:\Users\Jordan Braxton\.local\bin\claude.exe
  Next: Run claude --help to get started
‼ Setup notes:
  ● Native installation exists but C:\Users\Jordan Braxton\.local\bin is not in your PATH. Add it by opening: System
    Properties → Environment Variables → Edit User PATH → New → Add the path above. Then restart your terminal.
✅ Installation complete!
PS C:\Users\Jordan Braxton> cluade'
>> ^C
PS C:\Users\Jordan Braxton> claude
claude : The term 'claude' is not recognized as the name of a cmdlet, function, script file, or operable program.
Check the spelling of the name, or if a path was included, verify that the path is correct and try again.
At line:1 char:1
+ claude
+ ~~~~~~
    + CategoryInfo          : ObjectNotFound: (claude:String) [], ParentContainsErrorRecordException
    + FullyQualifiedErrorId : CommandNotFoundException
PS C:\Users\Jordan Braxton> claude
claude : The term 'claude' is not recognized as the name of a cmdlet, function, script file, or operable program.
Check the spelling of the name, or if a path was included, verify that the path is correct and try again.
At line:1 char:1
+ claude
+ ~~~~~~
    + CategoryInfo          : ObjectNotFound: (claude:String) [], ParentContainsErrorRecordException
    + FullyQualifiedErrorId : CommandNotFoundException
PS C:\Users\Jordan Braxton>

---

## 4. AI

This is exactly the PATH issue I mentioned — installer worked perfectly, but Windows doesn't know where `claude.exe` lives yet. Run these two lines in your current PowerShell window:

```powershell
[Environment]::SetEnvironmentVariable("PATH", "$env:PATH;$env:USERPROFILE\.local\bin", [EnvironmentVariableTarget]::User)
$env:PATH = "$env:PATH;$env:USERPROFILE\.local\bin"
```

What each line does:
- **Line 1** — permanently adds `C:\Users\Jordan Braxton\.local\bin` to your User PATH so every future terminal sees it.
- **Line 2** — adds it to your *current* session so you don't have to close and reopen PowerShell to test.

Then verify:

```powershell
claude --version
```

You should see `2.1.132`. If that works, run `claude` to log in (it'll open a browser).

> Sidenote: the space in "Jordan Braxton" is fine — `$env:USERPROFILE` handles it correctly because the variable is expanded as a single token. No quoting needed.

If `claude --version` still fails after running both lines, paste the output of:

```powershell
$env:PATH -split ';' | Select-String '.local'
Test-Path "$env:USERPROFILE\.local\bin\claude.exe"
```

That'll tell us whether the PATH update took and whether the binary is actually where the installer says it is.
