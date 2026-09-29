from django.urls import path
from . import views
urlpatterns = [
    path('services/',views.ServicesView.as_view()),
    path('slots/',views.SlotsView.as_view()),
    path('campaigns/',views.CampaignsView.as_view()),
    path('quote/',views.QuoteView.as_view()),
    path('bookings/',views.BookingsView.as_view()),
    path('bookings/<uuid:booking_id>/action/',views.BookingActionView.as_view()),
    path('bookings/<uuid:booking_id>/review/',views.ReviewView.as_view()),
    path('referrals/',views.ReferralsView.as_view()),
    path('notifications/',views.NotificationsView.as_view()),
    path('moderation/',views.ModerationView.as_view()),
]
