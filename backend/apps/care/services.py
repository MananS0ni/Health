from decimal import Decimal, ROUND_HALF_UP
from django.db import transaction
from django.db.models import F
from django.utils import timezone
from django.shortcuts import get_object_or_404
from rest_framework.exceptions import ValidationError
from .models import Booking, Slot, Campaign, Referral, Notification, AuditEvent

def notify(user, message, kind, reference=''):
    preference = 'admission' if kind == 'discharge' else kind
    if user.notification_preferences.get(preference, True):
        Notification.objects.create(user=user, message=message, kind=kind, reference=str(reference))

def audit(actor, action, object_id, **detail):
    AuditEvent.objects.create(actor=actor, action=action, object_id=str(object_id), detail=detail)

def price_booking(patient, slot, code='', referral_id=None, lock=False):
    now = timezone.now()
    if not slot.service.active or not slot.service.provider.professional_verified or not slot.service.provider.is_active or slot.starts_at <= now:
        raise ValidationError('Service or slot unavailable.')
    if slot.reserved >= slot.capacity:
        raise ValidationError('Slot is full.')
    campaign, referral = None, None
    price, discount = slot.service.price, Decimal('0')
    if referral_id:
        referral = get_object_or_404(Referral, pk=referral_id, patient=patient, service=slot.service, expires_at__gt=now)
    if code:
        campaigns = Campaign.objects.select_for_update() if lock else Campaign.objects
        campaign = get_object_or_404(campaigns, code=code.strip().upper(), service=slot.service, active=True, partner_approved=True, starts_at__lte=now, ends_at__gt=now)
        if campaign.reserved >= campaign.total_limit:
            raise ValidationError('Offer fully redeemed or reserved.')
        if campaign.requires_referral and not referral:
            raise ValidationError('A valid referral for this service is required.')
        if Booking.objects.filter(patient=patient,campaign=campaign).exclude(status='cancelled').count() >= campaign.per_patient_limit:
            raise ValidationError('Your offer redemption limit has been reached.')
        if campaign.kind == 'free':
            discount = price
        elif campaign.kind == 'percent':
            discount = price*campaign.value/Decimal('100')
        else:
            discount = campaign.value
        if campaign.kind != 'free' and campaign.max_discount is not None:
            discount = min(discount, campaign.max_discount)
        discount = min(price,discount).quantize(Decimal('0.01'),rounding=ROUND_HALF_UP)
    return campaign, referral, price, discount, price-discount

@transaction.atomic
def reserve(patient, slot_id, request_key, code='', referral_id=None):
    # Serialize retries by this patient before slot/campaign reservations.
    type(patient).objects.select_for_update().get(pk=patient.pk)
    existing = Booking.objects.filter(patient=patient,request_key=request_key).first()
    if existing:
        if existing.slot_id != slot_id:
            raise ValidationError('Idempotency key was used for a different slot.')
        return existing, False
    slot = get_object_or_404(Slot.objects.select_for_update().select_related('service__provider'),pk=slot_id)
    campaign, referral, price, discount, payable = price_booking(patient,slot,code,referral_id,lock=True)
    if not Slot.objects.filter(pk=slot.pk,reserved__lt=F('capacity')).update(reserved=F('reserved')+1):
        raise ValidationError('Slot has just filled. Choose another time.')
    if campaign and not Campaign.objects.filter(pk=campaign.pk,reserved__lt=F('total_limit')).update(reserved=F('reserved')+1):
        raise ValidationError('Offer has just filled.')
    booking=Booking.objects.create(patient=patient,slot=slot,campaign=campaign,referral=referral,original_price=price,discount=discount,payable=payable,request_key=request_key)
    notify(patient,f'Booking confirmed: {slot.service.name}. Amount payable: INR {payable:.2f}.','appointment',booking.pk)
    notify(slot.service.provider,f'New booking for {slot.service.name}.','appointment',booking.pk)
    audit(patient,'booking.confirmed',booking.pk,payable=str(payable))
    return booking, True

@transaction.atomic
def change_booking(actor, booking_id, action):
    booking=get_object_or_404(Booking.objects.select_for_update().select_related('slot__service'),pk=booking_id)
    provider_id=booking.slot.service.provider_id
    if actor.pk not in (booking.patient_id,provider_id):
        from rest_framework.exceptions import PermissionDenied
        raise PermissionDenied()
    if action == 'complete':
        if actor.pk != provider_id or not actor.professional_verified:
            raise ValidationError('Only the approved provider can complete the service.')
        if booking.status == 'completed': return booking
        if booking.status != 'confirmed': raise ValidationError('Cancelled booking cannot be completed.')
        if booking.slot.starts_at > timezone.now(): raise ValidationError('A future service cannot be marked completed.')
        booking.status='completed'
    elif action == 'cancel':
        if booking.status == 'cancelled': return booking
        if booking.status != 'confirmed': raise ValidationError('Completed service cannot be cancelled.')
        booking.status='cancelled'
        Slot.objects.filter(pk=booking.slot_id,reserved__gt=0).update(reserved=F('reserved')-1)
        if booking.campaign_id:
            Campaign.objects.filter(pk=booking.campaign_id,reserved__gt=0).update(reserved=F('reserved')-1)
    else: raise ValidationError('Action must be cancel or complete.')
    booking.save(update_fields=['status'])
    notify(booking.patient,f'Booking {booking.status}: {booking.slot.service.name}.','appointment',booking.pk)
    if actor.pk == booking.patient_id:
        notify(booking.slot.service.provider,f'A booking was {booking.status}.','appointment',booking.pk)
    audit(actor,'booking.'+booking.status,booking.pk)
    return booking
