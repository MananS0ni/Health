from django.urls import path
from .views import RequestOTPView, VerifyOTPView, RegisterProfileView, MeView, LogoutView
from rest_framework_simplejwt.views import TokenRefreshView

urlpatterns = [
    path('refresh/', TokenRefreshView.as_view(), name='token-refresh'),
    path('logout/', LogoutView.as_view(), name='logout'),
    path('request-otp/', RequestOTPView.as_view(), name='request-otp'),
    path('verify-otp/', VerifyOTPView.as_view(), name='verify-otp'),
    path('register-profile/', RegisterProfileView.as_view(), name='register-profile'),
    path('me/', MeView.as_view(), name='auth-me'),
]
