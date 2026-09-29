# Health Platform — progress tracker and account handoff

Last updated: 2026-09-29. Implementation in progress.

## Read this first when continuing

The user wants this file updated alongside implementation, starting with the next coding session, so work can continue from another account without relying on chat history. Read this file and `audit/PROJECT_REVIEW.md`, inspect the actual working tree, and reconcile progress before editing. Do not assume a new account has the previous conversation.

Project root: `D:\Health`.

Platform decision: patients use the Android/iOS app; doctors, labs, hospitals and administrators use web portals. Keep the Flutter + Django foundation and shared backend. Enforce identity, role, organization and patient-access permissions on the server, regardless of client platform.

## Completed versus pending

| Work | Status | Evidence / next action |
|---|---|---|
| Broad project inventory and audit | Completed with stated coverage limits | `audit/PROJECT_REVIEW.md`, `audit/file_inventory.csv` |
| Prioritized repair backlog | Completed | `audit/findings.json`: 44 grouped findings (8 critical, 21 high, 14 medium, 1 low) |
| Isolated backend defect reproductions | Completed | `audit/reproduce_findings.py`, `audit/reproduction_results.json`: 21 problematic behaviors reproduced; this is NOT a passing security score |
| Initial backend checks | Completed; failures remain | 12 tests: 8 pass, 4 fail. Deployment check: 6 warnings. Migration consistency: no changes detected |
| Initial Flutter checks | Completed; limited coverage | Static analysis clean; one MaterialApp smoke test passes. No complete device/end-to-end verification |
| Security and authorization repairs | In progress | Audit S01–S12; prioritize anonymous access, public admin, role escalation, OTP and consent bypass |
| Clinical-data integrity repairs | In progress | Audit L01–L09; stop fabricated measurements, cross-patient batch attachments and ambiguous identity matching; fix atomicity, duplication, admissions and appointments |
| Client saving/state/navigation repairs | In progress | Audit F01–F14; eliminate false success, persist edits/files, fix caching, routes, lab order flow and auth UI |
| Deployment, testing and maintenance repairs | Pending | Audit T01–T09; production configuration, release signing, dependencies, CI, audit history and documentation |
| New requested features | In progress | Detailed scope below |
| Final integrated verification | Pending | Patient mobile and professional web workflows, negative permission tests, failure/retry cases and applicable release checks |

Application repairs are now in progress; see the current checkpoint. Local SQLite migrations were applied on 2026-09-29 after a verified backup; see checkpoint. Existing application source and patient database were not changed during the audit. Audit artifacts and this handoff file were added. Recheck `git status` at the start of the next session.

## Agreed feature scope

| Feature | Expected behavior | Status |
|---|---|---|
| Unique email registration | One account per normalized email; reject duplicate registrations. Multiple roles use the same account. Do not assume Gmail-only registration or invent an alphabetic username rule; the original “alphabetics Gmail unique” phrase was interpreted as email uniqueness, and extra username requirements remain unconfirmed | Implemented; deployment portability pending |
| Discharge documents | Authorized hospital staff upload Word and PDF discharge documents linked to the correct patient/admission; patient can view/download them | Implemented; device QA pending |
| Disease dropdown | Common conditions in plain language, with Other and “I don't know.” Patient selections are not doctor-confirmed diagnoses. “Dropbox” meant dropdown, not the Dropbox service. Specific local languages remain to be selected | Implemented starter list; localization pending |
| Old medical reports | Patients upload historical reports, prescriptions and discharge documents, including photos/PDFs, dates and categories. Distinguish patient-uploaded documents from professionally verified records | Implemented; device QA pending |
| Patient notifications | Appointment booking/change/cancellation, completed discharge, new reports/prescriptions, consent requests and relevant booking/offer events. Persist user-specific events and preferences | Persistent in-app notifications/preferences implemented; push pending |
| Provider recommendations | Discover suitable doctors/labs using specialty, location, availability and verified feedback. Clinical relevance and promotional offers must be clearly distinguished | Implemented foundation; partner data pending |
| Booking from recommendations | Doctor cards offer Book Appointment; lab cards offer Book Test. Choose service and available slot, review price/offer, confirm; show in patient app and professional web portal | Implemented foundation; end-to-end QA pending |
| Referral offers | Provider-approved referral discounts, potentially 10%/20%, with eligibility, expiry and transparent final price. Actual partner terms are not yet agreed | Backend implemented; provider issuing UI/partner terms pending |
| Booking promo codes | Percentage and fixed-amount discounts applied and validated on the server during appointment/test booking; display original price, reduction and final payable amount | Implemented; partner validation pending |
| Genuinely free test campaigns | Approved partners can offer selected tests at ₹0, potentially to the first 100 eligible patients. No mandatory hidden registration/collection/report charges. Additional paid services must be optional. Example campaign codes and numbers are proposals, not live offers | ₹0 and capacity controls implemented; real partner offers pending |
| Campaign administration and redemption | Configure eligible services/locations/dates/slots, campaign and per-patient limits, discount caps and funding responsibility. Reserve an offer with booking, provide a redemption reference, and mark usage upon completion. Define cancellation/expiry behavior to avoid oversubscription | Create/reserve/redeem foundation implemented; edit/reporting UI pending |
| Campaign measurement | Track redemptions, completed bookings, costs and repeat visits to evaluate effectiveness; do not promise profitability | Basic counts; costs/repeat-visit reporting pending |
| Guided demo | Explain patient app and professional portal workflows using clearly isolated synthetic/demo data | Walkthrough implemented; isolated demo data pending |
| Ratings and feedback | Feedback after verified completed visits/tests/stays; ratings for doctors/labs/hospitals with moderation/complaint handling; use as one recommendation factor | Verified review and moderation foundation implemented; QA pending |

