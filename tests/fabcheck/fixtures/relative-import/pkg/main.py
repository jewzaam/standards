"""Fabcheck fixture: uses relative imports and explicit-dots navigation."""
from __future__ import annotations
from .helpers import greet
from . import helpers


def main() -> str:
    return f"{greet()} {helpers.__name__}"
