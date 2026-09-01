from django.urls import path
from .views import RequestOTPView, VerifyOTPView, UserProfileView

urlpatterns = [
    path('otp/request/', RequestOTPView.as_view(), name='otp_request'),
    path('otp/verify/', VerifyOTPView.as_view(), name='otp_verify'),
    path('me/', UserProfileView.as_view(), name='user_profile'),
]
