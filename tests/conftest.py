import functools
import http.server
import socketserver
import threading

import pytest


@pytest.fixture
def http_server(tmp_path):
    """Serve tmp_path/'srv' over localhost; yields (base_url, served_dir)."""
    served = tmp_path / "srv"
    served.mkdir()
    handler = functools.partial(
        http.server.SimpleHTTPRequestHandler, directory=str(served)
    )
    httpd = socketserver.ThreadingTCPServer(("127.0.0.1", 0), handler)
    port = httpd.server_address[1]
    thread = threading.Thread(target=httpd.serve_forever, daemon=True)
    thread.start()
    try:
        yield f"http://127.0.0.1:{port}", served
    finally:
        httpd.shutdown()
        httpd.server_close()
        thread.join()
