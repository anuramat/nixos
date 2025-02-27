#!/usr/bin/env python3

from collections import defaultdict
from itertools import zip_longest
import argparse
import os
import re
import sys

# TODO expand $HOME
# TODO syntax hl

TASK_FILE = "./notes/todo/todo.txt"

MIN_LINES = 10
MIN_DESC_CHARS = 30
PROMPT_N_LINES = 3


def add(line):
    with open(TASK_FILE, "a") as file:
        file.write(line + "\n")


def rm(task_number):
    lines = _read()

    if task_number < 1 or task_number > len(lines):
        print("invalid n")
        return

    del lines[task_number - 1]
    _write(lines)


def _read():
    with open(TASK_FILE, "r") as file:
        return file.readlines()


def _write(lines):
    with open(TASK_FILE, "w") as file:
        file.writelines(lines)


def ls():
    lines = _read()
    w = len(str(len(lines)))
    for i, line in enumerate(lines, 1):
        print(f"{str(i).rjust(w)} {line.strip()}")


def _get_tag_dict(tasks: list[str], symbol: str):
    if symbol == "+":
        symbol = "\\" + symbol
    exp = f"(?<!\\S){symbol}\\S+\\s*"
    pattern = re.compile(exp)
    tasks_by_tags = defaultdict(list)
    for task in tasks:
        tags = pattern.findall(task)
        task = pattern.sub("", task)
        task = task.strip()
        for tag in tags:
            tasks_by_tags[tag.strip()].append(task)
        if len(tags) == 0:
            tasks_by_tags[f"-{symbol[-1]}"].append(task)
    return tasks_by_tags


def _shorten(line: str, symbol: str, max_width: int):
    # very long line -> very long li...
    if len(symbol) > max_width:
        raise ValueError
    if len(line) > max_width:
        return line[: max_width - len(symbol)] + symbol
    return line


def overview(symbol: str):
    term_x, term_y = os.get_terminal_size()
    nx_cells = term_x // MIN_DESC_CHARS

    header = "-" * (term_x // 2) + "TODO"
    header += (term_x - len(header)) * "-"
    print(header)

    lines = _read()
    by_tags = _get_tag_dict(lines, symbol)

    n_tags = len(by_tags)
    ny_cells = (n_tags + nx_cells - 1) // nx_cells  # ceil(tags/cols)
    w = term_x // nx_cells
    h = max(MIN_LINES, (term_y - PROMPT_N_LINES - 1) // ny_cells)  # XXX -1 -- header

    cells = []
    for tag in by_tags:
        tasks = by_tags[tag]
        count = len(by_tags[tag])
        heading = f"{tag}: {count}"
        underline = len(heading) * "-"  # TODO
        cell_lines = ["", heading, underline] + tasks
        cell_lines = [_shorten(i, "~", w - 1).ljust(w) for i in cell_lines[:h]]
        cells.append(cell_lines)

    columns = [[] for _ in range(nx_cells)]
    for i, v in enumerate(cells):
        columns[i % nx_cells].append(v)
    columns = [sum(i, []) for i in columns]

    z = zip_longest(*columns, fillvalue=(" " * w))
    result = "\n".join(["".join(str(item) for item in row) for row in z])

    print(result)


def main():
    parser = argparse.ArgumentParser(prog="task")

    subparsers = parser.add_subparsers(dest="command")

    add_parser = subparsers.add_parser("add", help="Add a new task")
    add_parser.add_argument("task_text", type=str, help="Task description")

    done_parser = subparsers.add_parser("rm", help="Mark a task as done")
    done_parser.add_argument("task_number", type=int, help="Task number to remove")

    subparsers.add_parser("ls", help="List all tasks")
    subparsers.add_parser("prj", help="List all tasks by projects")
    subparsers.add_parser("ctx", help="List all tasks by context")

    args = parser.parse_args()

    if args.command == "add":
        add(args.task_text)
    elif args.command == "done":
        rm(args.task_number)
    elif args.command == "ls":
        ls()
    elif args.command == "prj":
        overview("+")
    elif args.command == "ctx":
        overview("@")
    else:
        parser.print_help()
        sys.exit(1)


if __name__ == "__main__":
    main()
