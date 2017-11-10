import os

from squealyproj.settings import *  # noqa F403

"""
Overrides settings from settings.py so that DEBUG is false
and SECRET_KEY is random.
"""

DEBUG = False


def make_secret_key():
    key = os.urandom(24).encode('hex')
    return (key)


SECRET_KEY = os.getenv('SECRET_KEY', make_secret_key())
