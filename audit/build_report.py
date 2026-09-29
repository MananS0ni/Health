"""Build a review with verified source-line links and an actionable backlog."""
import collections
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'audit'
findings = []

def source(path, needle):
    lines = (ROOT / path).read_text(encoding='utf-8-sig').splitlines()
    line = next(i for i, text in enumerate(lines, 1) if needle in text)
    return {'path': path, 'line': line}

def add(id, severity, title, evidence, consequence, fix, acceptance, refs):
    findings.append(dict(id=id, severity=severity, title=title, evidence=evidence,
                         consequence=consequence, fix=fix, acceptance=acceptance,
                         sources=[source(*r) for r in refs]))

add('S01','Critical','Anonymous callers can read and change patient data',
    'Reproduced: anonymous GET and PATCH to patients/me with X-User-Email return 200. Patient and report views use AllowAny, accept caller-supplied identity, and fall back to a specific account or the first user.',
    'Medical profiles, records, timelines, vitals, and family operations are exposed. Missing identity can select someone else rather than fail closed.',
    'Require authenticated users by default. Resolve self-service identity only from request.user. Remove header, query, body, and demo-account identity fallbacks. Authorize every object operation.',
    'Anonymous calls return 401/403; user A cannot read or modify B using any header or parameter; empty databases return controlled errors.',
    [('backend/apps/patients/views.py','def get_patient_user'),('backend/apps/reports/views.py','def get_patient_user')])
add('S02','Critical','Admin APIs expose users and verification controls publicly',
    'Reproduced: anonymous user listing and verification toggle both return 200. All three admin portal views explicitly use AllowAny.',
    'Anyone can enumerate account identifiers/contact details and change verification status. Overview also reveals recent clinical activity.',
    'Require a server-managed admin permission. Use an explicit desired verification state, approval reason, and audit event instead of an unaudited toggle.',
    'Anonymous and ordinary authenticated users cannot call any admin endpoint; admin changes record actor, target, time, and reason.',
    [('backend/apps/accounts/admin_views.py','class AdminPortalOverviewView'),('backend/apps/accounts/admin_views.py','class AdminPortalToggleVerifyView')])
add('S03','Critical','Search and locked charts leak clinical information',
    'Reproduced: anonymous global search returns a private record. A chart without consent still returns allergies. Global search scopes only authenticated patient-role users; patient directory search matches substrings and includes clinical details.',
    'Consent-protected records can be discovered via alternate endpoints. Providing a nonempty query is not an authorization rule.',
    'Apply the same owner/clinical-consent policy to search, chart metadata, exports, and files. Return minimal directory identity data and scope provider discovery to its legitimate workflow.',
    'Searching a known private title as anonymous/unrelated user produces no clinical results; a denied chart contains no sensitive fields.',
    [('backend/apps/reports/views.py','class GlobalSearchView'),('backend/apps/doctor/views.py','class DoctorPatientSearchView'),('backend/apps/doctor/views.py',"base_data = {")])
add('S04','Critical','An anonymous caller can approve consent and impersonate its doctor',
    'Reproduced: posting approve to doctor/incoming-requests/<id>/action activates consent without authentication; supplying the doctor email then unlocks the chart. The action lookup is not scoped to any actor. resolve_current_doctor prioritizes the header even over an authenticated user.',
    'The patient approval boundary is bypassed. A doctor can approve its own outgoing request; an unrelated caller can act on a known request.',
    'Separate provider request creation from patient approval. Only the patient or authorized guardian may grant consent. Bind provider identity to authentication and enforce actor/transition checks.',
    'Provider, unrelated user, and anonymous approval attempts fail; only the correct patient can approve; forged email headers never change the actor.',
    [('backend/apps/doctor/views.py','def resolve_current_doctor'),('backend/apps/doctor/views.py','class DoctorIncomingConsentActionView')])
add('S05','Critical','Registering an existing patient silently grants chart access',
    'Reproduced: doctor registration with an existing patient email updates that account and creates approved 24-hour consent. The registration endpoint itself permits anonymous access.',
    'Knowing an email can be sufficient to overwrite demographics and bypass patient consent, even after revocation.',
    'Do not update or grant access to existing accounts through walk-in registration. Separate unclaimed patient records, identity matching, invitation, and patient-approved access.',
    'Re-registering an existing email never changes its identity or consent; revoked consent stays revoked until the patient grants a new request.',
    [('backend/apps/doctor/views.py','Register a new patient from the Doctor Portal'),('backend/apps/doctor/views.py','# Pre-authorize this doctor')])
add('S06','Critical','Users can grant themselves professional and admin roles',
    'Reproduced: a patient can submit role=admin to register-profile. OTP verification also accepts roles=[admin]. Login sets is_verified=True, overriding a prior verification decision.',
    'Account ownership verification is confused with professional credential approval. Admin role assignment here is application-role escalation; it does not by itself set Django is_superuser.',
    'Use a server-owned role/membership table and credential approval lifecycle. Separate email_verified_at from professional_verification_status. Reject admin/professional role grants in public profile and login payloads.',
    'All privilege changes require authorized approval; re-login cannot change role grants or professional approval; invalid role strings fail validation.',
    [('backend/apps/accounts/views.py','merged_roles.update(roles)'),('backend/apps/accounts/views.py',"user.role = data.get('role'"),('backend/apps/accounts/serializers.py','class VerifyOTPSerializer')])
add('S07','High','OTP secrets, abuse controls, and consumption need hardening',
    'Reproduced dev_otp in a DEBUG response. Source also prints every OTP, stores plaintext OTPs, uses random.randint, has no configured throttles/attempt limit, and reads then consumes without an atomic guard.',
    'With DEBUG exposed, inbox possession can be bypassed. Otherwise logs/admin/database readers see active credentials; guessing, mail abuse, and concurrent reuse are insufficiently controlled. Concurrent reuse was not load-tested.',
    'Remove OTP responses and secret logging; use a cryptographic generator, keyed storage, per-account and per-origin limits, attempt budgets, and atomic one-time consumption. Validate the complete operation before consuming the code. Use a real delivery backend in production.',
    'No response/log contains the code; exhausted attempts are rejected; simultaneous verification yields at most one success; delivery failure is reported accurately.',
    [('backend/apps/accounts/models.py','def generate_otp'),('backend/apps/accounts/views.py',"print(f\"  OTP:"),('backend/apps/accounts/views.py','# Mark OTP as consumed'),('backend/config/settings.py','REST_FRAMEWORK =')])
