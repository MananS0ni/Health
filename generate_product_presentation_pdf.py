import os
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak, HRFlowable, KeepTogether
)
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.pdfgen import canvas

PDF_OUTPUT_PATH = r"d:\Health\Digital_Health_Platform_Product_Presentation.pdf"


class ProfessionalCanvas(canvas.Canvas):
    """Two-pass canvas for modern page numbering and running headers/footers"""
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
            self.draw_decorations(num_pages)
            super().showPage()
        super().save()

    def draw_decorations(self, total_pages):
        self.saveState()
        self.setFont("Helvetica-Bold", 8)
        self.setFillColor(colors.HexColor("#0284C7"))
        
        # Header (pages after cover page)
        if self._pageNumber > 1:
            self.drawString(54, 802, "DHEALTH PLATFORM")
            self.setFont("Helvetica", 8)
            self.setFillColor(colors.HexColor("#64748B"))
            self.drawString(155, 802, "•   Commercial Product Presentation & Executive Guide")
            self.drawRightString(540, 802, "Confidential Business Document")
            self.setStrokeColor(colors.HexColor("#CBD5E1"))
            self.setLineWidth(0.75)
            self.line(54, 794, 540, 794)
            
        # Footer on all pages
        self.setStrokeColor(colors.HexColor("#CBD5E1"))
        self.setLineWidth(0.75)
        self.line(54, 46, 540, 46)
        self.setFont("Helvetica-Bold", 8)
        self.setFillColor(colors.HexColor("#0F172A"))
        self.drawString(54, 32, "DHealth Ecosystem")
        self.setFont("Helvetica", 8)
        self.setFillColor(colors.HexColor("#64748B"))
        self.drawString(145, 32, "— Built for Hospitals, Clinics, Diagnostic Labs & Patients")
        page_indicator = f"Page {self._pageNumber} of {total_pages}"
        self.drawRightString(540, 32, page_indicator)
        self.restoreState()


