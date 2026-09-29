# Digital Health Platform — project review

Reviewed on 2026-09-28. **Verdict: a functional prototype with critical authorization and clinical-data-integrity defects; not ready to hold real patient data in an exposed deployment.**

This review records 44 grouped findings: 8 critical, 21 high, 14 medium, 1 low. These are findings with evidence, not a claim that every possible bug has been found. Closely related symptoms are grouped to avoid inflating the count.

## Scope and evidence limits

- Inventoried 532 files outside dependency/build/cache/Git directories: {'first-party text / config': 269, 'PDF documentation': 14, 'binary asset': 139, 'private local data': 2, 'local uploaded media': 108}. The inventory includes ignored local artifacts and uploaded media, not just Git-tracked files.
- Automated full-file reads covered 37,771 lines of text/configuration, with Python syntax parsing. Manual deep review focused on all backend API models/serializers/views/routes, central Flutter auth/API/state/navigation, and affected feature handlers. Theme/widget layout, generated platform boilerplate, mock data, and documentation generators received targeted/static review rather than an assertion of exhaustive manual line-by-line review.
- Text extracted from all 14 PDFs (102 pages total). PDF layout, screenshot pixels, icons, and device rendering were not comprehensively visually reviewed. Existing generated documentation was treated as claims to verify.
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


### S01 · Critical — Anonymous callers can read and change patient data

**Evidence:** Reproduced: anonymous GET and PATCH to patients/me with X-User-Email return 200. Patient and report views use AllowAny, accept caller-supplied identity, and fall back to a specific account or the first user.

**Impact:** Medical profiles, records, timelines, vitals, and family operations are exposed. Missing identity can select someone else rather than fail closed.

**Change:** Require authenticated users by default. Resolve self-service identity only from request.user. Remove header, query, body, and demo-account identity fallbacks. Authorize every object operation.

**Acceptance check:** Anonymous calls return 401/403; user A cannot read or modify B using any header or parameter; empty databases return controlled errors.

**Source:** [backend/apps/patients/views.py](D:/Health/backend/apps/patients/views.py:14); [backend/apps/reports/views.py](D:/Health/backend/apps/reports/views.py:12)


### S02 · Critical — Admin APIs expose users and verification controls publicly

**Evidence:** Reproduced: anonymous user listing and verification toggle both return 200. All three admin portal views explicitly use AllowAny.

**Impact:** Anyone can enumerate account identifiers/contact details and change verification status. Overview also reveals recent clinical activity.

**Change:** Require a server-managed admin permission. Use an explicit desired verification state, approval reason, and audit event instead of an unaudited toggle.

**Acceptance check:** Anonymous and ordinary authenticated users cannot call any admin endpoint; admin changes record actor, target, time, and reason.

**Source:** [backend/apps/accounts/admin_views.py](D:/Health/backend/apps/accounts/admin_views.py:12); [backend/apps/accounts/admin_views.py](D:/Health/backend/apps/accounts/admin_views.py:117)


### S03 · Critical — Search and locked charts leak clinical information

**Evidence:** Reproduced: anonymous global search returns a private record. A chart without consent still returns allergies. Global search scopes only authenticated patient-role users; patient directory search matches substrings and includes clinical details.

**Impact:** Consent-protected records can be discovered via alternate endpoints. Providing a nonempty query is not an authorization rule.

**Change:** Apply the same owner/clinical-consent policy to search, chart metadata, exports, and files. Return minimal directory identity data and scope provider discovery to its legitimate workflow.

**Acceptance check:** Searching a known private title as anonymous/unrelated user produces no clinical results; a denied chart contains no sensitive fields.

**Source:** [backend/apps/reports/views.py](D:/Health/backend/apps/reports/views.py:128); [backend/apps/doctor/views.py](D:/Health/backend/apps/doctor/views.py:140); [backend/apps/doctor/views.py](D:/Health/backend/apps/doctor/views.py:384)


### S04 · Critical — An anonymous caller can approve consent and impersonate its doctor

**Evidence:** Reproduced: posting approve to doctor/incoming-requests/<id>/action activates consent without authentication; supplying the doctor email then unlocks the chart. The action lookup is not scoped to any actor. resolve_current_doctor prioritizes the header even over an authenticated user.

**Impact:** The patient approval boundary is bypassed. A doctor can approve its own outgoing request; an unrelated caller can act on a known request.

**Change:** Separate provider request creation from patient approval. Only the patient or authorized guardian may grant consent. Bind provider identity to authentication and enforce actor/transition checks.

**Acceptance check:** Provider, unrelated user, and anonymous approval attempts fail; only the correct patient can approve; forged email headers never change the actor.

**Source:** [backend/apps/doctor/views.py](D:/Health/backend/apps/doctor/views.py:63); [backend/apps/doctor/views.py](D:/Health/backend/apps/doctor/views.py:534)


### S05 · Critical — Registering an existing patient silently grants chart access

**Evidence:** Reproduced: doctor registration with an existing patient email updates that account and creates approved 24-hour consent. The registration endpoint itself permits anonymous access.

**Impact:** Knowing an email can be sufficient to overwrite demographics and bypass patient consent, even after revocation.

**Change:** Do not update or grant access to existing accounts through walk-in registration. Separate unclaimed patient records, identity matching, invitation, and patient-approved access.

**Acceptance check:** Re-registering an existing email never changes its identity or consent; revoked consent stays revoked until the patient grants a new request.

**Source:** [backend/apps/doctor/views.py](D:/Health/backend/apps/doctor/views.py:204); [backend/apps/doctor/views.py](D:/Health/backend/apps/doctor/views.py:244)


### S06 · Critical — Users can grant themselves professional and admin roles

**Evidence:** Reproduced: a patient can submit role=admin to register-profile. OTP verification also accepts roles=[admin]. Login sets is_verified=True, overriding a prior verification decision.