add('S08','High','Lab and hospital endpoints accept any authenticated account',
    'Reproduced: an ordinary patient publishes a lab report for another patient and creates a hospital admission. These endpoints check IsAuthenticated but no professional role, credential, organization membership, or patient relationship.',
    'A signed-in patient can impersonate a care provider and inject clinical records. The lab/hospital owner filters on reads are useful but do not authorize who may become that owner.',
    'Add verified professional permissions and organization membership checks; authorize the selected patient/order/encounter. Preserve a distinct self-uploaded, unverified document workflow for patients.',
    'A patient token is denied provider writes; providers cannot operate on another organization\'s orders/admissions.',
    [('backend/apps/lab/views.py','class LabDirectUploadView'),('backend/apps/hospital/views.py','class InpatientAdmissionListCreateView')])
add('S09','High','Uploaded medical files have no access-controlled delivery path',
    'Source: DEBUG media routing serves MEDIA_ROOT directly; serializers expose FileField URLs; clients open those URLs externally. There is no download authorization layer or explicit content/size validation on these upload paths.',
    'A known media URL remains usable without owner/consent checks in the current development configuration. Uploading arbitrary content and large files expands exposure. Production reverse-proxy/storage behavior was not available to inspect.',
    'Use private storage plus authorized streaming or short-lived signed downloads after access checks. Restrict content, size and allowed formats, quarantine/scan uploads, and serve untrusted content from an isolated origin.',
    'Anonymous/unrelated downloads fail; revoked consent cannot mint new links; oversized and disallowed files are rejected before publication.',
    [('backend/config/urls.py','] + static'),('backend/apps/reports/models.py',"file_url = models.FileField"),('health_platform/lib/features/reports/reports_screen.dart','launchUrl(Uri.parse(fullUrl)')])
add('S10','High','Development security settings are the default deployment posture',
    'check --deploy produced six warnings: HSTS, HTTPS redirect, weak/insecure secret, secure session cookie, secure CSRF cookie, and DEBUG. Source defaults include a public secret, wildcard hosts, AllowAny, and unrestricted credentialed CORS.',
    'Deployment without overrides exposes debug behavior and weak signing configuration. CORS broadens browser access to already-open APIs; it is not an authentication substitute. JWT signing uses Django SECRET_KEY by default unless overridden.',
    'Separate local/production settings; require secrets with no production fallback, explicit hosts/origins, HTTPS configuration and secure cookies. Rotate deployed known keys and invalidate affected tokens.',
    'Production fails to boot without required secrets and passes reviewed deployment checks; an unapproved origin is rejected.',
    [('backend/config/settings.py','SECRET_KEY ='),('backend/config/settings.py','CORS_ALLOW_ALL_ORIGINS')])
add('S11','High','Client networking is hardcoded to plaintext local addresses',
    'Source: web always selects http://127.0.0.1:8000 before reading BACKEND_URL; non-web falls back to a private Wi-Fi IP. Android explicitly permits cleartext traffic.',
    'A hosted web app contacts the visitor\'s own computer, and tokens/health data use plaintext HTTP in the configured flows. Environment overrides do not work for web.',
    'Read an explicit validated API origin for every platform; prefer a same-origin HTTPS API on web. Keep HTTP exemptions in development-only configuration.',
    'A release build reaches the configured HTTPS server on another machine; no production request uses loopback/private demo addresses.',
    [('health_platform/lib/core/network/api_client.dart','static String get hostServerUrl'),('health_platform/android/app/src/main/AndroidManifest.xml','usesCleartextTraffic')])
add('S12','High','Session expiration and logout are incomplete',
    'Source: access tokens last seven days; refresh tokens are issued but there is no refresh URL/client refresh flow. Logout only clears memory; no blacklist app or server logout exists. Client auth is not restored from a validated session on restart.',
    'A copied access token can remain usable after UI logout. Sessions disappear on reload, and eventual expiry becomes silent empty/error behavior.',
    'Implement short-lived access, refresh rotation/revocation, explicit session lifecycle, and centralized 401 handling. Decide browser/native secure session storage deliberately; add server-side session invalidation if immediate access-token logout is required.',
    'Expiry refreshes once or signs out cleanly; revoked refresh tokens fail; logout semantics are documented and tested across devices.',
    [('backend/config/settings.py','SIMPLE_JWT ='),('backend/apps/accounts/urls.py','urlpatterns ='),('health_platform/lib/core/network/api_client.dart','void logout()')])

add('L01','Critical','Lab uploads fabricate clinical measurements',
    'Reproduced: a CBC upload without any file or parameters creates five hardcoded measurements. PDF/image contents are not parsed. The fallback includes preset normal values and a summary claiming verified extraction.',
    'Invented data is stored as a patient\'s diagnostic result. Frontend preset filenames/previews also imply an attached report even when there are no bytes.',
    'Remove clinical-data fallbacks from production. Store attachments as unparsed/pending review; require explicit verified parameters or a validated extraction pipeline with provenance and human review before publishing.',
    'A blank/unparsed upload never creates measurements or a Normal/Verified claim; every published value traces to a source and approving actor.',
    [('backend/apps/lab/views.py','if not params_list:'),('health_platform/lib/features/lab_portal/upload_report/upload_report_screen.dart','_presetTests =')])
add('L02','High','Patient matching can silently select the wrong person',
    'Source: several resolvers accept UUID prefixes, substring names/email matches, or choose the first result. PAT codes use only six UUID hex digits without a uniqueness constraint. PAT- yields an empty prefix that matches any UUID.',
    'Reports, appointments, and admissions can be attached to another person. CSV direct upload deliberately assigns every row to the selected patient, including rows identifying different people.',
    'Use exact immutable identifiers with database uniqueness. Treat display names as search-only. Require an explicit match confirmation; reject ambiguous/empty identifiers and cross-patient rows in a single-patient upload.',
    'Two similar names or colliding display codes never auto-resolve; PAT- is invalid; mixed-patient CSV input is rejected or safely routed as an explicit batch.',
    [('backend/apps/doctor/views.py','def resolve_patient_user'),('backend/apps/lab/views.py','raw_prefix = patient_id'),('backend/apps/lab/views.py','if u_str.startswith(raw_prefix)'),('backend/apps/hospital/views.py','if u_str.startswith(raw_prefix)')])