def build_product_guide():
    doc = SimpleDocTemplate(
        PDF_OUTPUT_PATH,
        pagesize=A4,
        leftMargin=54,
        rightMargin=54,
        topMargin=54,
        bottomMargin=54
    )

    styles = getSampleStyleSheet()

    # Typography Styles
    cover_title_style = ParagraphStyle(
        'CoverTitle',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=24,
        leading=28,
        textColor=colors.HexColor("#0F172A")
    )
    
    cover_subtitle_style = ParagraphStyle(
        'CoverSubtitle',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=11,
        leading=15,
        textColor=colors.HexColor("#0284C7")
    )

    section_h1 = ParagraphStyle(
        'SectionH1',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=13,
        leading=17,
        textColor=colors.HexColor("#1E3A8A"), # Deep Blue
        spaceBefore=10,
        spaceAfter=6
    )

    subsection_h2 = ParagraphStyle(
        'SubSectionH2',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=10,
        leading=14,
        textColor=colors.HexColor("#0F172A"),
        spaceBefore=6,
        spaceAfter=3
    )

    body_text = ParagraphStyle(
        'BodyTextCustom',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=8.8,
        leading=12.5,
        textColor=colors.HexColor("#334155")
    )

    callout_text = ParagraphStyle(
        'CalloutText',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=8.6,
        leading=12.5,
        textColor=colors.HexColor("#1E293B")
    )

    tbl_header = ParagraphStyle(
        'TblHeader',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=8.5,
        leading=11,
        textColor=colors.HexColor("#0F172A")
    )

    tbl_cell = ParagraphStyle(
        'TblCell',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=8.2,
        leading=11.2,
        textColor=colors.HexColor("#334155")
    )

    story = []

    # ═══════════════════════════════════════════════════════════════════════
    # PAGE 1: COVER, EXECUTIVE SUMMARY & INDUSTRY PROBLEM VS SOLUTION
    # ═══════════════════════════════════════════════════════════════════════
    story.append(Spacer(1, 4))
    story.append(Paragraph("DHealth Platform", cover_title_style))
    story.append(Spacer(1, 3))
    story.append(Paragraph("Next-Generation Unified Health Record & Clinical Operations Platform", cover_subtitle_style))
    story.append(Spacer(1, 6))
    story.append(HRFlowable(width="100%", thickness=2, color=colors.HexColor("#0284C7"), spaceBefore=0, spaceAfter=8))

    intro_box = [
        [
            Paragraph(
                "<b>Executive Summary for Prospective Buyers:</b><br/>"
                "Healthcare operations today suffer from severe fragmentation. Patient records are trapped in paper files, "
                "diagnostic lab slips are easily misplaced, clinic consultations lack past clinical history, and hospital wards "
                "struggle with manual bed tracking. <b>DHealth</b> is an all-in-one digital healthcare operating system that connects "
                "<b>Patients, Doctors, Diagnostic Labs, and Hospitals</b> into one unified, real-time ecosystem. "
                "Every prescription, blood test, and hospital admission synchronizes instantly across portals — eliminating paper waste, "
                "cutting overhead by 80%, and delivering a world-class patient experience.",
                callout_text
            )
        ]
    ]
    t_intro = Table(intro_box, colWidths=[486])
    t_intro.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, -1), colors.HexColor("#F0F9FF")),
        ('BOX', (0, 0), (-1, -1), 1, colors.HexColor("#BAE6FD")),
        ('TOPPADDING', (0, 0), (-1, -1), 7),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 7),
        ('LEFTPADDING', (0, 0), (-1, -1), 9),
        ('RIGHTPADDING', (0, 0), (-1, -1), 9),
    ]))
    story.append(t_intro)
    story.append(Spacer(1, 10))

    story.append(Paragraph("1. The Healthcare Dilemma vs. The DHealth Solution", section_h1))
    story.append(Paragraph(
        "Here is why traditional standalone healthcare tools fail, and why DHealth gives your organization an immediate competitive edge:",
        body_text
    ))
    story.append(Spacer(1, 6))

    comp_data = [
        [
            Paragraph("<b>Traditional Healthcare Reality (The Pain Points)</b>", tbl_header),
            Paragraph("<b>The DHealth Solution (What You Are Buying)</b>", tbl_header)
        ],
        [
            Paragraph("<b>Scattered, Lost Records:</b> Patients carry bulky files of paper reports; past treatments, surgeries, and drug allergies are missing during emergencies.", tbl_cell),
            Paragraph("<b>Unified Lifetime Health Locker:</b> Every digital prescription, lab report, and consultation note is permanently organized in one searchable timeline.", tbl_cell)
        ],
        [
            Paragraph("<b>Disconnected Software Silos:</b> Clinic prescription software cannot communicate with external diagnostic laboratories or local hospitals.", tbl_cell),
            Paragraph("<b>Real-Time Ecosystem Sync:</b> An action in one portal (e.g. an e-prescription or lab report) immediately appears in the patient's and doctor's records.", tbl_cell)
        ],
        [
            Paragraph("<b>Labor-Intensive Lab Entry:</b> Diagnostic centers waste hours manually typing 50 patient names and 200 parameter results into isolated computers.", tbl_cell),
            Paragraph("<b>'Zero Extra Work' Batch Ingest:</b> Labs upload standard spreadsheet/CSV files directly from their analyzers; accounts and reports are auto-created in seconds.", tbl_cell)
        ],
        [
            Paragraph("<b>Data Privacy Concerns:</b> Sensitive health conditions are either vulnerable to unauthorized staff or locked behind complex, unusable systems.", tbl_cell),
            Paragraph("<b>Granular 24-Hour Patient Consent:</b> Doctors request access with 1 click; patients approve or revoke access from their phone. Full compliance made easy.", tbl_cell)
        ],
        [
            Paragraph("<b>Delayed Emergency Care:</b> In critical road accidents, doctors have zero information on blood group or drug allergies, leading to dangerous medical errors.", tbl_cell),
            Paragraph("<b>Pure-Text Emergency Health Card:</b> Vital information (Blood group, allergies, conditions, contacts) opens in 0.5s without requiring QR scanner apps.", tbl_cell)
        ]
    ]
    t_comp = Table(comp_data, colWidths=[240, 246])
    t_comp.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor("#F8FAFC")),
        ('BOX', (0, 0), (-1, -1), 0.75, colors.HexColor("#CBD5E1")),
        ('INNERGRID', (0, 0), (-1, -1), 0.5, colors.HexColor("#E2E8F0")),
        ('TOPPADDING', (0, 0), (-1, -1), 4.5),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4.5),
        ('LEFTPADDING', (0, 0), (-1, -1), 6),
        ('RIGHTPADDING', (0, 0), (-1, -1), 6),
    ]))
    story.append(t_comp)

    # ═══════════════════════════════════════════════════════════════════════
    # PAGE 2: THE FOUR DEDICATED PORTALS & WORKFLOWS
    # ═══════════════════════════════════════════════════════════════════════
    story.append(PageBreak())
    story.append(Paragraph("2. The Four Specialized Portals (Built for Every Stakeholder)", section_h1))
    story.append(Paragraph(
        "DHealth provides four purpose-built interfaces tailored specifically to the daily tasks of each user role. "
        "No training or technical expertise is required to operate them:",
        body_text
    ))
    story.append(Spacer(1, 6))

    portals_data = [
        [
            Paragraph("<b>PORTAL & AUDIENCE</b>", tbl_header),
            Paragraph("<b>CORE MODULES & FEATURES</b>", tbl_header),
            Paragraph("<b>DIRECT VALUE TO YOUR BUSINESS</b>", tbl_header)
        ],
        [
            Paragraph("<b>1. Patient Portal</b><br/><i>(Web & Mobile)</i><br/><br/>Designed for patients and families seeking effortless control of their health.", tbl_cell),
            Paragraph(
                "• <b>Personal Health Locker:</b> Lifetime cloud storage for all prescriptions, diagnostic scans, and medical bills.<br/>"
                "• <b>Family Health Hub:</b> Manage dependents (aging parents, spouse, children) under a single master login.<br/>"
                "• <b>Emergency Medical Card:</b> Instant text summary of blood group, allergies, chronic conditions, and emergency contacts.<br/>"
                "• <b>Interactive Vitals Tracker:</b> Log blood pressure, glucose, heart rate, and weight with trend visualizers.<br/>"
                "• <b>Privacy Consent Manager:</b> Review and approve doctor access requests with 1 tap.",
                tbl_cell
            ),
            Paragraph("<b>Unmatched Patient Loyalty:</b> Patients stay loyal to healthcare networks that provide an intuitive, high-tech experience for their whole family.", tbl_cell)
        ],
        [
            Paragraph("<b>2. Doctor & Clinic Portal</b><br/><i>(OPD Workstation)</i><br/><br/>Designed for private practitioners, consultants, and OPD clinics.", tbl_cell),
            Paragraph(
                "• <b>Smart Appointment Scheduler:</b> View daily consultations, patient queues, and appointment statuses at a glance.<br/>"
                "• <b>360° Clinical History Chart:</b> Review past diagnoses, past prescriptions, and lab test trends before starting treatment.<br/>"
                "• <b>Digital Prescription Pad:</b> Issue clear, error-free electronic prescriptions with dosages, frequency, and instructions in seconds.<br/>"
                "• <b>Consent Enforcement Protocol:</b> Built-in privacy shield; 1-click request unlocks complete patient records for 24 hours.",
                tbl_cell
            ),
            Paragraph("<b>Higher Doctor Productivity:</b> Saves 15+ minutes per consultation, eliminates illegible handwriting errors, and prevents adverse drug interactions.", tbl_cell)
        ],
        [
            Paragraph("<b>3. Diagnostic Lab Portal</b><br/><i>(Pathology & Imaging)</i><br/><br/>Designed for standalone diagnostic centers and hospital labs.", tbl_cell),
            Paragraph(
                "• <b>Organized Sample Queue:</b> Filter test orders by discipline (Biochemistry, Hematology, Microbiology, etc.).<br/>"
                "• <b>Automatic Abnormality Detection:</b> High/low parameters automatically flagged in red for immediate pathologist review.<br/>"
                "• <b>'Zero Extra Work' Batch Ingest:</b> Upload machine CSV exports to process dozens of patient tests in one operation.<br/>"
                "• <b>Direct Locker Delivery:</b> 1-click report publishing sends verified results directly to patient smartphones.",
                tbl_cell
            ),
            Paragraph("<b>60% Faster Turnaround:</b> Diagnostic labs process 3x more tests daily, eliminate paper printing expenses, and reduce phone inquiries by 90%.", tbl_cell)
        ],
        [
            Paragraph("<b>4. Hospital Management</b><br/><i>(Inpatient Portal)</i><br/><br/>Designed for nursing supervisors, administrators, and ward staff.", tbl_cell),
            Paragraph(
                "• <b>Live Bed Occupancy Map:</b> Real-time visual tracking of vacant vs. occupied beds across ICU, General, and Private wards.<br/>"
                "• <b>Digital Admission Intake:</b> Rapid admission logging with assigned attending doctor, initial diagnosis, and room assignment.<br/>"
                "• <b>Automated Discharge Summaries:</b> Compiles hospital stay notes, final treatment, and follow-up advice directly into the patient's record.",
                tbl_cell
            ),
            Paragraph("<b>Optimized Hospital Revenue:</b> Maximizes bed occupancy rates, prevents bed hoarding, speeds up patient discharge clearance, and reduces readmissions.", tbl_cell)
        ]
    ]
    t_portals = Table(portals_data, colWidths=[98, 252, 136])
    t_portals.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor("#F1F5F9")),
        ('BOX', (0, 0), (-1, -1), 0.75, colors.HexColor("#CBD5E1")),
        ('INNERGRID', (0, 0), (-1, -1), 0.5, colors.HexColor("#E2E8F0")),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('TOPPADDING', (0, 0), (-1, -1), 4.5),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4.5),
        ('LEFTPADDING', (0, 0), (-1, -1), 6),
        ('RIGHTPADDING', (0, 0), (-1, -1), 6),
    ]))
    story.append(t_portals)

    # ═══════════════════════════════════════════════════════════════════════
    # PAGE 3: THE FOUR STANDOUT ADVANTAGES (DEAL CLOSERS)
    # ═══════════════════════════════════════════════════════════════════════
    story.append(PageBreak())
    story.append(Paragraph("3. Flagship Innovations That Make DHealth Unique", section_h1))
    story.append(Paragraph(
        "Most healthcare applications are either clunky hospital systems or basic calendar apps. "
        "DHealth introduces four groundbreaking features engineered to overcome real-world operational friction:",
        body_text
    ))
    story.append(Spacer(1, 6))

    # Feature 1: Batch Ingest
    story.append(Paragraph("A. 'Zero Extra Work' Automated Lab Ingestion (Bulk CSV Upload)", subsection_h2))
    p_batch = (
        "<b>The Barrier in Other Systems:</b> Diagnostic lab technicians refuse to use new software because they do not have time "
        "to manually type patient details and hundreds of test parameters after a busy testing run.<br/>"
        "<b>The DHealth Breakthrough:</b> Technicians simply drag and drop the CSV spreadsheet exported directly from their testing analyzer machine. "
        "The DHealth automated parser instantly matches existing patients or automatically registers new ones, populates test values, "
        "compares results against normal biological reference ranges, and dispatches the reports to patient health lockers in seconds. "
        "<b>Labs adopt DHealth eagerly because it requires literally zero extra typing.</b>"
    )
    story.append(Paragraph(p_batch, body_text))
    story.append(Spacer(1, 6))

    # Feature 2: Granular Consent
    story.append(Paragraph("B. Granular 24-Hour Patient Consent & Privacy Shield", subsection_h2))
    p_consent = (
        "<b>The Privacy Challenge:</b> Modern patients demand absolute privacy. If sensitive health records (past surgeries, mental health, gynecological notes) "
        "are visible to every clinic employee, patients will refuse to use the system.<br/>"
        "<b>The DHealth Breakthrough:</b> Patient clinical histories remain encrypted and locked behind a privacy shield. "
        "When a consulting doctor needs to review records, they tap <b>'Request Access'</b>. The patient receives an instant notification "
        "on their phone and can approve 24-hour access or deny it with 1 touch. After 24 hours, the shield locks automatically. "
        "<b>This provides enterprise-grade compliance with zero administrative bureaucracy.</b>"
    )
    story.append(Paragraph(p_consent, body_text))
    story.append(Spacer(1, 6))

    # Feature 3: Global Instant Search
    story.append(Paragraph("C. Global Instant Search Across the Entire Platform", subsection_h2))
    p_search = (
        "<b>No More Endless Clicking:</b> Healthcare professionals and patients do not have time to navigate through complicated menu trees. "
        "DHealth features an omnipresent search bar at the top of every screen. Typing just two letters instantly surfaces matching "
        "prescriptions, doctor consultations, lab reports, specific blood parameters (e.g., 'Cholesterol' or 'Hemoglobin'), and verified medical specialists. "
        "<b>Any medical record is accessible within two keystrokes.</b>"
    )
    story.append(Paragraph(p_search, body_text))
    story.append(Spacer(1, 6))

    # Feature 4: Emergency Health Card
    story.append(Paragraph("D. Pure-Text Emergency Medical Card (Life-Saving Simplicity)", subsection_h2))
    p_emerg = (
        "<b>Why QR Codes Fail in Real Emergencies:</b> In sudden road accidents, unconscious traumas, or poor cell-service zones, "
        "first responders and paramedics do not have time to unlock phones, download third-party scanner apps, or wait for QR links to buffer.<br/>"
        "<b>The DHealth Breakthrough:</b> The Emergency Medical Card is 100% pure text displayed directly on screen. It presents "
        "<b>Blood Group, Critical Drug Allergies, Chronic Conditions (e.g., Diabetes, Cardiac Stent), and 1-Touch Emergency Contact Dials</b>. "
        "It loads in 0.5 seconds, can be read in a single glance, and works reliably under extreme emergency stress without any scanner bloat."
    )
    story.append(Paragraph(p_emerg, body_text))
    story.append(Spacer(1, 8))

    # Feature highlight box
    f_box = [
        [
            Paragraph(
                "<b>Why Buyers Value These 4 Features:</b> Together, these innovations solve the four biggest complaints in digital health: "
                "data entry burnout (solved by CSV batch upload), patient privacy fears (solved by 24h consent), information search fatigue "
                "(solved by global instant search), and emergency usability (solved by the pure-text emergency card).",
                callout_text
            )
        ]
    ]
    t_fbox = Table(f_box, colWidths=[486])
    t_fbox.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, -1), colors.HexColor("#F8FAFC")),
        ('BOX', (0, 0), (-1, -1), 1, colors.HexColor("#0284C7")),
        ('TOPPADDING', (0, 0), (-1, -1), 6),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
        ('LEFTPADDING', (0, 0), (-1, -1), 8),
        ('RIGHTPADDING', (0, 0), (-1, -1), 8),
    ]))
    story.append(t_fbox)

    # ═══════════════════════════════════════════════════════════════════════
    # PAGE 4: THE CROSS-PORTAL SYNC ENGINE & REAL-WORLD SCENARIO
    # ═══════════════════════════════════════════════════════════════════════
    story.append(PageBreak())
    story.append(Paragraph("4. The Cross-Portal Sync Engine (Seamless Connected Care)", section_h1))
    story.append(Paragraph(
        "In traditional healthcare, each clinic or department is an isolated island. "
        "In DHealth, data flows automatically behind the scenes with zero duplicate paperwork:",
        body_text
    ))
    story.append(Spacer(1, 6))

    flow_data = [
        [
            Paragraph("<b>CLINICAL EVENT</b>", tbl_header),
            Paragraph("<b>STAFF ACTION TAKEN</b>", tbl_header),
            Paragraph("<b>WHAT DHEALTH DOES AUTOMATICALLY</b>", tbl_header)
        ],
        [
            Paragraph("<b>1. Doctor Consultation</b>", tbl_cell),
            Paragraph("Doctor inputs diagnosis and medicines on the digital prescription pad.", tbl_cell),
            Paragraph("<b>Instant Health Locker Delivery:</b> The prescription is immediately formatted and saved to the patient's phone and health timeline. No lost paper slips.", tbl_cell)
        ],
        [
            Paragraph("<b>2. Diagnostic Blood Test</b>", tbl_cell),
            Paragraph("Lab technician uploads bulk machine CSV or confirms test parameters.", tbl_cell),
            Paragraph("<b>Dual Notification & Sync:</b> The official report appears in the patient's locker, and the consulting doctor's patient chart updates with the new test trends.", tbl_cell)
        ],
        [
            Paragraph("<b>3. Inpatient Discharge</b>", tbl_cell),
            Paragraph("Hospital staff clicks 'Discharge Patient' upon treatment completion.", tbl_cell),
            Paragraph("<b>Instant Room Release & Record Filing:</b> Ward bed flips to 'Available' for new patients, and the complete discharge summary enters the patient's permanent record.", tbl_cell)
        ],
        [
            Paragraph("<b>4. Specialist Referral</b>", tbl_cell),
            Paragraph("Patient visits a new specialist and taps 'Approve (24h)'.", tbl_cell),
            Paragraph("<b>Instant Record Unmasking:</b> The specialist's workstation instantly reveals past medications, allergies, and diagnostic history without re-running tests.", tbl_cell)
        ]
    ]
    t_flow = Table(flow_data, colWidths=[110, 175, 201])
    t_flow.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor("#F1F5F9")),
        ('BOX', (0, 0), (-1, -1), 0.75, colors.HexColor("#CBD5E1")),
        ('INNERGRID', (0, 0), (-1, -1), 0.5, colors.HexColor("#E2E8F0")),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('TOPPADDING', (0, 0), (-1, -1), 5),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 5),
        ('LEFTPADDING', (0, 0), (-1, -1), 6),
        ('RIGHTPADDING', (0, 0), (-1, -1), 6),
    ]))
    story.append(t_flow)
    story.append(Spacer(1, 10))

    story.append(Paragraph("A Day in the Life: How DHealth Transforms Patient Journey", subsection_h2))
    journey_box = [
        [
            Paragraph(
                "<b>Scenario: Mr. Sharma's Journey (From Sickness to Full Recovery)</b><br/>"
                "<b>1. 9:00 AM — Clinic Visit:</b> Mr. Sharma visits Dr. Patel. With 1 tap, he approves 24-hour access. "
                "Dr. Patel immediately sees that Mr. Sharma is allergic to Penicillin (avoiding a dangerous error) and issues an e-prescription.<br/>"
                "<b>2. 11:30 AM — Diagnostic Lab:</b> Mr. Sharma stops by the pathology center for a routine blood test. "
                "The lab runs 30 samples on their analyzer and uploads the batch CSV. By 1:00 PM, Mr. Sharma receives his test results on his phone.<br/>"
                "<b>3. 3:00 PM — Doctor Review:</b> Dr. Patel checks his workstation; the new blood report is already linked to Mr. Sharma's chart.<br/>"
                "<b>4. 6:00 PM — Family Peace of Mind:</b> Mr. Sharma's daughter, living in another city, opens the DHealth Family Hub on her phone and sees that her father's tests are normal.<br/>"
                "<b>Total Paper Used: Zero. Total Phone Inquiries: Zero. Result: 100% Patient Delight.</b>",
                callout_text
            )
        ]
    ]
    t_journey = Table(journey_box, colWidths=[486])
    t_journey.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, -1), colors.HexColor("#F0FDF4")),
        ('BOX', (0, 0), (-1, -1), 1, colors.HexColor("#86EFAC")),
        ('TOPPADDING', (0, 0), (-1, -1), 7),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 7),
        ('LEFTPADDING', (0, 0), (-1, -1), 9),
        ('RIGHTPADDING', (0, 0), (-1, -1), 9),
    ]))
    story.append(t_journey)

    # ═══════════════════════════════════════════════════════════════════════
    # PAGE 5: COMMERCIAL ROI, TECHNICAL SIMPLICITY & CLOSING SUMMARY
    # ═══════════════════════════════════════════════════════════════════════
    story.append(PageBreak())
    story.append(Paragraph("5. Business Value & Return on Investment (Why It Pays For Itself)", section_h1))
    story.append(Paragraph(
        "For healthcare operators, clinics, and hospital networks, DHealth delivers immediate cost savings and revenue expansion:",
        body_text
    ))
    story.append(Spacer(1, 6))

    roi_data = [
        [
            Paragraph("<b>BUSINESS AREA</b>", tbl_header),
            Paragraph("<b>FINANCIAL & TIME SAVINGS</b>", tbl_header),
            Paragraph("<b>OPERATIONAL MECHANISM IN DHEALTH</b>", tbl_header)
        ],
        [
            Paragraph("<b>Printing & Paper Expenses</b>", tbl_cell),
            Paragraph("<font color='#059669'><b>80% Cost Reduction</b></font>", tbl_cell),
            Paragraph("Eliminates prescription pads, record folders, plastic film jackets, and physical archive rooms.", tbl_cell)
        ],
        [
            Paragraph("<b>Consultation Efficiency</b>", tbl_cell),
            Paragraph("<font color='#059669'><b>+25% Patient Throughput</b></font>", tbl_cell),
            Paragraph("Instant clinical history and digital prescriptions allow doctors to consult more patients per hour with higher care quality.", tbl_cell)
        ],
        [
            Paragraph("<b>Diagnostic Lab Throughput</b>", tbl_cell),
            Paragraph("<font color='#059669'><b>60% Faster Delivery</b></font>", tbl_cell),
            Paragraph("Batch CSV ingestion processes tests in bulk; automated digital publishing eliminates manual report printing and collection queues.", tbl_cell)
        ],
        [
            Paragraph("<b>Ward Bed Turnaround</b>", tbl_cell),
            Paragraph("<font color='#059669'><b>+15% Bed Utilization</b></font>", tbl_cell),
            Paragraph("Live bed status map prevents vacant beds from sitting unassigned; digital discharge frees up beds immediately.", tbl_cell)
        ],
        [
            Paragraph("<b>Messaging & SMS Costs</b>", tbl_cell),
            Paragraph("<font color='#059669'><b>100% Free Login Auth</b></font>", tbl_cell),
            Paragraph("Uses free, secure email verification (Gmail SMTP). Zero costly SMS gateway fees every time a patient logs in.", tbl_cell)
        ]
    ]
    t_roi = Table(roi_data, colWidths=[120, 115, 251])
    t_roi.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor("#F1F5F9")),
        ('BOX', (0, 0), (-1, -1), 0.75, colors.HexColor("#CBD5E1")),
        ('INNERGRID', (0, 0), (-1, -1), 0.5, colors.HexColor("#E2E8F0")),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('TOPPADDING', (0, 0), (-1, -1), 4.5),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4.5),
        ('LEFTPADDING', (0, 0), (-1, -1), 6),
        ('RIGHTPADDING', (0, 0), (-1, -1), 6),
    ]))
    story.append(t_roi)
    story.append(Spacer(1, 10))

    story.append(Paragraph("6. Technology & Security Without Any Technical Headaches", section_h1))
    setup_points = (
        "• <b>Works on Any Device Instantly:</b> Fully responsive. Runs effortlessly on mobile phones, tablets, laptops, and desktop computers without requiring expensive hardware upgrades.<br/>"
        "• <b>Zero Software Maintenance for Staff:</b> Everything runs through intuitive web and mobile screens. Front-desk staff, nurses, and technicians become proficient in less than 30 minutes.<br/>"
        "• <b>Bank-Grade Security:</b> Utilizes industry-standard token security (SimpleJWT) and strict role-based access control. Staff only see records relevant to their specific clinical duties.<br/>"
        "• <b>100% Ready for Turnkey Deployment:</b> The complete frontend client and backend API are fully built, automated, and pre-integrated for immediate deployment."
    )
    story.append(Paragraph(setup_points, body_text))
    story.append(Spacer(1, 10))

    story.append(Paragraph("7. Commercial Next Steps & Acquisition", section_h1))
    closing_box = [
        [
            Paragraph(
                "<b>Commercial Acquisition Summary:</b><br/>"
                "By acquiring the DHealth Platform, your organization is not just purchasing software — you are acquiring a "
                "<b>complete, production-tested digital health ecosystem</b> ready for immediate launch.<br/><br/>"
                "<b>What is Included in This Solution:</b><br/>"
                "1. <b>Full Source Code & Architecture:</b> Complete Flutter client application and Django REST backend.<br/>"
                "2. <b>All Four Operational Portals:</b> Patient Mobile Companion, Doctor Clinic Station, Lab Portal, and Hospital Ward Suite.<br/>"
                "3. <b>Zero-Friction Ingest & Sync Engine:</b> Ready-to-use batch CSV ingestion, 24-hour consent protocols, and automated sync.<br/>"
                "4. <b>Custom Branding & White-Labeling:</b> Can be customized with your brand identity, clinic logo, and private domain.<br/><br/>"
                "<b>Conclusion:</b> DHealth modernizes clinical workflows, eliminates paper costs, enhances patient trust, and drives revenue growth from Day 1.",
                callout_text
            )
        ]
    ]
    t_closing = Table(closing_box, colWidths=[486])
    t_closing.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, -1), colors.HexColor("#F8FAFC")),
        ('BOX', (0, 0), (-1, -1), 1.25, colors.HexColor("#0284C7")),
        ('TOPPADDING', (0, 0), (-1, -1), 7),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 7),
        ('LEFTPADDING', (0, 0), (-1, -1), 9),
        ('RIGHTPADDING', (0, 0), (-1, -1), 9),
    ]))
    story.append(t_closing)

    doc.build(story, canvasmaker=ProfessionalCanvas)
    print("Product Presentation PDF built successfully at:", PDF_OUTPUT_PATH)


if __name__ == "__main__":
    build_product_guide()
