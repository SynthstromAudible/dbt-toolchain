"""The single HTTP path for dbtbuilder (downloads and checksum fetches)."""

from pathlib import Path

import requests
from tqdm.rich import tqdm

from .errors import DownloadError

_TIMEOUT = 60


def fetch_text(url: str) -> str:
    try:
        response = requests.get(url, timeout=_TIMEOUT, allow_redirects=True)
        response.raise_for_status()
    except requests.RequestException as e:
        raise DownloadError(f"failed to fetch {url}: {e}") from e
    return response.text


def download_file(url: str, dest: Path) -> Path:
    dest.parent.mkdir(parents=True, exist_ok=True)
    block_size = 1024
    try:
        with requests.get(url, stream=True, allow_redirects=True, timeout=_TIMEOUT) as response:
            response.raise_for_status()
            file_size = int(response.headers.get("Content-Length", 0))
            with tqdm(
                total=file_size,
                unit="B",
                unit_scale=True,
                miniters=0.01,
                desc=dest.name,
            ) as pbar:
                with dest.open("wb") as f:
                    for data in response.iter_content(block_size):
                        f.write(data)
                        pbar.update(len(data))
                        pbar.refresh()
                pbar.refresh()
    except requests.RequestException as e:
        raise DownloadError(f"failed to download {url}: {e}") from e
    return dest