The user plans to speak with labs and hospitals. Build configuration for real partner-approved offers; do not publish invented partner agreements, availability or discounts. Appointment/test booking here concerns the product being built, not authorization to book real external appointments during development.

## Implementation order

1. Close critical server authorization/consent holes and stop fabricated or cross-patient clinical data.
2. Establish consistent identity, professional verification, organization access and exact patient matching.
3. Make clinical writes atomic/idempotent and correct appointment, admission, report and discharge relationships.
4. Make UI saving/errors, uploads, session caches and navigation truthful and reliable.
5. Implement the agreed new features on top of those controls, with server-authoritative booking/offer rules.
6. Complete production configuration and focused automated/integration/platform verification; regenerate documentation from actual evidence.

The user requested completion of all repairs/features in the next working session. Work toward the scope, but never mark unimplemented, untested or blocked work completed to meet that expectation.

## How to maintain this tracker during work

- Update after each meaningful work unit, before switching areas, and before stopping a session; do not wait until the account limit is reached.
- Use Pending / In progress / Implemented, verification pending / Completed / Blocked. Completed requires relevant checks and evidence; keep limitations explicit.
- Record exact files changed, audit IDs addressed, tests/commands and results, remaining failures, decisions and external dependencies.
- Preserve user edits. Inspect the working tree and any existing changes before continuing from a new account.
- Keep secrets, tokens, OTPs and real patient data out of this file and test logs.
- Leave a precise next step and any unfinished operation. If a test/service is still running, record how to identify it; do not assume session IDs transfer to another account.
- Do not rerun `backend/reset_and_seed_clean_db.py` or `run_hardcore_tests.py` against the existing database. The former deletes data; the latter mutates the configured database. Prefer isolated test databases.

## Current checkpoint

