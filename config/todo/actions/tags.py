#!/usr/bin/env python3

from collections import defaultdict
import sys
import re


def main():
    symbol = sys.argv[1]
    if symbol == "usage":
        return
    if symbol == "+":
        symbol = "\\" + symbol
    exp = f"(?<!\\S){symbol}\\S+\\s*"
    pattern = re.compile(exp)

    if not symbol:
        raise ValueError()

    tasks_by_tags = defaultdict(list)
    for task in sys.stdin:
        tags = pattern.findall(task)
        task = pattern.sub("", task)
        task = task.strip()
        for tag in tags:
            tasks_by_tags[tag.strip()].append(task)
        if len(tags) == 0:
            tasks_by_tags[f"-{symbol[-1]}"].append(task)

    delim = "\0"
    res = ""
    for tag, tasks in tasks_by_tags.items():
        res += f"{tag}{delim}{'\n'.join(tasks[::-1])}{delim}"

    print(res, end="")


if __name__ == "__main__":
    main()
