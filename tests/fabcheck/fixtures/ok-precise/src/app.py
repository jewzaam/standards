"""Fabcheck fixture: PIL import resolved precisely via pillow dist."""
import os
import json
from PIL import Image
import requests


def hello() -> str:
    return f"{os.getcwd()} {Image.__name__} {requests.__name__} {json.dumps([])}"
