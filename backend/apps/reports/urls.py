from django.urls import path
from .views import LabReportListCreateView, LabReportDetailView, AISummarizeReportView

urlpatterns = [
    path('', LabReportListCreateView.as_view(), name='report_list_create'),
    path('ai-explain/', AISummarizeReportView.as_view(), name='report_ai_explain'),
    path('<str:report_id>/', LabReportDetailView.as_view(), name='report_detail'),
]
