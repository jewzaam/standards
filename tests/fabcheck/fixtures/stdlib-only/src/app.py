"""Fabcheck fixture: stdlib-only imports, including __future__ and array."""
from __future__ import annotations
import os
import sys
import json
import re
import array
import pathlib


def hello() -> str:
    return f"{os.getcwd()} {sys.platform} {pathlib.Path.cwd()} {array.__name__} {json.dumps([])} {re.__name__}"
