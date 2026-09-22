import os
from reportlab.lib.pagesizes import letter, A4
from reportlab.lib import colors
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak, KeepTogether, HRFlowable
)
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.pdfgen import canvas

PDF_PATH = r"d:\Health\Digital_Health_Platform_Role_and_Auth_Guide.pdf"

class NumberedCanvas(canvas.Canvas):
    """Canvas that enables two-pass page numbering 'Page X of Y'"""
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_page_decorations(num_pages)
            super().showPage()
        super().save()

    def draw_page_decorations(self, page_count):
        self.saveState()
        self.setFont("Helvetica", 8)
        self.setFillColor(colors.HexColor("#64748B"))
        
        # Header (pages > 1)
        if self._pageNumber > 1:
            self.drawString(54, 800, "Digital Health Record Platform — Architecture, Roles & Auth Guide")
            self.setStrokeColor(colors.HexColor("#E2E8F0"))
            self.setLineWidth(0.5)
            self.line(54, 792, 540, 792)
            
        # Footer (all pages)
        self.setStrokeColor(colors.HexColor("#E2E8F0"))
        self.setLineWidth(0.5)
        self.line(54, 45, 540, 45)
        self.drawString(54, 32, "Confidential — Prepared for Manan Soni & Team | Free Email SMTP & Native Backend")
        page_str = f"Page {self._pageNumber} of {page_count}"
        self.drawRightString(540, 32, page_str)
        self.restoreState()


