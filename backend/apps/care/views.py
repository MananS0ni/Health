from datetime import timedelta
from django.db import transaction
from django.db.models import Avg, Count, Q, F, OuterRef, Subquery, IntegerField, Value
from django.db.models.functions import Coalesce
from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework import serializers
from rest_framework.exceptions import PermissionDenied, ValidationError
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from apps.accounts.permissions import VerifiedProfessional, IsPlatformAdmin, roles_for, resolve_patient, require_patient_access
from .models import Service, Slot, Campaign, Booking, Referral, Notification, Review
from .serializers import ServiceSerializer, SlotSerializer, CampaignSerializer, BookingSerializer, NotificationSerializer
from .services import price_booking, reserve, change_booking, notify, audit


def professional(request):
    if not VerifiedProfessional().has_permission(request, None):
        raise PermissionDenied('Reviewed professional credentials are required.')


class ServicesView(APIView):
    permission_classes = [IsAuthenticated]
    def get(self, request):
        qs = Service.objects.select_related('provider')
        if request.query_params.get('mine') == 'true':
            professional(request)
            qs = qs.filter(provider=request.user)
        else:
            qs = qs.filter(active=True, provider__professional_verified=True, provider__is_active=True)
        for field in ('kind', 'specialty', 'location'):
            if request.query_params.get(field):
                qs = qs.filter(**{field+'__icontains': request.query_params[field]})
        if request.query_params.get('search'):
            query = request.query_params['search'][:150]
            qs = qs.filter(Q(name__icontains=query)|Q(provider__full_name__icontains=query)|Q(specialty__icontains=query))
        available = Slot.objects.filter(service=OuterRef('pk'),starts_at__gt=timezone.now(),reserved__lt=F('capacity')).order_by().values('service').annotate(count=Count('pk')).values('count')
        qs = qs.annotate(rating=Avg('slots__bookings__review__rating',filter=Q(slots__bookings__review__published=True)), review_count=Count('slots__bookings__review',filter=Q(slots__bookings__review__published=True),distinct=True), available_slots=Coalesce(Subquery(available,output_field=IntegerField()),Value(0))).order_by('-available_slots','-rating','name','pk')[:100]
        data=[]
        for service in qs:
            item=ServiceSerializer(service).data
            item.update(rating=service.rating, review_count=service.review_count, available_slots=service.available_slots)
            data.append(item)
        return Response(data)
    def post(self, request):
        professional(request)
        serializer=ServiceSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        role={'consultation':'doctor','test':'lab','hospital':'hospital'}[serializer.validated_data['kind']]
        if role not in roles_for(request.user): raise PermissionDenied('Service does not match your approved role.')
        service=serializer.save(provider=request.user)
        audit(request.user,'service.created',service.pk)
        return Response(serializer.data,status=201)


class SlotsView(APIView):
    permission_classes=[IsAuthenticated]
    def get(self,request):
        service=get_object_or_404(Service,pk=serializers.IntegerField(min_value=1).run_validation(request.query_params.get('service')))
        if service.provider_id != request.user.pk and (not service.active or not service.provider.professional_verified or not service.provider.is_active):
            raise PermissionDenied()
        return Response(SlotSerializer(service.slots.filter(starts_at__gt=timezone.now(),reserved__lt=F('capacity')).order_by('starts_at')[:200],many=True).data)
    def post(self,request):
        professional(request)
        serializer=SlotSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        if serializer.validated_data['service'].provider_id != request.user.pk: raise PermissionDenied()
        serializer.save()
        return Response(serializer.data,status=201)


class CampaignsView(APIView):
    permission_classes=[IsAuthenticated]
    def get(self,request):
        qs=Campaign.objects.select_related('service')
        if request.query_params.get('mine')=='true':
            professional(request)
            qs=qs.filter(service__provider=request.user)
        else:
            qs=qs.filter(active=True,partner_approved=True,starts_at__lte=timezone.now(),ends_at__gt=timezone.now(),service__active=True,service__provider__professional_verified=True,service__provider__is_active=True,reserved__lt=F('total_limit'))
        if request.query_params.get('service'):
            qs=qs.filter(service_id=serializers.IntegerField(min_value=1).run_validation(request.query_params['service']))
        return Response(CampaignSerializer(qs.order_by('ends_at')[:100],many=True).data)
    @transaction.atomic
    def post(self,request):
        professional(request)
        serializer=CampaignSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        if serializer.validated_data['service'].provider_id != request.user.pk: raise PermissionDenied()
        campaign=serializer.save()
        audit(request.user,'campaign.created',campaign.pk,partner_approved=campaign.partner_approved,terms=campaign.terms,funded_by=campaign.funded_by)
        return Response(serializer.data,status=201)


class BookingInput(serializers.Serializer):
    slot=serializers.IntegerField(min_value=1)
    promo_code=serializers.CharField(max_length=40,required=False,allow_blank=True,default='')
    referral=serializers.UUIDField(required=False,allow_null=True,default=None)
    request_key=serializers.UUIDField(required=False)


