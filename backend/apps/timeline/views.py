from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import permissions
from .models import TimelineEvent
from .serializers import TimelineEventSerializer
from apps.accounts.models import CustomUser

class TimelineListView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        user = CustomUser.objects.first()
        if not user:
            user = CustomUser.objects.create(phone='+91 9876543210', full_name='Manan Soni', abha_id='manan.soni@abha')

        if TimelineEvent.objects.count() == 0:
            TimelineEvent.objects.create(
                patient=user,
                title='Blood Sample Collection & Lipid Screening',
                provider='Dr. Lal PathLabs (Delhi Central Branch)',
                event_type='Diagnostic Test',
                event_date='August 04, 2026',
                event_time='09:30 AM',
                status='Report Issued & Auto-Imported',
                details='Fasted blood sample submitted for Complete Blood Count and Lipid Panel.'
            )
            TimelineEvent.objects.create(
                patient=user,
                title='Routine Cardiology Follow-up',
                provider='Max Healthcare — Dr. Ritu Verma',
                event_type='Doctor Consultation',
                event_date='July 28, 2026',
                event_time='04:15 PM',
                status='Prescription Added to Locker',
                details='Vitals stable. ECG review normal. E-prescription issued and linked to ABHA ID.'
            )
            TimelineEvent.objects.create(
                patient=user,
                title='Chest Radiography (Digital X-Ray)',
                provider='Apollo Diagnostics Imaging Unit',
                event_type='Radiology',
                event_date='June 15, 2026',
                event_time='11:00 AM',
                status='OCR Verified',
                details='PA View Chest X-Ray completed. Zero abnormality identified.'
            )

        events = TimelineEvent.objects.filter(patient=user).order_by('-id')
        return Response({
            "count": events.count(),
            "results": TimelineEventSerializer(events, many=True).data
        })
