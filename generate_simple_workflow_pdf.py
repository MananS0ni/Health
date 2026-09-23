import os
from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, HRFlowable, PageBreak

def generate_pdf():
    pdf_filename = r"D:\Health\Digital_Health_Platform_Complete_Workflow_Guide.pdf"
    doc = SimpleDocTemplate(
        pdf_filename,
        pagesize=letter,
        rightMargin=36,
        leftMargin=36,
        topMargin=36,
        bottomMargin=36
    )

    styles = getSampleStyleSheet()

    # Colors
    primary_teal = colors.HexColor('#0F766E')
    secondary_blue = colors.HexColor('#0284C7')
    dark_slate = colors.HexColor('#1E293B')
    body_color = colors.HexColor('#334155')
    bg_card = colors.HexColor('#F8FAFC')
    accent_green = colors.HexColor('#059669')
    accent_amber = colors.HexColor('#D97706')
    border_gray = colors.HexColor('#E2E8F0')

    # Typography Styles
    title_style = ParagraphStyle(
        'MainTitle',
        parent=styles['Heading1'],
        fontName='Helvetica-Bold',
        fontSize=22,
        leading=26,
        textColor=primary_teal,
        spaceAfter=4
    )

    subtitle_style = ParagraphStyle(
        'SubTitle',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=11,
        leading=15,
        textColor=secondary_blue,
        spaceAfter=12
    )

    h1_style = ParagraphStyle(
        'SectionH1',
        parent=styles['Heading2'],
        fontName='Helvetica-Bold',
        fontSize=14,
        leading=18,
        textColor=primary_teal,
        spaceBefore=12,
        spaceAfter=6
    )

    h2_style = ParagraphStyle(
        'SectionH2',
        parent=styles['Heading3'],
        fontName='Helvetica-Bold',
        fontSize=11,
        leading=15,
        textColor=dark_slate,
        spaceBefore=8,
        spaceAfter=4
    )

    body_style = ParagraphStyle(
        'BodyTextCustom',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=9.5,
        leading=14,
        textColor=body_color,
        spaceAfter=6
    )

    bullet_style = ParagraphStyle(
        'BulletCustom',
        parent=body_style,
        leftIndent=15,
        firstLineIndent=-10,
        spaceAfter=4
    )

    callout_style = ParagraphStyle(
        'CalloutText',
        parent=styles['Normal'],
        fontName='Helvetica-Oblique',
        fontSize=9,
        leading=13,
        textColor=colors.HexColor('#065F46'),
        backColor=colors.HexColor('#ECFDF5'),
        borderColor=colors.HexColor('#A7F3D0'),
        borderWidth=1,
        borderPadding=8,
        spaceAfter=8
    )

    story = []

    # Title Banner
    story.append(Paragraph("Digital Health Record Platform — Full Workflow Guide", title_style))
    story.append(Paragraph("A Complete Non-Technical & Deep-Dive Explanation of System Architecture, Portals & Capabilities", subtitle_style))
    story.append(HRFlowable(width="100%", thickness=2, color=primary_teal, spaceAfter=10))

    # Executive Overview
    story.append(Paragraph("1. System Overview & Core Purpose", h1_style))
    story.append(Paragraph(
        "The <b>Digital Health Record Platform</b> is a unified healthcare management ecosystem designed to eliminate paper record loss, "
        "fragmented medical histories, and slow report deliveries. Built with a modern <b>Flutter Frontend</b> and a high-performance "
        "<b>Python Django REST Backend</b>, the platform seamlessly connects four distinct stakeholders: <b>Patients, Doctors, Diagnostic Labs, and Hospitals</b>.",
        body_style
    ))

    # Architecture Overview Table
    arch_data = [
        ["User Portal / Role", "Primary Responsibility", "Key Capabilities & Access Limits"],
        ["Patient Portal", "Personal Health Locker & Privacy", "Full control over health records, OTP login, Emergency Card, Family management, and doctor consent approval/revocation."],
        ["Doctor Portal", "Clinical Care & Prescriptions", "Search patient directory, view historical medical charts (if consented), schedule appointments, write digital prescriptions with auto-sync."],
        ["Diagnostic Lab Portal", "Test Ingestion & Results", "Receive pending test orders, fill verified parameter values, publish lab reports directly to patient lockers, batch CSV upload."],
        ["Hospital Care Portal", "Inpatient & Ward Care", "Manage ward beds, admit inpatients, track ICU/General stays, discharge patients with auto-generated Discharge Summaries."]
    ]
    t_arch = Table(arch_data, colWidths=[110, 140, 270])
    t_arch.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), primary_teal),
        ('TEXTCOLOR', (0,0), (-1,0), colors.white),
        ('FONTNAME', (0,0), (-1,0), 'Helvetica-Bold'),
        ('FONTSIZE', (0,0), (-1,0), 9),
        ('PADDING', (0,0), (-1,-1), 5),
        ('GRID', (0,0), (-1,-1), 0.5, border_gray),
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
    ]))
    story.append(t_arch)
    story.append(Spacer(1, 10))

    # SECTION 2: PATIENT FLOW
    story.append(Paragraph("2. Detailed Patient Workflow (Step-by-Step)", h1_style))
    story.append(Paragraph("When a patient opens the application, here is exactly how their journey works from start to finish:", body_style))

    story.append(Paragraph("Step 1: Simple Password-Less Authentication (Email / Mobile OTP)", h2_style))
    story.append(Paragraph("• <b>Login & Verification:</b> The patient enters their email or phone number. The backend instantly generates a secure 6-digit One-Time Password (OTP) valid for 5 minutes.", bullet_style))
    story.append(Paragraph("• <b>First-Time Registration:</b> If it's a new user, they complete their basic profile (Full Name, Gender, Age/DOB, Blood Group, Allergies, Emergency Contact).", bullet_style))

    story.append(Paragraph("Step 2: Patient Dashboard & Quick Glance", h2_style))
    story.append(Paragraph("• <b>Health Vitals Tracker:</b> Shows latest recorded metrics (Blood Pressure, Heart Rate, SpO2, Blood Sugar, BMI) with color-coded status chips (Normal, Elevated, High).", bullet_style))
    story.append(Paragraph("• <b>Quick Actions:</b> 1-tap buttons to show Emergency Card, view recent lab reports, book doctor appointments, or check active consent approvals.", bullet_style))

    story.append(Paragraph("Step 3: Digital Health Locker & Medical Records", h2_style))
    story.append(Paragraph("• <b>Centralized Vault:</b> Every prescription written by a doctor, every lab report published by a lab, and every hospital discharge summary automatically lands here.", bullet_style))
    story.append(Paragraph("• <b>What Patient Can Do:</b> View records, filter by type (Prescription, Lab Report, Discharge Summary), search keywords, download PDF reports.", bullet_style))
    story.append(Paragraph("• <b>What Patient Cannot Do:</b> Alter or tamper with official diagnostic results published by verified labs or doctors (ensuring legal data integrity).", bullet_style))

    story.append(Paragraph("Step 4: Unified Medical Timeline", h2_style))
    story.append(Paragraph("• <b>Chronological Stream:</b> Combines events across all clinics, diagnostic centers, and hospitals into a single chronological timeline (e.g. June 12: CBC Test at Lab Hub -> June 14: OPD Consultation at Patel Clinic -> July 01: Hospital Discharge at City Hospital).", bullet_style))

    story.append(Paragraph("Step 5: Patient Privacy & Consent Control Center", h2_style))
    story.append(Paragraph("• <b>Strict Data Privacy:</b> Patient health records are locked by default. Doctors cannot peek into historical medical records without patient permission.", bullet_style))
    story.append(Paragraph("• <b>Approving Access:</b> When a doctor requests record access, the patient receives an access request. When approved, access is granted for exactly 24 hours.", bullet_style))
    story.append(Paragraph("• <b>1-Tap Instant Revocation:</b> At any time, the patient can hit 'Revoke Access' to instantly cut off doctor access immediately.", bullet_style))

    story.append(Paragraph("Step 6: Family Account Management & Emergency Card", h2_style))
    story.append(Paragraph("• <b>Dependents Care:</b> Patients can add family members (children, elderly parents, spouse) and manage their health records under one master account.", bullet_style))
    story.append(Paragraph("• <b>Emergency Card:</b> Designed for critical situations, presenting Blood Group, Known Allergies, Emergency Contacts, and a scannable Patient QR code.", bullet_style))

    story.append(Spacer(1, 10))

    # SECTION 3: DOCTOR FLOW
    story.append(Paragraph("3. Detailed Doctor Workflow (Step-by-Step)", h1_style))
    story.append(Paragraph("Step 1: Doctor Login & OPD Dashboard", h2_style))
    story.append(Paragraph("• Doctors log in with verified medical credentials (Registration Number, Specialization, Clinic/Hospital Affiliation).", bullet_style))
    story.append(Paragraph("• The doctor dashboard lists today's appointments, queue status, and pending patient access approvals.", bullet_style))

    story.append(Paragraph("Step 2: Patient Directory Search & Registration", h2_style))
    story.append(Paragraph("• <b>Instant Search:</b> Doctors can search patients by Name, Phone Number, Email, or Patient Code (e.g., <code>PAT-4726A2</code>).", bullet_style))
    story.append(Paragraph("• <b>On-the-Fly Registration:</b> If a new walk-in patient visits, the doctor can register them directly. This automatically creates the patient account and pre-authorizes the doctor for 24 hours for immediate consultation.", bullet_style))

    story.append(Paragraph("Step 3: Consent-Gated Clinical Chart Access", h2_style))
    story.append(Paragraph("• <b>Unlocked Chart:</b> If active consent exists (or for newly registered walk-ins), the doctor sees full medical history, past prescriptions, vitals trends, and lab reports.", bullet_style))
    story.append(Paragraph("• <b>Locked Chart:</b> If consent is missing or expired, historical records display a security lock. The doctor clicks 'Request Access', triggering a notification to the patient.", bullet_style))

    story.append(Paragraph("Step 4: Writing Digital Prescriptions & Automated Synchronization", h2_style))
    story.append(Paragraph("• Doctor enters Clinical Diagnosis, Notes, and prescribes medicines (Medicine Name, Dosage e.g., 1-0-1, Duration e.g., 7 Days).", bullet_style))
    story.append(Paragraph("• <b>Auto-Sync Magic:</b> As soon as the doctor clicks 'Save Prescription', the backend immediately generates a formal record and injects it into the patient's personal health locker in real time!", bullet_style))

    story.append(Spacer(1, 10))

    # SECTION 4: LAB FLOW
    story.append(Paragraph("4. Detailed Diagnostic Lab Workflow (Step-by-Step)", h1_style))
    story.append(Paragraph("Step 1: Order Queue Management", h2_style))
    story.append(Paragraph("• Lab technicians log in to view pending diagnostic test orders placed by doctors or requested by patients.", bullet_style))

    story.append(Paragraph("Step 2: Verification & Publishing Results", h2_style))
    story.append(Paragraph("• Lab staff input individual test parameters (e.g. Hemoglobin: 14.2 g/dL, Fasting Blood Sugar: 110 mg/dL).", bullet_style))
    story.append(Paragraph("• Abnormal flags (High/Low) are set automatically or manually. Once verified, clicking 'Publish Report' instantly transfers the official verified report into the patient's digital locker.", bullet_style))

    story.append(Paragraph("Step 3: High-Volume Batch CSV Processing", h2_style))
    story.append(Paragraph("• Diagnostic centers processing hundreds of daily samples can upload a single CSV spreadsheet.", bullet_style))
    story.append(Paragraph("• The backend engine automatically matches each row to the patient email. If a patient is not in the database, it automatically creates their account and attaches their lab report seamlessly.", bullet_style))

    story.append(Spacer(1, 10))

    # SECTION 5: HOSPITAL FLOW
    story.append(Paragraph("5. Detailed Hospital Care Workflow (Step-by-Step)", h1_style))
    story.append(Paragraph("Step 1: Ward & Inpatient Bed Allocation", h2_style))
    story.append(Paragraph("• Hospital administration tracks bed availability across General Wards, ICU, and Emergency Units.", bullet_style))
    story.append(Paragraph("• When admitting a patient, staff record Ward Name, Bed Number, Attending Doctor, and Initial Diagnosis.", bullet_style))

    story.append(Paragraph("Step 2: Patient Discharge & Summary Auto-Sync", h2_style))
    story.append(Paragraph("• Upon recovery, hospital staff execute the discharge procedure and input clinical discharge summary notes.", bullet_style))
    story.append(Paragraph("• Hitting 'Discharge' frees up the hospital bed and automatically transmits a formatted Discharge Summary into the patient's digital locker.", bullet_style))

    story.append(Spacer(1, 10))

    # SECTION 6: HOW IT WORKS BEHIND THE SCENES
    story.append(Paragraph("6. How Everything Works Behind The Scenes (In Simple Words)", h1_style))
    story.append(Paragraph(
        "<b>1. The User Interface (Frontend):</b> Built with <b>Flutter</b>, delivering a fast, responsive experience across mobile phones and web browsers. It never talks directly to the raw database; it communicates via secure API requests.",
        body_style
    ))
    story.append(Paragraph(
        "<b>2. The Application Engine (Backend):</b> Powered by <b>Python Django REST Framework</b>. It acts as the traffic controller, verifying security tokens, checking permissions, validating inputs, and executing database queries.",
        body_style
    ))
    story.append(Paragraph(
        "<b>3. Multi-Role Security Guard:</b> Ensures that a Patient can only see their records, a Doctor can only see patients who granted consent, a Lab can only publish test results, and a Hospital can only manage ward admissions.",
        body_style
    ))
    story.append(Paragraph(
        "<b>4. Automated Synchronization Engine:</b> Eliminates manual data entry between systems. When an action occurs in one portal (e.g. Doctor writes prescription or Lab publishes test), background signals automatically update the Patient's personal locker instantly.",
        body_style
    ))

    story.append(Spacer(1, 15))
    story.append(HRFlowable(width="100%", thickness=1, color=border_gray, spaceAfter=10))
    story.append(Paragraph("Digital Health Record Platform • Complete In-Depth Workflow & Architecture Guide • 2026", ParagraphStyle('Footer', parent=body_style, fontSize=8, textColor=colors.HexColor('#94A3B8'), alignment=1)))

    doc.build(story)
    print(f"PDF successfully generated at {pdf_filename}")

if __name__ == '__main__':
    generate_pdf()
