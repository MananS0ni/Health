from django.contrib import admin
from .models import MedicalRecord, LabReport, TestParameter

@admin.register(MedicalRecord)
class MedicalRecordAdmin(admin.ModelAdmin):
    list_display = ('title', 'record_type', 'patient', 'record_date', 'doctor_name', 'facility_name')
    list_filter = ('record_type', 'record_date')
    search_fields = ('title', 'patient__email', 'doctor_name', 'facility_name')

class TestParameterInline(admin.TabularInline):
    model = TestParameter
    extra = 1

@admin.register(LabReport)
class LabReportAdmin(admin.ModelAdmin):
    list_display = ('report_name', 'patient', 'category', 'report_date', 'status')
    list_filter = ('category', 'status', 'report_date')
    search_fields = ('report_name', 'patient__email', 'facility_name')
    inlines = [TestParameterInline]
