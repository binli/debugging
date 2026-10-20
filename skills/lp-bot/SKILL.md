---
name: lp-bot
description: Query Launchpad bugs, tasks, comments, and attachments via high-speed REST API.
version: 1.2.0
author: Li Bin (binli), Copilot, Hermes Agent
license: MIT
platforms: [linux, macos]
metadata:
  hermes:
    tags: [launchpad, canonical, bugs, attachments, sru, template, rest, tags]
    related_skills: [document-to-action-items]
---

# Launchpad-Bot Skill

Query Launchpad bugs, inspect target task statuses, read comments, download attachments, post comments, add tags, and create new bugs (including Ubuntu SRU bugs) using `launchpad_rest.py` cached at `~/.cache/oem-scripts/launchpad_rest.py`.

The script uses Launchpad's direct REST API via `requests` and OAuth 1.0 signing via `oauthlib`, returning queries in ~2-4s (compared to ~50s+ with `launchpadlib`).

## When to Use

- Retrieve details, tasks, status, description, comments, or attachments for a Launchpad bug (e.g. `2158956` or URL `https://bugs.launchpad.net/bugs/2158956`).
- Download attachments from a Launchpad bug to a local directory.
- Add comments to a Launchpad bug.
- Add tags to an existing Launchpad bug (`--add-tags`).
- Create a new bug or author an Ubuntu SRU (Stable Release Update) bug following the official SRU template.

## Prerequisites

Need to have a valid Launchpad credentials file at ~/launchpad.credentials
Which contains the following information:

```
consumer_key =
consumer_secret =
access_token =
access_secret =
```

Dependencies:
- Python 3 with `requests` library installed.

## How to Run

Prefer the local repo copy when available, and fall back to downloading only if needed:

```bash
LP_PY="$HOME/.cache/oem-scripts/launchpad_rest.py"
[ -f "$LP_PY" ] && python3 "$LP_PY" "$@"
```

## Quick Reference

View bug details, tasks, comments, and attachments:
```bash
python3 "$HOME/.cache/oem-scripts/launchpad_rest.py" -b 2158956
```

Pass full URL directly:
```bash
python3 "$HOME/.cache/oem-scripts/launchpad_rest.py" -b https://bugs.launchpad.net/bugs/2158956
```

Inspect bug in JSON format:
```bash
python3 "$HOME/.cache/oem-scripts/launchpad_rest.py" -b 2158956 --json
```

Add tags to an existing bug:
```bash
python3 "$HOME/.cache/oem-scripts/launchpad_rest.py" -b 2158956 --add-tags "verification-done-noble,sutton-qa-passed"
```

Add a comment to a bug:
```bash
python3 "$HOME/.cache/oem-scripts/launchpad_rest.py" -b 2158956 -c "Patch verified on test machine."
```

Download all attachments to a specific directory:
```bash
python3 "$HOME/.cache/oem-scripts/launchpad_rest.py" -b 2158956 -d -o /path/to/attachments_dir
```

Create a new regular bug:
```bash
python3 "$HOME/.cache/oem-scripts/launchpad_rest.py" --create -p gnome-shell --title "Example Issue" -m "Detailed issue description" --tags "oem,sutton"
```

Create an SRU bug using an SRU description file:
```bash
python3 "$HOME/.cache/oem-scripts/launchpad_rest.py" --create -p sutton --title "[SRU] Fix Cirrus Amps noise" -F sru_description.txt --tags "kernel-daily-bug,sru"
```

## Standard Ubuntu SRU Bug Template

When filing or updating an SRU bug, the description must strictly adhere to Canonical's standard SRU format:

```text
[ Impact ]

 * An explanation of the effects of the bug on users and justification
   for backporting the fix to the stable release.

 * In addition, it is helpful, but not required, to include an
   explanation of how the upload fixes this bug.

[ Test Plan ]

 * detailed instructions how to reproduce the bug

 * these should allow someone who is not familiar with the affected
   package to reproduce the bug and verify that the updated package
   fixes the problem.

 * if other testing is appropriate to perform before landing this
   update, this should also be described here.

[ Where problems could occur ]

 * Think about what the upload changes in the software. Imagine the
   change is wrong or breaks something else: how would this show up?

 * It is assumed that any SRU candidate patch is well-tested before
   upload and has a low overall risk of regression, but it's important
   to make the effort to think about what ''could'' happen in the event
   of a regression.

 * This must never be "None" or "Low", or entirely an argument as to why
   your upload is low risk.

 * This both shows the SRU team that the risks have been considered,
   and provides guidance to testers in regression-testing the SRU.

[ Other Info ]

 * Anything else you think is useful to include

 * Make sure to explain any deviation from the norm, to save the SRU
   reviewer from having to infer your reasoning, possibly incorrectly.
   This should also help reduce review iterations, particularly when the
   reason for the deviation is not obvious.

 * Anticipate questions from users, SRU, +1 maintenance, security teams
   and the Technical Board and address these questions in advance
```

## Procedure for Creating SRU Bugs

1. **Draft the SRU Description**:
   Write the structured text containing `[ Impact ]`, `[ Test Plan ]`, `[ Where problems could occur ]`, and `[ Other Info ]` to a local file (e.g. `/tmp/sru_desc.txt`).
   *Rule*: In `[ Where problems could occur ]`, never write "None" or "Low" — detail potential regression blast radiuses.
   *Rule*: If the user asks for a short version, keep the prose terse and move provenance into tags and `[ Other Info ]` instead of repeating it in the impact text.
   *Rule*: When an upstream fix URL is available, include the commit hash and the full upstream URL verbatim in `[ Other Info ]`.

2. **Submit via `launchpad_rest.py`**:
   ```bash
   python3 "$HOME/.cache/oem-scripts/launchpad_rest.py" --create \
       -p <PROJECT> \
       --title "[SRU] <Short Summary>" \
       -F /tmp/sru_desc.txt \
       --tags "<TAGS>"
   ```

## Pitfalls

- **Credentials for Writing**: Reading bugs, comments, and attachments works anonymously. Writing operations (`--comment`, `--add-tags`, `--create`) automatically load OAuth credentials from `~/launchpad.credentials`.
- **ETag on Tag Updates**: Launchpad REST requires the bug resource's `ETag` via `If-Match` header to safely update tags without race conditions. `add_tags()` handles this automatically.
- **`[ Where problems could occur ]` Rejections**: Canonical SRU reviewers immediately reject SRU bug filings if this section says "None", "Low risk", or is omitted.
