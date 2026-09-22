from rest_framework.test import APITestCase
from rest_framework import status
from apps.accounts.models import User, EmailOTP, Role


class AuthFlowTests(APITestCase):
    def test_complete_auth_flow(self):
        # 1. Request OTP
        resp = self.client.post('/api/auth/request-otp/', {'email': 'dr.patel@health.com'}, format='json')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertTrue(resp.json()['success'])

        otp_obj = EmailOTP.objects.filter(email='dr.patel@health.com', is_used=False).first()
        self.assertIsNotNone(otp_obj)

        # 2. Verify OTP
        resp_verify = self.client.post('/api/auth/verify-otp/', {
            'email': 'dr.patel@health.com',
            'otp': otp_obj.otp
        }, format='json')
        self.assertEqual(resp_verify.status_code, status.HTTP_200_OK)
        self.assertTrue(resp_verify.json()['success'])
        self.assertIn('tokens', resp_verify.json())

        access_token = resp_verify.json()['tokens']['access']
        self.client.credentials(HTTP_AUTHORIZATION='Bearer ' + access_token)

        # 3. Register Profile
        resp_profile = self.client.post('/api/auth/register-profile/', {
            'full_name': 'Dr. Max Patel',
            'phone_number': '9876543210',
            'role': 'doctor',
            'registration_number': 'MCI-847291',
            'specialization': 'Cardiology',
            'clinic_name': 'Apollo Heart Institute'
        }, format='json')
        self.assertEqual(resp_profile.status_code, status.HTTP_200_OK)

        # 4. Get Current User
        resp_me = self.client.get('/api/auth/me/')
        self.assertEqual(resp_me.status_code, status.HTTP_200_OK)
        user_data = resp_me.json()['user']
        self.assertEqual(user_data['full_name'], 'Dr. Max Patel')
        self.assertEqual(user_data['role'], 'doctor')
        self.assertEqual(user_data['doctor_profile']['specialization'], 'Cardiology')
