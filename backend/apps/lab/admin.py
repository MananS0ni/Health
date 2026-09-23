from django.contrib import admin
from .models import LabTestOrder

@admin.register(LabTestOrder)
class LabTestOrderAdmin(admin.ModelAdmin):
    list_display = ('order_id', 'patient_name', 'test_name', 'category', 'status', 'order_date')
    list_filter = ('status', 'category', 'order_date')
    search_fields = ('patient_name', 'order_id', 'test_name')
