from django.urls import path
from .views import LabPendingOrdersView, LabPublishReportView, LabBatchUploadView

urlpatterns = [
    path('orders/', LabPendingOrdersView.as_view(), name='lab-orders'),
    path('orders/<str:order_id>/publish/', LabPublishReportView.as_view(), name='lab-publish-report'),
    path('batch-upload/', LabBatchUploadView.as_view(), name='lab-batch-upload'),
]
