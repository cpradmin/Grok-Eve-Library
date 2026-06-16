---
name: google-workspace-gws
description: >
  Google Workspace automation via the gws CLI tool (50+ Google API operations). Use when the user mentions Gmail, Google Drive, Google Sheets, Google Calendar, Google Docs, Google Slides, Google Meet, Google Forms, Google Groups, Google Admin, workspace admin tasks, Google API automation, or any G Suite / Google Workspace operation. Covers reading/writing emails, managing Drive files and folders, reading and updating Sheets, creating calendar events, sharing documents, managing workspace users and groups, and composing multi-step workspace workflows. Also use for tasks like "send an email via CLI", "update a Google Sheet from code", "list Drive files", "create a calendar invite", or "manage workspace users".
user-invocable: true
license: MIT
---

# Google Workspace (GWS) CLI Skill

You are a Google Workspace automation expert using the `gws` CLI tool and Google APIs.

## Setup

The `gws` CLI requires authentication:
```bash
gws auth login          # authenticate with Google account
gws auth status         # check current auth state
gws config set account  # switch between accounts
```

## Core Operations

### Gmail
```bash
gws gmail list [--limit N] [--query QUERY]   # list emails (supports Gmail search syntax)
gws gmail read <message-id>                   # read email content
gws gmail send --to EMAIL --subject SUBJECT --body BODY
gws gmail send --to EMAIL --subject SUBJECT --attachment FILE
gws gmail label add <message-id> <label>
gws gmail archive <message-id>
gws gmail delete <message-id>
```

### Google Drive
```bash
gws drive list [--folder-id ID] [--query QUERY]
gws drive upload <local-file> [--parent-id FOLDER_ID]
gws drive download <file-id> [--output PATH]
gws drive create-folder <name> [--parent-id FOLDER_ID]
gws drive share <file-id> --email EMAIL --role reader|writer|owner
gws drive move <file-id> --to <folder-id>
gws drive delete <file-id>
gws drive info <file-id>
```

### Google Sheets
```bash
gws sheets read <spreadsheet-id> [--range RANGE]    # e.g. --range "Sheet1!A1:D10"
gws sheets write <spreadsheet-id> --range RANGE --values '[[row1],[row2]]'
gws sheets append <spreadsheet-id> --range RANGE --values '[[new-row]]'
gws sheets create --title NAME
gws sheets add-sheet <spreadsheet-id> --title SHEET_NAME
```

### Google Calendar
```bash
gws calendar list [--days N]
gws calendar create --title TITLE --start DATETIME --end DATETIME [--attendees EMAIL,EMAIL]
gws calendar get <event-id>
gws calendar delete <event-id>
```

### Google Docs
```bash
gws docs create --title TITLE [--content TEXT]
gws docs read <doc-id>
gws docs append <doc-id> --content TEXT
```

### Workspace Admin (requires admin account)
```bash
gws admin users list [--domain DOMAIN]
gws admin users create --email EMAIL --firstname NAME --lastname NAME
gws admin users suspend <email>
gws admin groups list
gws admin groups add-member <group-email> --member <user-email>
```

## Workflow Patterns

**Email + Sheet reporting:**
1. `gws gmail list --query "from:alerts@system.com"` — find alert emails
2. Parse results, extract data
3. `gws sheets append <id> --range "A:D" --values ...` — log to sheet

**Drive folder automation:**
1. `gws drive create-folder "Reports/2026-06"` — create dated folder
2. `gws drive upload report.pdf --parent-id <folder-id>` — upload
3. `gws drive share <file-id> --email team@company.com --role reader` — share

**Calendar + notification:**
1. `gws calendar create --title "Sprint Review" --start 2026-06-15T14:00:00 --attendees team@co.com`
2. `gws gmail send --to team@co.com --subject "Invite sent" --body "Calendar invite created"`

## Notes
- All IDs can be found with `list` commands or from Google URLs
- DateTime format: ISO 8601 (YYYY-MM-DDTHH:MM:SS or YYYY-MM-DDTHH:MM:SSZ for UTC)
- Use `--json` flag for machine-readable output on any command
- Supports service account auth for automated/CI workflows: `gws auth service-account --key key.json`
