from django.urls import path
from .views import (
    DoctorAppointmentListCreateView,
    DoctorPatientSearchView,
    DoctorPatientDetailChartView,
    DoctorPrescriptionCreateView,
    DoctorRequestConsentView,
    DoctorDirectoryView,
    DoctorIncomingConsentListView,
    DoctorIncomingConsentActionView,
)

urlpatterns = [
    path('directory/', DoctorDirectoryView.as_view(), name='doctor-directory'),
    path('appointments/', DoctorAppointmentListCreateView.as_view(), name='doctor-appointments'),
    path('patients/', DoctorPatientSearchView.as_view(), name='doctor-patient-search'),
    path('patients/<str:patient_id>/chart/', DoctorPatientDetailChartView.as_view(), name='doctor-patient-chart'),
    path('prescriptions/', DoctorPrescriptionCreateView.as_view(), name='doctor-prescriptions'),
    path('consent/request/', DoctorRequestConsentView.as_view(), name='doctor-consent-request'),
    path('incoming-requests/', DoctorIncomingConsentListView.as_view(), name='doctor-incoming-requests'),
    path('incoming-requests/<str:consent_id>/action/', DoctorIncomingConsentActionView.as_view(), name='doctor-incoming-request-action'),
]
