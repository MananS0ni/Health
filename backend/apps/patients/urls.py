from django.urls import path
from .views import PatientProfileDetailView, EmergencyCardView

urlpatterns = [
    path('me/', PatientProfileDetailView.as_view(), name='patient_profile_me'),
    path('emergency-card/', EmergencyCardView.as_view(), name='emergency_card'),
]
