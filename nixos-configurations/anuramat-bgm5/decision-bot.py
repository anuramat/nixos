# Telegram bot that classifies every message with the decision model and, when
# it's confident, replies with a random canned reply for the category.
# usage: decision-bot URL, with the bot token in $CREDENTIALS_DIRECTORY/token
# and the config in $CREDENTIALS_DIRECTORY/config: JSON of the form
# {"chat": ID, "categories": {NAME: [DESCRIPTION, [REPLY, ...], [USERNAME, ...]], ...}},
# where chat is the only chat the bot reads, the description is the model's, and
# a category with usernames (without the @) is only offered for their messages.
# URL is the decision model's /v1/systemone. In groups, the bot needs privacy
# mode off (BotFather: /setprivacy) to see messages not addressed to it.
import base64
import io
import json
import os
import random
import sys
import time
from collections import defaultdict, deque

import httpx
from PIL import Image
from telegram.ext import Application, MessageHandler, filters

THRESHOLD = 0.7  # of the answer's confidence: 0 is uniform, 1 is certain
COOLDOWN = 30 * 60  # s a category stays silent after replying
HISTORY = 10  # earlier messages per chat given as context
# photos are shrunk to fit a square of this many px: the latest message's, and the rest
IMAGE_SIZE = 1024
CONTEXT_IMAGE_SIZE = 256

url = sys.argv[1]
credentials = os.environ["CREDENTIALS_DIRECTORY"]
token = open(os.path.join(credentials, "token")).read().strip()
config = json.load(open(os.path.join(credentials, "config")))
# category -> (description for the model, replies, usernames or [] for everyone);
# "none" is never replied to
categories = config["categories"] | {"none": ("none of the above", [], [])}
# chat -> (line, photo as a data URI of CONTEXT_IMAGE_SIZE, or None) per message
history = defaultdict(lambda: deque(maxlen=HISTORY))
# category -> time.monotonic() of its last reply
last_reply = defaultdict(lambda: -COOLDOWN)
http = httpx.AsyncClient(timeout=60)


def line(msg):
    user = msg.from_user
    name = f"{user.full_name} (@{user.username})" if user.username else user.full_name
    return f"{name}: {msg.text or msg.caption or ''}"


async def photo_uri(msg, size):
    """The message's photo as a JPEG data URI, shrunk to fit size x size, or None."""
    if not msg.photo:
        return None
    # the smallest of Telegram's sizes (in ascending order) that fills the box, or the largest
    photo = next(
        (p for p in msg.photo if max(p.width, p.height) >= size), msg.photo[-1]
    )
    data = await (await photo.get_file()).download_as_bytearray()
    image = Image.open(io.BytesIO(data)).convert("RGB")
    image.thumbnail((size, size))
    buf = io.BytesIO()
    image.save(buf, format="JPEG", quality=90)
    return "data:image/jpeg;base64," + base64.b64encode(buf.getvalue()).decode()


async def classify(state, media, criteria):
    r = await http.post(
        url,
        json={
            "state": state,
            "media": media,
            "questions": {
                "category": {
                    "type": "choice",
                    "instructions": "Which category does the latest message belong to?",
                    "criteria": criteria,
                }
            },
        },
    )
    r.raise_for_status()
    return r.json()["answers"]["category"]


async def on_message(update, _context):
    msg = update.message
    media = []

    def entry(text, uri):
        """The line, followed by the photo's placeholder; qev wants the media in order of appearance."""
        if uri is None:
            return text
        media.append({"type": "image", "data": uri})
        return f"{text} <image:{len(media)}>"

    state = {"earlier messages": [entry(*m) for m in history[msg.chat_id]]}
    if reply := msg.reply_to_message:
        state["the latest message replies to"] = entry(
            line(reply), await photo_uri(reply, CONTEXT_IMAGE_SIZE)
        )
    state["latest message"] = entry(line(msg), await photo_uri(msg, IMAGE_SIZE))
    history[msg.chat_id].append((line(msg), await photo_uri(msg, CONTEXT_IMAGE_SIZE)))
    criteria = {
        k: d
        for k, (d, _, users) in categories.items()
        if not users or msg.from_user.username in users
    }
    a = await classify(state, media, criteria)
    # stderr, since stdout is buffered under systemd
    print(
        msg.chat_id,
        msg.chat.type,
        msg.chat.effective_name,
        a["choice"],
        a["confidence"],
        file=sys.stderr,
    )
    replies = categories[a["choice"]][1]
    now = time.monotonic()
    if (
        replies
        and a["confidence"] >= THRESHOLD
        and now - last_reply[a["choice"]] >= COOLDOWN
    ):
        last_reply[a["choice"]] = now
        await msg.reply_text(random.choice(replies))


app = Application.builder().token(token).build()
app.add_handler(
    MessageHandler(
        filters.Chat(config["chat"])
        & filters.UpdateType.MESSAGE
        & (filters.TEXT | filters.CAPTION | filters.PHOTO),
        on_message,
    )
)
app.run_polling()
