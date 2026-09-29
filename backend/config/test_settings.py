"""Isolated test configuration: never sends real email or uses clinical storage."""
import os
os.environ['DEBUG'] = 'True'
os.environ.setdefault('SECRET_KEY', 'tests-only-key-not-for-deployment-' * 3)
from .settings import *
DATABASES = {'default': {'ENGINE': 'django.db.backends.sqlite3', 'NAME': ':memory:'}}
EMAIL_BACKEND = 'django.core.mail.backends.locmem.EmailBackend'
ALLOWED_HOSTS = ['testserver', 'localhost', '127.0.0.1']
PASSWORD_HASHERS = ['django.contrib.auth.hashers.MD5PasswordHasher']
MEDIA_ROOT = BASE_DIR.parent / 'audit' / 'test_media'
REST_FRAMEWORK = {**REST_FRAMEWORK, 'DEFAULT_THROTTLE_RATES': {'otp_send':'10000/hour', 'otp_verify':'10000/hour'}}
