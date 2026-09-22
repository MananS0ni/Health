from django.contrib import admin
from .models import User, EmailOTP, DoctorProfile, LabProfile, HospitalProfile

@admin.register(User)
class UserAdmin(admin.ModelAdmin):
    list_display = ('email', 'full_name', 'role', 'phone_number', 'is_verified', 'created_at')
    list_filter = ('role', 'is_verified', 'is_staff')
    search_fields = ('email', 'full_name', 'phone_number')
    ordering = ('-created_at',)

@admin.register(EmailOTP)
class EmailOTPAdmin(admin.ModelAdmin):
    list_display = ('email', 'otp', 'is_used', 'created_at', 'expires_at')
    list_filter = ('is_used', 'created_at')
    search_fields = ('email', 'otp')
    ordering = ('-created_at',)

@admin.register(DoctorProfile)
class DoctorProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'specialization', 'registration_number', 'clinic_name')
    search_fields = ('user__email', 'user__full_name', 'registration_number', 'specialization')

@admin.register(LabProfile)
class LabProfileAdmin(admin.ModelAdmin):
    list_display = ('lab_name', 'user', 'license_number')
    search_fields = ('lab_name', 'user__email', 'license_number')

@admin.register(HospitalProfile)
class HospitalProfileAdmin(admin.ModelAdmin):
    list_display = ('hospital_name', 'user', 'registration_id')
    search_fields = ('hospital_name', 'user__email', 'registration_id')
