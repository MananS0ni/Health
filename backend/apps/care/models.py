import uuid
from django.conf import settings
from django.db import models
from django.db.models import Q

class Service(models.Model):
    provider = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT, related_name='bookable_services')
    name = models.CharField(max_length=160)
    kind = models.CharField(max_length=20, choices=[('consultation','Consultation'),('test','Lab test'),('hospital','Hospital appointment')])
    specialty = models.CharField(max_length=100, blank=True)
    location = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    price = models.DecimalField(max_digits=10, decimal_places=2)
    active = models.BooleanField(default=False)
    class Meta:
        constraints = [models.CheckConstraint(condition=Q(price__gte=0), name='care_nonnegative_price')]

class Slot(models.Model):
    service = models.ForeignKey(Service, on_delete=models.PROTECT, related_name='slots')
    starts_at = models.DateTimeField()
    capacity = models.PositiveSmallIntegerField(default=1)
    reserved = models.PositiveSmallIntegerField(default=0)
    class Meta:
        constraints = [models.UniqueConstraint(fields=['service','starts_at'],name='care_unique_service_slot'),models.CheckConstraint(condition=Q(capacity__gte=1)&Q(reserved__lte=models.F('capacity')),name='care_slot_capacity')]

class Campaign(models.Model):
    service = models.ForeignKey(Service, on_delete=models.PROTECT, related_name='campaigns')
    code = models.CharField(max_length=40, unique=True)
    kind = models.CharField(max_length=12, choices=[('percent','Percentage'),('fixed','Fixed amount'),('free','Genuinely free')])
    value = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    max_discount = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    total_limit = models.PositiveIntegerField()
    reserved = models.PositiveIntegerField(default=0)
    per_patient_limit = models.PositiveSmallIntegerField(default=1)
    starts_at = models.DateTimeField()
    ends_at = models.DateTimeField()
    active = models.BooleanField(default=False)
    requires_referral = models.BooleanField(default=False)
    funded_by = models.CharField(max_length=150)
    terms = models.TextField()
    partner_approved = models.BooleanField(default=False)
    class Meta:
        constraints = [models.CheckConstraint(condition=Q(total_limit__gte=1)&Q(per_patient_limit__gte=1)&Q(reserved__lte=models.F('total_limit')),name='care_campaign_limits')]

class Referral(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    referrer = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT, related_name='issued_referrals')
    patient = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT, related_name='received_referrals')
    service = models.ForeignKey(Service, on_delete=models.PROTECT)
    expires_at = models.DateTimeField()
    note = models.CharField(max_length=500, blank=True)

class Booking(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    patient = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT, related_name='bookings')
    slot = models.ForeignKey(Slot, on_delete=models.PROTECT, related_name='bookings')
    campaign = models.ForeignKey(Campaign, null=True, blank=True, on_delete=models.PROTECT)
    referral = models.ForeignKey(Referral, null=True, blank=True, on_delete=models.PROTECT)
    original_price = models.DecimalField(max_digits=10, decimal_places=2)
    discount = models.DecimalField(max_digits=10, decimal_places=2)
    payable = models.DecimalField(max_digits=10, decimal_places=2)
    status = models.CharField(max_length=12, choices=[('confirmed','Confirmed'),('cancelled','Cancelled'),('completed','Completed')], default='confirmed')
    request_key = models.UUIDField()
    created_at = models.DateTimeField(auto_now_add=True)
    class Meta:
        constraints = [models.UniqueConstraint(fields=['patient','request_key'],name='care_booking_idempotency'),models.CheckConstraint(condition=Q(payable__gte=0)&Q(discount__gte=0),name='care_booking_amounts')]

class Notification(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='notifications')
    message = models.CharField(max_length=500)
    kind = models.CharField(max_length=30)
    reference = models.CharField(max_length=100, blank=True)
    read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    class Meta:
        ordering = ['-created_at']

class Review(models.Model):
    booking = models.OneToOneField(Booking, on_delete=models.PROTECT, related_name='review')
    rating = models.PositiveSmallIntegerField()
    comment = models.CharField(max_length=2000, blank=True)
    published = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    class Meta:
        constraints = [models.CheckConstraint(condition=Q(rating__gte=1)&Q(rating__lte=5),name='care_review_rating')]

class AuditEvent(models.Model):
    actor = models.ForeignKey(settings.AUTH_USER_MODEL, null=True, on_delete=models.SET_NULL)
    action = models.CharField(max_length=80)
    object_id = models.CharField(max_length=100)
    detail = models.JSONField(default=dict)
    created_at = models.DateTimeField(auto_now_add=True)
