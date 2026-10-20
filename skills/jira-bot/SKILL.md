---
name: jira-bot
description: Query Jira tickets, comments, and attachments via Jira API.
version: 1.0.0
author: Li Bin (binli), Copilot, Hermes Agent
license: MIT
platforms: [linux, macos]
metadata:
  hermes:
    tags: [jira, canonical, tickets, attachments, warthogs, comments, launchpad]
    related_skills: [document-to-action-items]
---

# Jira-Bot Skill

Query Atlassian / Canonical Jira issues (e.g. `warthogs.atlassian.net`), parse ticket summaries, descriptions, comments, download attachments, add comments, and link Launchpad bugs using `jira.py` cached at `~/.cache/oem-scripts/jira.py`.

## When to Use

- Retrieve details, status, description, comments, or bug link of a Jira issue (e.g. `SUTTON-5608` or full URL `https://warthogs.atlassian.net/browse/...`).
- Download attachments from a Jira ticket to a local directory.
- Post a new comment to an existing Jira ticket.
- Link a Launchpad bug to a Jira ticket (`--bug-link`).
- Query issue lists in Canonical OEM projects (`sutton`, `stella`, `somerville`, `delta`).
- Don't use for: GitHub issues or PRs (use `github` skill instead).

## Prerequisites

Required environment variables:
- `JIRA_USER`: Jira user email address (e.g. your Canonical email).
- `JIRA_TOKEN`: Jira API token generated from Atlassian Account Settings.

Dependencies:
- Python 3 with `requests` library installed.

## How to Run

Runs Python directly in one step:

```bash
JIRA_PY="$HOME/.cache/oem-scripts/jira.py"
[ -f "$JIRA_PY" ] && python3 "$JIRA_PY" "$@"
```

## Quick Reference

View ticket details, bug link, and comments:
```bash
python3 "$HOME/.cache/oem-scripts/jira.py" -t SUTTON-5608
```

Link a Launchpad bug to a Jira ticket:
```bash
python3 "$HOME/.cache/oem-scripts/jira.py" -t SUTTON-5608 --bug-link https://bugs.launchpad.net/bugs/2158956
# or simply with the bug number:
python3 "$HOME/.cache/oem-scripts/jira.py" -t SUTTON-5608 --bug-link 2158956
```

Add a comment to a ticket:
```bash
python3 "$HOME/.cache/oem-scripts/jira.py" -t SUTTON-5608 -c "Investigating the issue. Will update once verified."
```

Inspect ticket in JSON format:
```bash
python3 "$HOME/.cache/oem-scripts/jira.py" -t SUTTON-5608 --json
```

Download all attachments to a specific directory:
```bash
python3 "$HOME/.cache/oem-scripts/jira.py" -t SUTTON-5608 -d -o /path/to/attachments_dir
```

Pass full URL directly:
```bash
python3 "$HOME/.cache/oem-scripts/jira.py" -t https://warthogs.atlassian.net/browse/SUTTON-5608
```

## Procedure

1. **Verify Credentials**:
   Ensure `JIRA_USER` and `JIRA_TOKEN` are set in the environment.

2. **Ensure `jira.py` Exists in Cache**:
   ```bash
   JIRA_PY="$HOME/.cache/oem-scripts/jira.py"
   [ -f "$JIRA_PY" ] || echo "Error: $JIRA_PY not found. Please download or clone the jira.py script."
   ```

3. **Retrieve Ticket Information**:
   ```bash
   python3 "$HOME/.cache/oem-scripts/jira.py" -t <ISSUE_KEY_OR_URL>
   ```

4. **Link Launchpad Bug**:
   ```bash
   python3 "$HOME/.cache/oem-scripts/jira.py" -t <ISSUE_KEY> --bug-link <LP_URL_OR_BUG_ID>
   ```

5. **Add a Comment**:
   ```bash
   python3 "$HOME/.cache/oem-scripts/jira.py" -t <ISSUE_KEY_OR_URL> -c "<COMMENT_TEXT>"
   ```

6. **Fetch Attachments (if requested)**:
   Add `-d` and `-o <DIR>`:
   ```bash
   python3 "$HOME/.cache/oem-scripts/jira.py" -t <ISSUE_KEY> -d -o <TARGET_DIR>
   ```

## Pitfalls

- **Bug Link Field**: Canonical Jira stores the Launchpad bug URL in `customfield_10596`. Passing `--bug-link 2158956` automatically formats the URL to `https://bugs.launchpad.net/bugs/2158956`.
- **Multi-line Comments**: `add_comment` automatically handles newline characters (`\n`) by building ADF paragraph blocks.
- **Atlassian Document Format (ADF)**: Jira API v3 returns rich JSON documents rather than plain markdown. `jira.py` parses headings, paragraphs, lists, and tables into plain readable text.
- **Upstream Push Needed**: Because `jira.py` downloads from GitHub `main`, make sure your local changes to `jira.py` in `canonical/oem-design-phase` are pushed so other users get the comment, ticket inspection, and attachment download features.
