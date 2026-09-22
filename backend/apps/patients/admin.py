from django.contrib import admin
from .models import PatientProfile, HealthVital, FamilyMember

@admin.register(PatientProfile)
class PatientProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'blood_group', 'gender', 'date_of_birth')
    search_fields = ('user__email', 'user__full_name', 'blood_group')

@admin.register(HealthVital)
class HealthVitalAdmin(admin.ModelAdmin):
    list_display = ('patient', 'vital_type', 'value', 'unit', 'status', 'recorded_at')
    list_filter = ('vital_type', 'recorded_at')
    search_fields = ('patient__email', 'vital_type')

@admin.register(FamilyMember)
class FamilyMemberAdmin(admin.ModelAdmin):
    list_display = ('full_name', 'relationship', 'patient', 'blood_group', 'created_at')
    search_fields = ('full_name', 'patient__email', 'relationship')