**Impact:** Account ownership verification is confused with professional credential approval. Admin role assignment here is application-role escalation; it does not by itself set Django is_superuser.

**Change:** Use a server-owned role/membership table and credential approval lifecycle. Separate email_verified_at from professional_verification_status. Reject admin/professional role grants in public profile and login payloads.

**Acceptance check:** All privilege changes require authorized approval; re-login cannot change role grants or professional approval; invalid role strings fail validation.

**Source:** [backend/apps/accounts/views.py](D:/Health/backend/apps/accounts/views.py:178); [backend/apps/accounts/views.py](D:/Health/backend/apps/accounts/views.py:303); [backend/apps/accounts/serializers.py](D:/Health/backend/apps/accounts/serializers.py:14)


### S07 · High — OTP secrets, abuse controls, and consumption need hardening

**Evidence:** Reproduced dev_otp in a DEBUG response. Source also prints every OTP, stores plaintext OTPs, uses random.randint, has no configured throttles/attempt limit, and reads then consumes without an atomic guard.

**Impact:** With DEBUG exposed, inbox possession can be bypassed. Otherwise logs/admin/database readers see active credentials; guessing, mail abuse, and concurrent reuse are insufficiently controlled. Concurrent reuse was not load-tested.

**Change:** Remove OTP responses and secret logging; use a cryptographic generator, keyed storage, per-account and per-origin limits, attempt budgets, and atomic one-time consumption. Validate the complete operation before consuming the code. Use a real delivery backend in production.

**Acceptance check:** No response/log contains the code; exhausted attempts are rejected; simultaneous verification yields at most one success; delivery failure is reported accurately.

**Source:** [backend/apps/accounts/models.py](D:/Health/backend/apps/accounts/models.py:107); [backend/apps/accounts/views.py](D:/Health/backend/apps/accounts/views.py:67); [backend/apps/accounts/views.py](D:/Health/backend/apps/accounts/views.py:126); [backend/config/settings.py](D:/Health/backend/config/settings.py:111)


### S08 · High — Lab and hospital endpoints accept any authenticated account

**Evidence:** Reproduced: an ordinary patient publishes a lab report for another patient and creates a hospital admission. These endpoints check IsAuthenticated but no professional role, credential, organization membership, or patient relationship.

**Impact:** A signed-in patient can impersonate a care provider and inject clinical records. The lab/hospital owner filters on reads are useful but do not authorize who may become that owner.

**Change:** Add verified professional permissions and organization membership checks; authorize the selected patient/order/encounter. Preserve a distinct self-uploaded, unverified document workflow for patients.

**Acceptance check:** A patient token is denied provider writes; providers cannot operate on another organization's orders/admissions.

**Source:** [backend/apps/lab/views.py](D:/Health/backend/apps/lab/views.py:295); [backend/apps/hospital/views.py](D:/Health/backend/apps/hospital/views.py:11)


### S09 · High — Uploaded medical files have no access-controlled delivery path

**Evidence:** Source: DEBUG media routing serves MEDIA_ROOT directly; serializers expose FileField URLs; clients open those URLs externally. There is no download authorization layer or explicit content/size validation on these upload paths.

**Impact:** A known media URL remains usable without owner/consent checks in the current development configuration. Uploading arbitrary content and large files expands exposure. Production reverse-proxy/storage behavior was not available to inspect.

**Change:** Use private storage plus authorized streaming or short-lived signed downloads after access checks. Restrict content, size and allowed formats, quarantine/scan uploads, and serve untrusted content from an isolated origin.

**Acceptance check:** Anonymous/unrelated downloads fail; revoked consent cannot mint new links; oversized and disallowed files are rejected before publication.

**Source:** [backend/config/urls.py](D:/Health/backend/config/urls.py:42); [backend/apps/reports/models.py](D:/Health/backend/apps/reports/models.py:18); [health_platform/lib/features/reports/reports_screen.dart](D:/Health/health_platform/lib/features/reports/reports_screen.dart:381)


### S10 · High — Development security settings are the default deployment posture

**Evidence:** check --deploy produced six warnings: HSTS, HTTPS redirect, weak/insecure secret, secure session cookie, secure CSRF cookie, and DEBUG. Source defaults include a public secret, wildcard hosts, AllowAny, and unrestricted credentialed CORS.

**Impact:** Deployment without overrides exposes debug behavior and weak signing configuration. CORS broadens browser access to already-open APIs; it is not an authentication substitute. JWT signing uses Django SECRET_KEY by default unless overridden.

**Change:** Separate local/production settings; require secrets with no production fallback, explicit hosts/origins, HTTPS configuration and secure cookies. Rotate deployed known keys and invalidate affected tokens.

**Acceptance check:** Production fails to boot without required secrets and passes reviewed deployment checks; an unapproved origin is rejected.

**Source:** [backend/config/settings.py](D:/Health/backend/config/settings.py:17); [backend/config/settings.py](D:/Health/backend/config/settings.py:132)


### S11 · High — Client networking is hardcoded to plaintext local addresses

**Evidence:** Source: web always selects http://127.0.0.1:8000 before reading BACKEND_URL; non-web falls back to a private Wi-Fi IP. Android explicitly permits cleartext traffic.

**Impact:** A hosted web app contacts the visitor's own computer, and tokens/health data use plaintext HTTP in the configured flows. Environment overrides do not work for web.

**Change:** Read an explicit validated API origin for every platform; prefer a same-origin HTTPS API on web. Keep HTTP exemptions in development-only configuration.

**Acceptance check:** A release build reaches the configured HTTPS server on another machine; no production request uses loopback/private demo addresses.

**Source:** [health_platform/lib/core/network/api_client.dart](D:/Health/health_platform/lib/core/network/api_client.dart:7); [health_platform/android/app/src/main/AndroidManifest.xml](D:/Health/health_platform/android/app/src/main/AndroidManifest.xml:13)


