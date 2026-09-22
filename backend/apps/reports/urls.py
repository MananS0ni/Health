from django.urls import path
from .views import (
    MedicalRecordListCreateView,
    LabReportListCreateView,
    TimelineView
)

urlpatterns = [
    path('records/', MedicalRecordListCreateView.as_view(), name='record-list-create'),
    path('lab/', LabReportListCreateView.as_view(), name='lab-list-create'),
    path('lab-reports/', LabReportListCreateView.as_view(), name='lab-reports-list-create'),
    path('timeline/', TimelineView.as_view(), name='health-timeline'),
]
