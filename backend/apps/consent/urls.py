from django.urls import path
from .views import ConsentListCreateView, ConsentRevokeView

urlpatterns = [
    path('', ConsentListCreateView.as_view(), name='consent_list_create'),
    path('<str:consent_id>/revoke/', ConsentRevokeView.as_view(), name='consent_revoke'),
]