### S12 · High — Session expiration and logout are incomplete

**Evidence:** Source: access tokens last seven days; refresh tokens are issued but there is no refresh URL/client refresh flow. Logout only clears memory; no blacklist app or server logout exists. Client auth is not restored from a validated session on restart.

**Impact:** A copied access token can remain usable after UI logout. Sessions disappear on reload, and eventual expiry becomes silent empty/error behavior.

**Change:** Implement short-lived access, refresh rotation/revocation, explicit session lifecycle, and centralized 401 handling. Decide browser/native secure session storage deliberately; add server-side session invalidation if immediate access-token logout is required.

**Acceptance check:** Expiry refreshes once or signs out cleanly; revoked refresh tokens fail; logout semantics are documented and tested across devices.

**Source:** [backend/config/settings.py](D:/Health/backend/config/settings.py:121); [backend/apps/accounts/urls.py](D:/Health/backend/apps/accounts/urls.py:4); [health_platform/lib/core/network/api_client.dart](D:/Health/health_platform/lib/core/network/api_client.dart:631)


### L01 · Critical — Lab uploads fabricate clinical measurements

**Evidence:** Reproduced: a CBC upload without any file or parameters creates five hardcoded measurements. PDF/image contents are not parsed. The fallback includes preset normal values and a summary claiming verified extraction.

**Impact:** Invented data is stored as a patient's diagnostic result. Frontend preset filenames/previews also imply an attached report even when there are no bytes.

**Change:** Remove clinical-data fallbacks from production. Store attachments as unparsed/pending review; require explicit verified parameters or a validated extraction pipeline with provenance and human review before publishing.

**Acceptance check:** A blank/unparsed upload never creates measurements or a Normal/Verified claim; every published value traces to a source and approving actor.

**Source:** [backend/apps/lab/views.py](D:/Health/backend/apps/lab/views.py:426); [health_platform/lib/features/lab_portal/upload_report/upload_report_screen.dart](D:/Health/health_platform/lib/features/lab_portal/upload_report/upload_report_screen.dart:55)


### L02 · High — Patient matching can silently select the wrong person

**Evidence:** Source: several resolvers accept UUID prefixes, substring names/email matches, or choose the first result. PAT codes use only six UUID hex digits without a uniqueness constraint. PAT- yields an empty prefix that matches any UUID.

**Impact:** Reports, appointments, and admissions can be attached to another person. CSV direct upload deliberately assigns every row to the selected patient, including rows identifying different people.

**Change:** Use exact immutable identifiers with database uniqueness. Treat display names as search-only. Require an explicit match confirmation; reject ambiguous/empty identifiers and cross-patient rows in a single-patient upload.

**Acceptance check:** Two similar names or colliding display codes never auto-resolve; PAT- is invalid; mixed-patient CSV input is rejected or safely routed as an explicit batch.

**Source:** [backend/apps/doctor/views.py](D:/Health/backend/apps/doctor/views.py:16); [backend/apps/lab/views.py](D:/Health/backend/apps/lab/views.py:113); [backend/apps/lab/views.py](D:/Health/backend/apps/lab/views.py:327); [backend/apps/hospital/views.py](D:/Health/backend/apps/hospital/views.py:39)


### L03 · Critical — Batch reports attach the complete multi-patient CSV to each patient

**Evidence:** Source: batch-upload passes the original uploaded_file into process_lab_csv_data. Every generated LabReport and MedicalRecord stores that same full document as its attachment.

**Impact:** Even after API authorization is repaired, a patient downloading their legitimate attachment may receive other patients' rows from the batch.

**Change:** Retain original batches in provider-only storage. Generate per-patient artifacts or attach no patient-visible source until split and verified.

**Acceptance check:** A batch containing patients A and B produces an A download containing no B identifiers or results.

**Source:** [backend/apps/lab/views.py](D:/Health/backend/apps/lab/views.py:246); [backend/apps/lab/views.py](D:/Health/backend/apps/lab/views.py:169)


### L04 · High — CSV normalization loses clinical meaning and import boundaries

**Evidence:** Reproduced: status=low is stored Normal. Source additionally ignores override_test_name/category, groups by patient and test name alone, defaults dates to today, duplicates units into values, and silently catches direct CSV exceptions before creating a fallback report.

**Impact:** Abnormal low results are misclassified; repeated specimens can merge; imported dates/categories can be lost; malformed uploads may publish partial or unrelated fallback results. CSV response also hardcodes status=Normal.

**Change:** Define a validated import schema with specimen/order identifiers and collection/report dates. Normalize high/low/critical explicitly, preserve raw data, preview row errors, and reject malformed imports without fallback publication.

**Acceptance check:** Fixtures cover low/critical, two specimens of one test, dates, quoted CSV fields, invalid rows, and form overrides; returned status matches persisted results.

**Source:** [backend/apps/lab/views.py](D:/Health/backend/apps/lab/views.py:153); [backend/apps/lab/views.py](D:/Health/backend/apps/lab/views.py:159); [backend/apps/lab/views.py](D:/Health/backend/apps/lab/views.py:386)


### L05 · High — Multi-record clinical writes are not atomic or idempotent

**Evidence:** Reproduced: publishing one order twice creates two reports. Source has no transactions around report/parameter/order updates, prescription/medicine/locker sync, or admission/discharge sync. Repeated discharge also appends summaries.

**Impact:** Retries or partial failures can create duplicates, incomplete prescriptions, mismatched status, or a discharged stay without its summary.

**Change:** Create domain services using transaction.atomic, enforce valid status transitions, link canonical records to their source order/encounter, and use idempotency keys/unique constraints. Handle storage changes and notifications after commit.

**Acceptance check:** Repeat requests return the same result; injected mid-operation failures leave no partial clinical state.

