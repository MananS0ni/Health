"""
Main URL Configuration for Digital Health Record Platform API.
"""

from django.contrib import admin
from django.urls import path, include
from django.http import JsonResponse


def health_check(request):
    return JsonResponse({
        'status': 'online',
        'platform': 'Digital Health Record Platform API',
        'version': '1.0.0',
        'auth_mode': 'Email SMTP OTP',
    })


from apps.reports.views import GlobalSearchView

urlpatterns = [
    path('', health_check, name='api-root'),
    path('admin/', admin.site.urls),
    path('api/auth/', include('apps.accounts.urls')),
    path('api/patients/', include('apps.patients.urls')),
    path('api/reports/', include('apps.reports.urls')),
    path('api/doctor/', include('apps.doctor.urls')),
    path('api/hospital/', include('apps.hospital.urls')),
    path('api/lab/', include('apps.lab.urls')),
    path('api/search/', GlobalSearchView.as_view(), name='global-search'),
]
