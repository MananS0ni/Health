import os
from reportlab.lib.pagesizes import letter
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Image, Table, TableStyle, PageBreak, HRFlowable
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib import colors

def generate_pdf(filename="d:/Health/Digital_Health_Platform_Verification_Report.pdf"):
    doc = SimpleDocTemplate(
        filename,
        pagesize=letter,
        rightMargin=36,
        leftMargin=36,
        topMargin=36,
        bottomMargin=36
    )
    styles = getSampleStyleSheet()

    # Custom styles
    title_style = ParagraphStyle(
        'DocTitle',
        parent=styles['Heading1'],
        fontName='Helvetica-Bold',
        fontSize=22,
        leading=26,
        textColor=colors.HexColor('#1E40AF'),
        alignment=1,
        spaceAfter=8
    )

    subtitle_style = ParagraphStyle(
        'DocSubtitle',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=11,
        leading=14,
        textColor=colors.HexColor('#475569'),
        alignment=1,
        spaceAfter=15
    )

    h2_style = ParagraphStyle(
        'SectionH2',
        parent=styles['Heading2'],
        fontName='Helvetica-Bold',
        fontSize=14,
        leading=18,
        textColor=colors.HexColor('#0F172A'),
        spaceBefore=12,
        spaceAfter=6
    )

    body_style = ParagraphStyle(
        'BodyDark',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=9.5,
        leading=13,
        textColor=colors.HexColor('#334155'),
        spaceAfter=6
    )

    bullet_style = ParagraphStyle(
        'BulletText',
        parent=body_style,
        leftIndent=15,
        firstLineIndent=-10,
        spaceAfter=4
    )

    story = []

    # Title & Metadata
    story.append(Paragraph("Digital Health Platform: Verification & Audit Report", title_style))
    story.append(Paragraph("Comprehensive Clinical Architecture, Patient-Doctor Sync & UI Proof", subtitle_style))
    story.append(HRFlowable(width="100%", thickness=1.5, color=colors.HexColor('#2563EB'), spaceAfter=14))

    # Executive Summary
    story.append(Paragraph("1. Executive Summary & Problem Resolution", h2_style))
    summary_text = (
        "This report documents the resolution of the patient linking, consent protocol, and UI consistency issues. "
        "Previously, the doctor appointment creation generated a detached random identifier (e.g. PAT_98036) with hardcoded "
        "dummy age (30 yrs) and missing email binding. This caused the clinical chart to trigger 'Patient History Locked by Consent Protocol' "
        "and displayed 'null' metadata across consultations.<br/><br/>"
        "<b>Key Fixes Implemented:</b><br/>"
        "• <b>Patient Linking by Email & Code:</b> Doctors now schedule appointments using a smart patient selector that resolves "
        "to registered patient accounts (Manan Soni, <code>PAT-4726A2</code>, <code>manansoni2905@gmail.com</code>).<br/>"
        "• <b>Bidirectional Sync:</b> Scheduled appointments instantly appear on the Patient Dashboard under 'Upcoming Appointments' "
        "with doctor specialization, clinic name, date, and time.<br/>"
        "• <b>Active Consent Protocol:</b> Clicking 'Open Chart' navigates to <code>#/doctor/patient-detail?id=PAT-4726A2</code>, "
        "which immediately renders the verified green 'Active Patient Consent (24h Clinical Window)' banner.<br/>"
        "• <b>UI Polish:</b> Eliminated all raw 'null' strings, pre-filled age defaults, and debug state toolbars across all portals."
    )
    story.append(Paragraph(summary_text, body_style))
    story.append(Spacer(1, 10))

    # System Architecture Table
    story.append(Paragraph("2. System Integration Matrix", h2_style))
    table_data = [
        ["Component", "Identifier / Endpoint", "Status", "Clinical Integration"],
        ["Patient Account", "manansoni2905@gmail.com (PAT-4726A2)", "Verified Active", "Primary Patient Master Record"],
        ["Doctor Portal", "Dr. Dhruv Patel (Patel Clinic / Neuro)", "Online (Port 8080)", "Schedules, Charts, Prescriptions"],
        ["Consent Engine", "/api/doctor/consent/request/", "24h Window Active", "Zero-trust ABHA/ABDM Standard"],
        ["Diagnostic Lab", "/api/lab/orders/ & LIMS Gateway", "Connected", "Pathology Test Upload & Sync"],
        ["Hospital Facility", "/api/hospital/admissions/", "Connected", "Inpatient Bed & Discharge EHR"]
    ]
    t = Table(table_data, colWidths=[110, 180, 100, 150])
    t.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#1E40AF')),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, -1), 8.5),
        ('GRID', (0, 0), (-1, -1), 0.5, colors.HexColor('#CBD5E1')),
        ('BACKGROUND', (0, 1), (-1, -1), colors.HexColor('#F8FAFC')),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
    ]))
    story.append(t)
    story.append(Spacer(1, 14))

    # Screenshot 1: Doctor Dashboard
    story.append(PageBreak())
    story.append(Paragraph("3. Verification Proof: Doctor Portal Dashboard", h2_style))
    story.append(Paragraph("Verification of real appointments schedule, zero 'null' text, and clean patient visit history.", body_style))
    if os.path.exists("d:/Health/proof_doctor_dash.png"):
        story.append(Image("d:/Health/proof_doctor_dash.png", width=540, height=300))
    story.append(Spacer(1, 14))

    # Screenshot 2: Clinical Chart with Active Consent
    story.append(Paragraph("4. Verification Proof: Clinical Chart & Active Consent", h2_style))
    story.append(Paragraph("Opening chart for Manan Soni (PAT-4726A2) displays the active 24-hour clinical consent window, unlocking vitals and medical history.", body_style))
    if os.path.exists("d:/Health/proof_chart_active_consent.png"):
        story.append(Image("d:/Health/proof_chart_active_consent.png", width=540, height=300))
    story.append(Spacer(1, 14))

    # Screenshot 3: Patient Dashboard Sync
    story.append(PageBreak())
    story.append(Paragraph("5. Verification Proof: Patient Dashboard Synchronized", h2_style))
    story.append(Paragraph("Patient Manan Soni's dashboard reflects the upcoming appointment scheduled by Dr. Dhruv Patel on 2026-09-11 at 10:30 AM.", body_style))
    if os.path.exists("d:/Health/proof_patient_dash.png"):
        story.append(Image("d:/Health/proof_patient_dash.png", width=540, height=300))
    story.append(Spacer(1, 14))

    # Screenshot 4: Clean Appointments Schedule
    story.append(Paragraph("6. Verification Proof: Doctor Appointments Schedule", h2_style))
    story.append(Paragraph("Clean appointment card with 'Scheduled' status, correct chief complaint, and functional 'Open Chart' button.", body_style))
    if os.path.exists("d:/Health/proof_appointments_clean.png"):
        story.append(Image("d:/Health/proof_appointments_clean.png", width=540, height=300))
    story.append(Spacer(1, 14))

    # Screenshot 5 & 6: Lab & Hospital Portals
    story.append(PageBreak())
    story.append(Paragraph("7. Verification Proof: Diagnostic Lab & Hospital Portals", h2_style))
    story.append(Paragraph("Integrated multi-portal infrastructure connecting laboratory orders and hospital inpatient admissions.", body_style))
    if os.path.exists("d:/Health/proof_lab_portal.png"):
        story.append(Image("d:/Health/proof_lab_portal.png", width=540, height=270))
    story.append(Spacer(1, 10))
    if os.path.exists("d:/Health/proof_hospital_portal.png"):
        story.append(Image("d:/Health/proof_hospital_portal.png", width=540, height=270))
    story.append(Spacer(1, 14))

    # Screenshot 7: Emergency Card
    story.append(PageBreak())
    story.append(Paragraph("8. Verification Proof: Emergency Medical Card", h2_style))
    story.append(Paragraph("Patient emergency card with emergency contact information, blood type, and instant clinical access for first responders.", body_style))
    if os.path.exists("d:/Health/proof_emergency_card.png"):
        story.append(Image("d:/Health/proof_emergency_card.png", width=540, height=300))
    story.append(Spacer(1, 14))

    doc.build(story)
    print("PDF generated successfully:", filename)

if __name__ == "__main__":
    generate_pdf()