def build_pdf():
    doc = SimpleDocTemplate(
        PDF_PATH,
        pagesize=A4,
        leftMargin=54,
        rightMargin=54,
        topMargin=54,
        bottomMargin=54
    )

    styles = getSampleStyleSheet()
    
    # Custom Typography Styles
    title_style = ParagraphStyle(
        'DocTitle',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=20,
        leading=24,
        textColor=colors.HexColor("#042F2E")
    )
    
    subtitle_style = ParagraphStyle(
        'DocSubtitle',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=11,
        leading=15,
        textColor=colors.HexColor("#475569")
    )
    
    h1_style = ParagraphStyle(
        'Heading1_Custom',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=13,
        leading=17,
        textColor=colors.HexColor("#0F766E"),
        spaceBefore=12,
        spaceAfter=6
    )

    h2_style = ParagraphStyle(
        'Heading2_Custom',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=10.5,
        leading=14,
        textColor=colors.HexColor("#1E293B"),
        spaceBefore=8,
        spaceAfter=4
    )

    body_style = ParagraphStyle(
        'Body_Custom',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=8.5,
        leading=12,
        textColor=colors.HexColor("#334155")
    )

    bullet_style = ParagraphStyle(
        'Bullet_Custom',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=8.5,
        leading=12,
        textColor=colors.HexColor("#334155"),
        leftIndent=12
    )

    callout_style = ParagraphStyle(
        'Callout_Text',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=8.5,
        leading=12,
        textColor=colors.HexColor("#064E3B")
    )

    tbl_header_style = ParagraphStyle(
        'TblHeader',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=8,
        leading=10,
        textColor=colors.HexColor("#0F172A")
    )

    tbl_cell_style = ParagraphStyle(
        'TblCell',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=8,
        leading=11,
        textColor=colors.HexColor("#334155")
    )

    story = []

    # 1. Header Banner
    story.append(Paragraph("DIGITAL HEALTH RECORD PLATFORM", ParagraphStyle('Tag', fontName='Helvetica-Bold', fontSize=8, leading=10, textColor=colors.HexColor("#0F766E"))))
    story.append(Spacer(1, 4))
    story.append(Paragraph("System Architecture, Multi-Role Login & Access Guide", title_style))
    story.append(Spacer(1, 4))
    story.append(Paragraph("Comprehensive technical reference for Patient, Doctor, Diagnostic Lab, and Hospital workflows.", subtitle_style))
    story.append(Spacer(1, 10))
    story.append(HRFlowable(width="100%", thickness=1.5, color=colors.HexColor("#0F766E"), spaceAfter=12))

    # Meta Info Box
    meta_data = [
        [
            Paragraph("<b>PROJECT:</b> Digital Health Platform", tbl_cell_style),
            Paragraph("<b>AUTH METHOD:</b> Free Email SMTP OTP", tbl_cell_style)
        ],
        [
            Paragraph("<b>TECH STACK:</b> Django / DRF + PostgreSQL", tbl_cell_style),
            Paragraph("<b>CONSTRAINTS:</b> Zero ABHA / Zero Docker (Native venv)", tbl_cell_style)
        ]
    ]
    meta_table = Table(meta_data, colWidths=[240, 245])
    meta_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, -1), colors.HexColor("#F8FAFC")),
        ('BOX', (0, 0), (-1, -1), 0.5, colors.HexColor("#CBD5E1")),
        ('INNERGRID', (0, 0), (-1, -1), 0.5, colors.HexColor("#E2E8F0")),
        ('TOPPADDING', (0, 0), (-1, -1), 5),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 5),
        ('LEFTPADDING', (0, 0), (-1, -1), 8),
        ('RIGHTPADDING', (0, 0), (-1, -1), 8),
    ]))
    story.append(meta_table)
    story.append(Spacer(1, 14))

    # 2. Key Architecture Decisions
    story.append(Paragraph("1. Core Architectural Pillars", h1_style))
    p1 = (
        "• <b>Zero External ABHA / ABDM Dependency:</b> The platform operates 100% independently as your private digital health record "
        "cloud. There is no government API integration, no ABDM sandboxing, and no compliance delay.<br/>"
        "• <b>100% Free Email SMTP Authentication:</b> No paid SMS gateways (Twilio, MSG91, Fast2SMS). The Django backend dispatches secure, "
        "time-limited (5-min) 6-digit OTP codes straight to the user's email inbox using Gmail App Password or custom SMTP.<br/>"
        "• <b>Direct Native Execution (No Docker):</b> Backends runs natively with Python <code>venv</code> and standard local PostgreSQL/SQLite, "
        "enabling fast debugging, simple deployment, and zero virtualization overhead.<br/>"
        "• <b>Frontend-First Alignment:</b> The database models and endpoints directly mirror the state and models of the live Flutter application."
    )
    story.append(Paragraph(p1, body_style))
    story.append(Spacer(1, 14))

    # 3. Role Comparison Table
    story.append(Paragraph("2. Multi-Role Comparison & Differentiation Matrix", h1_style))
    story.append(Paragraph(
        "A single, clean login page accepts any registered email address. The user's role in the database governs their credentials, "
        "data accessibility, and automatically directs them to their customized portal:",
        body_style
    ))
    story.append(Spacer(1, 6))

    role_table_data = [
        [
            Paragraph("Role", tbl_header_style),
            Paragraph("Primary Purpose", tbl_header_style),
            Paragraph("Signup Credentials", tbl_header_style),
            Paragraph("Landing Portal", tbl_header_style)
        ],
        [
            Paragraph("<b>Patient</b>", tbl_cell_style),
            Paragraph("Personal & family health locker, review lab test parameters, monitor vitals, access emergency medical card.", tbl_cell_style),
            Paragraph("Full Name, Email, Gender, Blood Group (optional).", tbl_cell_style),
            Paragraph("<b>Patient Dashboard</b><br/><code>/dashboard</code>", tbl_cell_style)
        ],
        [
            Paragraph("<b>Doctor</b>", tbl_cell_style),
            Paragraph("Review patient directory, clinical chart history, allergy warnings, enter primary diagnosis, issue digital prescriptions (Rx).", tbl_cell_style),
            Paragraph("Full Name, Email, <b>Medical Council Reg No.</b>, <b>Specialization</b>, Clinic/Hospital.", tbl_cell_style),
            Paragraph("<b>Doctor Portal</b><br/><code>/doctor</code>", tbl_cell_style)
        ],
        [
            Paragraph("<b>Diagnostic Lab</b>", tbl_cell_style),
            Paragraph("Manage incoming diagnostic test order queue, input observed parameter values, attach report PDFs, auto-notify patients.", tbl_cell_style),
            Paragraph("Lab Name, Email, <b>Lab Registration / License No.</b>, Address, Incharge Name.", tbl_cell_style),
            Paragraph("<b>Lab Portal</b><br/><code>/lab</code>", tbl_cell_style)
        ],
        [
            Paragraph("<b>Hospital Care</b>", tbl_cell_style),
            Paragraph("Monitor inpatient ward bed occupancy (ICU, General, Private), admit emergency patients, finalize discharge summaries.", tbl_cell_style),
            Paragraph("Hospital Name, Email, <b>Hospital Reg ID</b>, Wards / Departments, Staff Name.", tbl_cell_style),
            Paragraph("<b>Hospital Portal</b><br/><code>/hospital</code>", tbl_cell_style)
        ]
    ]

    role_table = Table(role_table_data, colWidths=[70, 165, 140, 110])
    role_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor("#F1F5F9")),
        ('BOX', (0, 0), (-1, -1), 0.5, colors.HexColor("#94A3B8")),
        ('INNERGRID', (0, 0), (-1, -1), 0.5, colors.HexColor("#E2E8F0")),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('TOPPADDING', (0, 0), (-1, -1), 5),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 5),
        ('LEFTPADDING', (0, 0), (-1, -1), 6),
        ('RIGHTPADDING', (0, 0), (-1, -1), 6),
        ('BACKGROUND', (0, 1), (0, 1), colors.HexColor("#E0F2FE")),
        ('BACKGROUND', (0, 2), (0, 2), colors.HexColor("#EDE9FE")),
        ('BACKGROUND', (0, 3), (0, 3), colors.HexColor("#D1FAE5")),
        ('BACKGROUND', (0, 4), (0, 4), colors.HexColor("#FEF3C7")),
    ]))
    story.append(role_table)
    story.append(Spacer(1, 12))

    # Page Break for clean multi-page reading
    story.append(PageBreak())

    # 4. Detailed Portal Breakdown
    story.append(Paragraph("3. Detailed Portal Breakdown & Capabilities", h1_style))
    story.append(Spacer(1, 4))

    # Patient Details
    story.append(Paragraph("👤 Patient Portal Capabilities", h2_style))
    patient_bullets = [
        "<b>Health Vitals Tracker:</b> Records Blood Pressure (systolic/diastolic), Heart Rate, Fasting Sugar, and BMI with status tags.",
        "<b>Medical Records Locker:</b> Categorized repository for past prescriptions, consultation summaries, and medical history.",
        "<b>Lab Reports Table:</b> Diagnostic parameter viewing (e.g. HbA1c, Lipid panel) showing measured values and reference ranges.",
        "<b>Chronological Health Timeline:</b> Vertical timeline showing all medical interactions, visits, and hospital admissions across time.",
        "<b>Family Health Profiles:</b> Dedicated dependents management for children and elderly parents without requiring separate phone accounts.",
        "<b>Instant Emergency Card:</b> Rapid one-tap emergency card displaying Blood Group, Allergies (e.g. Penicillin), and Emergency Contacts."
    ]
    for b in patient_bullets:
        story.append(Paragraph(f"• {b}", bullet_style))
    story.append(Spacer(1, 8))

    # Doctor Details
    story.append(Paragraph("🩺 Doctor Portal Capabilities", h2_style))
    doctor_bullets = [
        "<b>Appointment Queue:</b> Daily schedule showing booked patients, appointment time slots, and consultation statuses.",
        "<b>EMR Directory Search:</b> Live search across patient records by name, email, or system-generated Patient ID.",
        "<b>Clinical Chart View:</b> Full review of patient vitals trends, prior prescriptions, and diagnostic lab reports.",
        "<b>Prominent Allergy Warnings:</b> High-visibility warning chips alerting the clinician to severe drug allergies before prescribing.",
        "<b>Digital Prescription Generator:</b> Fast medicine entry with dosage (e.g. 1-0-1), frequency, and duration (e.g. 14 Days).",
        "<b>Instant Locker Sync:</b> Saved diagnoses and prescriptions automatically appear in the patient's mobile app timeline."
    ]
    for b in doctor_bullets:
        story.append(Paragraph(f"• {b}", bullet_style))
    story.append(Spacer(1, 8))

    # Lab Details
    story.append(Paragraph("🧪 Diagnostic Laboratory Portal", h2_style))
    lab_bullets = [
        "<b>Pending Test Order Queue:</b> Filterable by discipline (Biochemistry, Endocrinology, Cardiology, Diabetology, Nephrology).",
        "<b>Structured Parameter Entry:</b> Input observed numerical values, units (mg/dL, cells/mcL), and biological reference intervals.",
        "<b>Report PDF Upload:</b> Ability to attach certified lab report PDFs alongside structured parameters.",
        "<b>Automated Publishing:</b> Submitting test results immediately unlocks the report in the patient's personal locker."
    ]
    for b in lab_bullets:
        story.append(Paragraph(f"• {b}", bullet_style))
    story.append(Spacer(1, 8))

    # Hospital Details
    story.append(Paragraph("🏥 Hospital Inpatient Care Portal", h2_style))
    hosp_bullets = [
        "<b>Ward Bed Occupancy:</b> Real-time bed occupancy stats across General Wards, ICU, Private, and Semi-Private rooms.",
        "<b>Inpatient Admission Intake:</b> Bed allocation, attending physician assignment, and primary admission diagnosis recording.",
        "<b>Discharge Summary Flow:</b> Formulate finalized discharge documentation with treatment summary, instructions, and follow-up date."
    ]
    for b in hosp_bullets:
        story.append(Paragraph(f"• {b}", bullet_style))
    story.append(Spacer(1, 14))

    # 5. Free Email SMTP Authentication Workflow
    story.append(Paragraph("4. Authentication Architecture: Free Email SMTP OTP", h1_style))
    story.append(Paragraph(
        "Instead of paid SMS gateways, authentication uses a standard email OTP mechanism powered by free Gmail SMTP (or custom SMTP):",
        body_style
    ))
    story.append(Spacer(1, 6))

    auth_steps = [
        ["Step", "Action", "Backend Logic"],
        ["1", "User Enters Email", "Frontend validates email format and sends request to <code>/api/auth/request-otp/</code>."],
        ["2", "Generate 6-Digit OTP", "Django generates a cryptographically random 6-digit code with a 5-minute expiration timestamp."],
        ["3", "Dispatch SMTP Email", "Django sends HTML email directly to the user's inbox using free SMTP settings."],
        ["4", "User Enters OTP", "Flutter app accepts 6 digits and submits to <code>/api/auth/verify-otp/</code>."],
        ["5", "Verify & Issue JWT", "If code is valid, backend generates JWT access & refresh tokens."],
        ["6", "Role-Based Redirection", "Existing users immediately land on their role dashboard; new users complete role registration."]
    ]
    auth_table = Table([[Paragraph(c, tbl_header_style if i == 0 else tbl_cell_style) for c in row] for i, row in enumerate(auth_steps)], colWidths=[35, 140, 310])
    auth_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor("#F1F5F9")),
        ('BOX', (0, 0), (-1, -1), 0.5, colors.HexColor("#94A3B8")),
        ('INNERGRID', (0, 0), (-1, -1), 0.5, colors.HexColor("#E2E8F0")),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ('LEFTPADDING', (0, 0), (-1, -1), 6),
        ('RIGHTPADDING', (0, 0), (-1, -1), 6),
    ]))
    story.append(auth_table)
    story.append(Spacer(1, 14))

    # 6. Real World App References
    story.append(Paragraph("5. Industry Benchmarks & References", h1_style))
    benchmarks = [
        "• <b>Practo (practo.com):</b> Patients browse records and book tests on <code>practo.com</code>; doctors log into <b>Practo Pro</b> (Ray) for digital clinic EMR and prescriptions.",
        "• <b>Eka Care (eka.care):</b> Consumer app serves as a digital health locker; <b>Eka Doctor</b> provides clinicians with digital prescription pads.",
        "• <b>Apollo 24|7 (apollo247.com):</b> Patient app displays Apollo records and lab tests; hospital doctors access internal HIS systems."
    ]
    for bm in benchmarks:
        story.append(Paragraph(bm, body_style))
    story.append(Spacer(1, 14))

    # 7. Next Implementation Steps
    story.append(Paragraph("6. Next Implementation Steps", h1_style))
    next_steps = (
        "<b>Step 1:</b> Configure SMTP credentials (email address + 16-character Google App Password) in Django <code>settings.py</code>.<br/>"
        "<b>Step 2:</b> Create Django <code>accounts</code> app with custom User model, roles, and OTP generation logic.<br/>"
        "<b>Step 3:</b> Build <code>/api/auth/request-otp/</code> and <code>/api/auth/verify-otp/</code> endpoints.<br/>"
        "<b>Step 4:</b> Wire the Flutter <code>signup_screen.dart</code> and <code>otp_entry_screen.dart</code> to the live endpoints."
    )
    story.append(Paragraph(next_steps, body_style))

    doc.build(story, canvasmaker=NumberedCanvas)
    print("PDF build complete at:", PDF_PATH)

if __name__ == "__main__":
    build_pdf()
