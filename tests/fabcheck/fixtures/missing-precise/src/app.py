"""Fabcheck fixture: PIL import is undeclared (pillow missing from deps)."""
from PIL import Image
import requests


def hello() -> str:
    return f"{Image.__name__} {requests.__name__}"
