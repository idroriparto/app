#!/usr/bin/env python3
"""Serve la build web con gli header COOP/COEP richiesti da Flutter."""

from __future__ import annotations

import os
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer

ROOT = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", "build", "web")
)


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=ROOT, **kwargs)

    def end_headers(self) -> None:
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "credentialless")
        self.send_header("Cache-Control", "no-cache")
        super().end_headers()


def main() -> None:
    port = int(os.environ.get("PORT", "8080"))
    httpd = ThreadingHTTPServer(("0.0.0.0", port), Handler)
    print(f"IdroRiparto → http://0.0.0.0:{port}  ({ROOT})", flush=True)
    httpd.serve_forever()


if __name__ == "__main__":
    main()
