#!/usr/bin/env python3

from collections import defaultdict
from datetime import datetime, UTC
from itertools import zip_longest
from math import ceil
import argparse
import os
import re
import sys
import tempfile

EDITOR = os.environ.get("EDITOR") or "vi"
DATE_PATTERN = re.compile(r"^\d{4}-\d{2}-\d{2}(?= )")
MIN_CELL_HEIGHT = 10
MIN_CELL_WIDTH = 30
TAG_LOOKBEHIND = r"(?<!\S@)(?<=@)"
TAG_PATTERN = re.compile(TAG_LOOKBEHIND + r"\S+")
TODO_FILE = os.environ.get("TODO_FILE") or os.path.expanduser("${XDG_DATA_HOME:-$HOME/.local/share}/notes/todo.txt")
TERM_HEIGHT_OFFSET = 5  # 2 * (prompt_lines = 2) + 1 * (divider_lines = 1)


def date_wrap(line) -> str:
    if bool(DATE_PATTERN.match(line)):
        return line
    return f"{datetime.now(UTC).strftime("%Y-%m-%d")} {line}"


def get_date(line: str) -> str:
    m = DATE_PATTERN.search(line)
    if m:
        return m.group()
    return ""


def partition_by_tag(lines: list[str], tag: str) -> tuple[list[str], list[str]]:
    match = []
    rest = []
    for line in lines:
        matches = TAG_PATTERN.findall(line)
        if (not matches and tag == "unfiled") or tag in matches:
            match.append(line)
        else:
            rest.append(line)
    return match, rest


def count_changes(inp: list[str], out: list[str]) -> int:
    """
    count changes
    expects SORTED lines
    """
    out = sorted(out)
    i = j = 0
    n_unchanged = 0
    while i < len(inp) and j < len(out):
        if inp[i] == out[j]:
            i += 1
            j += 1
            n_unchanged += 1
        elif inp[i] < out[j]:
            i += 1
        else:
            j += 1
    return max(len(inp) - n_unchanged, len(out) - n_unchanged)


def edit_tag(tag: str):
    lines = read()
    before, remaining = partition_by_tag(lines, tag)
    if not before:
        print(f"No tasks found for tag: {tag}")
        return
    with tempfile.TemporaryDirectory() as dir:
        path = os.path.join(dir, "todo.txt")
        with open(path, "w") as file:
            write(before, path)
        os.system(f"{EDITOR} {path}")
        with open(path, "r") as file:
            after = norm(read(path))
        changes = count_changes(before, after)
        print(f"{changes} changes")
        write(norm(remaining + after))


def add(line: str):
    line = line.strip()
    if not line:
        return
    with open(TODO_FILE, "a") as file:
        file.write(date_wrap(line) + "\n")


def rm(task_number: int):
    lines = read()
    if task_number < 1 or task_number > len(lines):
        print("invalid n")
        return
    del lines[task_number - 1]
    write(lines)


def norm(lines: list[str]) -> list[str]:
    """
    strip, remove empty, deduplicate, ensure date, sort
    """
    result = []
    for line in lines:
        line = line.strip()
        if line:
            result.append(date_wrap(line))
    result.sort()
    result = dedupe(result)
    return result


def dedupe(lines: list[str]) -> list[str]:
    """
    deduplicate SORTED lines
    """
    prev = ""
    result = []
    for line in lines:
        if line != prev:
            result.append(line)
            prev = line
    return result


def read(filename=TODO_FILE) -> list[str]:
    with open(filename, "r") as file:
        return [line.strip() for line in file.readlines()]


def write(lines: list[str], filename=TODO_FILE):
    with open(filename, "w") as file:
        file.write("\n".join(lines) + "\n")


def strip_date(lines):
    # shift to skip the space that is not caught by lookahead
    return [DATE_PATTERN.sub("", i)[1:] for i in lines]


def ls():
    result = number(strip_date(read()))
    print("\n".join(result))


def number(lines: list[str]) -> list[str]:
    """
    prepends aligned task numbers (for printing)
    """
    w = len(str(len(lines)))
    result = []
    for i, line in enumerate(lines, 1):
        result.append(f"{str(i).rjust(w)} {line}")
    return result


def _get_tag_dict(tasks: list[str]) -> dict[str, list[str]]:
    tasks_by_tags = defaultdict(list)
    for task in tasks:
        tags = TAG_PATTERN.findall(task)
        task = task.rstrip()
        for tag in tags:
            tasks_by_tags[tag].append(task)
        if len(tags) == 0:
            tasks_by_tags["unfiled"].append(task)
    return tasks_by_tags


def _shorten(line: str, symbol: str, max_width: int) -> str:
    # very long line -> very long li~
    if len(symbol) > max_width:
        raise ValueError
    if len(line) > max_width:
        return line[: max_width - len(symbol)] + symbol
    return line


