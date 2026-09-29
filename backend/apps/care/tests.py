import uuid
from decimal import Decimal
from datetime import timedelta
from django.utils import timezone
from rest_framework.test import APITestCase
from apps.accounts.models import User
from .models import Service, Slot, Campaign, Notification, Review

class BookingTests(APITestCase):
    def setUp(self):
        self.patient=User.objects.create_user(email='patient@example.com')
        self.other=User.objects.create_user(email='other@example.com')
        self.lab=User.objects.create_user(email='lab@example.com',role='lab',roles=['lab'],professional_verified=True)
        self.service=Service.objects.create(provider=self.lab,name='Basic test',kind='test',location='Ahmedabad',price=100,active=True)
        self.slot=Slot.objects.create(service=self.service,starts_at=timezone.now()+timedelta(days=1),capacity=10)
        self.campaign=Campaign.objects.create(service=self.service,code='PARTNERFREE',kind='free',total_limit=1,starts_at=timezone.now()-timedelta(hours=1),ends_at=timezone.now()+timedelta(days=2),active=True,partner_approved=True,funded_by='Test partner',terms='Selected service is free including collection and report.')
        self.client.force_authenticate(self.patient)
    def book(self,**kwargs):
        return self.client.post('/api/care/bookings/',{'slot':self.slot.pk,'request_key':str(uuid.uuid4()),**kwargs},format='json')
    def test_free_price_and_idempotency(self):
        key=str(uuid.uuid4())
        first=self.book(promo_code='partnerfree',request_key=key,payable='999')
        self.assertEqual(first.status_code,201,first.data)
        self.assertEqual(Decimal(first.data['payable']),0)
        again=self.book(promo_code='partnerfree',request_key=key)
        self.assertEqual(again.status_code,200)
        self.assertEqual(first.data['id'],again.data['id'])
        self.slot.refresh_from_db(); self.campaign.refresh_from_db()
        self.assertEqual(self.slot.reserved,1); self.assertEqual(self.campaign.reserved,1)
        self.assertEqual(Notification.objects.filter(user=self.patient).count(),1)
    def test_limits_cancellation_and_scoping(self):
        first=self.book(promo_code='PARTNERFREE')
        self.client.force_authenticate(self.other)
        self.assertEqual(self.book(promo_code='PARTNERFREE').status_code,400)
        self.assertEqual(self.client.get('/api/care/bookings/').data,[])
        self.assertEqual(self.client.get('/api/care/notifications/').data,[])
        path=f"/api/care/bookings/{first.data['id']}/action/"
        self.assertEqual(self.client.post(path,{'action':'cancel'}).status_code,403)
        self.client.force_authenticate(self.patient)
        self.assertEqual(self.client.post(path,{'action':'cancel'}).status_code,200)
        self.assertEqual(self.client.post(path,{'action':'cancel'}).status_code,200)
        self.campaign.refresh_from_db(); self.assertEqual(self.campaign.reserved,0)
        self.client.force_authenticate(self.other)
        self.assertEqual(self.book(promo_code='PARTNERFREE').status_code,201)
    def test_completed_service_required_for_feedback(self):
        result=self.book(); identifier=result.data['id']
        path=f'/api/care/bookings/{identifier}/action/'
        self.assertEqual(self.client.post(path,{'action':'complete'}).status_code,400)
        self.assertEqual(self.client.post(f'/api/care/bookings/{identifier}/review/',{'rating':5}).status_code,404)
        self.client.force_authenticate(self.lab)
        self.assertEqual(self.client.post(path,{'action':'complete'}).status_code,400)
        self.slot.starts_at=timezone.now()-timedelta(hours=1); self.slot.save()
        self.assertEqual(self.client.post(path,{'action':'complete'}).status_code,200)
        self.client.force_authenticate(self.patient)
        self.assertEqual(self.client.post(f'/api/care/bookings/{identifier}/review/',{'rating':5}).status_code,201)
        self.assertFalse(Review.objects.get().published)
        self.assertEqual(self.client.post(f'/api/care/bookings/{identifier}/review/',{'rating':5}).status_code,400)
    def test_invalid_offers(self):
        for changes in ({'partner_approved':False},{'active':False},{'ends_at':timezone.now()-timedelta(seconds=1)}):
            with self.subTest(changes=changes):
                Campaign.objects.filter(pk=self.campaign.pk).update(**changes)
                self.assertEqual(self.book(promo_code='PARTNERFREE').status_code,404)
                Campaign.objects.filter(pk=self.campaign.pk).update(partner_approved=True,active=True,ends_at=timezone.now()+timedelta(days=2))
        Campaign.objects.filter(pk=self.campaign.pk).update(requires_referral=True)
        self.assertEqual(self.book(promo_code='PARTNERFREE').status_code,400)
    def test_percentage_cap_and_capacity(self):
        Campaign.objects.filter(pk=self.campaign.pk).update(kind='percent',value=20,max_discount=10)
        result=self.book(promo_code='PARTNERFREE')
        self.assertEqual(Decimal(result.data['payable']),90)
        Slot.objects.filter(pk=self.slot.pk).update(reserved=10)
        self.assertEqual(self.book().status_code,400)
    def test_provider_ownership_and_role(self):
        self.assertEqual(self.client.post('/api/care/services/',{}).status_code,403)
        self.assertEqual(self.client.get('/api/care/bookings/?context=professional').status_code,403)
        other_lab=User.objects.create_user(email='lab2@example.com',role='lab',roles=['lab'],professional_verified=True)
        self.client.force_authenticate(other_lab)
        self.assertEqual(self.client.post('/api/care/slots/',{'service':self.service.pk,'starts_at':(timezone.now()+timedelta(days=3)).isoformat()}).status_code,403)
