import uuid
import random
from datetime import timedelta
from django.db import models
from django.utils import timezone
from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin, BaseUserManager


class Role(models.TextChoices):
    PATIENT = 'patient', 'Patient'
    DOCTOR = 'doctor', 'Doctor'
    LAB = 'lab', 'Diagnostic Lab'
    HOSPITAL = 'hospital', 'Hospital Care'


class UserManager(BaseUserManager):
    def create_user(self, email, password=None, **extra_fields):
        if not email:
            raise ValueError('Email address is required')
        email = self.normalize_email(email)
        user = self.model(email=email, **extra_fields)
        if password:
            user.set_password(password)
        else:
            user.set_unusable_password()
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('role', Role.PATIENT)
        if not password:
            raise ValueError('Superuser must have a password.')
        return self.create_user(email, password, **extra_fields)


class User(AbstractBaseUser, PermissionsMixin):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    email = models.EmailField(unique=True, db_index=True)
    full_name = models.CharField(max_length=255, blank=True, default='')
    phone_number = models.CharField(max_length=20, blank=True, null=True)
    role = models.CharField(max_length=20, choices=Role.choices, default=Role.PATIENT)
    roles = models.JSONField(default=list, blank=True)

    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    is_verified = models.BooleanField(default=False)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    objects = UserManager()

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = []

    def __str__(self):
        return f"{self.email} ({self.get_role_display()})"


class DoctorProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='doctor_profile')
    registration_number = models.CharField(max_length=100)
    specialization = models.CharField(max_length=150)
    clinic_name = models.CharField(max_length=200, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Dr. {self.user.full_name} - {self.specialization}"


class LabProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='lab_profile')
    lab_name = models.CharField(max_length=200)
    license_number = models.CharField(max_length=100)
    address = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.lab_name


class HospitalProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='hospital_profile')
    hospital_name = models.CharField(max_length=200)
    registration_id = models.CharField(max_length=100)
    departments = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.hospital_name


class EmailOTP(models.Model):
    email = models.EmailField(db_index=True)
    otp = models.CharField(max_length=6)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    is_used = models.BooleanField(default=False)

    class Meta:
        ordering = ['-created_at']

    @classmethod
    def generate_otp(cls, email: str, validity_minutes: int = 5):
        code = str(random.randint(100000, 999999))
        expires = timezone.now() + timedelta(minutes=validity_minutes)
        # Invalidate old unused OTPs for this email
        cls.objects.filter(email=email.lower().strip(), is_used=False).update(is_used=True)
        return cls.objects.create(
            email=email.lower().strip(),
            otp=code,
            expires_at=expires
        )

    def is_valid(self) -> bool:
        return not self.is_used and timezone.now() <= self.expires_at
