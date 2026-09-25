from django.urls import path
from .views import (
    LabPendingOrdersView,
    LabPublishReportView,
    LabBatchUploadView,
    LabDirectUploadView,
    LabPatientListView,
)

urlpatterns = [
    path('orders/', LabPendingOrdersView.as_view(), name='lab-orders'),
    path('orders/<str:order_id>/publish/', LabPublishReportView.as_view(), name='lab-publish-report'),
    path('batch-upload/', LabBatchUploadView.as_view(), name='lab-batch-upload'),
    path('upload-report/', LabDirectUploadView.as_view(), name='lab-upload-report'),
    path('patients/', LabPatientListView.as_view(), name='lab-patients'),
]