def ls_tag(item: str):
    file_lines = number(read())
    lines_by_tags = _get_tag_dict(file_lines)
    print("\n".join(lines_by_tags[item]))


def tag_overview():
    file_lines = number(read())
    lines_by_tags = _get_tag_dict(file_lines)

    term_x, term_y = os.get_terminal_size()

    header = "-" * (term_x // 2) + "TAGS"
    header += (term_x - len(header)) * "-"

    n_x = term_x // MIN_CELL_WIDTH
    n_y = ceil(len(lines_by_tags) / n_x)

    w = term_x // n_x
    h = max(
        MIN_CELL_HEIGHT,
        (
            term_y - TERM_HEIGHT_OFFSET - (n_y - 1) - 1
        )  # subtracting prompt, spacing, and main header
        // n_y,
    )

    cells_lines = []
    for tag in sorted(lines_by_tags.keys()):
        lines = lines_by_tags[tag]
        heading = f"{tag}: {len(lines_by_tags[tag])}"
        underline = len(heading) * "-"
        lines = ([heading, underline] + lines)[:h]
        lines += [""] * (h - len(lines))  # exact cell height
        lines = [_shorten(i, "~", w - 1).ljust(w) for i in lines]  # exact line width
        cells_lines.append(lines)

    cells_by_columns = [[] for _ in range(n_x)]
    for i, v in enumerate(cells_lines):
        cells_by_columns[i % n_x].append(v + [""])
    column_lines = [sum(i, []) for i in cells_by_columns]

    zipped_columns = zip_longest(*column_lines, fillvalue=(" " * w))
    final_lines = ["".join(str(item) for item in row) for row in zipped_columns]
    final_lines = final_lines[:-1]  # remove last padding line
    result = "\n".join(final_lines)

    print(header + result)


def edit():
    line_nr = len(read())
    os.system(f"{EDITOR} +{line_nr} {TODO_FILE}")


def merge(left_name: str, root_name: str, right_name: str):
    # to be used as git merge driver
    left_lines = read(left_name)
    right_lines = read(right_name)
    root = set(read(root_name))
    left = set(left_lines)
    right = set(right_lines)

    # keep intersection -- old tasks (or rarely -- added in both revisions)
    # (union - intersection) -- either added in one or removed in the other:
    # check if it was in root: if it was, then it was removed => drop;
    # otherwise it was added => keep
    unchanged = left & right
    diff = (left | right) - unchanged
    new = diff - root
    keep = unchanged | new

    # TODO sort by date
    result = []
    for line in left_lines + right_lines:
        if line in keep:
            result.append(line)
            keep.remove(line)

    write(result, left_name)


def _setup_parser():
    """Set up command line argument parser."""
    parser = argparse.ArgumentParser(prog="task")
    subparsers = parser.add_subparsers(dest="command")

    # Add command
    add_parser = subparsers.add_parser("add", help="Add a new task")
    add_parser.add_argument("task_text", type=str, help="Task description")

    # Remove command
    rm_parser = subparsers.add_parser("rm", help="Mark a task as done")
    rm_parser.add_argument("task_number", type=int, help="Task number to remove")

    # Merge command
    merge_parser = subparsers.add_parser("merge", help="Merge")
    merge_parser.add_argument("left", type=str, help="Current version (%%A)")
    merge_parser.add_argument("root", type=str, help="Common ancestor's version (%%O)")
    merge_parser.add_argument("right", type=str, help="Other branches' (%%B)")

    # Simple commands without arguments
    subparsers.add_parser("ls", help="List all tasks")
    subparsers.add_parser("norm", help="Normalize the file")
    subparsers.add_parser("unfiled", help="List unfiled tasks")
    subparsers.add_parser("edit", help="Edit tasks file")

    return parser


def _handle_edit_tag_command():
    if len(sys.argv) == 3 and sys.argv[1] == "edit":
        tag = sys.argv[2]
        if len(tag) == 0:
            raise Exception
        edit_tag(tag)
        return True
    return False


def _handle_ls_tag_command():
    if len(sys.argv) == 3 and sys.argv[1] == "ls":
        tag = sys.argv[2]
        if len(tag) == 0:
            raise Exception
        ls_tag(tag)
        return True
    return False


def _dispatch_command(args):
    command_handlers = {
        "add": lambda: add(args.task_text),
        "rm": lambda: rm(args.task_number),
        "ls": ls,
        "norm": lambda: write(norm(read())),
        "merge": lambda: merge(args.left, args.root, args.right),
        "edit": edit,
    }

    if args.command in command_handlers:
        command_handlers[args.command]()
    else:
        tag_overview()


def main():
    # special cases
    if _handle_ls_tag_command():
        return
    if _handle_edit_tag_command():
        return

    parser = _setup_parser()
    args = parser.parse_args()
    _dispatch_command(args)


if __name__ == "__main__":
    main()
