from django.contrib import admin
from .models import AuditEvent, Booking, Campaign, Notification, Referral, Review, Service, Slot

@admin.register(AuditEvent)
class AuditEventAdmin(admin.ModelAdmin):
    list_display = ('created_at','actor','action','object_id')
    list_filter = ('action','created_at')
    search_fields = ('object_id','actor__email')
    readonly_fields = ('actor','action','object_id','detail','created_at')
    def has_add_permission(self, request): return False
    def has_change_permission(self, request, obj=None): return False
    def has_delete_permission(self, request, obj=None): return False

admin.site.register([Booking,Campaign,Notification,Referral,Review,Service,Slot])
