from django.contrib import admin
from .models import Appointment, Prescription, PrescriptionItem, ConsentRequest

@admin.register(Appointment)
class AppointmentAdmin(admin.ModelAdmin):
    list_display = ('patient_name', 'doctor', 'appointment_date', 'time_slot', 'status')
    list_filter = ('appointment_date', 'status')
    search_fields = ('patient_name', 'doctor__email')

class PrescriptionItemInline(admin.TabularInline):
    model = PrescriptionItem
    extra = 1

@admin.register(Prescription)
class PrescriptionAdmin(admin.ModelAdmin):
    list_display = ('diagnosis', 'patient', 'doctor', 'prescribed_date')
    search_fields = ('diagnosis', 'patient__email', 'doctor__email')
    inlines = [PrescriptionItemInline]

@admin.register(ConsentRequest)
class ConsentRequestAdmin(admin.ModelAdmin):
    list_display = ('patient', 'doctor', 'purpose', 'status', 'valid_until', 'created_at')
    list_filter = ('status', 'created_at')
    search_fields = ('patient__email', 'doctor__email', 'purpose')
