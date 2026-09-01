import os
from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, HRFlowable

def generate_pdf():
    pdf_filename = r"D:\Health\Digital_Health_Record_Platform_Summary.pdf"
    doc = SimpleDocTemplate(
        pdf_filename,
        pagesize=letter,
        rightMargin=40,
        leftMargin=40,
        topMargin=40,
        bottomMargin=40
    )

    styles = getSampleStyleSheet()

    # Custom Color Palette
    teal_dark = colors.HexColor('#0F766E')
    blue_sky = colors.HexColor('#0284C7')
    slate_body = colors.HexColor('#334155')
    bg_light = colors.HexColor('#F8FAFC')
    border_color = colors.HexColor('#CBD5E1')

    # Typography Styles
    title_style = ParagraphStyle(
        'DocTitle',
        parent=styles['Heading1'],
        fontName='Helvetica-Bold',
        fontSize=24,
        leading=28,
        textColor=teal_dark,
        spaceAfter=4
    )

    subtitle_style = ParagraphStyle(
        'DocSubtitle',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=11,
        leading=15,
        textColor=blue_sky,
        spaceAfter=15
    )

    h2_style = ParagraphStyle(
        'SectionH2',
        parent=styles['Heading2'],
        fontName='Helvetica-Bold',
        fontSize=14,
        leading=18,
        textColor=teal_dark,
        spaceBefore=14,
        spaceAfter=6
    )

    body_style = ParagraphStyle(
        'BodyDark',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=9.5,
        leading=14,
        textColor=slate_body,
        spaceAfter=6
    )

    code_style = ParagraphStyle(
        'CodeBlock',
        parent=styles['Normal'],
        fontName='Courier-Bold',
        fontSize=9,
        leading=12,
        textColor=colors.HexColor('#064E3B'),
        backColor=colors.HexColor('#ECFDF5'),
        borderColor=colors.HexColor('#A7F3D0'),
        borderWidth=1,
        borderPadding=6,
        spaceAfter=8
    )

    story = []

    # Title & Subtitle Banner
    story.append(Paragraph("Digital Health Record Platform", title_style))
    story.append(Paragraph("Full-Stack Engineering, Mobile OTP Auth, UI/UX & Django Backend Implementation Report", subtitle_style))
    story.append(HRFlowable(width="100%", thickness=2, color=teal_dark, spaceAfter=15))

    # Meta Table
    meta_data = [
        [Paragraph("<b>Prepared For:</b> Manan Soni & Project Team", body_style), Paragraph("<b>Date:</b> September 01, 2026", body_style)],
        [Paragraph("<b>Tech Stack:</b> Flutter, Python (Django REST), PostgreSQL, Redis", body_style), Paragraph("<b>GitHub Repo:</b> github.com/MananS0ni/Health", body_style)]
    ]
    meta_table = Table(meta_data, colWidths=[260, 260])
    meta_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), bg_light),
        ('PADDING', (0,0), (-1,-1), 8),
        ('BOX', (0,0), (-1,-1), 1, border_color),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
    ]))
    story.append(meta_table)
    story.append(Spacer(1, 14))

    # 1. Executive Summary
    story.append(Paragraph("1. Executive Summary & Vision", h2_style))
    story.append(Paragraph(
        "Today we successfully designed, developed, and deployed the complete end-to-end architecture for the <b>Digital Health Record Platform</b>. "
        "The platform addresses medical record fragmentation by establishing a patient-owned digital health locker. "
        "It eliminates manual paper report scanning by enabling automated diagnostic report ingestion directly from hospital (HIS) and laboratory (LIS) systems.",
        body_style
    ))

    # 2. UI/UX Design
    story.append(Paragraph("2. Frontend UI/UX & Patient Experience (Flutter + Web)", h2_style))
    story.append(Paragraph(
        "We completely simplified and redesigned the patient-facing interface to be <b>clean, visual, and intuitive</b> for non-technical users. "
        "Heavy technical walls of text were replaced with visual metric cards, clear status chips, and plain-language summaries.",
        body_style
    ))

    ui_features = [
        ["Module / Feature", "Description & Patient Experience"],
        ["Mobile OTP Authentication", "Secure login via 6-digit SMS OTP code sent directly to patient's mobile number (+91 98765 43210)."],
        ["Emergency Health Card", "1-tap access card showing Blood Group (O+), Allergies, Emergency Contact, and scannable Patient QR code."],
        ["Digital Health Locker", "Central store for Blood Tests, Prescriptions, Scans & Hospital Notes with 1-click 'Explain in Simple English'."],
        ["Unified Medical Timeline", "Chronological history of medical visits across Dr. Lal PathLabs, Max Healthcare, Apollo, and Fortis."],
        ["1-Click Doctor Consent", "Patient-controlled privacy manager with time-bound access limits and instant 'Stop Doctor Access Now'."],
        ["Lab Auto-Sync Notice", "Visual 3-step story showing how reports arrive automatically with zero manual upload effort."]
    ]
    ui_table = Table(ui_features, colWidths=[150, 370])
    ui_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), teal_dark),
        ('TEXTCOLOR', (0,0), (-1,0), colors.white),
        ('FONTNAME', (0,0), (-1,0), 'Helvetica-Bold'),
        ('FONTSIZE', (0,0), (-1,0), 9.5),
        ('PADDING', (0,0), (-1,-1), 6),
        ('GRID', (0,0), (-1,-1), 0.5, border_color),
        ('BACKGROUND', (0,1), (-1,-1), colors.white),
    ]))
    story.append(ui_table)
    story.append(Spacer(1, 14))

    # 3. Python Django Backend
    story.append(Paragraph("3. Python Django REST Framework Backend Server", h2_style))
    story.append(Paragraph(
        "We built a modular, production-ready <b>Django REST Framework (DRF)</b> backend server under <code>D:\\Health\\backend</code>. "
        "It provides secure RESTful APIs, dual PostgreSQL/SQLite database support, SimpleJWT token authentication, and CORS cross-origin headers.",
        body_style
    ))

    backend_apps = [
        ["Django App", "API Endpoint Route", "Functionality"],
        ["accounts", "/api/auth/otp/verify/", "Mobile OTP verification and JWT access/refresh token issuance."],
        ["patients", "/api/patients/me/", "Patient profile management, blood group, allergies & Emergency Card payload."],
        ["reports", "/api/reports/", "Fetches health locker documents & provides AI plain-language explanation API."],
        ["consent", "/api/consent/revoke/", "Manages time-bound permissions and processes 1-click access revocations."],
        ["timeline", "/api/timeline/", "Streams chronological medical encounter history."],
        ["integrations", "/api/integrations/lab/push/", "Webhook endpoint allowing LIS lab systems to auto-push report payloads."]
    ]
    be_table = Table(backend_apps, colWidths=[80, 160, 280])
    be_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), blue_sky),
        ('TEXTCOLOR', (0,0), (-1,0), colors.white),
        ('FONTNAME', (0,0), (-1,0), 'Helvetica-Bold'),
        ('FONTSIZE', (0,0), (-1,0), 9),
        ('PADDING', (0,0), (-1,-1), 5),
        ('GRID', (0,0), (-1,-1), 0.5, border_color),
        ('BACKGROUND', (0,1), (-1,-1), colors.white),
    ]))
    story.append(be_table)
    story.append(Spacer(1, 10))

    story.append(Paragraph("Verified Live Backend API Response (http://127.0.0.1:8000/api/integrations/status/):", body_style))
    story.append(Paragraph('{"status": "HEALTHY", "service": "Django REST Framework Engine", "database": "Active"}', code_style))

    # 4. GitHub & Deployment
    story.append(Paragraph("4. Code Repository & GitHub Deployment", h2_style))
    story.append(Paragraph(
        "The entire codebase was initialized with Git, configured for remote <b>MananS0ni</b>, and pushed to GitHub.",
        body_style
    ))
    story.append(Paragraph("<b>GitHub Repository URL:</b> https://github.com/MananS0ni/Health", code_style))

    # 5. Quick Terminal Commands
    story.append(Paragraph("5. Quick Terminal Commands Reference", h2_style))
    story.append(Paragraph("<b>Run Flutter App:</b> <code>cd D:\\Health\\health_platform &amp;&amp; flutter run -d chrome</code>", body_style))
    story.append(Paragraph("<b>Run Django Backend:</b> <code>cd D:\\Health\\backend &amp;&amp; .\\venv\\Scripts\\python.exe manage.py runserver 0.0.0.0:8000</code>", body_style))
    story.append(Paragraph("<b>Push Code Updates:</b> <code>cd D:\\Health\\health_platform &amp;&amp; git push -u origin main</code>", body_style))

    story.append(Spacer(1, 15))
    story.append(HRFlowable(width="100%", thickness=1, color=border_color, spaceAfter=10))
    story.append(Paragraph("Digital Health Record Platform • Official Engineering Summary Document • 2026", ParagraphStyle('Footer', parent=body_style, fontSize=8, textColor=colors.HexColor('#94A3B8'), alignment=1)))

    doc.build(story)
    print(f"PDF successfully generated at {pdf_filename}")

if __name__ == '__main__':
    generate_pdf()