add('L03','Critical','Batch reports attach the complete multi-patient CSV to each patient',
    'Source: batch-upload passes the original uploaded_file into process_lab_csv_data. Every generated LabReport and MedicalRecord stores that same full document as its attachment.',
    'Even after API authorization is repaired, a patient downloading their legitimate attachment may receive other patients\' rows from the batch.',
    'Retain original batches in provider-only storage. Generate per-patient artifacts or attach no patient-visible source until split and verified.',
    'A batch containing patients A and B produces an A download containing no B identifiers or results.',
    [('backend/apps/lab/views.py','result = process_lab_csv_data(reader, lab_name, default_file_obj=uploaded_file)'),('backend/apps/lab/views.py','file_url=default_file_obj if default_file_obj else None')])
add('L04','High','CSV normalization loses clinical meaning and import boundaries',
    'Reproduced: status=low is stored Normal. Source additionally ignores override_test_name/category, groups by patient and test name alone, defaults dates to today, duplicates units into values, and silently catches direct CSV exceptions before creating a fallback report.',
    'Abnormal low results are misclassified; repeated specimens can merge; imported dates/categories can be lost; malformed uploads may publish partial or unrelated fallback results. CSV response also hardcodes status=Normal.',
    'Define a validated import schema with specimen/order identifiers and collection/report dates. Normalize high/low/critical explicitly, preserve raw data, preview row errors, and reject malformed imports without fallback publication.',
    'Fixtures cover low/critical, two specimens of one test, dates, quoted CSV fields, invalid rows, and form overrides; returned status matches persisted results.',
    [('backend/apps/lab/views.py','is_abnormal = str(status_val)'),('backend/apps/lab/views.py','report_key ='),('backend/apps/lab/views.py','except Exception:')])
add('L05','High','Multi-record clinical writes are not atomic or idempotent',
    'Reproduced: publishing one order twice creates two reports. Source has no transactions around report/parameter/order updates, prescription/medicine/locker sync, or admission/discharge sync. Repeated discharge also appends summaries.',
    'Retries or partial failures can create duplicates, incomplete prescriptions, mismatched status, or a discharged stay without its summary.',
    'Create domain services using transaction.atomic, enforce valid status transitions, link canonical records to their source order/encounter, and use idempotency keys/unique constraints. Handle storage changes and notifications after commit.',
    'Repeat requests return the same result; injected mid-operation failures leave no partial clinical state.',
    [('backend/apps/lab/views.py','class LabPublishReportView'),('backend/apps/doctor/serializers.py','def create(self, validated_data):'),('backend/apps/hospital/views.py','class InpatientDischargeView')])
add('L06','High','Hospital admission linkage and bed allocation are unreliable',
    'Reproduced: a supplied patient UUID in the patient field is overridden with None when name lookup does not match. Omitting ward bypasses the occupancy check but saves the model\'s default ward; two admissions can take the same bed. There is also a check-then-save concurrency race.',
    'An admission can lose its intended patient link and fail locker synchronization; beds can be double-booked.',
    'Validate identifiers through one serializer; honor patient or reject conflicting fields. Resolve defaults before checking occupancy and enforce one active occupancy per organization/bed transactionally.',
    'UUID-only linkage is retained; two same-bed requests, including simultaneous requests and omitted/default wards, cannot both succeed.',
    [('backend/apps/hospital/views.py',"identifier = (data.get('patient_identifier')"),('backend/apps/hospital/views.py','if ward and bed_no:'),('backend/apps/hospital/models.py',"ward = models.CharField")])
add('L07','High','Appointment ownership changes with role combination or invalid input',
    'Reproduced: a doctor with roles=[doctor,patient] receives their personal patient appointments rather than booked doctor visits. An unknown patient identifier creates an appointment with the doctor as patient. patient_email also permits querying another patient\'s bookings.',
    'Normal multi-role doctors see an empty/wrong schedule, and mistyped patients silently become the wrong appointment owner.',
    'Separate doctor and patient appointment resources or authorize an explicit context. Reject unresolved patients; enforce provider/patient scope and use validated date/time fields with booking-conflict rules.',
    'A multi-role doctor sees the correct lists in both portals; unknown patients return 400/404; unrelated patient_email queries are denied.',
    [('backend/apps/doctor/views.py',"elif request.user.is_authenticated and ('patient'"),('backend/apps/doctor/views.py',"data['patient'] = doc.id"),('backend/apps/doctor/models.py',"time_slot = models.CharField")])
add('L08','Medium','Clinical chart and prescription sync omit relevant data',
    'Source: the chart returns prescriptions, lab reports, and vitals but never MedicalRecord, so general notes/admission/discharge summaries are absent. Prescription locker descriptions include medicine names but omit dosage/duration/instructions. The UI follow-up date is never submitted.',
    'The advertised unified chart and patient-facing prescription record are incomplete.',
    'Represent encounters and prescriptions canonically; include authorized document types and structured medication instructions. Persist follow-up dates or remove the unused field.',
    'A consented chart shows admission/discharge records; patient prescription detail includes every medication instruction; follow-up survives reload.',
    [('backend/apps/doctor/views.py','prescriptions = Prescription.objects.filter'),('backend/apps/doctor/views.py','med_list ='),('health_platform/lib/features/doctor_portal/add_diagnosis_screen.dart','DateTime _followUpDate')])
add('L09','Medium','Profile and clinical schemas permit inconsistent data',
    'Reproduced: patients/me omits current_medications even though the model/auth response contains it. Birth dates are strings and the doctor flow stores values such as 54 yrs; JSON medical lists and several status fields are weakly validated. Approved consent with no expiry is treated as active indefinitely.',
    'Age calculations, medication editing, expiry expectations, and downstream integrations cannot rely on one consistent contract.',
    'Use typed dates and enums, structured list validation, explicit unknown values, and clear timezone semantics. Expose medications consistently. Require expiry for time-limited consent and preserve consent history rather than overwriting it.',
    'Invalid dates/statuses/list types are rejected; medication PATCH round-trips; approved time-limited consent always has an expiry.',
    [('backend/apps/patients/serializers.py','class PatientProfileSerializer'),('backend/apps/patients/models.py','date_of_birth ='),('backend/apps/doctor/models.py','def is_active')])

