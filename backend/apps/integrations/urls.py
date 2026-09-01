from django.urls import path
from .views import LabPushWebhookView, HospitalSyncWebhookView, HealthStatusCheckView

urlpatterns = [
    path('lab/push/', LabPushWebhookView.as_view(), name='lab_push_webhook'),
    path('hospital/sync/', HospitalSyncWebhookView.as_view(), name='hospital_sync_webhook'),
    path('status/', HealthStatusCheckView.as_view(), name='health_status_check'),
]