**Source:** [backend/apps/lab/views.py](D:/Health/backend/apps/lab/views.py:33); [backend/apps/doctor/serializers.py](D:/Health/backend/apps/doctor/serializers.py:33); [backend/apps/hospital/views.py](D:/Health/backend/apps/hospital/views.py:88)


### L06 · High — Hospital admission linkage and bed allocation are unreliable

**Evidence:** Reproduced: a supplied patient UUID in the patient field is overridden with None when name lookup does not match. Omitting ward bypasses the occupancy check but saves the model's default ward; two admissions can take the same bed. There is also a check-then-save concurrency race.

**Impact:** An admission can lose its intended patient link and fail locker synchronization; beds can be double-booked.

**Change:** Validate identifiers through one serializer; honor patient or reject conflicting fields. Resolve defaults before checking occupancy and enforce one active occupancy per organization/bed transactionally.

**Acceptance check:** UUID-only linkage is retained; two same-bed requests, including simultaneous requests and omitted/default wards, cannot both succeed.

**Source:** [backend/apps/hospital/views.py](D:/Health/backend/apps/hospital/views.py:29); [backend/apps/hospital/views.py](D:/Health/backend/apps/hospital/views.py:50); [backend/apps/hospital/models.py](D:/Health/backend/apps/hospital/models.py:16)


### L07 · High — Appointment ownership changes with role combination or invalid input

**Evidence:** Reproduced: a doctor with roles=[doctor,patient] receives their personal patient appointments rather than booked doctor visits. An unknown patient identifier creates an appointment with the doctor as patient. patient_email also permits querying another patient's bookings.

**Impact:** Normal multi-role doctors see an empty/wrong schedule, and mistyped patients silently become the wrong appointment owner.

**Change:** Separate doctor and patient appointment resources or authorize an explicit context. Reject unresolved patients; enforce provider/patient scope and use validated date/time fields with booking-conflict rules.

**Acceptance check:** A multi-role doctor sees the correct lists in both portals; unknown patients return 400/404; unrelated patient_email queries are denied.

**Source:** [backend/apps/doctor/views.py](D:/Health/backend/apps/doctor/views.py:114); [backend/apps/doctor/views.py](D:/Health/backend/apps/doctor/views.py:130); [backend/apps/doctor/models.py](D:/Health/backend/apps/doctor/models.py:14)


### L08 · Medium — Clinical chart and prescription sync omit relevant data

**Evidence:** Source: the chart returns prescriptions, lab reports, and vitals but never MedicalRecord, so general notes/admission/discharge summaries are absent. Prescription locker descriptions include medicine names but omit dosage/duration/instructions. The UI follow-up date is never submitted.

**Impact:** The advertised unified chart and patient-facing prescription record are incomplete.

**Change:** Represent encounters and prescriptions canonically; include authorized document types and structured medication instructions. Persist follow-up dates or remove the unused field.

**Acceptance check:** A consented chart shows admission/discharge records; patient prescription detail includes every medication instruction; follow-up survives reload.

**Source:** [backend/apps/doctor/views.py](D:/Health/backend/apps/doctor/views.py:361); [backend/apps/doctor/views.py](D:/Health/backend/apps/doctor/views.py:327); [health_platform/lib/features/doctor_portal/add_diagnosis_screen.dart](D:/Health/health_platform/lib/features/doctor_portal/add_diagnosis_screen.dart:31)


### L09 · Medium — Profile and clinical schemas permit inconsistent data

**Evidence:** Reproduced: patients/me omits current_medications even though the model/auth response contains it. Birth dates are strings and the doctor flow stores values such as 54 yrs; JSON medical lists and several status fields are weakly validated. Approved consent with no expiry is treated as active indefinitely.

**Impact:** Age calculations, medication editing, expiry expectations, and downstream integrations cannot rely on one consistent contract.

**Change:** Use typed dates and enums, structured list validation, explicit unknown values, and clear timezone semantics. Expose medications consistently. Require expiry for time-limited consent and preserve consent history rather than overwriting it.

**Acceptance check:** Invalid dates/statuses/list types are rejected; medication PATCH round-trips; approved time-limited consent always has an expiry.

**Source:** [backend/apps/patients/serializers.py](D:/Health/backend/apps/patients/serializers.py:5); [backend/apps/patients/models.py](D:/Health/backend/apps/patients/models.py:12); [backend/apps/doctor/models.py](D:/Health/backend/apps/doctor/models.py:65)


### F01 · High — Client error handling reports failed writes as successful

**Evidence:** Source: many API mutations decode JSON without checking HTTP status; notifiers optimistically mutate and swallow exceptions. AddDiagnosis marks submitted after a rejected response. Discharge sets submitted=true even in catch.

**Impact:** Users can believe a prescription, admission, consent decision, or discharge was saved when it was rejected or the server was unavailable.

**Change:** Centralize typed response/error handling and timeouts. Await writes, show actual errors, reconcile or roll back optimistic changes, and only display success after persisted confirmation.

**Acceptance check:** 403, 400, 500, timeout, and invalid JSON never produce a success state; retry does not duplicate records.

**Source:** [health_platform/lib/core/network/api_client.dart](D:/Health/health_platform/lib/core/network/api_client.dart:312); [health_platform/lib/features/hospital_portal/discharge_summary/discharge_summary_screen.dart](D:/Health/health_platform/lib/features/hospital_portal/discharge_summary/discharge_summary_screen.dart:90); [health_platform/lib/core/config/providers.dart](D:/Health/health_platform/lib/core/config/providers.dart:908)


### F02 · High — Profile and emergency edit buttons do not persist their promises

**Evidence:** Source: settings, doctor-profile and hospital-profile Save handlers only close dialogs and show success. Emergency edits change AuthNotifier memory only. API emergency helpers point at an absent /patients/emergency-card/ route (404 reproduced).

**Impact:** Emergency information reverts after re-login/reload, and professional/profile edits are discarded entirely.

