from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/auth/', include('apps.accounts.urls')),
    path('api/patients/', include('apps.patients.urls')),
    path('api/reports/', include('apps.reports.urls')),
    path('api/consent/', include('apps.consent.urls')),
    path('api/timeline/', include('apps.timeline.urls')),
    path('api/integrations/', include('apps.integrations.urls')),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
