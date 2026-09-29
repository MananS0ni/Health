from django.urls import path
from .files import DocumentLinkView, DocumentDownloadView
from .views import (
    MedicalRecordListCreateView,
    LabReportListCreateView,
    PatientDocumentDeleteView,
    TimelineView
)

urlpatterns = [
    path('<str:kind>/<str:identifier>/', PatientDocumentDeleteView.as_view()),
    path('files/<str:kind>/<str:identifier>/', DocumentLinkView.as_view()),
    path('download/', DocumentDownloadView.as_view(), name='document-download'),
    path('records/', MedicalRecordListCreateView.as_view(), name='record-list-create'),
    path('lab/', LabReportListCreateView.as_view(), name='lab-list-create'),
    path('lab-reports/', LabReportListCreateView.as_view(), name='lab-reports-list-create'),
    path('timeline/', TimelineView.as_view(), name='health-timeline'),
]