**Change:** Implement authorized profile PATCH flows, connect UI forms, await persistence, and refresh the canonical user. Use patients/me consistently or implement and test the intended emergency resource.

**Acceptance check:** Edit, reload, and sign in on another device show the saved values; backend validation errors remain visible.

**Source:** [health_platform/lib/features/settings/settings_screen.dart](D:/Health/health_platform/lib/features/settings/settings_screen.dart:66); [health_platform/lib/features/doctor_portal/doctor_profile_screen.dart](D:/Health/health_platform/lib/features/doctor_portal/doctor_profile_screen.dart:83); [health_platform/lib/features/hospital_portal/hospital_profile_screen.dart](D:/Health/health_platform/lib/features/hospital_portal/hospital_profile_screen.dart:79); [health_platform/lib/features/emergency/emergency_screen.dart](D:/Health/health_platform/lib/features/emergency/emergency_screen.dart:128)


### F03 · High — Patient record upload discards file bytes and report entry drops findings

**Evidence:** Source: record picker reads bytes but retains only filename/size; addRecord sends JSON without a file. Patient report form collects key findings but creates a LabReport without summary or parameters.

**Impact:** A successful-looking medical upload loses its attachment; entered findings disappear from saved reports.

**Change:** Use multipart uploads and persist the returned file identity; map all submitted report fields and remove unsupported inputs until implemented.

**Acceptance check:** Upload and reload yield byte-identical downloads; all entered findings are present in the stored report.

**Source:** [health_platform/lib/features/records/records_screen.dart](D:/Health/health_platform/lib/features/records/records_screen.dart:164); [health_platform/lib/core/config/providers.dart](D:/Health/health_platform/lib/core/config/providers.dart:454); [health_platform/lib/features/reports/reports_screen.dart](D:/Health/health_platform/lib/features/reports/reports_screen.dart:124)


### F04 · Medium — Delete and appointment cancellation only alter memory

**Evidence:** Source: deleteRecord, deleteReport, and cancelAppointment only filter provider lists. Matching backend detail-delete/cancel endpoints do not exist.

**Impact:** Items reappear on refresh and the user has no durable cancellation/deletion result.

**Change:** Implement authorized, audited lifecycle endpoints; for clinical records consider amendment/withdrawal rather than destructive deletion. Await server confirmation.

**Acceptance check:** Cancellation persists after reload and releases its slot; deletion/withdrawal behavior is explicit and auditable.

**Source:** [health_platform/lib/core/config/providers.dart](D:/Health/health_platform/lib/core/config/providers.dart:469); [health_platform/lib/core/config/providers.dart](D:/Health/health_platform/lib/core/config/providers.dart:505); [health_platform/lib/core/config/providers.dart](D:/Health/health_platform/lib/core/config/providers.dart:616)


### F05 · High — Queued lab orders are disconnected from the upload workflow

**Evidence:** Source: pending rows navigate with order/patient/test/category query parameters, but the router constructs a LabShell without reading them; its UploadReportScreen has no arguments. The upload handler calls direct upload and never uses widget.orderId or publishes/completes the queued order. New queue entries also omit patient linkage.

**Impact:** Patient/test context is lost, orders remain pending, and reports can be created independently of the selected order.

**Change:** Route to an order-backed upload screen using immutable order ID; fetch and authorize order context; require patient linkage and publish through one order-aware transaction.

**Acceptance check:** Selecting a pending order preserves its exact patient/test, publishes once, completes that order, and removes it from pending counts.

**Source:** [health_platform/lib/features/lab_portal/pending_reports/pending_reports_screen.dart](D:/Health/health_platform/lib/features/lab_portal/pending_reports/pending_reports_screen.dart:259); [health_platform/lib/core/config/router.dart](D:/Health/health_platform/lib/core/config/router.dart:120); [health_platform/lib/features/lab_portal/upload_report/upload_report_screen.dart](D:/Health/health_platform/lib/features/lab_portal/upload_report/upload_report_screen.dart:366)


### F06 · Medium — Some routes select nonexistent or incorrect screens

**Evidence:** Source: /lab/integration uses initialIndex=3 but LabShell has only three screens (0-2). /hospital/integration selects HospitalProfileScreen. MainShell and LabShell also initialize the index only in initState, unlike HospitalShell's didUpdateWidget handling.

**Impact:** The lab integration route has no valid selected child; hospital integration shows a profile. Same-widget route changes may retain an old tab. These route effects were source-reviewed, not device-tested.

**Change:** Use explicit routes for screens and one navigation source of truth; wire or remove obsolete integration routes; handle parameter changes and guard route indices.

**Acceptance check:** Every registered deep link renders its intended screen; browser back/forward and tab links stay synchronized.

**Source:** [health_platform/lib/core/config/router.dart](D:/Health/health_platform/lib/core/config/router.dart:124); [health_platform/lib/features/lab_portal/lab_shell.dart](D:/Health/health_platform/lib/features/lab_portal/lab_shell.dart:32); [health_platform/lib/features/hospital_portal/hospital_shell.dart](D:/Health/health_platform/lib/features/hospital_portal/hospital_shell.dart:33); [health_platform/lib/shared/widgets/main_shell.dart](D:/Health/health_platform/lib/shared/widgets/main_shell.dart:46)


### F07 · Medium — OTP resend timer never enables resend at zero

**Evidence:** Source: the timer decrements 1 to 0 and returns false. _canResend is set only in the else branch on a subsequent iteration, which never happens.

**Impact:** Users whose OTP is delayed/expired cannot use the resend control normally.

**Change:** Set canResend when the decrement reaches zero; use a cancellable timer and clear stale OTP/pending-registration state when beginning a new flow.

**Acceptance check:** A fake-clock widget test advances 30 seconds, finds resend enabled, resends once, and verifies the timer resets.

**Source:** [health_platform/lib/features/auth/otp_entry_screen.dart](D:/Health/health_platform/lib/features/auth/otp_entry_screen.dart:36)


