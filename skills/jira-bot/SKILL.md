---
name: jira-bot
description: Create and query Jira tickets, comments, attachments, and Launchpad bug links via Jira API.
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