add('F01','High','Client error handling reports failed writes as successful',
    'Source: many API mutations decode JSON without checking HTTP status; notifiers optimistically mutate and swallow exceptions. AddDiagnosis marks submitted after a rejected response. Discharge sets submitted=true even in catch.',
    'Users can believe a prescription, admission, consent decision, or discharge was saved when it was rejected or the server was unavailable.',
    'Centralize typed response/error handling and timeouts. Await writes, show actual errors, reconcile or roll back optimistic changes, and only display success after persisted confirmation.',
    '403, 400, 500, timeout, and invalid JSON never produce a success state; retry does not duplicate records.',
    [('health_platform/lib/core/network/api_client.dart','Future<Map<String, dynamic>> createPrescription'),('health_platform/lib/features/hospital_portal/discharge_summary/discharge_summary_screen.dart','// Even if server returns non-200'),('health_platform/lib/core/config/providers.dart','Future<void> addAdmission')])
add('F02','High','Profile and emergency edit buttons do not persist their promises',
    'Source: settings, doctor-profile and hospital-profile Save handlers only close dialogs and show success. Emergency edits change AuthNotifier memory only. API emergency helpers point at an absent /patients/emergency-card/ route (404 reproduced).',
    'Emergency information reverts after re-login/reload, and professional/profile edits are discarded entirely.',
    'Implement authorized profile PATCH flows, connect UI forms, await persistence, and refresh the canonical user. Use patients/me consistently or implement and test the intended emergency resource.',
    'Edit, reload, and sign in on another device show the saved values; backend validation errors remain visible.',
    [('health_platform/lib/features/settings/settings_screen.dart','Profile details updated successfully'),('health_platform/lib/features/doctor_portal/doctor_profile_screen.dart','Doctor practice profile updated successfully'),('health_platform/lib/features/hospital_portal/hospital_profile_screen.dart','Hospital profile updated successfully'),('health_platform/lib/features/emergency/emergency_screen.dart','updateCurrentUser(updatedUser)')])
add('F03','High','Patient record upload discards file bytes and report entry drops findings',
    'Source: record picker reads bytes but retains only filename/size; addRecord sends JSON without a file. Patient report form collects key findings but creates a LabReport without summary or parameters.',
    'A successful-looking medical upload loses its attachment; entered findings disappear from saved reports.',
    'Use multipart uploads and persist the returned file identity; map all submitted report fields and remove unsupported inputs until implemented.',
    'Upload and reload yield byte-identical downloads; all entered findings are present in the stored report.',
    [('health_platform/lib/features/records/records_screen.dart','final bytes = await file.readAsBytes();'),('health_platform/lib/core/config/providers.dart','Future<void> addRecord'),('health_platform/lib/features/reports/reports_screen.dart','final newReport = LabReport(')])
add('F04','Medium','Delete and appointment cancellation only alter memory',
    'Source: deleteRecord, deleteReport, and cancelAppointment only filter provider lists. Matching backend detail-delete/cancel endpoints do not exist.',
    'Items reappear on refresh and the user has no durable cancellation/deletion result.',
    'Implement authorized, audited lifecycle endpoints; for clinical records consider amendment/withdrawal rather than destructive deletion. Await server confirmation.',
    'Cancellation persists after reload and releases its slot; deletion/withdrawal behavior is explicit and auditable.',
    [('health_platform/lib/core/config/providers.dart','void deleteRecord'),('health_platform/lib/core/config/providers.dart','void deleteReport'),('health_platform/lib/core/config/providers.dart','void cancelAppointment')])
add('F05','High','Queued lab orders are disconnected from the upload workflow',
    'Source: pending rows navigate with order/patient/test/category query parameters, but the router constructs a LabShell without reading them; its UploadReportScreen has no arguments. The upload handler calls direct upload and never uses widget.orderId or publishes/completes the queued order. New queue entries also omit patient linkage.',
    'Patient/test context is lost, orders remain pending, and reports can be created independently of the selected order.',
    'Route to an order-backed upload screen using immutable order ID; fetch and authorize order context; require patient linkage and publish through one order-aware transaction.',
    'Selecting a pending order preserves its exact patient/test, publishes once, completes that order, and removes it from pending counts.',
    [('health_platform/lib/features/lab_portal/pending_reports/pending_reports_screen.dart',"'/lab/upload?order="),('health_platform/lib/core/config/router.dart',"path: '/lab/upload'"),('health_platform/lib/features/lab_portal/upload_report/upload_report_screen.dart','Future<void> _handleUploadAndSync')])
add('F06','Medium','Some routes select nonexistent or incorrect screens',
    'Source: /lab/integration uses initialIndex=3 but LabShell has only three screens (0-2). /hospital/integration selects HospitalProfileScreen. MainShell and LabShell also initialize the index only in initState, unlike HospitalShell\'s didUpdateWidget handling.',
    'The lab integration route has no valid selected child; hospital integration shows a profile. Same-widget route changes may retain an old tab. These route effects were source-reviewed, not device-tested.',
    'Use explicit routes for screens and one navigation source of truth; wire or remove obsolete integration routes; handle parameter changes and guard route indices.',
    'Every registered deep link renders its intended screen; browser back/forward and tab links stay synchronized.',
    [('health_platform/lib/core/config/router.dart',"path: '/lab/integration'"),('health_platform/lib/features/lab_portal/lab_shell.dart','final List<Widget> _screens'),('health_platform/lib/features/hospital_portal/hospital_shell.dart','final List<Widget> _screens'),('health_platform/lib/shared/widgets/main_shell.dart','void initState()')])
add('F07','Medium','OTP resend timer never enables resend at zero',
    'Source: the timer decrements 1 to 0 and returns false. _canResend is set only in the else branch on a subsequent iteration, which never happens.',
    'Users whose OTP is delayed/expired cannot use the resend control normally.',
    'Set canResend when the decrement reaches zero; use a cancellable timer and clear stale OTP/pending-registration state when beginning a new flow.',
    'A fake-clock widget test advances 30 seconds, finds resend enabled, resends once, and verifies the timer resets.',
    [('health_platform/lib/features/auth/otp_entry_screen.dart','void _startResendTimer')])
add('F08','High','Provider caches can remain stale or cross session boundaries',
    'Source: many fetches update state only for nonempty lists; asynchronous requests are not bound to an auth/session generation. Logout resets caches but pending requests can complete later. Notifications/active role are not reset with the other providers.',
    'An empty server result leaves old data on screen; slow responses can repopulate a signed-out or different-user session. The race is inferred from source, not concurrency-tested.',
    'Key caches to authenticated user/context; cancel or discard stale responses; assign empty results; invalidate all user-scoped providers on logout; distinguish loading/error/empty states.',
    'Delay user A\'s response until after user B signs in; it is discarded. Empty responses clear data, and logout clears notifications and active role.',
    [('health_platform/lib/core/config/providers.dart','if (list.isNotEmpty)'),('health_platform/lib/core/config/providers.dart','void logout()')])