### F08 · High — Provider caches can remain stale or cross session boundaries

**Evidence:** Source: many fetches update state only for nonempty lists; asynchronous requests are not bound to an auth/session generation. Logout resets caches but pending requests can complete later. Notifications/active role are not reset with the other providers.

**Impact:** An empty server result leaves old data on screen; slow responses can repopulate a signed-out or different-user session. The race is inferred from source, not concurrency-tested.

**Change:** Key caches to authenticated user/context; cancel or discard stale responses; assign empty results; invalidate all user-scoped providers on logout; distinguish loading/error/empty states.

**Acceptance check:** Delay user A's response until after user B signs in; it is discarded. Empty responses clear data, and logout clears notifications and active role.

**Source:** [health_platform/lib/core/config/providers.dart](D:/Health/health_platform/lib/core/config/providers.dart:448); [health_platform/lib/core/config/providers.dart](D:/Health/health_platform/lib/core/config/providers.dart:351)


### F09 · High — Unauthenticated UI has privileged demo identity and offline login fallback

**Evidence:** Source: userProvider creates a named fallback user with patient/doctor/hospital/lab/admin roles and writes its email into the API singleton. Router has no auth/role redirect. The phone/fallback verification path accepts any six characters locally; the visible login screen currently uses email.

**Impact:** Direct routes appear signed in and can activate the backend identity fallbacks. Dormant mock authentication is unsafe to retain in the production path.

**Change:** Return no user until a server-validated session exists; remove offline verification/demo identity from release code; add route guards and server permission enforcement.

**Acceptance check:** Every protected deep link redirects signed-out users; no credential-free path creates a verified user; role menus reflect server grants.

**Source:** [health_platform/lib/core/config/providers.dart](D:/Health/health_platform/lib/core/config/providers.dart:402); [health_platform/lib/core/config/providers.dart](D:/Health/health_platform/lib/core/config/providers.dart:319); [health_platform/lib/core/config/router.dart](D:/Health/health_platform/lib/core/config/router.dart:19)


### F10 · Medium — Notifications, integration status, and operational metrics are placeholders

**Evidence:** Source: notifications build returns fixed clinical messages. Lab/hospital integration screens show ONLINE and HL7/FHIR labels without connectors. Admin returns constant engine health; healthSummary ignores recorded vitals. Hospital counts include discharged stays; pending lab queries include completed orders.

**Impact:** Users see events and system health that are not measured, and operational queues/counts are misleading.

**Change:** Drive status from real health probes and filtered server aggregates. Persist user-scoped notifications and delivery outcomes. Label integrations unavailable until implemented; connect vitals to the summary.

**Acceptance check:** A fresh account has no fictional notifications; disconnecting a gateway changes status; completed/discharged items are excluded from active queues.

**Source:** [health_platform/lib/features/notifications/notifications_provider.dart](D:/Health/health_platform/lib/features/notifications/notifications_provider.dart:41); [backend/apps/accounts/admin_views.py](D:/Health/backend/apps/accounts/admin_views.py:65); [health_platform/lib/core/config/providers.dart](D:/Health/health_platform/lib/core/config/providers.dart:700); [backend/apps/lab/views.py](D:/Health/backend/apps/lab/views.py:18); [backend/apps/hospital/views.py](D:/Health/backend/apps/hospital/views.py:19)


### F11 · Medium — Family linking does not actually link a patient account

**Evidence:** Source: UI accepts a patient ID/email and says linked, but addMember sends only demographics. FamilyMember has no linked-user foreign key or guardian authorization relationship; total_records is a mutable counter.

**Impact:** The feature creates an address-book-like dependent profile, not authorized access to another patient's records.

**Change:** Either describe it accurately as a local dependent profile or implement verified guardian/delegate relationships with explicit scopes and consent. Derive record counts from actual relationships.

**Acceptance check:** Linking requires the defined consent/guardian process and resolves an exact account; counts reflect accessible records.

**Source:** [health_platform/lib/features/family/family_screen.dart](D:/Health/health_platform/lib/features/family/family_screen.dart:187); [health_platform/lib/core/config/providers.dart](D:/Health/health_platform/lib/core/config/providers.dart:561); [backend/apps/patients/models.py](D:/Health/backend/apps/patients/models.py:45)


### F12 · High — Forms silently default unknown clinical facts

**Evidence:** Source: signup defaults blood group to O+, family form defaults B+, admission model defaults age 35 and Male, and discharge narrative is prefilled with stable/normal findings.

**Impact:** Skipping a field can turn an assumption into recorded clinical information. This compounds the fabricated-lab issue.

**Change:** Default clinical values to unknown/unrecorded. Require deliberate confirmation for relevant clinical assertions and record author/source/time.

**Acceptance check:** Submitting untouched optional fields stores unknown, never an invented blood group, age, or clinical observation.

**Source:** [health_platform/lib/features/auth/signup_screen.dart](D:/Health/health_platform/lib/features/auth/signup_screen.dart:49); [health_platform/lib/features/family/family_screen.dart](D:/Health/health_platform/lib/features/family/family_screen.dart:28); [backend/apps/hospital/models.py](D:/Health/backend/apps/hospital/models.py:14); [health_platform/lib/features/hospital_portal/discharge_summary/discharge_summary_screen.dart](D:/Health/health_platform/lib/features/hospital_portal/discharge_summary/discharge_summary_screen.dart:39)


### F13 · Medium — Asynchronous search and upload state can reuse stale results

**Evidence:** Source: global/patient search does not debounce or discard older responses. Picking CSV sets _customExtractedParameters; picking a subsequent non-CSV file does not clear it. File picking calls setState after awaits without an initial mounted check.

**Impact:** Search results may belong to an earlier query, and an uploaded PDF can inherit a previously selected CSV's parameters. Closing the screen during picking can trigger disposed-state errors.

