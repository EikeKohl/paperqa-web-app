import logging
import re
from pathlib import Path

import requests


def download_pdf(pdf_url, save_dir):
    file_name = Path(pdf_url.split("/")[-1])
    downloaded_pdf = Path(
        save_dir, sanitize_file_name(file_name.stem) + file_name.suffix
    )
    downloaded_pdf.parent.mkdir(exist_ok=True, parents=True)
    if not downloaded_pdf.exists():
        logging.info(downloaded_pdf.as_posix())
        downloaded_pdf.write_bytes(requests.get(pdf_url).content)


def sanitize_file_name(raw_file_name):
    return re.sub(r"[,/]", "", raw_file_name)