add('F09','High','Unauthenticated UI has privileged demo identity and offline login fallback',
    'Source: userProvider creates a named fallback user with patient/doctor/hospital/lab/admin roles and writes its email into the API singleton. Router has no auth/role redirect. The phone/fallback verification path accepts any six characters locally; the visible login screen currently uses email.',
    'Direct routes appear signed in and can activate the backend identity fallbacks. Dormant mock authentication is unsafe to retain in the production path.',
    'Return no user until a server-validated session exists; remove offline verification/demo identity from release code; add route guards and server permission enforcement.',
    'Every protected deep link redirects signed-out users; no credential-free path creates a verified user; role menus reflect server grants.',
    [('health_platform/lib/core/config/providers.dart','final userProvider ='),('health_platform/lib/core/config/providers.dart','// Phone / Fallback offline mode'),('health_platform/lib/core/config/router.dart','final appRouter =')])
add('F10','Medium','Notifications, integration status, and operational metrics are placeholders',
    'Source: notifications build returns fixed clinical messages. Lab/hospital integration screens show ONLINE and HL7/FHIR labels without connectors. Admin returns constant engine health; healthSummary ignores recorded vitals. Hospital counts include discharged stays; pending lab queries include completed orders.',
    'Users see events and system health that are not measured, and operational queues/counts are misleading.',
    'Drive status from real health probes and filtered server aggregates. Persist user-scoped notifications and delivery outcomes. Label integrations unavailable until implemented; connect vitals to the summary.',
    'A fresh account has no fictional notifications; disconnecting a gateway changes status; completed/discharged items are excluded from active queues.',
    [('health_platform/lib/features/notifications/notifications_provider.dart','List<NotificationItem> build()'),('backend/apps/accounts/admin_views.py',"'database': 'POSTGRESQL_READY'"),('health_platform/lib/core/config/providers.dart','final healthSummaryProvider'),('backend/apps/lab/views.py','orders = LabTestOrder.objects.filter'),('backend/apps/hospital/views.py','admissions = InpatientAdmission.objects.filter')])
add('F11','Medium','Family linking does not actually link a patient account',
    'Source: UI accepts a patient ID/email and says linked, but addMember sends only demographics. FamilyMember has no linked-user foreign key or guardian authorization relationship; total_records is a mutable counter.',
    'The feature creates an address-book-like dependent profile, not authorized access to another patient\'s records.',
    'Either describe it accurately as a local dependent profile or implement verified guardian/delegate relationships with explicit scopes and consent. Derive record counts from actual relationships.',
    'Linking requires the defined consent/guardian process and resolves an exact account; counts reflect accessible records.',
    [('health_platform/lib/features/family/family_screen.dart','final newMember = FamilyMember('),('health_platform/lib/core/config/providers.dart','Future<void> addMember'),('backend/apps/patients/models.py','class FamilyMember')])
add('F12','High','Forms silently default unknown clinical facts',
    'Source: signup defaults blood group to O+, family form defaults B+, admission model defaults age 35 and Male, and discharge narrative is prefilled with stable/normal findings.',
    'Skipping a field can turn an assumption into recorded clinical information. This compounds the fabricated-lab issue.',
    'Default clinical values to unknown/unrecorded. Require deliberate confirmation for relevant clinical assertions and record author/source/time.',
    'Submitting untouched optional fields stores unknown, never an invented blood group, age, or clinical observation.',
    [('health_platform/lib/features/auth/signup_screen.dart',"String _bloodGroup = 'O+'"),('health_platform/lib/features/family/family_screen.dart',"text: 'B+'"),('backend/apps/hospital/models.py','age = models.IntegerField'),('health_platform/lib/features/hospital_portal/discharge_summary/discharge_summary_screen.dart',"'Clinical course stable.")])
add('F13','Medium','Asynchronous search and upload state can reuse stale results',
    'Source: global/patient search does not debounce or discard older responses. Picking CSV sets _customExtractedParameters; picking a subsequent non-CSV file does not clear it. File picking calls setState after awaits without an initial mounted check.',
    'Search results may belong to an earlier query, and an uploaded PDF can inherit a previously selected CSV\'s parameters. Closing the screen during picking can trigger disposed-state errors.',
    'Use request sequence IDs/cancellation, reset dependent fields atomically whenever a file or target patient changes, and check mounted after async work.',
    'Reverse response order leaves the latest search visible; CSV-to-PDF selection clears old parameters; closing a picker screen is safe.',
    [('health_platform/lib/shared/widgets/global_search_dialog.dart','Future<void> _performSearch'),('health_platform/lib/features/lab_portal/upload_report/upload_report_screen.dart','if (extractedParams.isNotEmpty)')])

add('F14','Medium','Signup remains stuck after a failed OTP request',
    'Source: SignupScreen sets its private _isLoading flag true before starting registration and never resets it. The submit button is disabled when either that flag or authState.isLoading is true; this screen does not display authState.error.',
    'An existing-email rejection, SMTP failure or network error can leave the form indefinitely disabled without explaining the failure.',
    'Use one asynchronous auth loading state, await registration/send completion, reset in finally, and render the server error next to the form.',
    'Simulate an existing email and a network failure: the error appears and the corrected form can be submitted again without restarting the app.',
    [('health_platform/lib/features/auth/signup_screen.dart','setState(() => _isLoading = true)'),('health_platform/lib/features/auth/signup_screen.dart','(_isLoading || authState.isLoading)')])

add('T01','Medium','PostgreSQL readiness is not implemented by the current settings',
    'Source: DATABASES configures only ENGINE and NAME, without application-level USER/PASSWORD/HOST/PORT or a URL parser. Local deployment is SQLite; no PostgreSQL test was run.',
    'Changing the advertised engine is not a complete ordinary remote PostgreSQL setup. PostgreSQL-specific behavior, concurrency, and deployment remain unverified.',
    'Provide explicit tested database configuration, a redacted env example, migrations/backup procedures, and PostgreSQL CI coverage before claiming support.',
    'A clean environment can connect, migrate, run the permission suite, and restore a backup using documented configuration.',
    [('backend/config/settings.py','DATABASES =')])
