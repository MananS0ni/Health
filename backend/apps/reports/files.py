from apps.care.services import audit
import csv
import io
import zipfile
from pathlib import Path
from django.core import signing
from django.http import FileResponse
from django.shortcuts import get_object_or_404
from django.urls import reverse
from rest_framework import permissions, serializers
from rest_framework.views import APIView
from rest_framework.response import Response
from apps.accounts.models import User
from apps.accounts.permissions import require_patient_access
from .models import MedicalRecord, LabReport

def validate_document(file, allow_csv=False):
    if not file:
        return file
    if file.size > 10 * 1024 * 1024 or file.size == 0:
        raise serializers.ValidationError('File must be nonempty and at most 10 MB.')
    ext = Path(file.name).suffix.lower()
    signature = file.read(8)
    file.seek(0)
    valid = ((ext == '.pdf' and signature.startswith(b'%PDF-')) or
             (ext in ('.jpg','.jpeg') and signature.startswith(b'\xff\xd8\xff')) or
             (ext == '.png' and signature == b'\x89PNG\r\n\x1a\n') or
             (ext == '.doc' and signature == b'\xd0\xcf\x11\xe0\xa1\xb1\x1a\xe1'))
    if ext == '.docx':
        try:
            with zipfile.ZipFile(file) as archive:
                valid = 'word/document.xml' in archive.namelist() and sum(i.file_size for i in archive.infolist()) < 30*1024*1024
        except (zipfile.BadZipFile, OSError):
            valid = False
        finally:
            file.seek(0)
    if allow_csv and ext == '.csv':
        try:
            file.read().decode('utf-8-sig')
            valid = True
        except UnicodeDecodeError:
            valid = False
        finally:
            file.seek(0)
    if not valid:
        raise serializers.ValidationError('Unsupported or invalid document. Use PDF, Word, JPEG or PNG.')
    return file

def resolve_document(kind, identifier):
    if kind == 'records':
        return get_object_or_404(MedicalRecord, record_id=identifier)
    if kind == 'reports':
        return get_object_or_404(LabReport, report_id=identifier)
    raise serializers.ValidationError('Invalid document type.')

class DocumentLinkView(APIView):
    def get(self, request, kind, identifier):
        document = resolve_document(kind, identifier)
        require_patient_access(request.user, document.patient)
        if not document.file_url:
            return Response({'error':'No document attached.'}, status=404)
        audit(request.user,'document.link_issued',identifier,kind=kind)
        ticket = signing.dumps({'actor':str(request.user.pk),'kind':kind,'id':str(identifier)}, salt='clinical-download')
        return Response({'url':request.build_absolute_uri(reverse('document-download'))+'?ticket='+ticket})

class DocumentDownloadView(APIView):
    permission_classes = [permissions.AllowAny]
    authentication_classes = []
    def get(self, request):
        try:
            data = signing.loads(request.query_params.get('ticket',''), salt='clinical-download', max_age=60)
        except signing.BadSignature:
            return Response({'error':'Download link expired or invalid.'}, status=403)
        actor = get_object_or_404(User, pk=data['actor'], is_active=True)
        document = resolve_document(data['kind'], data['id'])
        require_patient_access(actor, document.patient)
        if not document.file_url:
            return Response({'error':'No document attached.'}, status=404)
        audit(actor,'document.downloaded',data['id'],kind=data['kind'])
        response = FileResponse(document.file_url.open('rb'), as_attachment=True, filename=Path(document.file_url.name).name)
        response['Cache-Control'] = 'no-store'
        response['X-Content-Type-Options'] = 'nosniff'
        return response
