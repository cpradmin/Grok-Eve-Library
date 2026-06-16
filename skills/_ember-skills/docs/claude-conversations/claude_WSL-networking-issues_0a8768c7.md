# WSL networking issues
*Created: 5/5/2026, 5:23:18 PM*
*Exported: 5/15/2026, 1:58:36 PM*

---

## 1. User

help me fix wsl networking issues plase and ty

---

## 2. AI

Happy to help. WSL networking covers a lot of ground, so let me narrow it down quickly.Pick whichever fits and I'll walk you through the fix. If "something else," just describe what you're seeing — exact error message, what command produced it, and what you were trying to do.

---

## 3. User

Q: What's actually broken?
A: just look at it

Q: Which WSL version?
A: WSL 2 (default)

Q: Are you on a VPN or corporate network?
A: just look at it

---

## 4. AI

Ha, I wish I could — but I can't see your machine. No screen share, no remote access, no peeking at your system. I'm working off whatever you paste in.

Easiest path forward: run a few commands in WSL and paste the output. That'll usually tell me exactly what's wrong.

In your WSL terminal:

```bash
cat /etc/resolv.conf
ip addr show eth0
ping -c 3 8.8.8.8
ping -c 3 google.com
curl -I https://www.google.com
```

And in PowerShell (Windows side):

```powershell
wsl --version
wsl --status
Get-NetAdapter | Where-Object { $_.Name -like "*WSL*" -or $_.Name -like "*vEthernet*" }
```

Also helpful to know:
- What's the actual symptom? (commands hang? DNS errors? "network unreachable"? slow? specific app failing?)
- Did this just start, or is it a fresh WSL install?
- Anything change recently — Windows update, new VPN, antivirus, Docker Desktop install?

Paste what you get and we'll sort it out.

---

## 5. User

give me the ps installer for claude code cli

---

## 6. AI

Here's the official one-liner. Open PowerShell and run:

```powershell
irm https://claude.ai/install.ps1 | iex
```

A couple of things worth knowing up front:

Git for Windows is required — Claude Code uses Git Bash internally even when launched from PowerShell or CMD. If you don't have it, grab it from git-scm.com first (default install options are fine).

After install, restart your terminal and run `claude --version` to verify. If you get "claude is not recognized," the binary went to `~\.local\bin` but that folder isn't in your PATH. Fix:

1. Win+R → `sysdm.cpl` → Advanced → Environment Variables
2. Edit your user `PATH` → New → add `%USERPROFILE%\.local\bin`
3. Restart the terminal

Then `claude` should work. Run `claude doctor` if anything's still off — it diagnoses install/PATH/auth issues.

You'll need a Pro, Max, Team, Enterprise, or Console (API) account to actually log in — there's no free tier for Claude Code.

---

## 7. User

Windows PowerShell
Copyright (C) Microsoft Corporation. All rights reserved.
Install the latest PowerShell for new features and improvements! https://aka.ms/PSWindows
PS C:\windows\system32> irm https://claude.ai/install.ps1 | iex
Setting up Claude Code...
√ Claude Code successfully installed!
                                                                                                                          Version: 2.1.128
  Location: C:\Users\kntrnjb\.local\bin\claude.exe
  Next: Run claude --help to get started
‼ Setup notes:
  ● Native installation exists but C:\Users\kntrnjb\.local\bin is not in your PATH. Add it by opening: System Properties
     → Environment Variables → Edit User PATH → New → Add the path above. Then restart your terminal.
✅ Installation complete!
PS C:\windows\system32>

---

## 8. AI

Install worked — you just hit the PATH gotcha I mentioned. Let's fix it.

**Quickest fix (one PowerShell command):**

```powershell
[Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path", "User") + ";$env:USERPROFILE\.local\bin", "User")
```

Then **close PowerShell completely and open a new window** (the change won't show up in the current session). Verify with:

```powershell
claude --version
```

You should see `2.1.128`.

**If you'd rather do it through the GUI** (same end result):

1. Win+R → type `sysdm.cpl` → Enter
2. Advanced tab → Environment Variables
3. Under **User variables**, select `Path` → Edit
4. New → paste: `C:\Users\kntrnjb\.local\bin`
5. OK out of all three windows
6. Open a fresh PowerShell

Once `claude --version` works, just run `claude` in any project folder to start. First launch will walk you through login.

---

## 9. User

PS C:\windows\system32> [Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path", "User") + ";$env:USERPROFILE\.local\bin", "User")
PS C:\windows\system32> claude --version
claude : The term 'claude' is not recognized as the name of a cmdlet, function, script file, or operable program.
Check the spelling of the name, or if a path was included, verify that the path is correct and try again.
At line:1 char:1
+ claude --version
+ ~~~~~~
    + CategoryInfo          : ObjectNotFound: (claude:String) [], ParentContainsErrorRecordException
    + FullyQualifiedErrorId : CommandNotFoundException
PS C:\windows\system32> claude
claude : The term 'claude' is not recognized as the name of a cmdlet, function, script file, or operable program.
Check the spelling of the name, or if a path was included, verify that the path is correct and try again.
At line:1 char:1
+ claude
+ ~~~~~~
    + CategoryInfo          : ObjectNotFound: (claude:String) [], ParentContainsErrorRecordException
    + FullyQualifiedErrorId : CommandNotFoundException
PS C:\windows\system32>

---

## 10. AI

The PATH update only takes effect in **new** PowerShell windows — your current session still has the old PATH. Two options:

**Option 1: Close this window and open a brand new PowerShell**, then try `claude --version` again. This is the cleanest fix.

**Option 2: Refresh PATH in the current session** without restarting:

```powershell
$env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")
claude --version
```

If neither works, let's verify the binary actually exists. Run:

```powershell
Test-Path "$env:USERPROFILE\.local\bin\claude.exe"
```

That should return `True`. If it does, you can run claude directly with the full path as a sanity check:

```powershell
& "$env:USERPROFILE\.local\bin\claude.exe" --version
```

Let me know which of those works and we'll go from there.
