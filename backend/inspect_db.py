import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from apps.accounts.models import User, EmailOTP, DoctorProfile, LabProfile, HospitalProfile

print("=== DATABASE CONNECTION ===")
from django.db import connection
print("Engine:", connection.settings_dict['ENGINE'])
print("Database File:", connection.settings_dict['NAME'])

print("\n=== USERS IN DATABASE ===")
users = User.objects.all()
print(f"Total Users: {users.count()}")
for u in users:
    print(f" - Email: {u.email} | Name: '{u.full_name}' | Roles: {u.roles} | Verified: {u.is_verified}")

print("\n=== GENERATED OTPS IN DATABASE ===")
otps = EmailOTP.objects.order_by('-created_at')[:5]
print(f"Recent OTPs count: {EmailOTP.objects.count()}")
for o in otps:
    print(f" - Email: {o.email} | OTP: {o.otp} | Created: {o.created_at} | Used: {o.is_used}")