add('T02','High','Tests do not validate the security boundaries and currently fail',
    'Executed: Django discovers 12 tests; 8 pass and 4 fail. Two auth tests assume unknown-email login creates an account; two prescription tests omit required consent. Four app tests.py files are stubs. Flutter has one passing smoke test.',
    'Existing tests do not establish privacy, authorization, correct uploads, persistence, or end-to-end safety. force_authenticate bypasses real login behavior in many tests.',
    'Update obsolete fixtures to the intended contract without weakening security. Add anonymous/wrong-role/wrong-owner/expired-consent tests, actual token tests, import validation, idempotency and critical UI persistence tests to CI.',
    'All existing tests pass for the intended behavior; every critical finding has a regression test that fails before the fix and passes afterward.',
    [('backend/apps/accounts/test_full_system.py','def test_auth_otp_flow'),('backend/apps/reports/tests.py','def test_doctor_prescription_cross_syncs_to_patient_locker'),('health_platform/test/widget_test.dart',"testWidgets('App smoke test'")])
add('T03','High','Generated audit reports hardcode success and production-readiness claims',
    'Source: report builders insert 12/12 Passed, 27/27 and ZERO DEFECTS text directly. Current fresh test results contradict those claims. The PDF titled 30Page contains 10 pages.',
    'Screenshots and old generated documents can give false assurance about security and functionality. No claim of encryption/compliance should be treated as established by those reports.',
    'Generate verification documents only from timestamped test artifacts tied to a commit/configuration. Separate implemented, demonstrated, tested, planned and independently assessed capabilities.',
    'A failing test produces a failing report and nonzero verification status; no static production-ready badge overrides results.',
    [('backend/generate_pdf_report.py','12/12 Passed'),('generate_hardcore_testing_report_pdf.py','ZERO DEFECTS')])
add('T04','High','Demo utilities can destroy data or use known administrator credentials',
    'Source: reset_and_seed_clean_db deletes operational tables, users and media and creates a superuser with a fixed password. run_hardcore_tests uses the configured real database and writes records; inspect_db prints recent OTPs. These utilities were not executed.',
    'An operator can irreversibly destroy data or leave a known-credential administrator by running a seemingly convenient setup/test script.',
    'Replace with explicit development-only management commands, separate database settings, environment guards and synthetic credentials; isolate all tests and stop printing OTPs.',
    'Reset/seed refuse production settings, tests never touch live DB/media, and seeded credentials cannot persist in a release environment.',
    [('backend/reset_and_seed_clean_db.py','def reset_and_seed'),('backend/reset_and_seed_clean_db.py','admin_user.set_password'),('run_hardcore_tests.py','django.setup()'),('backend/inspect_db.py','GENERATED OTPS')])
add('T05','Medium','Schema lacks organization membership, clinical provenance, and access audit history',
    'Source: labs/hospitals are user accounts; clinical author/facility names are strings; report source-order and record-source links are absent. ConsentRequest is mutable with no unique actor pair or immutable grant/revocation history. General clinical read/write audit events are absent.',
    'Shared staff workflows, reliable attribution, duplicate prevention, amendment history and access investigations are difficult. Django admin logging does not cover these API operations.',
    'Introduce Organization, Membership, verified Credential, Encounter, versioned clinical documents, source order/report references, and immutable access/consent events. Normalize roles and derive patient display identifiers safely.',
    'Two staff members in one organization share only authorized resources; every clinical change/download/consent action has attributable provenance.',
    [('backend/apps/accounts/models.py','class LabProfile'),('backend/apps/reports/models.py','class MedicalRecord'),('backend/apps/doctor/models.py','class ConsentRequest')])
add('T06','Medium','Queries and polling will scale poorly',
    'Source: patient matching scans User.objects.all in Python; serializers access relations per item; most lists have no pagination. Patient dashboard polls three endpoints every three seconds, including while retained in an IndexedStack.',
    'Latency, database load and bandwidth grow with records and concurrent sessions; errors may still look like empty lists.',
    'Move exact matching/filtering to indexed DB queries, use select_related/prefetch_related, paginate, and add measured query budgets. Poll only visible authenticated views with backoff, or introduce event delivery after correctness is established.',
    'Representative large fixtures stay within documented query/latency budgets; hidden/signed-out screens stop polling.',
    [('backend/apps/doctor/views.py','all_users = User.objects.all()'),('backend/apps/reports/serializers.py','parameters = TestParameterSerializer'),('health_platform/lib/features/dashboard/dashboard_screen.dart','Timer.periodic')])
add('T07','Medium','Release platform configuration remains development-oriented',
    'Source: Android release uses debug signing. iOS has no explicit policy for the configured HTTP endpoint. macOS sandbox release entitlements omit network client access. Native app behavior was not built or device-tested.',
    'Distribution identity and networking can fail outside local development. Several Android sensitive permissions are declared without a demonstrated need in the current flows.',
    'Configure production signing securely, HTTPS, required platform network entitlements and minimal permissions; test each supported platform. Do not advertise untested targets as ready.',
    'Signed release builds authenticate/upload/download on real target devices under release security policies.',
    [('health_platform/android/app/build.gradle.kts','signingConfig ='),('health_platform/ios/Runner/Info.plist','<dict>'),('health_platform/macos/Runner/Release.entitlements','com.apple.security.app-sandbox')])
add('T08','Medium','Build/dependency documentation is insufficient for reproducible releases',
    'Source: Python dependencies mostly have unbounded upper versions and no lock; PDF generation dependencies such as reportlab are installed locally but absent from requirements.txt. Flutter has a lockfile, but README is the starter template. No project CI/deployment manifest was found in the surveyed source.',
    'Another machine may install different dependencies or fail report generation; dependency vulnerabilities and release behavior are not continuously checked.',
    'Lock production/dev dependencies, separate document-generation extras, add a real setup/env/API README and CI checks. Audit installed/locked versions using a maintained advisory scanner before release.',
    'A clean checkout can install deterministically and run the same checks. Advisory scanning is recorded; no unsupported CVE-free claim is made.',
    [('backend/requirements.txt','Django>='),('health_platform/README.md','A new Flutter project.'),('health_platform/pubspec.yaml','dependencies:')])
add('T09','Low','Legacy/demo artifacts obscure the supported product',
    'Source: src/components contains three React components but no React app manifest/entry point in the surveyed project. Its OTP is simulated. mock_data, screenshot/capture utilities, root PDF generators and multiple overlapping reports coexist with the live Flutter app.',
    'Maintainers can edit the wrong frontend or mistake mock demonstrations for working functionality. Binary screenshots are historical evidence, not executable verification.',
    'Document Flutter as the supported client; archive legacy React/demo assets, move scripts/docs/test fixtures into clear folders, and label generated artifacts with source commit and date.',
    'The root README explains every top-level directory and one documented path runs the supported app and tests.',
    [('src/components/AuthModal.jsx','const handleVerifyOtp'),('health_platform/lib/mock_data/mock_user.dart','import')])

