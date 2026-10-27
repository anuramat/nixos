"""KnowLine's /v1/systemone server (knowline_server.py from its model repo), with llama-server as the backend.

usage: knowline.py SRC LLAMA_URL HOST PORT
SRC holds the model repo's knowline_server.py, knowline_layout.py and tokenizer files.

KnowLine is a plain causal LM: an answer is the softmax over the options' label tokens after the prompt. The prompt
is tokenized with the model's own tokenizer and sent as token ids; with temperature < 0, llama-server's n_probs are a
plain softmax of the raw logits (the readout temperature is folded into the weights).
"""

import io
import json
import sys

import requests

src, url, host, port = sys.argv[1:]
sys.path.insert(0, src)
import knowline_server as ks  # noqa: E402
from knowline_layout import Layout  # noqa: E402
from transformers import AutoTokenizer  # noqa: E402

N_PROBS = 128  # labels outside the top N get probability 0


class LlamaCpp:
    def __init__(self, tok):
        self.tok, self.http = tok, requests.Session()

    def _post(self, text):
        ids = self.tok.encode(text, add_special_tokens=False)
        body = {"prompt": ids, "n_predict": 1, "n_probs": N_PROBS, "temperature": -1}
        r = self.http.post(f"{url}/completion", json=body, timeout=600)
        r.raise_for_status()
        return r.json(), len(ids)

    def warm(self, prefix, media):
        self._post(prefix)

    def score(self, text, media, ids):
        if media:
            raise ValueError("images are not supported")
        r, n = self._post(text)
        got = {
            t["id"]: t["logprob"]
            for t in r["completion_probabilities"][0]["top_logprobs"]
        }
        return ks._finite([got.get(i) for i in ids]), n


class Handler(ks.Handler):
    def do_POST(self):
        # upstream ignores llama-server's top-level image fields, answering without the images
        body = self.rfile.read(int(self.headers.get("Content-Length", 0)))
        try:
            media = {"images", "files"} & set(json.loads(body or b"{}"))
        except ValueError:
            media = None  # invalid JSON: upstream reports it
        if media:
            return self._send(422, {"error": "images are not supported"})
        self.rfile = io.BytesIO(body)
        super().do_POST()


tok = AutoTokenizer.from_pretrained(src)
srv = ks.Server((host, int(port)), Handler)
srv.engine, srv.name = (
    ks.KnowLine(tok, LlamaCpp(tok), layout=Layout(read_twice=True)),
    "knowline",
)
srv.serve_forever()
