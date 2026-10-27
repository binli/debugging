#!/usr/bin/env python3
"""Read and update Google Sheets; credentials never belong in the skill folder."""

import argparse
import json
import math
import os
from pathlib import Path
import re
import sys
import tempfile
from urllib.parse import urlparse


SCOPES = ["https://www.googleapis.com/auth/spreadsheets"]
RENDER_OPTIONS = {"formatted": "FORMATTED_VALUE", "unformatted": "UNFORMATTED_VALUE", "formula": "FORMULA"}


def write_json_file(path, data, force=False):
    """Publish a complete private JSON file, without clobbering by default."""
    descriptor, temporary = tempfile.mkstemp(prefix=".sheets-export-", dir=path.parent)
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
            json.dump(data, handle, ensure_ascii=False, indent=2, allow_nan=False)
            handle.write("\n")
        if force:
            os.replace(temporary, path)
        else:
            # Atomic no-clobber publication, even if another process creates it.
            os.link(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def dump_sheet(api, sheet_id, args):
    metadata = api.get(
        spreadsheetId=sheet_id,
        fields="spreadsheetId,spreadsheetUrl,properties(title),sheets(properties)",
    ).execute(num_retries=2)
    tabs = [sheet["properties"]["title"] for sheet in metadata.get("sheets", [])]
    if args.tab is not None and args.tab not in tabs:
        raise ValueError("The requested tab does not exist. Use info to list available tabs.")
    if args.a1_range:
        ranges = [args.a1_range]
    else:
        selected = [args.tab] if args.tab is not None else tabs
        ranges = ["'" + title.replace("'", "''") + "'" for title in selected]
    response = api.values().batchGet(
        spreadsheetId=sheet_id, ranges=ranges, majorDimension="ROWS",
        valueRenderOption=RENDER_OPTIONS[args.render],
    ).execute(num_retries=2) if ranges else {"valueRanges": []}
    data = {
        "spreadsheetId": sheet_id,
        "spreadsheet": metadata,
        "render": args.render,
        "valueRanges": response.get("valueRanges", []),
    }
    output = Path(args.output).expanduser().absolute()
    write_json_file(output, data, force=args.force)
    return {"saved": True, "output": str(output), "ranges_exported": len(data["valueRanges"])}


def spreadsheet_id(value):
    value = value.strip()
    if re.fullmatch(r"[A-Za-z0-9_-]+", value):
        return value
    url = urlparse(value)
    if url.scheme == "https" and url.hostname == "docs.google.com":
        if url.path.startswith("/spreadsheets/d/e/"):
            raise ValueError("Published spreadsheet links are not API IDs. Supply the original spreadsheet's edit URL or ID.")
        match = re.match(r"/spreadsheets/(?:u/\d+/)?d/([A-Za-z0-9_-]+)(?:/|$)", url.path)
        if match:
            return match.group(1)
    raise ValueError("Expected a spreadsheet ID or an https://docs.google.com/spreadsheets/d/... URL.")


def load_values(args):
    if args.values_file:
        text = Path(args.values_file).expanduser().read_text(encoding="utf-8")
    else:
        text = args.values
    values = json.loads(text)
    if not isinstance(values, list) or not values:
        raise ValueError("Values must be a nonempty two-dimensional JSON array.")
    width = None
    for row in values:
        if not isinstance(row, list) or not row:
            raise ValueError("Each row must be a nonempty array.")
        if width is None:
            width = len(row)
        if len(row) != width:
            raise ValueError("Rows must all have the same number of columns.")
        for cell in row:
            if not isinstance(cell, (str, int, float, bool)):
                raise ValueError("Cells must be strings, numbers, or booleans; use an empty string to clear a cell.")
            if isinstance(cell, float) and not math.isfinite(cell):
                raise ValueError("NaN and infinity are not supported.")
    return values


def column_number(label):
    number = 0
    for letter in label.upper():
        number = number * 26 + ord(letter) - ord("A") + 1
    return number


def column_label(number):
    label = ""
    while number:
        number, remainder = divmod(number - 1, 26)
        label = chr(ord("A") + remainder) + label
    return label


def update_range(a1_range, values):
    """Expand a single anchor, or reject a mismatched explicit rectangle."""
    match = re.fullmatch(
        r"(?P<tab>'(?:[^']|'')+'|[^'!]+)!\$?(?P<col>[A-Za-z]+)\$?(?P<row>[1-9]\d*)"
        r"(?::\$?(?P<endcol>[A-Za-z]+)\$?(?P<endrow>[1-9]\d*))?",
        a1_range,
    )
    if not match:
        raise ValueError("Updates require an explicit tab and a cell or bounded rectangle, e.g. 'Sheet1'!A1:B2.")
    start_col = column_number(match["col"])
    start_row = int(match["row"])
    end_col = start_col + len(values[0]) - 1
    end_row = start_row + len(values) - 1
    if match["endcol"] and (
        column_number(match["endcol"]) != end_col or int(match["endrow"]) != end_row
    ):
        raise ValueError("The update range dimensions must exactly match the values array.")
    return f"{match['tab']}!{column_label(start_col)}{start_row}:{column_label(end_col)}{end_row}"


def save_token(directory, credentials):
    directory.mkdir(mode=0o700, parents=True, exist_ok=True)
    descriptor, temporary = tempfile.mkstemp(prefix=".token-", dir=directory)
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
            handle.write(credentials.to_json())
        os.replace(temporary, directory / "token.json")
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def credentials_for(args):
    from google.auth.transport.requests import Request
    from google.oauth2.credentials import Credentials

    directory = Path(args.credentials_dir).expanduser()
    if args.service_account:
        from google.oauth2 import service_account

        if args.command == "auth":
            raise ValueError("Service accounts do not use browser authentication; run info or read instead.")
        return service_account.Credentials.from_service_account_file(
            str(Path(args.service_account).expanduser()), scopes=SCOPES
        )
    if args.command == "auth":
        from google_auth_oauthlib.flow import InstalledAppFlow

        flow = InstalledAppFlow.from_client_secrets_file(
            str(directory / ".google-sheets-secret.json"), SCOPES
        )
        credentials = flow.run_local_server(
            host="localhost", port=args.port, open_browser=not args.no_browser,
            access_type="offline", prompt="consent", timeout_seconds=300,
        )
        save_token(directory, credentials)
        return credentials
    token = directory / "token.json"
    if not token.is_file():
        raise ValueError("No saved OAuth token. Run the auth subcommand in your own terminal first.")
    credentials = Credentials.from_authorized_user_file(str(token), SCOPES)
    if not credentials.valid:
        if not credentials.refresh_token:
            raise ValueError("The saved login cannot be refreshed. Run auth again.")
        credentials.refresh(Request())
        save_token(directory, credentials)
    return credentials


def parser():
    result = argparse.ArgumentParser(description=__doc__)
    data_home = Path(os.environ.get("XDG_DATA_HOME", str(Path.home())))
    result.add_argument("--credentials-dir", default=str(data_home))
    result.add_argument("--service-account", metavar="KEY_JSON", help="Use a service-account key instead of OAuth")
    commands = result.add_subparsers(dest="command", required=True)
    auth = commands.add_parser("auth", help="Interactive OAuth sign-in; run in your terminal")
    auth.add_argument("--no-browser", action="store_true")
    auth.add_argument("--port", type=int, default=0, help="Callback port; default selects an available port")
    for name in ("info", "read", "update", "dump"):
        command = commands.add_parser(name)
        command.add_argument("--spreadsheet", required=True, help="Spreadsheet URL or ID")
        if name in ("read", "update"):
            command.add_argument("--range", required=True, dest="a1_range")
        if name in ("read", "dump"):
            command.add_argument("--render", choices=("formatted", "unformatted", "formula"), default="formatted")
        if name == "dump":
            selection = command.add_mutually_exclusive_group()
            selection.add_argument("--range", dest="a1_range", help="Export one A1 range instead of all tabs")
            selection.add_argument("--tab", help="Export one whole tab by its exact title")
            command.add_argument("--output", required=True, help="Destination UTF-8 JSON file")
            command.add_argument("--force", action="store_true", help="Replace an existing output file")
        if name == "update":
            source = command.add_mutually_exclusive_group(required=True)
            source.add_argument("--values", help="JSON array of rows")
            source.add_argument("--values-file", help="Path to UTF-8 JSON array of rows")
            command.add_argument("--user-entered", action="store_true", help="Interpret formulas and parse values")
            command.add_argument("--dry-run", action="store_true", help="Read current cells and preview; do not write")
    return result


def run(args):
    # Validate user input before loading credentials or contacting Google.
    sheet_id = spreadsheet_id(args.spreadsheet) if args.command != "auth" else None
    values = load_values(args) if args.command == "update" else None
    target = update_range(args.a1_range, values) if values is not None else None
    if args.command == "dump":
        output = Path(args.output).expanduser().absolute()
        if not output.parent.is_dir():
            raise ValueError("The output directory does not exist. Create it before exporting.")
        if (output.exists() or output.is_symlink()) and not args.force:
            raise ValueError("The output file already exists. Choose another path or pass --force to replace it.")
        if output.is_dir():
            raise ValueError("The output must be a file, not a directory.")
    if args.command == "auth" and not 0 <= args.port <= 65535:
        raise ValueError("Callback port must be between 0 and 65535.")
    credentials = credentials_for(args)
    if args.command == "auth":
        return {"authenticated": True, "token_file": str(Path(args.credentials_dir).expanduser() / "token.json")}

    from googleapiclient.discovery import build

    sheets = build("sheets", "v4", credentials=credentials, cache_discovery=False).spreadsheets()
    if args.command == "dump":
        return dump_sheet(sheets, sheet_id, args)
    if args.command == "info":
        return sheets.get(
            spreadsheetId=sheet_id,
            fields="spreadsheetId,spreadsheetUrl,properties(title),sheets(properties)",
        ).execute(num_retries=2)
    if args.command == "read":
        return sheets.values().get(
            spreadsheetId=sheet_id, range=args.a1_range,
            valueRenderOption=RENDER_OPTIONS[args.render],
        ).execute(num_retries=2)
    if args.dry_run:
        current = sheets.values().get(
            spreadsheetId=sheet_id, range=target, valueRenderOption="FORMULA",
        ).execute(num_retries=2)
        return {
            "dry_run": True, "spreadsheetId": sheet_id, "range": target,
            "current": current, "proposed": values,
            "valueInputOption": "USER_ENTERED" if args.user_entered else "RAW",
        }
    # Do not automatically retry writes after an ambiguous network failure.
    response = sheets.values().update(
        spreadsheetId=sheet_id, range=target,
        valueInputOption="USER_ENTERED" if args.user_entered else "RAW",
        body={"majorDimension": "ROWS", "values": values},
    ).execute(num_retries=0)
    result = {"write_succeeded": True, "update": response}
    try:
        result["readback"] = sheets.values().get(
            spreadsheetId=sheet_id, range=response.get("updatedRange", target),
            valueRenderOption="FORMULA",
        ).execute(num_retries=2)
    except Exception:
        result["verification_error"] = "Write succeeded, but readback failed. Read the range again before retrying."
    return result


def main():
    args = parser().parse_args()
    try:
        result = run(args)
    except ImportError:
        error = "Missing Google API dependencies. Install scripts/requirements.txt in the skill's virtual environment."
    except (ValueError, OSError) as exc:
        error = str(exc)
    except Exception as exc:
        # Google and transport exceptions may contain sensitive response details.
        status = getattr(getattr(exc, "resp", None), "status", None)
        error = f"Google API/authentication request failed ({type(exc).__name__}"
        error += f", HTTP {status})." if status else ")."
        error += " Check sign-in, API enablement, spreadsheet sharing, range, and network. A write failure may be ambiguous; read cells before retrying."
    else:
        print(json.dumps(result, ensure_ascii=False, indent=2, allow_nan=False))
        return 0
    print(json.dumps({"error": error}), file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
