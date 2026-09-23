from django.contrib import admin
from .models import InpatientAdmission

@admin.register(InpatientAdmission)
class InpatientAdmissionAdmin(admin.ModelAdmin):
    list_display = ('admission_id', 'patient_name', 'ward', 'bed_no', 'status', 'admission_date')
    list_filter = ('status', 'ward', 'admission_date')
    search_fields = ('patient_name', 'admission_id', 'diagnosis')