**Change:** Use request sequence IDs/cancellation, reset dependent fields atomically whenever a file or target patient changes, and check mounted after async work.

**Acceptance check:** Reverse response order leaves the latest search visible; CSV-to-PDF selection clears old parameters; closing a picker screen is safe.

**Source:** [health_platform/lib/shared/widgets/global_search_dialog.dart](D:/Health/health_platform/lib/shared/widgets/global_search_dialog.dart:38); [health_platform/lib/features/lab_portal/upload_report/upload_report_screen.dart](D:/Health/health_platform/lib/features/lab_portal/upload_report/upload_report_screen.dart:312)


### F14 · Medium — Signup remains stuck after a failed OTP request

**Evidence:** Source: SignupScreen sets its private _isLoading flag true before starting registration and never resets it. The submit button is disabled when either that flag or authState.isLoading is true; this screen does not display authState.error.

**Impact:** An existing-email rejection, SMTP failure or network error can leave the form indefinitely disabled without explaining the failure.

**Change:** Use one asynchronous auth loading state, await registration/send completion, reset in finally, and render the server error next to the form.

**Acceptance check:** Simulate an existing email and a network failure: the error appears and the corrected form can be submitted again without restarting the app.

**Source:** [health_platform/lib/features/auth/signup_screen.dart](D:/Health/health_platform/lib/features/auth/signup_screen.dart:117); [health_platform/lib/features/auth/signup_screen.dart](D:/Health/health_platform/lib/features/auth/signup_screen.dart:649)


### T01 · Medium — PostgreSQL readiness is not implemented by the current settings

**Evidence:** Source: DATABASES configures only ENGINE and NAME, without application-level USER/PASSWORD/HOST/PORT or a URL parser. Local deployment is SQLite; no PostgreSQL test was run.

**Impact:** Changing the advertised engine is not a complete ordinary remote PostgreSQL setup. PostgreSQL-specific behavior, concurrency, and deployment remain unverified.

**Change:** Provide explicit tested database configuration, a redacted env example, migrations/backup procedures, and PostgreSQL CI coverage before claiming support.

**Acceptance check:** A clean environment can connect, migrate, run the permission suite, and restore a backup using documented configuration.

**Source:** [backend/config/settings.py](D:/Health/backend/config/settings.py:78)


### T02 · High — Tests do not validate the security boundaries and currently fail

**Evidence:** Executed: Django discovers 12 tests; 8 pass and 4 fail. Two auth tests assume unknown-email login creates an account; two prescription tests omit required consent. Four app tests.py files are stubs. Flutter has one passing smoke test.

**Impact:** Existing tests do not establish privacy, authorization, correct uploads, persistence, or end-to-end safety. force_authenticate bypasses real login behavior in many tests.

**Change:** Update obsolete fixtures to the intended contract without weakening security. Add anonymous/wrong-role/wrong-owner/expired-consent tests, actual token tests, import validation, idempotency and critical UI persistence tests to CI.

**Acceptance check:** All existing tests pass for the intended behavior; every critical finding has a regression test that fails before the fix and passes afterward.

**Source:** [backend/apps/accounts/test_full_system.py](D:/Health/backend/apps/accounts/test_full_system.py:40); [backend/apps/reports/tests.py](D:/Health/backend/apps/reports/tests.py:94); [health_platform/test/widget_test.dart](D:/Health/health_platform/test/widget_test.dart:8)


### T03 · High — Generated audit reports hardcode success and production-readiness claims

**Evidence:** Source: report builders insert 12/12 Passed, 27/27 and ZERO DEFECTS text directly. Current fresh test results contradict those claims. The PDF titled 30Page contains 10 pages.

**Impact:** Screenshots and old generated documents can give false assurance about security and functionality. No claim of encryption/compliance should be treated as established by those reports.

**Change:** Generate verification documents only from timestamped test artifacts tied to a commit/configuration. Separate implemented, demonstrated, tested, planned and independently assessed capabilities.

**Acceptance check:** A failing test produces a failing report and nonzero verification status; no static production-ready badge overrides results.

**Source:** [backend/generate_pdf_report.py](D:/Health/backend/generate_pdf_report.py:192); [generate_hardcore_testing_report_pdf.py](D:/Health/generate_hardcore_testing_report_pdf.py:317)


### T04 · High — Demo utilities can destroy data or use known administrator credentials

**Evidence:** Source: reset_and_seed_clean_db deletes operational tables, users and media and creates a superuser with a fixed password. run_hardcore_tests uses the configured real database and writes records; inspect_db prints recent OTPs. These utilities were not executed.

**Impact:** An operator can irreversibly destroy data or leave a known-credential administrator by running a seemingly convenient setup/test script.

**Change:** Replace with explicit development-only management commands, separate database settings, environment guards and synthetic credentials; isolate all tests and stop printing OTPs.

**Acceptance check:** Reset/seed refuse production settings, tests never touch live DB/media, and seeded credentials cannot persist in a release environment.

**Source:** [backend/reset_and_seed_clean_db.py](D:/Health/backend/reset_and_seed_clean_db.py:17); [backend/reset_and_seed_clean_db.py](D:/Health/backend/reset_and_seed_clean_db.py:64); [run_hardcore_tests.py](D:/Health/run_hardcore_tests.py:9); [backend/inspect_db.py](D:/Health/backend/inspect_db.py:20)


### T05 · Medium — Schema lacks organization membership, clinical provenance, and access audit history

**Evidence:** Source: labs/hospitals are user accounts; clinical author/facility names are strings; report source-order and record-source links are absent. ConsentRequest is mutable with no unique actor pair or immutable grant/revocation history. General clinical read/write audit events are absent.

**Impact:** Shared staff workflows, reliable attribution, duplicate prevention, amendment history and access investigations are difficult. Django admin logging does not cover these API operations.