- Phase: Security/clinical repair plus booking features in progress. This is NOT a completed or deployment-ready release.
- Backend implemented: authenticated/scoped patient/report APIs; superuser-only admin; reviewed professional roles; exact patient resolver; patient-only consent; no auto-consent; hashed OTP with limits; refresh/logout; private download tickets; measured-only lab results; CSV validation/no shared batch attachments; transactional admissions/discharge with repeat protection.
- New `apps.care`: services, slots, campaigns, quotes, idempotent bookings, cancellation/completion, referrals, persisted notifications, completed-service feedback and admin moderation. Owner checks; server-authoritative percentage/fixed/free pricing; free means zero; campaign/per-patient capacity; partner attestation and funding/terms; feedback cannot precede appointment. No real offers seeded. Booking IDs are redemption references; no payment gateway is implied.
- Notifications wired into appointments, prescriptions, lab publishing, admission/discharge and consent. No mobile push delivery yet.
- Flutter: checked HTTP client with refresh/timeout/stale-session protection; protected routes; server roles; HTTPS-only release URLs; fixed OTP resend/signup loading; server notifications; patient care recommendations/booking/quote/promo/reviews; professional service/slot/campaign creation and booking actions. New toolbar booking links. Patient record upload now sends actual bytes and historical date; discharge can attach Word/PDF. Removed synthetic laboratory measurements and demo CSV; lab publication requires a real report/results file.
- Verification: full backend suite **39 tests passed** in isolated SQLite (`manage.py test --settings=config.test_settings --noinput`), including 15 security regressions + 6 booking scenarios. Flutter analyze clean; Django check and migration dry-run pass. Widget smoke and web release build passed before the latest client edits; latest web builds are blocked because Windows Application Control denies Flutter's `impellerc.exe` shader compiler. Re-run web build and device/browser QA when permitted. Real PostgreSQL concurrency remains pending.
- Migrations: accounts 0004/0005, hospital 0003/0004, reports 0003, care 0001 and token blacklist APPLIED to local SQLite on 2026-09-29. Preflight: 17 accounts, zero normalized-email duplicate groups, one active superuser. Verified SQLite backup at `D:\Health\backups\before-security-upgrade-20260929-093400.sqlite3` (integrity_check=ok). Migration normalized emails, expired/scrubbed old OTPs and marked existing professional roles pending review; NO professional was automatically approved. Clinical files were not modified. Django check clean. Backup contains private data and is gitignored.
- Next: re-run web build on a host where Windows permits Flutter `impellerc.exe`; complete device/browser QA and remaining access/session/UI workflows. Recent implemented additions: patient/professional provenance (legacy remains unknown); disease selector Other/unknown; historical PDF/photo/Word upload and preserved notes/date; persistent patient/emergency/professional profile changes; notification preferences; honest integration status and deletion availability; Android HTTPS/release signing configuration.
- Known remaining: organization membership/access, secure persistent login, remaining patient profile/load error states, notification push, campaign editing/metrics UI/referral issuing UI, rescheduling, server idempotency outside care, phone OTP provider integration, full audit F/T backlog, native release signing secrets, iOS signing and real partner configuration. The current web build cannot finish until Windows permits Flutter `impellerc.exe` or the build runs on an unrestricted supported builder. Provider creation forms are functional but need friendlier selectors/date pickers. Dashboard polling has been reduced to 60 seconds; static demo state selectors elsewhere still need review. Lab sample measurements and sample-patient CSV were removed; patient-supplied reports are labeled accordingly. Login response no longer confirms whether an email has an account.
- Care endpoints live under `/api/care/`; UI `/care`, professional `/doctor/bookings`, `/lab/bookings`, `/hospital/bookings`. Services remain empty until approved providers configure real services and future slots.
- Running jobs: None at this checkpoint.

## Work log

| Date | Work unit | Files / audit IDs | Verification | Remaining / next step |
|---|---|---|---|---|
| 2026-09-29 | Booking/promotion/notification foundation and Flutter compatibility | `backend/apps/care`, clinical notification hooks, API/router/care/notifications/upload screens | Full 39-test backend suite passes; Flutter analyze clean; Django check/migration dry-run pass. Latest web build blocked by Windows Application Control at `impellerc.exe` | Hospital 0004 applied after verified local backup; rerun web build on permitted host and finish workflows above |
| 2026-09-29 | Backend repair unit | accounts/doctor/patients/reports/lab/hospital/config and migrations | 15 new isolated security tests pass | Client compatibility and full-suite verification; existing DB untouched |
| 2026-09-28 | Audit and feature planning; persistent handoff established | `audit/`, `PROJECT_HANDOFF.md` | Audit baseline recorded above | Start implementation on user continuation |

## Message to paste into a new account

“Continue the Health Platform project in D:\Health. First read PROJECT_HANDOFF.md and audit/PROJECT_REVIEW.md, then inspect the current working tree. Follow the saved patient Android/iOS and professional web requirements. Continue the next unfinished repair or feature, preserve existing changes, and update PROJECT_HANDOFF.md alongside the work with completed/pending items, changed files, verification results and the exact next step. Do not treat the audit's reproduced vulnerabilities as passing security tests.”
