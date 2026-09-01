from django.db import models
from django.contrib.auth.models import AbstractUser, BaseUserManager

class CustomUserManager(BaseUserManager):
    def create_user(self, phone, password=None, **extra_fields):
        if not phone:
            raise ValueError('Mobile phone number is required')
        extra_fields.setdefault('username', phone)
        user = self.model(phone=phone, **extra_fields)
        if password:
            user.set_password(password)
        else:
            user.set_unusable_password()
        user.save(using=self._db)
        return user

    def create_superuser(self, phone, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('role', 'ADMIN')
        return self.create_user(phone, password, **extra_fields)

class CustomUser(AbstractUser):
    ROLE_CHOICES = (
        ('PATIENT', 'Patient'),
        ('DOCTOR', 'Doctor'),
        ('LAB', 'Diagnostic Lab'),
        ('HOSPITAL', 'Hospital Staff'),
        ('ADMIN', 'System Administrator'),
    )

    phone = models.CharField(max_length=20, unique=True)
    abha_id = models.CharField(max_length=100, null=True, blank=True)
    full_name = models.CharField(max_length=150, default='Patient')
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='PATIENT')
    is_verified = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    objects = CustomUserManager()

    USERNAME_FIELD = 'phone'
    REQUIRED_FIELDS = []

    def __str__(self):
        return f"{self.full_name} ({self.phone}) - {self.role}"