summary=json.loads((OUT/'inventory_summary.json').read_text(encoding='utf-8'))
counts=collections.Counter(f['severity'] for f in findings)
intro=f'''# Digital Health Platform — project review

Reviewed on 2026-09-28. **Verdict: a functional prototype with critical authorization and clinical-data-integrity defects; not ready to hold real patient data in an exposed deployment.**

This review records {len(findings)} grouped findings: {', '.join(f'{v} {k.lower()}' for k,v in counts.items())}. These are findings with evidence, not a claim that every possible bug has been found. Closely related symptoms are grouped to avoid inflating the count.

## Scope and evidence limits

- Inventoried {summary['files']} files outside dependency/build/cache/Git directories: {summary['categories']}. The inventory includes ignored local artifacts and uploaded media, not just Git-tracked files.
- Automated full-file reads covered {summary['text_lines']:,} lines of text/configuration, with Python syntax parsing. Manual deep review focused on all backend API models/serializers/views/routes, central Flutter auth/API/state/navigation, and affected feature handlers. Theme/widget layout, generated platform boilerplate, mock data, and documentation generators received targeted/static review rather than an assertion of exhaustive manual line-by-line review.
- Text extracted from all 14 PDFs (122 pages total if the per-file page counts sum to that value; see inventory_summary.json for authoritative counts). PDF layout, screenshot pixels, icons, and device rendering were not comprehensively visually reviewed. Existing generated documentation was treated as claims to verify.
- Local .env values, patient database contents and uploaded clinical contents were not exported into the report. Existing patient rows were not queried; the migration consistency check may inspect migration metadata. Dependency/cache internals and Git history were excluded. No deployed server, cloud storage policy, SMTP delivery, native release build, penetration/load test, backup restore, or package advisory audit was verified.
- Application source and the existing database were not modified. Audit scripts/reports were added under audit/. Backend reproductions use an in-memory SQLite database, synthetic accounts and local-memory email. No real messages were sent. The inventory reads local files; its output contains metadata only for private data/uploads.

## What currently exists and how it works

| Area | Current role and flow |
|---|---|
| backend/config | Django settings, URL registration, ASGI/WSGI. SQLite locally; SMTP or console email; JWT authentication available but most patient/doctor/report/admin endpoints explicitly allow anonymous calls. |
| backend/apps/accounts | Email request/verification → user/profile create/update → JWT issue. One User with primary role plus JSON roles and professional subprofiles. Custom admin portal lives here. |
| backend/apps/patients | Personal profile/emergency details, vitals and family demographic rows. Ownership currently relies on unsafe identity resolvers. |
| backend/apps/doctor | Patient discovery/registration, appointments, consent requests/actions, prescriptions and chart assembly. Prescriptions create a second MedicalRecord entry. |
| backend/apps/lab | Lab orders → publish or direct PDF/image/CSV upload → LabReport/TestParameter; direct/CSV upload also creates MedicalRecord entries. Some publication paths are disconnected from orders. |
| backend/apps/hospital | Admission → bed/ward status → discharge → patient MedicalRecord summaries when linked. Provider ownership is a user FK, not an organization membership. |
| backend/apps/reports | Patient record/report lists, global search and timeline merge. Timeline merges MedicalRecord plus LabReport, so upload paths creating both can display a lab event twice. |
| health_platform/lib/core | Riverpod auth/cache providers, HTTP singleton, GoRouter and theme. Email login is the visible path; token/session state is in memory. Role switcher changes UI context. |
| health_platform/lib/features | Patient, doctor, lab, hospital and admin screens. Several mutations are connected; several Save/Sync/Online states are presentation-only or optimistic. |
| health_platform/lib/shared | Models, navigation, reusable widgets and global search. Useful separation, but dynamic maps weaken API contract checks. |
| health_platform/android, ios, macos, linux, windows, web | Flutter platform scaffolding and release metadata. Existence of these folders does not establish working release support. |
| src/components | Three leftover React components; not wired into the Flutter application. |
| test_samples, screenshots, report_screenshots, root PDFs/scripts | Sample imports, historical screenshots, documentation and report-generation utilities. These are not evidence of current passing security tests. |

The intended care flow is patient sign-in → provider discovery/request → patient grants time-limited consent → provider views/writes → results appear in patient records/timeline. The current code bypasses this boundary in several places. Repair the server authorization model before adding more portal features.

## Verification actually performed

| Check | Result |
|---|---|
| Django test --noinput | **12 tests: 8 passed, 4 failed.** Two stale OTP signup expectations (404 vs 200); two missing-consent prescription fixtures (403 vs 201). |
| Isolated synthetic reproductions | **21/21 described bad behaviors reproduced.** This is a vulnerability reproduction count, not a passing-security score. See reproduction_results.json. |
| Django check --deploy | **6 security warnings**, detailed in S10. |
| makemigrations --check --dry-run | No changes detected. Existing migration files match current models. |
| Flutter analyze --no-pub | No issues found. Ran using installed Flutter tool snapshot with SDK-cache access. |
| Flutter test --no-pub | One smoke test passed; it only checks that MaterialApp exists. |
| Python AST parsing | No syntax errors in surveyed Python files. |

The initial Flutter wrapper attempt stalled in the restricted environment; direct invocation identified SDK cache permission needs. Analysis and the smoke test subsequently completed with cache access. An initial audit helper attempt hit temporary-directory cleanup permissions; the successful reproduction run uses the audit-local media path and an in-memory database.

## Prioritized findings

Critical means direct sensitive-data exposure, privilege/consent bypass, or fabricated/cross-patient clinical data. High means material security or workflow integrity risk. Medium/Low indicate reliability, completeness or maintenance concerns. Reproduced findings say so explicitly; other findings are confirmed source behavior or labeled untested/inferred runtime effects.
'''
intro=intro.replace('122 pages total if the per-file page counts sum to that value; see inventory_summary.json for authoritative counts',str(sum(p['pages'] for p in summary['pdf_summaries']))+' pages total')
parts=[intro]
for f in findings:
    refs='; '.join(f"[{s['path']}]({(ROOT/s['path']).as_posix()}:{s['line']})" for s in f['sources'])
    parts.append(f"\n### {f['id']} · {f['severity']} — {f['title']}\n\n**Evidence:** {f['evidence']}\n\n**Impact:** {f['consequence']}\n\n**Change:** {f['fix']}\n\n**Acceptance check:** {f['acceptance']}\n\n**Source:** {refs}\n")
