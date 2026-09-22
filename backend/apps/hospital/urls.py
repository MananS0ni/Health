from django.urls import path
from .views import InpatientAdmissionListCreateView, InpatientDischargeView

urlpatterns = [
    path('admissions/', InpatientAdmissionListCreateView.as_view(), name='hospital-admissions'),
    path('admissions/<str:admission_id>/discharge/', InpatientDischargeView.as_view(), name='hospital-discharge'),
]
