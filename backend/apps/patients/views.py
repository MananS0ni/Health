from rest_framework import status, permissions
from rest_framework.views import APIView
from rest_framework.response import Response

from apps.accounts.models import User
from .models import PatientProfile, HealthVital, FamilyMember
from .serializers import (
    PatientProfileSerializer,
    HealthVitalSerializer,
    FamilyMemberSerializer
)


def get_patient_user(request):
    return request.user


class PatientMeView(APIView):
    """
    GET /api/patients/me/ — Retrieve the current patient profile, emergency details, allergies.
    PATCH /api/patients/me/ — Update blood group, allergies, conditions, emergency contacts.
    """
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        user = get_patient_user(request)
        profile, _ = PatientProfile.objects.get_or_create(user=user)
        serializer = PatientProfileSerializer(profile)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def patch(self, request):
        user = get_patient_user(request)
        profile, _ = PatientProfile.objects.get_or_create(user=user)
        serializer = PatientProfileSerializer(profile, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class FamilyMemberListCreateView(APIView):
    """
    GET /api/patients/family/ — List all family members linked to patient.
    POST /api/patients/family/ — Add a dependent / family member.
    """
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        user = get_patient_user(request)
        members = FamilyMember.objects.filter(patient=user)
        serializer = FamilyMemberSerializer(members, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def post(self, request):
        user = get_patient_user(request)
        serializer = FamilyMemberSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(patient=user)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class FamilyMemberDetailView(APIView):
    """
    DELETE /api/patients/family/<id>/ — Remove a linked family member.
    """
    permission_classes = [permissions.IsAuthenticated]

    def delete(self, request, member_id):
        user = get_patient_user(request)
        lookup = FamilyMember.objects.filter(patient=user)
        member = lookup.filter(member_id=member_id).first()
        if not member and member_id.isdigit():
            member = lookup.filter(id=int(member_id)).first()
        if not member:
            return Response({'error': 'Family member not found.'}, status=status.HTTP_404_NOT_FOUND)
        member.delete()
        return Response({'success': True, 'message': 'Family member removed.'}, status=status.HTTP_204_NO_CONTENT)


class HealthVitalsView(APIView):
    """
    GET /api/patients/vitals/ — Get latest recorded health vitals.
    POST /api/patients/vitals/ — Record a new vital metric.
    """
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        user = get_patient_user(request)
        vitals = HealthVital.objects.filter(patient=user)[:20]
        serializer = HealthVitalSerializer(vitals, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def post(self, request):
        user = get_patient_user(request)
        serializer = HealthVitalSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(patient=user)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
