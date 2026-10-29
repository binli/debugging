---
name: jira-bot
description: Create and query Jira tickets, comments, attachments, and Launchpad bug links via Jira API.
version: 1.1.0
author: Li Bin (binli)
license: MIT
platforms: [linux]
---

# Jira-Bot Skill

Create and inspect Canonical Jira issues using `~/.cache/oem-scripts/jira.py` against `warthogs.atlassian.net`.
Get ticket summaries, descriptions, comments, download attachments, add comments, and link Launchpad bug.

## When to Use

- Create a Jira issue in an OEM project, optionally linking its Launchpad bug.
- Inspect tickets, comments, attachments, status, components, and Bug Link.
- Comment on tickets, download attachments, or update a Launchpad Bug Link.
- Query issue lists on OEM projects (`sutton`, `stella`, `somerville`, `delta`).
- Don't use for: GitHub issues or PRs (use `github` skill instead).

## Prerequisites

Required environment variables:
- `JIRA_USER`: Jira user email address (e.g. your Canonical email).
- `JIRA_TOKEN`: Jira API token generated from Atlassian Account Settings.

Dependencies:
- Python 3 with `requests` library installed.

Before a write operation, check the cached helper's `--help` output; do not assume it has the latest flags.

## Helper Selection

- Use `python3 ~/.cache/oem-scripts/jira.py` for supported operations, including period searches.
- Prefer the helper's compact search output over ad hoc REST requests.
- If an operation is not supported, reading the entire helper source and try to add a new function to the helper rather than using a different tool.

## Searching Issues by Period

Use the read-only `--search` mode to list issues created or updated during a lookback period:

```bash
# SUTTON issues created OR updated in the preceding seven days
python3 ~/.cache/oem-scripts/jira.py --search --project SUTTON --period 7d

# The same search, restricted to Bin Li, with compact JSON output
python3 ~/.cache/oem-scripts/jira.py --search --project SUTTON --period 7d --assignee "Bin Li" --json

# Only issues created in the preceding two weeks
python3 ~/.cache/oem-scripts/jira.py --search --project SUTTON --period 2w --date-field created
```

- `--project` defaults to `sutton`.
- `--period` defaults to `7d`. Use a positive integer followed by `m` (minutes), `h` (hours), `d` (days), or `w` (weeks), such as `30m`, `12h`, or `2w`. For a negative-form argument, use `--period=-7d`.
- `--date-field` accepts `created`, `updated`, or `either` (default). `either` means `created >= -<period> OR updated >= -<period>`, not AND.
- `--assignee` optionally filters by exact display name (case-insensitive), account ID, or a known alias such as `binli`. Use `Unassigned` for tickets without an assignee. Filtering is performed locally on the search results.
- Results include all pages, ordered by most recently updated first, with only `id`, `title`, and `assignee`. `id` is the ticket key (for example, `SUTTON-6350`), not Jira's internal numeric ID.
- Default output is tab-separated with an `ID`, `Title`, and `Assignee` header. `--json` returns a compact JSON array; no matches returns `[]`.
- Python callers can use `Jira.search_period(project, period="7d", date_field="either", assignee=None)` to receive the same compact records.
- Do not combine `--search` with ticket inspection, creation, comments, Bug Link updates, or attachment operations.

For issue lists, use this compact mode rather than fetching full ticket details. Fetch individual tickets only when additional fields are requested. Derive counts from the returned records instead of estimating them.

## Creating an Issue
Check the project and component with `Jira.get_components(project)` and search for an existing ticket before filing a new one.
The helper's `--create` option takes `--project`, `--summary`, `--description`, `--type` (default `Bug`), one or more `--component` values, and an optional `--bug-link` (Launchpad URL or bug number).
It creates the issue, links the bug when provided, adds `jira-<lowercase-issue-key>` to that Launchpad bug, and prints the issue key and URL.

For Python callers, `Jira.create_issue_with_bug_link(project, summary, description, issuetype, component, bug_link="")` returns the Jira issue key.
It uses `issue_creation()` and, when a link is given, `issue_update_bug_link()` internally. If linking or tagging fails, the error includes the created issue key: retry the link on that issue rather than filing a duplicate.
Verify the component and, when specified, the Bug Link and Launchpad tag on the resulting ticket.

## Existing Tickets
- `--ticket` accepts an issue key or Jira URL; `--json` returns structured ticket details.
- `--ticket` with `--bug-link` updates the Bug Link and adds the Jira tag to Launchpad; a bare bug number is converted to its Launchpad URL.
- `--ticket` with `--comment` adds a comment.
- `--ticket` with `--download-attachments` downloads attachments; `--output-dir` selects the destination.

The Bug Link is Jira field `customfield_10596`. The helper reads and writes Atlassian Document Format for ticket content.
Tagging requires Launchpad OAuth credentials and `oauthlib`; the Launchpad helper preserves existing tags. If tagging fails after the Jira update, retry `--ticket` with the same `--bug-link` rather than recreating the ticket.
