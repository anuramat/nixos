"""KnowLine's /v1/systemone server (knowline_server.py from its model repo), with llama-server as the backend.

usage: knowline.py SRC LLAMA_URL HOST PORT MAX_IMAGE_TOKENS [--no-read-twice]
SRC holds the model repo's knowline_server.py, knowline_layout.py and tokenizer files. Short text-only requests are
written twice (Gen1.5); --no-read-twice gives the Gen1 prompts, as the flag of upstream's server. Images over
MAX_IMAGE_TOKENS, llama-server's --image-max-tokens, are refused rather than downscaled.

KnowLine is a plain causal LM: an answer is the softmax over the options' label tokens after the prompt. With
temperature < 0, llama-server's n_probs are a plain softmax of the raw logits (the readout temperature is folded into
the weights). The prompt goes as text, since llama-server takes images only with a text prompt: its tokenizer gives
the same ids as the HF one, once the text has gone through the HF tokenizer's normalizer (NFC).
"""

import base64
import io
import json
import sys

import requests
from PIL import Image

src, url, host, port, max_image_tokens, *opts = sys.argv[1:]
sys.path.insert(0, src)
import knowline_server as ks  # noqa: E402
from knowline_layout import Layout  # noqa: E402
from transformers import AutoTokenizer  # noqa: E402

N_PROBS = 128  # labels outside the top N get probability 0
IMAGE = "<|vision_start|><|image_pad|><|vision_end|>"  # an image in the chat template's output


def image_base64(data_url):
    """The base64 data of an image data URL, if llama-server takes the image without downscaling it."""
    if not isinstance(data_url, str) or not data_url.startswith("data:"):
        raise ValueError("images must be data URLs (data:image/...;base64,...)")
    data = data_url.split(",", 1)[1]
    w, h = Image.open(io.BytesIO(base64.b64decode(data))).size
    # llama-server's count: each side rounded to the nearest 32 px (a 2x2 merge of 16 px patches)
    n = max(1, (w + 16) // 32) * max(1, (h + 16) // 32)
    if n > int(max_image_tokens):
        raise ValueError(
            f"a {w}x{h} image is {n} tokens of 32x32 px, over the {max_image_tokens} allowed"
        )
    return data


class LlamaCpp:
    def __init__(self, tok):
        self.norm = tok.backend_tokenizer.normalizer.normalize_str
        self.http = requests.Session()
        self.marker = None  # llama-server's placeholder for an image in a text prompt, random per run

    def _post(self, text, media):
        if self.marker is None:
            self.marker = self.http.get(f"{url}/props").json()["media_marker"]
        prompt = {
            "prompt_string": self.norm(text).replace(IMAGE, self.marker),
            "multimodal_data": [image_base64(m) for m in media],
        }
        body = {"prompt": prompt, "n_predict": 1, "n_probs": N_PROBS, "temperature": -1}
        r = self.http.post(f"{url}/completion", json=body, timeout=600)
        r.raise_for_status()
        return r.json()

    def warm(self, prefix, media):
        self._post(prefix, media)

    def score(self, text, media, ids):
        r = self._post(text, media)
        got = {
            t["id"]: t["logprob"]
            for t in r["completion_probabilities"][0]["top_logprobs"]
        }
        return ks._finite([got.get(i) for i in ids]), r["tokens_evaluated"]


def images_to_state(req):
    """llama-server's /v1/systemone also takes top-level images; upstream reads them only from the state's chat."""
    parts = [
        {"type": "image_url", "image_url": {"url": u}}
        for k in ("images", "files")
        for u in req.pop(k, None) or []
    ]
    if not parts:
        return req
    state = req.get("state", "")
    msgs = (
        state["messages"]
        if isinstance(state, dict) and set(state) == {"messages"}
        else state
    )
    if (
        isinstance(msgs, list)
        and msgs
        and all(isinstance(m, dict) and "role" in m for m in msgs)
    ):
        req["state"] = [{"role": "user", "content": parts}] + msgs
    else:
        text = {"type": "text", "text": ks.render_value(state)}
        req["state"] = [{"role": "user", "content": parts + [text]}]
    return req


class Handler(ks.Handler):
    def do_POST(self):
        body = self.rfile.read(int(self.headers.get("Content-Length", 0)))
        try:
            body = json.dumps(images_to_state(json.loads(body or b"{}"))).encode()
        except ValueError:
            pass  # invalid JSON: upstream reports it
        self.rfile = io.BytesIO(body)
        del self.headers["Content-Length"]
        self.headers["Content-Length"] = str(len(body))
        super().do_POST()


tok = AutoTokenizer.from_pretrained(src)
srv = ks.Server((host, int(port)), Handler)
srv.engine, srv.name = (
    ks.KnowLine(
        tok,
        LlamaCpp(tok),
        layout=None if "--no-read-twice" in opts else Layout(read_twice=True),
    ),
    "knowline",
)
srv.serve_forever()