**Change:** Introduce Organization, Membership, verified Credential, Encounter, versioned clinical documents, source order/report references, and immutable access/consent events. Normalize roles and derive patient display identifiers safely.

**Acceptance check:** Two staff members in one organization share only authorized resources; every clinical change/download/consent action has attributable provenance.

**Source:** [backend/apps/accounts/models.py](D:/Health/backend/apps/accounts/models.py:74); [backend/apps/reports/models.py](D:/Health/backend/apps/reports/models.py:9); [backend/apps/doctor/models.py](D:/Health/backend/apps/doctor/models.py:52)


### T06 · Medium — Queries and polling will scale poorly

**Evidence:** Source: patient matching scans User.objects.all in Python; serializers access relations per item; most lists have no pagination. Patient dashboard polls three endpoints every three seconds, including while retained in an IndexedStack.

**Impact:** Latency, database load and bandwidth grow with records and concurrent sessions; errors may still look like empty lists.

**Change:** Move exact matching/filtering to indexed DB queries, use select_related/prefetch_related, paginate, and add measured query budgets. Poll only visible authenticated views with backoff, or introduce event delivery after correctness is established.

**Acceptance check:** Representative large fixtures stay within documented query/latency budgets; hidden/signed-out screens stop polling.

**Source:** [backend/apps/doctor/views.py](D:/Health/backend/apps/doctor/views.py:157); [backend/apps/reports/serializers.py](D:/Health/backend/apps/reports/serializers.py:12); [health_platform/lib/features/dashboard/dashboard_screen.dart](D:/Health/health_platform/lib/features/dashboard/dashboard_screen.dart:33)


### T07 · Medium — Release platform configuration remains development-oriented

**Evidence:** Source: Android release uses debug signing. iOS has no explicit policy for the configured HTTP endpoint. macOS sandbox release entitlements omit network client access. Native app behavior was not built or device-tested.

**Impact:** Distribution identity and networking can fail outside local development. Several Android sensitive permissions are declared without a demonstrated need in the current flows.

**Change:** Configure production signing securely, HTTPS, required platform network entitlements and minimal permissions; test each supported platform. Do not advertise untested targets as ready.

**Acceptance check:** Signed release builds authenticate/upload/download on real target devices under release security policies.

**Source:** [health_platform/android/app/build.gradle.kts](D:/Health/health_platform/android/app/build.gradle.kts:32); [health_platform/ios/Runner/Info.plist](D:/Health/health_platform/ios/Runner/Info.plist:4); [health_platform/macos/Runner/Release.entitlements](D:/Health/health_platform/macos/Runner/Release.entitlements:5)


### T08 · Medium — Build/dependency documentation is insufficient for reproducible releases

**Evidence:** Source: Python dependencies mostly have unbounded upper versions and no lock; PDF generation dependencies such as reportlab are installed locally but absent from requirements.txt. Flutter has a lockfile, but README is the starter template. No project CI/deployment manifest was found in the surveyed source.

**Impact:** Another machine may install different dependencies or fail report generation; dependency vulnerabilities and release behavior are not continuously checked.

**Change:** Lock production/dev dependencies, separate document-generation extras, add a real setup/env/API README and CI checks. Audit installed/locked versions using a maintained advisory scanner before release.

**Acceptance check:** A clean checkout can install deterministically and run the same checks. Advisory scanning is recorded; no unsupported CVE-free claim is made.

**Source:** [backend/requirements.txt](D:/Health/backend/requirements.txt:1); [health_platform/README.md](D:/Health/health_platform/README.md:3); [health_platform/pubspec.yaml](D:/Health/health_platform/pubspec.yaml:30)


### T09 · Low — Legacy/demo artifacts obscure the supported product

**Evidence:** Source: src/components contains three React components but no React app manifest/entry point in the surveyed project. Its OTP is simulated. mock_data, screenshot/capture utilities, root PDF generators and multiple overlapping reports coexist with the live Flutter app.

**Impact:** Maintainers can edit the wrong frontend or mistake mock demonstrations for working functionality. Binary screenshots are historical evidence, not executable verification.

**Change:** Document Flutter as the supported client; archive legacy React/demo assets, move scripts/docs/test fixtures into clear folders, and label generated artifacts with source commit and date.

**Acceptance check:** The root README explains every top-level directory and one documented path runs the supported app and tests.

**Source:** [src/components/AuthModal.jsx](D:/Health/src/components/AuthModal.jsx:24); [health_platform/lib/mock_data/mock_user.dart](D:/Health/health_platform/lib/mock_data/mock_user.dart:1)


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
- reproduce_findings.py and reproduction_results.json: 21 synthetic current-behavior reproductions. Re-run from D:\Health with `backend\venv\Scripts\python.exe audit\reproduce_findings.py`. The script deliberately reports whether a defect remains reproducible; it is not a pass/fail release gate.
- findings.json: structured repair backlog with source line anchors and acceptance checks.
- pdf_text/: extracted documentation text for internal comparison. These are local review intermediates, not replacement published reports.

## Primary technical references

These references support the repair approach; all project-specific findings above come from local source or local checks.

- [DRF permissions](https://www.django-rest-framework.org/api-guide/permissions/): authentication and object authorization must be enforced explicitly in custom views; list querysets must be appropriately scoped.
- [SimpleJWT settings](https://django-rest-framework-simplejwt.readthedocs.io/en/stable/settings.html) and [blacklist app](https://django-rest-framework-simplejwt.readthedocs.io/en/stable/blacklist_app.html): signing keys, token lifetime, rotation and revocation configuration.
- [Django deployment checklist](https://docs.djangoproject.com/en/5.2/howto/deployment/checklist/): production secrets, HTTPS, host validation and handling untrusted uploaded media.

This review does not certify regulatory compliance or the absence of undiscovered vulnerabilities. A full manual review of every layout/boilerplate line and binary asset, real-device end-to-end testing, deployment review and current dependency advisory scan remain separate coverage gaps.