class QuoteView(APIView):
    permission_classes=[IsAuthenticated]
    def post(self,request):
        serializer=BookingInput(data=request.data)
        serializer.is_valid(raise_exception=True)
        data=serializer.validated_data
        slot=get_object_or_404(Slot.objects.select_related('service__provider'),pk=data['slot'])
        campaign,referral,original,discount,payable=price_booking(request.user,slot,data['promo_code'],data['referral'])
        return Response({'original_price':str(original),'discount':str(discount),'payable':str(payable),'currency':'INR','terms':campaign.terms if campaign else '', 'availability_reserved':False})


class BookingsView(APIView):
    permission_classes=[IsAuthenticated]
    def get(self,request):
        qs=Booking.objects.select_related('slot__service__provider','patient')
        if request.query_params.get('context')=='professional':
            professional(request)
            qs=qs.filter(slot__service__provider=request.user)
        else: qs=qs.filter(patient=request.user)
        return Response(BookingSerializer(qs.order_by('-created_at')[:200],many=True).data)
    def post(self,request):
        serializer=BookingInput(data=request.data)
        serializer.is_valid(raise_exception=True)
        data=serializer.validated_data
        if 'request_key' not in data: raise ValidationError({'request_key':'A UUID retry key is required.'})
        booking,created=reserve(request.user,data['slot'],data['request_key'],data['promo_code'],data['referral'])
        return Response(BookingSerializer(booking).data,status=201 if created else 200)


class BookingActionView(APIView):
    permission_classes=[IsAuthenticated]
    def post(self,request,booking_id):
        return Response(BookingSerializer(change_booking(request.user,booking_id,request.data.get('action'))).data)


class ReferralsView(APIView):
    permission_classes=[IsAuthenticated]
    def get(self,request):
        qs=Referral.objects.filter(patient=request.user,expires_at__gt=timezone.now()).select_related('service__provider')
        return Response([{'id':str(r.pk),'service':ServiceSerializer(r.service).data,'expires_at':r.expires_at,'note':r.note} for r in qs[:100]])
    @transaction.atomic
    def post(self,request):
        professional(request)
        patient=resolve_patient(request.data.get('patient'))
        require_patient_access(request.user,patient)
        service=get_object_or_404(Service,pk=serializers.IntegerField(min_value=1).run_validation(request.data.get('service')),active=True,provider__professional_verified=True,provider__is_active=True)
        days=serializers.IntegerField(min_value=1,max_value=30).run_validation(request.data.get('valid_days',7))
        note=serializers.CharField(max_length=500,allow_blank=True).run_validation(request.data.get('note',''))
        referral=Referral.objects.create(referrer=request.user,patient=patient,service=service,expires_at=timezone.now()+timedelta(days=days),note=note)
        notify(patient,'A provider has recommended a service for you.','referral',referral.pk)
        audit(request.user,'referral.created',referral.pk)
        return Response({'id':str(referral.pk),'expires_at':referral.expires_at},status=201)


class NotificationsView(APIView):
    permission_classes=[IsAuthenticated]
    def get(self,request):
        return Response(NotificationSerializer(Notification.objects.filter(user=request.user)[:200],many=True).data)
    def patch(self,request):
        identifier=serializers.IntegerField(min_value=1).run_validation(request.data.get('id'))
        item=get_object_or_404(Notification,user=request.user,pk=identifier)
        item.read=True
        item.save(update_fields=['read'])
        return Response(NotificationSerializer(item).data)


class ReviewView(APIView):
    permission_classes=[IsAuthenticated]
    @transaction.atomic
    def post(self,request,booking_id):
        booking=get_object_or_404(Booking.objects.select_for_update(),pk=booking_id,patient=request.user,status='completed')
        if Review.objects.filter(booking=booking).exists(): raise ValidationError('Feedback already submitted.')
        rating=serializers.IntegerField(min_value=1,max_value=5).run_validation(request.data.get('rating'))
        comment=serializers.CharField(max_length=2000,allow_blank=True).run_validation(request.data.get('comment',''))
        review=Review.objects.create(booking=booking,rating=rating,comment=comment)
        audit(request.user,'review.submitted',review.pk)
        return Response({'id':review.pk,'status':'pending moderation'},status=201)


class ModerationView(APIView):
    permission_classes=[IsPlatformAdmin]
    def get(self,request):
        return Response(list(Review.objects.filter(published=False).values('id','rating','comment','booking_id')[:100]))
    @transaction.atomic
    def post(self,request):
        review=get_object_or_404(Review,pk=serializers.IntegerField(min_value=1).run_validation(request.data.get('id')))
        review.published=serializers.BooleanField().run_validation(request.data.get('published'))
        reason=serializers.CharField(max_length=500).run_validation(request.data.get('reason'))
        review.save(update_fields=['published'])
        audit(request.user,'review.moderated',review.pk,published=review.published,reason=reason)
        return Response({'id':review.pk,'published':review.published})
