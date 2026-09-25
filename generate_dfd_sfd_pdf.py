import os
import sys
from PIL import Image, ImageDraw, ImageFont
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Image as RLImage, Table, TableStyle, PageBreak
)
from reportlab.pdfgen import canvas

OUTPUT_DIR = r"D:\Health"
PDF_PATH = os.path.join(OUTPUT_DIR, "Digital_Health_Platform_DFD_SFD_Report.pdf")

def get_font(size, bold=False):
    font_names = [
        "arialbd.ttf" if bold else "arial.ttf",
        "segoeuib.ttf" if bold else "segoeui.ttf",
        "calibrib.ttf" if bold else "calibri.ttf",
    ]
    for fn in font_names:
        try:
            return ImageFont.truetype(fn, size)
        except Exception:
            continue
    return ImageFont.load_default()

def draw_rounded_rect(draw, xy, radius, fill, outline=None, width=1):
    draw.rounded_rectangle(xy, radius=radius, fill=fill, outline=outline, width=width)

def draw_arrow(draw, start, end, color=(71, 85, 105), width=2, arrow_size=8):
    x1, y1 = start
    x2, y2 = end
    draw.line([start, end], fill=color, width=width)
    import math
    angle = math.atan2(y2 - y1, x2 - x1)
    p1 = (x2 - arrow_size * math.cos(angle - math.pi / 6), y2 - arrow_size * math.sin(angle - math.pi / 6))
    p2 = (x2 - arrow_size * math.cos(angle + math.pi / 6), y2 - arrow_size * math.sin(angle + math.pi / 6))
    draw.polygon([end, p1, p2], fill=color)