parts.append('''
## Recommended repair order

1. **Contain critical exposure and false clinical data.** Remove anonymous identity fallbacks and public admin/clinical access; stop auto-consent, self-assigned privileges, fabricated measurements and shared multi-patient attachments. Ensure existing demo credentials/secrets are not active in a deployed environment. Do not simply hide buttons: fix API authorization first.
2. **Establish one coherent identity and access model.** Server-owned roles, credential approval distinct from email ownership, organization membership, exact patient identity and patient-controlled consent. Centralize policies across reads, writes, search and file delivery. Add negative authorization tests alongside these changes.
3. **Make clinical operations trustworthy.** Atomic/idempotent prescription/report/admission/discharge services; source-order links, validated dates/statuses/units and no inferred clinical facts. Make patient matching explicit and correct bed/appointment ownership constraints.
4. **Make the UI accurately reflect persistence.** Central response/error handling; awaited writes; correct empty/error/loading states; user-bound cache invalidation; working edit/upload/cancel flows; lab order routing; OTP timer and route tests. Remove claims of success/online/verified until backed by saved data.
5. **Prepare a reproducible release.** Tested PostgreSQL config if required, private storage, HTTPS, secure secrets, production signing, locked dependencies, CI, redacted logs, monitoring, backup/restore testing and a real project README. Regenerate documentation from fresh test evidence.

Do not weaken the new consent requirement just to make old tests green. Update tests to create legitimate consent and assert denial without it. Also do not solve the database warning merely by adding PostgreSQL: database choice cannot repair authorization or invented results.

## Additions and upgrades worth building after the blockers

| Priority | Addition | Concrete value / prerequisite |
|---|---|---|
| First | Patient access history and consent center | Show who requested/viewed/downloaded records, purpose, expiry and revocation. Requires immutable audit events and enforcement on every data path. |
| First | Clinical document provenance and amendment history | Distinguish patient-uploaded, lab-issued, doctor-signed, draft and corrected records; retain the original and link corrections. |
| First | Organization/staff administration | Multiple staff accounts per lab/hospital, invitation, credential review and scoped permissions without sharing accounts. |
| Next | Reliable appointment lifecycle | Real time slots/timezones, availability, conflict prevention, rescheduling/cancellation and delivery-tracked reminders. |
| Next | Report ingestion review queue | File validation, import preview, per-row errors, patient/specimen reconciliation and explicit approval; add OCR only with review/provenance, never invented fallback values. |
| Next | Longitudinal vitals and report trends | Numeric values, normalized units, collection times and source references. Keep interpretation separate from unverified data. |
| Next | Real notifications and delivery status | Persist user-scoped events, read state, preferences and delivery outcomes; enqueue only after database commit. |
| Next | Verified family/guardian delegation | Explicit consent/authority and limited access scopes; do not treat entering an email as permission. |
| Later | Emergency sharing with scoped expiring access | Implement a real endpoint and minimally necessary fields, revocation and access logs. Current UI copies a hardcoded healthrecord.in link whose service is not implemented here. |
| Later | HL7/FHIR adapters for actual partners | Define supported messages/resources and validation, idempotent delivery, retries and measured status before displaying ONLINE. Standards integration is an implementation project, not a label. |

Keep the current Django + Flutter foundation while repairing it. A framework rewrite or additional AI features would not solve the identified authorization and data-integrity defects. Extract backend domain services and split the large Flutter provider/API files by feature as each workflow is repaired, with shared policy and error handling rather than copied helpers.

## Suggested regression matrix

For each sensitive endpoint cover anonymous, patient owner, other patient, unverified provider, verified provider without consent, verified provider with valid consent, expired/revoked consent, staff from another organization, and authorized admin. Include list/search/download as well as mutation endpoints. Test concurrent OTP use, duplicate publish/discharge, duplicate bed booking, malformed imports, mid-write failure, empty responses, offline failures and account switching with delayed requests.

Use actual JWT authentication in part of the suite. Keep fast serializer/domain tests, focused widget tests and a small set of full care-flow tests. Record source commit, configuration, runtime versions and output artifacts in CI. Existing screenshot reports should supplement these tests rather than replace them.

## Supporting artifacts and rerun instructions

- file_inventory.csv: per-file category, size, hash where appropriate, line count and coverage note.
- inventory_summary.json: exclusions, PDF page counts and syntax results.
- reproduce_findings.py and reproduction_results.json: 21 synthetic current-behavior reproductions. Re-run from D:\\Health with `backend\\venv\\Scripts\\python.exe audit\\reproduce_findings.py`. The script deliberately reports whether a defect remains reproducible; it is not a pass/fail release gate.
- findings.json: structured repair backlog with source line anchors and acceptance checks.
- pdf_text/: extracted documentation text for internal comparison. These are local review intermediates, not replacement published reports.

## Primary technical references

These references support the repair approach; all project-specific findings above come from local source or local checks.

- [DRF permissions](https://www.django-rest-framework.org/api-guide/permissions/): authentication and object authorization must be enforced explicitly in custom views; list querysets must be appropriately scoped.
- [SimpleJWT settings](https://django-rest-framework-simplejwt.readthedocs.io/en/stable/settings.html) and [blacklist app](https://django-rest-framework-simplejwt.readthedocs.io/en/stable/blacklist_app.html): signing keys, token lifetime, rotation and revocation configuration.
- [Django deployment checklist](https://docs.djangoproject.com/en/5.2/howto/deployment/checklist/): production secrets, HTTPS, host validation and handling untrusted uploaded media.

This review does not certify regulatory compliance or the absence of undiscovered vulnerabilities. A full manual review of every layout/boilerplate line and binary asset, real-device end-to-end testing, deployment review and current dependency advisory scan remain separate coverage gaps.
''')
(OUT/'PROJECT_REVIEW.md').write_text('\n'.join(parts),encoding='utf-8')
(OUT/'findings.json').write_text(json.dumps(findings,indent=2),encoding='utf-8')
print(json.dumps({'findings':len(findings),'severity_counts':dict(counts),'report':str(OUT/'PROJECT_REVIEW.md')},indent=2))
