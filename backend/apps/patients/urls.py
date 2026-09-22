from django.urls import path
from .views import (
    PatientMeView,
    FamilyMemberListCreateView,
    FamilyMemberDetailView,
    HealthVitalsView
)
from apps.doctor.views import (
    PatientConsentListView,
    PatientConsentActionView
)

urlpatterns = [
    path('me/', PatientMeView.as_view(), name='patient-me'),
    path('family/', FamilyMemberListCreateView.as_view(), name='family-list-create'),
    path('family/<str:member_id>/', FamilyMemberDetailView.as_view(), name='family-detail'),
    path('vitals/', HealthVitalsView.as_view(), name='health-vitals'),
    path('consents/', PatientConsentListView.as_view(), name='patient-consents'),
    path('consents/<str:consent_id>/action/', PatientConsentActionView.as_view(), name='patient-consent-action'),
]