# -------------------------------------------------------------
# 1. GENERATE LEVEL 0 DFD (CONTEXT DIAGRAM)
# -------------------------------------------------------------
def generate_dfd_level_0():
    img_w, img_h = 1600, 1100
    img = Image.new("RGB", (img_w, img_h), "#F8FAFC")
    draw = ImageDraw.Draw(img)

    f_title = get_font(28, bold=True)
    f_header = get_font(18, bold=True)
    f_body = get_font(14, bold=False)
    f_label = get_font(12, bold=False)

    # Title Banner
    draw.rectangle([0, 0, img_w, 70], fill="#0F172A")
    draw.text((40, 20), "LEVEL 0 DATA FLOW DIAGRAM (CONTEXT LEVEL) — DIGITAL HEALTH PLATFORM", fill="#F8FAFC", font=f_title)

    # Central System (Circle/Pill)
    cx, cy = 800, 520
    cw, ch = 340, 220
    draw.ellipse([cx - cw//2, cy - ch//2, cx + cw//2, cy + ch//2], fill="#0284C7", outline="#0369A1", width=4)
    draw.text((cx, cy - 50), "0.0", fill="#BAE6FD", font=get_font(22, bold=True), anchor="mm")
    draw.text((cx, cy - 15), "DIGITAL HEALTH RECORD", fill="#FFFFFF", font=get_font(20, bold=True), anchor="mm")
    draw.text((cx, cy + 15), "& CONSENT ENGINE", fill="#FFFFFF", font=get_font(20, bold=True), anchor="mm")
    draw.text((cx, cy + 50), "(Centralized Core System)", fill="#E0F2FE", font=f_body, anchor="mm")

    # Entities
    # 1. Patient (Top Left)
    draw_rounded_rect(draw, (80, 120, 360, 280), radius=10, fill="#FFFFFF", outline="#0284C7", width=3)
    draw.rectangle([80, 120, 360, 165], fill="#E0F2FE")
    draw.text((220, 142), "PATIENT", fill="#0369A1", font=f_header, anchor="mm")
    draw.text((100, 180), "• Patient Credentials & OTP", fill="#334155", font=f_body)
    draw.text((100, 205), "• Doctor Email Lookup Query", fill="#334155", font=f_body)
    draw.text((100, 230), "• Consent Authorization / Revoke", fill="#334155", font=f_body)
    draw.text((100, 255), "• Emergency Contact & Vitals", fill="#334155", font=f_body)

    # 2. Doctor (Top Right)
    draw_rounded_rect(draw, (1240, 120, 1520, 280), radius=10, fill="#FFFFFF", outline="#1E40AF", width=3)
    draw.rectangle([1240, 120, 1520, 165], fill="#EFF6FF")
    draw.text((1380, 142), "DOCTOR", fill="#1E40AF", font=f_header, anchor="mm")
    draw.text((1260, 180), "• Doctor Credentials & Reg No", fill="#334155", font=f_body)
    draw.text((1260, 205), "• Patient Email Search Query", fill="#334155", font=f_body)
    draw.text((1260, 230), "• Clinical Diagnosis & Rx Data", fill="#334155", font=f_body)
    draw.text((1260, 255), "• Consent Accept / Decline", fill="#334155", font=f_body)

    # 3. Diagnostic Lab (Bottom Left)
    draw_rounded_rect(draw, (80, 760, 360, 920), radius=10, fill="#FFFFFF", outline="#059669", width=3)
    draw.rectangle([80, 760, 360, 805], fill="#ECFDF5")
    draw.text((220, 782), "DIAGNOSTIC LAB", fill="#065F46", font=f_header, anchor="mm")
    draw.text((100, 820), "• Lab Tech Credentials & License", fill="#334155", font=f_body)
    draw.text((100, 845), "• Individual Lab Test Orders", fill="#334155", font=f_body)
    draw.text((100, 870), "• Bulk Diagnostic CSV Batches", fill="#334155", font=f_body)
    draw.text((100, 895), "• Report Test Status & Values", fill="#334155", font=f_body)

    # 4. Hospital Administration (Bottom Right)
    draw_rounded_rect(draw, (1240, 760, 1520, 920), radius=10, fill="#FFFFFF", outline="#D97706", width=3)
    draw.rectangle([1240, 760, 1520, 805], fill="#FEF3C7")
    draw.text((1380, 782), "HOSPITAL CARE", fill="#92400E", font=f_header, anchor="mm")
    draw.text((1260, 820), "• Hospital Admin Credentials", fill="#334155", font=f_body)
    draw.text((1260, 845), "• Patient Admission (Ward/Bed)", fill="#334155", font=f_body)
    draw.text((1260, 870), "• Daily Inpatient Monitoring Vitals", fill="#334155", font=f_body)
    draw.text((1260, 895), "• Discharge Summaries & Release", fill="#334155", font=f_body)

    # 5. External Email/OTP Service (Top Center)
    draw_rounded_rect(draw, (650, 100, 950, 190), radius=8, fill="#F1F5F9", outline="#64748B", width=2)
    draw.text((800, 125), "EXTERNAL SMTP / EMAIL SERVICE", fill="#334155", font=f_header, anchor="mm")
    draw.text((800, 155), "Dispatches 6-Digit Secure OTPs & Alerts", fill="#64748B", font=f_body, anchor="mm")

    # Connectors & Data Flows
    draw_arrow(draw, (360, 200), (660, 440), color="#0284C7", width=3)
    draw.text((450, 300), "Auth, Consent, Search by Email", fill="#0369A1", font=f_label)

    draw_arrow(draw, (650, 480), (360, 240), color="#0284C7", width=3)
    draw.text((430, 380), "EMR Timeline, Rx, Verified Doctor Details", fill="#0369A1", font=f_label)

    draw_arrow(draw, (1240, 200), (940, 440), color="#1E40AF", width=3)
    draw.text((980, 300), "Diagnosis, Rx, Search Patient Email", fill="#1E40AF", font=f_label)

    draw_arrow(draw, (950, 480), (1240, 240), color="#1E40AF", width=3)
    draw.text((1000, 380), "Unlocked Clinical Chart (24h Window)", fill="#1E40AF", font=f_label)

    draw_arrow(draw, (770, 410), (770, 190), color="#64748B", width=2)
    draw.text((700, 320), "OTP Request", fill="#475569", font=f_label)

    draw_arrow(draw, (830, 190), (830, 410), color="#64748B", width=2)
    draw.text((840, 320), "OTP Delivery", fill="#475569", font=f_label)

    draw_arrow(draw, (360, 820), (670, 600), color="#059669", width=3)
    draw.text((440, 680), "Batch CSV, Lab Results, Test Orders", fill="#065F46", font=f_label)

    draw_arrow(draw, (650, 640), (360, 860), color="#059669", width=3)
    draw.text((420, 750), "Validation Status & Published EMR Confirm", fill="#065F46", font=f_label)

    draw_arrow(draw, (1240, 820), (930, 600), color="#D97706", width=3)
    draw.text((980, 680), "Admissions, Bed Allocation, Ward Vitals", fill="#92400E", font=f_label)

    draw_arrow(draw, (950, 640), (1240, 860), color="#D97706", width=3)
    draw.text((980, 750), "Bed Occupancy, Patient Discharge Summary", fill="#92400E", font=f_label)

    path = os.path.join(OUTPUT_DIR, "dfd_level_0.png")
    img.save(path, "PNG", dpi=(300, 300))
    return path

# -------------------------------------------------------------
# 2. GENERATE LEVEL 1 DFD (DECOMPOSED SUBSYSTEMS)
# -------------------------------------------------------------
def generate_dfd_level_1():
    img_w, img_h = 1600, 1200
    img = Image.new("RGB", (img_w, img_h), "#F8FAFC")
    draw = ImageDraw.Draw(img)

    f_title = get_font(28, bold=True)
    f_header = get_font(16, bold=True)
    f_body = get_font(13, bold=False)
    f_bold = get_font(13, bold=True)
    f_label = get_font(11, bold=True)

    # Title Banner
    draw.rectangle([0, 0, img_w, 70], fill="#1E293B")
    draw.text((40, 20), "LEVEL 1 DATA FLOW DIAGRAM — FUNCTIONAL SUBSYSTEMS DECOMPOSITION", fill="#F8FAFC", font=f_title)

    # External Entities
    draw_rounded_rect(draw, (50, 100, 250, 200), radius=8, fill="#E0F2FE", outline="#0284C7", width=2)
    draw.text((150, 130), "👤 PATIENT", fill="#0369A1", font=f_header, anchor="mm")
    draw.text((150, 160), "Web & Mobile Client", fill="#0284C7", font=f_body, anchor="mm")

    draw_rounded_rect(draw, (1350, 100, 1550, 200), radius=8, fill="#EFF6FF", outline="#1E40AF", width=2)
    draw.text((1450, 130), "👨‍⚕️ DOCTOR", fill="#1E40AF", font=f_header, anchor="mm")
    draw.text((1450, 160), "Clinical Workstation", fill="#1E40AF", font=f_body, anchor="mm")

    draw_rounded_rect(draw, (50, 850, 250, 950), radius=8, fill="#ECFDF5", outline="#059669", width=2)
    draw.text((150, 880), "🔬 DIAGNOSTIC LAB", fill="#065F46", font=f_header, anchor="mm")
    draw.text((150, 910), "Laboratory Staff", fill="#059669", font=f_body, anchor="mm")

    draw_rounded_rect(draw, (1350, 850, 1550, 950), radius=8, fill="#FEF3C7", outline="#D97706", width=2)
    draw.text((1450, 880), "🏥 HOSPITAL CARE", fill="#92400E", font=f_header, anchor="mm")
    draw.text((1450, 910), "Inpatient Ward Admin", fill="#D97706", font=f_body, anchor="mm")

    # 6 Core Subsystem Processes
    def draw_process(num, title, sub, x, y, color):
        draw_rounded_rect(draw, (x-120, y-50, x+120, y+50), radius=25, fill=color, outline="#0F172A", width=2)
        draw.text((x, y-25), num, fill="#FFFFFF", font=get_font(14, bold=True), anchor="mm")
        draw.text((x, y-2), title, fill="#FFFFFF", font=get_font(13, bold=True), anchor="mm")
        draw.text((x, y+22), sub, fill="#F1F5F9", font=get_font(11, bold=False), anchor="mm")

    draw_process("1.0", "AUTH & IDENTITY", "Email OTP & JWT Session", 450, 160, "#475569")
    draw_process("2.0", "DIRECTORY & LOOKUP", "Strict Email-Based Search", 800, 160, "#0284C7")
    draw_process("3.0", "CONSENT PROTOCOL", "24-Hour Active Window", 1150, 160, "#7C3AED")

    draw_process("4.0", "CLINICAL EMR & RX", "Diagnosis & Prescriptions", 1150, 500, "#2563EB")
    draw_process("5.0", "DIAGNOSTIC TESTING", "Lab Orders & CSV Upload", 450, 680, "#059669")
    draw_process("6.0", "HOSPITAL CARE", "Admissions, Beds & Vitals", 1150, 850, "#D97706")

    # 5 Data Stores
    def draw_datastore(ds_id, name, x, y):
        draw.rectangle([x, y, x+220, y+50], fill="#FFFFFF", outline="#64748B", width=2)
        draw.line([x+45, y, x+45, y+50], fill="#64748B", width=2)
        draw.text((x+22, y+25), ds_id, fill="#0F172A", font=f_bold, anchor="mm")
        draw.text((x+130, y+25), name, fill="#0F172A", font=f_bold, anchor="mm")

    draw_datastore("D1", "User & Role Profiles", 700, 320)
    draw_datastore("D2", "Consents & Access Timers", 700, 420)
    draw_datastore("D3", "Prescriptions & Medicines", 700, 530)
    draw_datastore("D4", "Diagnostic Lab Reports", 700, 680)
    draw_datastore("D5", "Inpatient Beds & Vitals", 700, 820)

    # Connections
    draw_arrow(draw, (250, 140), (330, 150), color="#0284C7")
    draw.text((260, 125), "Email / OTP", fill="#0369A1", font=f_label)

    draw_arrow(draw, (250, 170), (680, 160), color="#0284C7")
    draw.text((340, 180), "Search Doctor Email", fill="#0369A1", font=f_label)

    draw_arrow(draw, (1350, 140), (1270, 150), color="#1E40AF")
    draw.text((1280, 125), "Auth / Login", fill="#1E40AF", font=f_label)

    draw_arrow(draw, (1350, 170), (920, 160), color="#1E40AF")
    draw.text((1180, 180), "Search Patient Email", fill="#1E40AF", font=f_label)

    draw_arrow(draw, (920, 160), (1030, 160), color="#7C3AED")
    draw.text((930, 140), "Target Profile", fill="#6D28D9", font=f_label)

    draw_arrow(draw, (1150, 210), (920, 430), color="#7C3AED")
    draw.text((1050, 310), "Write 24h Window", fill="#6D28D9", font=f_label)

    draw_arrow(draw, (1350, 200), (1250, 460), color="#2563EB")
    draw.text((1300, 330), "Rx & Diagnosis", fill="#1D4ED8", font=f_label)

    draw_arrow(draw, (1030, 500), (920, 545), color="#2563EB")
    draw.text((950, 510), "Save Rx Items", fill="#1D4ED8", font=f_label)

    draw_arrow(draw, (700, 555), (200, 200), color="#0284C7")
    draw.text((380, 370), "Sync Rx to Patient Timeline", fill="#0369A1", font=f_label)

    draw_arrow(draw, (250, 870), (330, 710), color="#059669")
    draw.text((220, 780), "Upload CSV / Test", fill="#065F46", font=f_label)

    draw_arrow(draw, (570, 690), (700, 690), color="#059669")
    draw.text((580, 670), "Store Report Data", fill="#065F46", font=f_label)

    draw_arrow(draw, (1350, 880), (1270, 860), color="#D97706")
    draw.text((1280, 890), "Admit / Bed # / Vitals", fill="#92400E", font=f_label)

    draw_arrow(draw, (1030, 850), (920, 840), color="#D97706")
    draw.text((940, 825), "Update Ward Status", fill="#92400E", font=f_label)

    draw_arrow(draw, (450, 210), (700, 330), color="#475569")
    draw.text((510, 260), "Store Verified User", fill="#334155", font=f_label)

    path = os.path.join(OUTPUT_DIR, "dfd_level_1.png")
    img.save(path, "PNG", dpi=(300, 300))
    return path

# -------------------------------------------------------------
# 3. GENERATE SYSTEM FLOW DIAGRAM (SFD)
# -------------------------------------------------------------
def generate_sfd():
    img_w, img_h = 1600, 1300
    img = Image.new("RGB", (img_w, img_h), "#FFFFFF")
    draw = ImageDraw.Draw(img)

    f_title = get_font(28, bold=True)
    f_header = get_font(15, bold=True)
    f_body = get_font(12, bold=False)
    f_bold = get_font(12, bold=True)
    f_step = get_font(11, bold=True)

    # Title Banner
    draw.rectangle([0, 0, img_w, 70], fill="#047857")
    draw.text((40, 20), "SYSTEM FLOW DIAGRAM (SFD) — COMPLETE WORKFLOW & DECISION LOGIC", fill="#FFFFFF", font=f_title)

    def draw_box(x, y, w, h, title, sub, fill, outline):
        draw_rounded_rect(draw, (x, y, x+w, y+h), radius=6, fill=fill, outline=outline, width=2)
        draw.text((x + w//2, y + h//2 - 8), title, fill=outline, font=f_header, anchor="mm")
        draw.text((x + w//2, y + h//2 + 10), sub, fill="#475569", font=f_body, anchor="mm")

    def draw_decision(cx, cy, w, h, text, fill="#FEF3C7", outline="#D97706"):
        draw.polygon([(cx, cy - h//2), (cx + w//2, cy), (cx, cy + h//2), (cx - w//2, cy)], fill=fill, outline=outline)
        draw.text((cx, cy), text, fill=outline, font=f_bold, anchor="mm")

    # Column 1
    draw.text((250, 95), "1. AUTHENTICATION & ACCESS", fill="#0F172A", font=get_font(16, bold=True), anchor="mm")
    draw_box(130, 130, 240, 60, "USER INPUT", "Enter Email on Login Screen", "#F0FDF4", "#16A34A")
    draw_arrow(draw, (250, 190), (250, 230), color="#16A34A")

    draw_box(130, 230, 240, 60, "OTP DISPATCH", "POST /api/auth/request-otp/", "#E0F2FE", "#0284C7")
    draw_arrow(draw, (250, 290), (250, 330), color="#0284C7")

    draw_decision(250, 380, 200, 70, "Valid 6-Digit OTP?")
    draw_arrow(draw, (250, 415), (250, 480), color="#16A34A")
    draw.text((260, 440), "YES", fill="#16A34A", font=f_step)

    draw_arrow(draw, (150, 380), (80, 380), color="#DC2626")
    draw.line([(80, 380), (80, 160), (130, 160)], fill="#DC2626", width=2)
    draw.text((90, 360), "NO: Retry", fill="#DC2626", font=f_step)

    draw_box(130, 480, 240, 60, "SESSION TOKEN", "Issue JWT & Load Role Portal", "#EFF6FF", "#2563EB")

    # Column 2
    draw.text((650, 95), "2. EMAIL-BASED DISCOVERY & CONSENT", fill="#0F172A", font=get_font(16, bold=True), anchor="mm")
    draw_arrow(draw, (370, 510), (530, 510), color="#2563EB")
    draw.text((400, 490), "Route Role", fill="#2563EB", font=f_step)

    draw_box(530, 480, 240, 60, "TARGET QUERY", "Enter Doctor / Patient Email", "#F5F3FF", "#7C3AED")
    draw_arrow(draw, (650, 540), (650, 590), color="#7C3AED")

    draw_decision(650, 640, 220, 80, "Record Exists in DB?")
    draw_arrow(draw, (650, 680), (650, 750), color="#16A34A")
    draw.text((660, 710), "YES: Display Card", fill="#16A34A", font=f_step)

    draw_arrow(draw, (540, 640), (480, 640), color="#DC2626")
    draw.line([(480, 640), (480, 510), (530, 510)], fill="#DC2626", width=2)
    draw.text((410, 620), "NO: 0 Results Prompt", fill="#DC2626", font=f_step)

    draw_box(530, 750, 240, 60, "CONSENT REQUEST", "Link & Set Duration Window", "#FDF4FF", "#C026D3")
    draw_arrow(draw, (650, 810), (650, 860), color="#C026D3")

    draw_decision(650, 910, 220, 80, "Doctor / Patient Approves?")
    draw_arrow(draw, (650, 950), (650, 1020), color="#16A34A")
    draw.text((660, 980), "YES: 24h Window Active", fill="#16A34A", font=f_step)

    draw_arrow(draw, (760, 910), (840, 910), color="#DC2626")
    draw.line([(840, 910), (840, 1020)], fill="#DC2626", width=2)
    draw_box(740, 1020, 200, 60, "ACCESS LOCKED", "EMR History Protected", "#FEF2F2", "#DC2626")

    draw_box(530, 1020, 240, 60, "UNLOCKED EMR", "Vitals, History, & Reports", "#ECFDF5", "#059669")

    # Column 3
    draw.text((1050, 95), "3. CLINICAL PRESCRIPTION ENGINE", fill="#0F172A", font=get_font(16, bold=True), anchor="mm")
    draw_arrow(draw, (770, 1050), (930, 1050), color="#059669")
    draw.text((800, 1030), "Clinical Chart", fill="#059669", font=f_step)

    draw_box(930, 1020, 240, 60, "DOCTOR CONSULT", "Record Diagnosis & Advice", "#EFF6FF", "#1D4ED8")
    draw_arrow(draw, (1050, 1080), (1050, 1130), color="#1D4ED8")

    draw_box(930, 1130, 240, 60, "DIGITAL PRESCRIPTION", "Save Medicines & Instructions", "#EFF6FF", "#1D4ED8")
    draw_arrow(draw, (930, 1160), (250, 1160), color="#0284C7")
    draw.line([(250, 1160), (250, 540)], fill="#0284C7", width=2)
    draw.text((580, 1140), "Real-time Sync to Patient Timeline & Records", fill="#0369A1", font=f_step)

    # Column 4
    draw.text((1400, 95), "4. LAB & HOSPITAL INPATIENT", fill="#0F172A", font=get_font(16, bold=True), anchor="mm")
    draw_box(1300, 150, 200, 60, "LAB BATCH UPLOAD", "Upload Multi-Patient CSV", "#ECFDF5", "#059669")
    draw_arrow(draw, (1400, 210), (1400, 270), color="#059669")

    draw_box(1300, 270, 200, 60, "INGESTION ENGINE", "Parse & Map to Patient IDs", "#ECFDF5", "#059669")
    draw_arrow(draw, (1400, 330), (1400, 390), color="#059669")

    draw_box(1300, 390, 200, 60, "PUBLISH REPORTS", "Link to EMR Central Store", "#ECFDF5", "#059669")

    draw_box(1300, 520, 200, 60, "INPATIENT ADMISSION", "Assign Ward & Bed #", "#FEF3C7", "#D97706")
    draw_arrow(draw, (1400, 580), (1400, 640), color="#D97706")

    draw_box(1300, 640, 200, 60, "DAILY MONITORING", "Log BP, HR, SpO2 Vitals", "#FEF3C7", "#D97706")
    draw_arrow(draw, (1400, 700), (1400, 760), color="#D97706")

    draw_box(1300, 760, 200, 60, "DISCHARGE SUMMARY", "Release Bed & Archive File", "#FEF3C7", "#D97706")

    path = os.path.join(OUTPUT_DIR, "system_flow_diagram.png")
    img.save(path, "PNG", dpi=(300, 300))
    return path

# -------------------------------------------------------------
# 4. BUILD THE MASTER REPORTLAB PDF
# -------------------------------------------------------------
class NumberedCanvas(canvas.Canvas):
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
        if self._pageNumber == 1:
            return
        self.saveState()
        self.setFont("Helvetica-Bold", 8)
        self.setFillColor(colors.HexColor("#64748B"))
        self.drawString(54, 800, "DIGITAL HEALTH RECORD PLATFORM — ARCHITECTURE SPECIFICATION")
        self.setStrokeColor(colors.HexColor("#CBD5E1"))
        self.setLineWidth(0.5)
        self.line(54, 794, 558, 794)

        self.setFont("Helvetica", 8)
        self.drawString(54, 34, "Confidential — Healthcare Platform System Flow Diagrams")
        self.drawRightString(558, 34, f"Page {self._pageNumber} of {page_count}")
        self.line(54, 44, 558, 44)
        self.restoreState()

def create_pdf(dfd0_img, dfd1_img, sfd_img):
    doc = SimpleDocTemplate(
        PDF_PATH,
        pagesize=A4,
        leftMargin=40,
        rightMargin=40,
        topMargin=50,
        bottomMargin=50
    )

    styles = getSampleStyleSheet()
    
    title_style = ParagraphStyle(
        'CoverTitle',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=24,
        leading=30,
        textColor=colors.HexColor("#0F172A"),
        alignment=1,
    )
    subtitle_style = ParagraphStyle(
        'CoverSubTitle',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=13,
        leading=18,
        textColor=colors.HexColor("#0284C7"),
        alignment=1,
    )
    h1_style = ParagraphStyle(
        'Heading1_Custom',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=16,
        leading=20,
        textColor=colors.HexColor("#0F172A"),
        spaceBefore=12,
        spaceAfter=6,
    )
    h2_style = ParagraphStyle(
        'Heading2_Custom',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=12,
        leading=16,
        textColor=colors.HexColor("#1E40AF"),
        spaceBefore=10,
        spaceAfter=4,
    )
    body_style = ParagraphStyle(
        'Body_Custom',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=9,
        leading=13,
        textColor=colors.HexColor("#334155"),
        spaceAfter=5,
    )

    story = []

    # COVER PAGE
    story.append(Spacer(1, 35))
    story.append(Paragraph("DIGITAL HEALTH PLATFORM", title_style))
    story.append(Spacer(1, 8))
    story.append(Paragraph("LEVEL 0 DFD, LEVEL 1 DFD & SYSTEM FLOW DIAGRAM (SFD)", subtitle_style))
    story.append(Spacer(1, 18))

    cover_meta = [
        [Paragraph("<b>Platform Scope:</b>", body_style), Paragraph("Patient, Doctor, Diagnostic Lab & Hospital Inpatient Modules", body_style)],
        [Paragraph("<b>Security Standard:</b>", body_style), Paragraph("HIPAA / ABDM Compliant 24-Hour Clinical Consent Protocol", body_style)],
        [Paragraph("<b>Discovery Engine:</b>", body_style), Paragraph("Strict Email-Based Verification (Zero Public Directory Leak)", body_style)],
        [Paragraph("<b>Backend Stack:</b>", body_style), Paragraph("Django REST Framework, PostgreSQL / SQLite, JWT + SMTP OTP", body_style)],
        [Paragraph("<b>Frontend Stack:</b>", body_style), Paragraph("Flutter Web & Mobile Reactive State (Riverpod)", body_style)],
        [Paragraph("<b>Document Type:</b>", body_style), Paragraph("System Engineering Diagrams & Functional Specifications", body_style)],
    ]
    meta_table = Table(cover_meta, colWidths=[150, 360])
    meta_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor("#F8FAFC")),
        ('PADDING', (0,0), (-1,-1), 7),
        ('BOX', (0,0), (-1,-1), 1, colors.HexColor("#CBD5E1")),
        ('INNERGRID', (0,0), (-1,-1), 0.5, colors.HexColor("#E2E8F0")),
    ]))
    story.append(meta_table)
    story.append(Spacer(1, 25))

    story.append(Paragraph("Executive Summary & Core Architectural Highlights", h2_style))
    story.append(Paragraph(
        "This engineering report provides official visual diagrams and architectural models for the Digital Health Platform. "
        "The system decouples clinical roles while ensuring that sensitive medical history is accessible only with active, patient-consented time-bounded windows. "
        "Zero arbitrary directory listing prevents mass harvesting of doctor or patient accounts, upholding patient rights and HIPAA standards.",
        body_style
    ))
    story.append(PageBreak())

    # SECTION 1: LEVEL 0 DFD
    story.append(Paragraph("1. Level 0 Data Flow Diagram (Context Level)", h1_style))
    story.append(Paragraph(
        "The Level 0 Context Diagram establishes the global boundary of the Digital Health Platform. The central system (Process 0.0) interacts with four primary external entities (Patient, Doctor, Diagnostic Lab, Hospital Care) and an external SMTP notification service.",
        body_style
    ))
    story.append(Spacer(1, 6))
    story.append(RLImage(dfd0_img, width=515, height=354))
    story.append(Spacer(1, 10))

    dfd0_data = [
        ["External Entity", "Input Data Flows into System", "Output Data Flows to Entity"],
        ["Patient", "Credentials, OTP, Doctor Email Query, Consent Grant/Revocation", "Auth JWT, Verified Doctor Details, Prescriptions, Lab Reports"],
        ["Doctor", "Doctor Credentials, Patient Email Query, Diagnosis, Meds, Consent Action", "Auth JWT, Unlocked Clinical EMR Chart (24h Window)"],
        ["Diagnostic Lab", "Lab Tech Auth, Single Test Orders, Batch CSV Uploads", "Batch Parsing Status, Published EMR Record Confirmation"],
        ["Hospital Care", "Admin Auth, Inpatient Admission, Ward/Bed Assignment, Daily Vitals", "Real-Time Bed Occupancy Dashboard, Discharge Summary"]
    ]
    t_dfd0 = Table(dfd0_data, colWidths=[105, 205, 205])
    t_dfd0.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), colors.HexColor("#0284C7")),
        ('TEXTCOLOR', (0,0), (-1,0), colors.white),
        ('FONTNAME', (0,0), (-1,0), 'Helvetica-Bold'),
        ('FONTSIZE', (0,0), (-1,-1), 8),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, colors.HexColor("#F8FAFC")]),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor("#CBD5E1")),
        ('PADDING', (0,0), (-1,-1), 5),
    ]))
    story.append(t_dfd0)
    story.append(PageBreak())

    # SECTION 2: LEVEL 1 DFD
    story.append(Paragraph("2. Level 1 Data Flow Diagram (Subsystem Decomposition)", h1_style))
    story.append(Paragraph(
        "The Level 1 DFD decomposes the central process into 6 specialized subprocesses and 5 centralized persistent data stores (D1 to D5). Strict email search rules guarantee that no entity can enumerate public clinical records without authorization.",
        body_style
    ))
    story.append(Spacer(1, 6))
    story.append(RLImage(dfd1_img, width=515, height=386))
    story.append(Spacer(1, 10))

    dfd1_data = [
        ["Process ID", "Subsystem Name", "Primary Data Inputs", "Target Data Store"],
        ["1.0", "Authentication & Identity", "Email, OTP, Role Profile Payload", "D1: Users & Role Profiles"],
        ["2.0", "Directory & Lookup", "Target Email Query (Doctor / Patient)", "D1: Read-Only Verification"],
        ["3.0", "Consent Protocol", "Requested Duration (24h/7d), Doctor ID", "D2: Consents & Access Timers"],
        ["4.0", "Clinical EMR & Rx", "Diagnosis, Drug Name, Dosage, Instructions", "D3: Prescriptions & Items"],
        ["5.0", "Diagnostic Testing", "Lab Order Form, Bulk CSV File", "D4: Diagnostic Lab Reports"],
        ["6.0", "Hospital Care", "Admission Code, Ward/Bed #, Daily Vitals", "D5: Inpatient Beds & Vitals"]
    ]
    t_dfd1 = Table(dfd1_data, colWidths=[65, 130, 180, 140])
    t_dfd1.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), colors.HexColor("#1E293B")),
        ('TEXTCOLOR', (0,0), (-1,0), colors.white),
        ('FONTNAME', (0,0), (-1,0), 'Helvetica-Bold'),
        ('FONTSIZE', (0,0), (-1,-1), 8),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, colors.HexColor("#F8FAFC")]),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor("#CBD5E1")),
        ('PADDING', (0,0), (-1,-1), 5),
    ]))
    story.append(t_dfd1)
    story.append(PageBreak())

    # SECTION 3: SYSTEM FLOW DIAGRAM
    story.append(Paragraph("3. System Flow Diagram (SFD) — Operational & Decision Logic", h1_style))
    story.append(Paragraph(
        "The System Flow Diagram details step-by-step branching logic, decision diamonds, database validation, and rollback operations across Authentication, Discovery, Consent Locking, and Prescription Delivery.",
        body_style
    ))
    story.append(Spacer(1, 6))
    story.append(RLImage(sfd_img, width=515, height=418))
    story.append(Spacer(1, 10))

    sfd_notes = [
        ["Decision Check", "Evaluation Rule", "Success Path", "Failure / Rollback Path"],
        ["Valid 6-Digit OTP?", "Match against EmailOTP within 5 mins", "Issue JWT & Redirect to Role Portal", "Increment attempts; lock on 3 fails"],
        ["Record Exists in DB?", "Query User by email__iexact", "Render Verified Profile Badge", "Return 0 results; display error prompt"],
        ["Consent Approved?", "Check status='approved' & valid_until", "Unlock 24h Clinical History Chart", "Enforce Consent Required Lock Screen"],
        ["Valid CSV Ingestion?", "Validate email, headers, test values", "Store batch & publish to EMR", "Reject batch; display error report"]
    ]
    t_sfd = Table(sfd_notes, colWidths=[100, 155, 130, 130])
    t_sfd.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), colors.HexColor("#047857")),
        ('TEXTCOLOR', (0,0), (-1,0), colors.white),
        ('FONTNAME', (0,0), (-1,0), 'Helvetica-Bold'),
        ('FONTSIZE', (0,0), (-1,-1), 8),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, colors.HexColor("#F8FAFC")]),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor("#CBD5E1")),
        ('PADDING', (0,0), (-1,-1), 5),
    ]))
    story.append(t_sfd)

    doc.build(story, canvasmaker=NumberedCanvas)
    print("PDF Successfully Generated at:", PDF_PATH)

if __name__ == "__main__":
    dfd0 = generate_dfd_level_0()
    dfd1 = generate_dfd_level_1()
    sfd = generate_sfd()
    create_pdf(dfd0, dfd1, sfd)
