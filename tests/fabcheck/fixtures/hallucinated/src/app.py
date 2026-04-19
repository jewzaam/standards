"""Fabcheck fixture: completely fabricated import."""
import totally_fake_package_xyz  # noqa: F401


def hello() -> str:
    return totally_fake_package_xyz.greet()
