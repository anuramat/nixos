import argparse
import asyncio
import json
import os
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path

from dbus_next import Variant
from dbus_next.aio import MessageBus

BUS_NAME = "org.freedesktop.secrets"
BASE_PATH = "/org/freedesktop/secrets"
COLLECTION_LABEL = "org.freedesktop.Secret.Collection.Label"
ITEM_LABEL = "org.freedesktop.Secret.Item.Label"
ITEM_ATTRIBUTES = "org.freedesktop.Secret.Item.Attributes"


def json_file(path):
    try:
        return json.loads(path.read_text())
    except FileNotFoundError:
        return {}


def safe_id(name):
    return re.sub(r"[^A-Za-z0-9_]", "_", name).strip("_") or "collection"


def decrypt(path):
    result = subprocess.run(
        ["gpg", "--decrypt", str(path)],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if result.returncode:
        raise RuntimeError(f"gpg failed to decrypt {path}")
    return result.stdout


async def interface(bus, path, name):
    node = await bus.introspect(BUS_NAME, path)
    return bus.get_proxy_object(BUS_NAME, path, node).get_interface(name)


def parse_args():
    store = Path(os.environ.get("PASSWORD_STORE_DIR", "~/.password-store")).expanduser()
    parser = argparse.ArgumentParser(prog="pss-migrate")
    parser.add_argument("--store", type=Path, default=store)
    parser.add_argument("--backup", type=Path)
    parser.add_argument("--allow-existing", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--yes", action="store_true")
    return parser.parse_args()


def old_collections(old_base):
    return sorted(path for path in old_base.iterdir() if path.is_dir())


def new_secret_count(new_base):
    return sum(1 for _ in new_base.rglob("*.gpg")) if new_base.exists() else 0


def backup_store(store, backup):
    shutil.copytree(store, backup, symlinks=True)
    return backup


async def migrate(args):
    store = args.store.expanduser()
    old_base = store / "secret_service"
    new_base = store / "secret-service"
    backup = args.backup or store.with_name(
        f"{store.name}.pre-rust-pss.{time.strftime('%Y%m%d%H%M%S')}"
    )

    if not old_base.exists():
        raise SystemExit(f"old store not found: {old_base}")

    collections = old_collections(old_base)
    items = [
        (collection, item)
        for collection in collections
        for item in sorted(collection.glob("*.gpg"))
    ]
    existing = new_secret_count(new_base)

    print(f"old collections: {len(collections)}")
    print(f"old secrets: {len(items)}")
    print(f"new secrets: {existing}")
    print(f"backup: {backup}")

    if existing and not args.allow_existing:
        raise SystemExit(
            "new Rust store already has secrets; pass --allow-existing to import anyway"
        )
    if args.dry_run:
        return
    if not args.yes:
        raise SystemExit("rerun with --yes to write the migration")
    if backup.exists():
        raise SystemExit(f"backup already exists: {backup}")

    backup_store(store, backup)

    aliases = json_file(old_base / ".aliases")
    aliases_by_collection = {}
    for alias, collection in aliases.items():
        aliases_by_collection.setdefault(collection, []).append(alias)

    bus = await MessageBus().connect()
    try:
        service = await interface(bus, BASE_PATH, "org.freedesktop.Secret.Service")
        _, session_path = await service.call_open_session("plain", Variant("s", ""))
        session = await interface(bus, session_path, "org.freedesktop.Secret.Session")

        for collection in collections:
            collection_aliases = sorted(
                aliases_by_collection.get(collection.name, []),
                key=lambda alias: alias != "default",
            )
            create_alias = collection_aliases[0] if collection_aliases else ""
            collection_props = json_file(collection / ".properties")
            label = str(collection_props.get(COLLECTION_LABEL) or collection.name)
            path, prompt = await service.call_create_collection(
                {COLLECTION_LABEL: Variant("s", safe_id(collection.name))},
                create_alias,
            )
            if prompt != "/":
                raise RuntimeError(
                    f"unexpected prompt while creating collection {collection.name}: {prompt}"
                )

            target = await interface(bus, path, "org.freedesktop.Secret.Collection")
            await target.set_label(label)

            for alias in collection_aliases[1:]:
                await service.call_set_alias(alias, path)

            for secret_file in sorted(collection.glob("*.gpg")):
                props = json_file(secret_file.with_suffix(".properties"))
                item_props = {}
                if ITEM_LABEL in props:
                    item_props[ITEM_LABEL] = Variant("s", str(props[ITEM_LABEL]))
                if ITEM_ATTRIBUTES in props:
                    attrs = {str(k): str(v) for k, v in props[ITEM_ATTRIBUTES].items()}
                    item_props[ITEM_ATTRIBUTES] = Variant("a{ss}", attrs)
                item_path, prompt = await target.call_create_item(
                    item_props,
                    [session_path, b"", decrypt(secret_file), "text/plain"],
                    False,
                )
                if prompt != "/" or item_path == "/":
                    raise RuntimeError(f"failed to create item for {secret_file}")

        await session.call_close()
    finally:
        bus.disconnect()

    print("migration complete")


if __name__ == "__main__":
    try:
        asyncio.run(migrate(parse_args()))
    except Exception as err:
        print(f"error: {err}", file=sys.stderr)
        raise SystemExit(1)
