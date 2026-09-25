import os
from reportlab.lib import colors
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, HRFlowable
)

def generate_lab_pdf(output_path):
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    doc = SimpleDocTemplate(
        output_path,
        pagesize=letter,
        rightMargin=26,
        leftMargin=26,
        topMargin=22,
        bottomMargin=20
    )

    styles = getSampleStyleSheet()

    # Custom styles
    title_style = ParagraphStyle(
        'LabTitle',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=15,
        leading=18,
        textColor=colors.HexColor('#0F172A'),
        alignment=0
    )
    subtitle_style = ParagraphStyle(
        'LabSubtitle',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=8,
        leading=10,
        textColor=colors.HexColor('#64748B'),
        alignment=0
    )
    badge_style = ParagraphStyle(
        'LabBadge',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=7.5,
        leading=9.5,
        textColor=colors.HexColor('#0D9488'),
        alignment=2
    )
    meta_label = ParagraphStyle(
        'MetaLabel',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=7.5,
        leading=9.5,
        textColor=colors.HexColor('#475569')
    )
    meta_val = ParagraphStyle(
        'MetaVal',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=7.5,
        leading=9.5,
        textColor=colors.HexColor('#0F172A')
    )
    sec_title = ParagraphStyle(
        'SecTitle',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=8,
        leading=10,
        textColor=colors.HexColor('#0369A1')
    )
    th_style = ParagraphStyle(
        'THStyle',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=7.5,
        leading=9.5,
        textColor=colors.HexColor('#1E293B')
    )
    cell_param = ParagraphStyle(
        'CellParam',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=7.5,
        leading=9,
        textColor=colors.HexColor('#1E293B')
    )
    cell_val_normal = ParagraphStyle(
        'CellValNormal',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=7.5,
        leading=9,
        textColor=colors.HexColor('#0F172A')
    )
    cell_val_high = ParagraphStyle(
        'CellValHigh',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=7.5,
        leading=9,
        textColor=colors.HexColor('#DC2626')
    )
    cell_ref = ParagraphStyle(
        'CellRef',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=7,
        leading=8.5,
        textColor=colors.HexColor('#64748B')
    )
    flag_normal = ParagraphStyle(
        'FlagNormal',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=7,
        leading=8.5,
        textColor=colors.HexColor('#16A34A'),
        alignment=1
    )
    flag_high = ParagraphStyle(
        'FlagHigh',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=7,
        leading=8.5,
        textColor=colors.HexColor('#DC2626'),
        alignment=1
    )
    flag_low = ParagraphStyle(
        'FlagLow',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=7,
        leading=8.5,
        textColor=colors.HexColor('#D97706'),
        alignment=1
    )

    story = []

    # 1. Header Banner
    header_data = [
        [
            Paragraph("METRO CARE DIAGNOSTICS & RESEARCH CENTER", title_style),
            Paragraph("<b>ACCORD # NABL-2026-MC</b><br/>ISO 15189:2022 Certified", badge_style)
        ],
        [
            Paragraph("Plot 42, Health City Avenue, Medical District • Tel: +91 22 2847 9000 • contact@metrocarelab.com", subtitle_style),
            Paragraph("Verified Digital Laboratory EHR", badge_style)
        ]
    ]
    header_table = Table(header_data, colWidths=[400, 160])
    header_table.setStyle(TableStyle([
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
        ('BOTTOMPADDING', (0,0), (-1,-1), 1),
        ('TOPPADDING', (0,0), (-1,-1), 0),
        ('LEFTPADDING', (0,0), (-1,-1), 0),
        ('RIGHTPADDING', (0,0), (-1,-1), 0),
    ]))
    story.append(header_table)
    story.append(HRFlowable(width="100%", thickness=1.5, color=colors.HexColor('#0D9488'), spaceBefore=3, spaceAfter=5))

    # 2. Patient Demographics & Order Metadata Box
    meta_data = [
        [
            Paragraph("<b>Patient Name:</b>", meta_label),
            Paragraph("Sample Record", meta_val),
            Paragraph("<b>Patient ID:</b>", meta_label),
            Paragraph("PAT-2026-99999", meta_val),
        ],
        [
            Paragraph("<b>Age / Gender:</b>", meta_label),
            Paragraph("34 Yrs / Male", meta_val),
            Paragraph("<b>Sample Collected:</b>", meta_label),
            Paragraph("25-Sep-2026 08:30 AM", meta_val),
        ],
        [
            Paragraph("<b>Referred By:</b>", meta_label),
            Paragraph("Dr. Siddharth Rao (MD, FACP)", meta_val),
            Paragraph("<b>Report Released:</b>", meta_label),
            Paragraph("25-Sep-2026 02:45 PM", meta_val),
        ],
        [
            Paragraph("<b>Sample Type:</b>", meta_label),
            Paragraph("EDTA Whole Blood & Plasma", meta_val),
            Paragraph("<b>Lab Order Barcode:</b>", meta_label),
            Paragraph("ORD-2026-78419", meta_val),
        ],
    ]
    meta_table = Table(meta_data, colWidths=[90, 190, 95, 185])
    meta_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#F8FAFC')),
        ('BOX', (0,0), (-1,-1), 0.75, colors.HexColor('#E2E8F0')),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('TOPPADDING', (0,0), (-1,-1), 2.5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 2.5),
        ('LEFTPADDING', (0,0), (-1,-1), 6),
        ('RIGHTPADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(meta_table)
    story.append(Spacer(1, 5))

    # Test parameter rows
    all_tests = [
        # (Category, Param, Value, Unit, Range, Status)
        ("HEMATOLOGY (COMPLETE BLOOD COUNT)", "Hemoglobin (Hb)", "11.2", "g/dL", "13.0 - 17.0", "Low"),
        ("HEMATOLOGY (COMPLETE BLOOD COUNT)", "Total Leukocyte Count (WBC)", "7,400", "/uL", "4,000 - 11,000", "Normal"),
        ("HEMATOLOGY (COMPLETE BLOOD COUNT)", "Platelet Count", "260,000", "/uL", "150,000 - 450,000", "Normal"),
        ("HEMATOLOGY (COMPLETE BLOOD COUNT)", "RBC Count", "4.10", "mil/uL", "4.50 - 5.90", "Low"),
        ("HEMATOLOGY (COMPLETE BLOOD COUNT)", "Packed Cell Volume (PCV)", "35.4", "%", "40.0 - 50.0", "Low"),
        ("HEMATOLOGY (COMPLETE BLOOD COUNT)", "Mean Corpuscular Volume (MCV)", "78.0", "fL", "80.0 - 100.0", "Low"),

        ("BIOCHEMISTRY & METABOLIC PANEL", "Fasting Blood Glucose", "108", "mg/dL", "70 - 100", "High"),
        ("BIOCHEMISTRY & METABOLIC PANEL", "HbA1c (Glycated Hemoglobin)", "6.8", "%", "4.0 - 5.6", "High"),
        ("BIOCHEMISTRY & METABOLIC PANEL", "Estimated Avg Glucose (eAG)", "148", "mg/dL", "90 - 120", "High"),

        ("LIPID PROFILE", "Total Cholesterol", "225", "mg/dL", "125 - 200", "High"),
        ("LIPID PROFILE", "HDL Cholesterol (Good)", "44", "mg/dL", "40 - 60", "Normal"),
        ("LIPID PROFILE", "LDL Cholesterol (Bad)", "142", "mg/dL", "< 100", "High"),
        ("LIPID PROFILE", "Serum Triglycerides", "195", "mg/dL", "< 150", "High"),

        ("RENAL & ELECTROLYTES", "Serum Creatinine", "1.05", "mg/dL", "0.70 - 1.30", "Normal"),
        ("RENAL & ELECTROLYTES", "Blood Urea Nitrogen (BUN)", "16.0", "mg/dL", "7.0 - 20.0", "Normal"),
        ("RENAL & ELECTROLYTES", "Serum Uric Acid", "5.8", "mg/dL", "3.5 - 7.2", "Normal"),

        ("HEPATIC & ENDOCRINE PANEL", "SGPT / ALT", "32", "U/L", "7 - 56", "Normal"),
        ("HEPATIC & ENDOCRINE PANEL", "SGOT / AST", "28", "U/L", "10 - 40", "Normal"),
        ("HEPATIC & ENDOCRINE PANEL", "TSH (Ultrasensitive)", "2.45", "uIU/mL", "0.40 - 4.50", "Normal"),

        ("IMMUNOLOGY & VITAMINS", "Vitamin D (25-Hydroxy)", "18.2", "ng/mL", "30.0 - 100.0", "Low"),
        ("IMMUNOLOGY & VITAMINS", "Vitamin B12 (Cyanocobalamin)", "485", "pg/mL", "200 - 900", "Normal"),
    ]

    # Build the main test results table
    table_rows = [
        [
            Paragraph("TEST PARAMETER", th_style),
            Paragraph("OBSERVED VALUE", th_style),
            Paragraph("UNIT", th_style),
            Paragraph("REFERENCE INTERVAL", th_style),
            Paragraph("FLAG", th_style),
        ]
    ]

    current_cat = None
    row_idx = 1
    category_row_indices = []

    for item in all_tests:
        cat, param, val, unit, ref_range, flag = item
        if cat != current_cat:
            current_cat = cat
            table_rows.append([
                Paragraph(f"<b>{current_cat}</b>", sec_title),
                Paragraph("", th_style),
                Paragraph("", th_style),
                Paragraph("", th_style),
                Paragraph("", th_style),
            ])
            category_row_indices.append(row_idx)
            row_idx += 1

        val_style = cell_val_high if flag in ("High", "Low") else cell_val_normal
        flag_p = flag_high if flag == "High" else (flag_low if flag == "Low" else flag_normal)

        table_rows.append([
            Paragraph(param, cell_param),
            Paragraph(f"<b>{val}</b>", val_style),
            Paragraph(unit, cell_ref),
            Paragraph(ref_range, cell_ref),
            Paragraph(f"<b>[{flag.upper()}]</b>", flag_p),
        ])
        row_idx += 1

    results_table = Table(table_rows, colWidths=[210, 100, 70, 115, 65])
    ts = [
        ('BACKGROUND', (0,0), (-1,0), colors.HexColor('#F1F5F9')),
        ('BOX', (0,0), (-1,-1), 0.75, colors.HexColor('#CBD5E1')),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor('#E2E8F0')),
        ('TOPPADDING', (0,0), (-1,-1), 1.5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 1.5),
        ('LEFTPADDING', (0,0), (-1,-1), 5),
        ('RIGHTPADDING', (0,0), (-1,-1), 5),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
    ]
    for c_idx in category_row_indices:
        ts.extend([
            ('SPAN', (0, c_idx), (-1, c_idx)),
            ('BACKGROUND', (0, c_idx), (-1, c_idx), colors.HexColor('#E0F2FE')),
            ('TOPPADDING', (0, c_idx), (-1, c_idx), 2),
            ('BOTTOMPADDING', (0, c_idx), (-1, c_idx), 2),
        ])
    results_table.setStyle(TableStyle(ts))
    story.append(results_table)

    story.append(Spacer(1, 5))

    # Clinical Summary & Doctor Authentication
    notes_p = Paragraph(
        "<b>CLINICAL INTERPRETATION & NOTES:</b> "
        "• <b>Glycemic:</b> Fasting blood glucose (108 mg/dL) & HbA1c (6.8%) indicate impaired fasting glycemia/prediabetic state. "
        "• <b>Lipids:</b> Mixed dyslipidemia (elevated Total Chol 225 mg/dL, LDL 142 mg/dL, Triglycerides 195 mg/dL). "
        "• <b>Hematology:</b> Hemoglobin 11.2 g/dL, PCV 35.4%, MCV 78 fL suggest mild microcytosis. "
        "• <b>Vitamins:</b> Vitamin D (25-OH) 18.2 ng/mL reflects deficiency. Supplementation & dietary follow-up advised.",
        ParagraphStyle('Notes', parent=styles['Normal'], fontSize=6.8, leading=8.8, textColor=colors.HexColor('#334155'))
    )
    notes_table = Table([[notes_p]], colWidths=[560])
    notes_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#F8FAFC')),
        ('BOX', (0,0), (-1,-1), 0.75, colors.HexColor('#CBD5E1')),
        ('LEFTPADDING', (0,0), (-1,-1), 6),
        ('RIGHTPADDING', (0,0), (-1,-1), 6),
        ('TOPPADDING', (0,0), (-1,-1), 3),
        ('BOTTOMPADDING', (0,0), (-1,-1), 3),
    ]))
    story.append(notes_table)

    story.append(Spacer(1, 6))

    # Signatures
    sign_data = [
        [
            Paragraph("<b>Medical Technologist</b><br/>Kavita Sharma, B.Sc MLT", subtitle_style),
            Paragraph("<b>Verified By Biochemist</b><br/>Dr. Siddharth Rao, MD", subtitle_style),
            Paragraph("<b>Chief Pathologist</b><br/>Dr. Priya Shah, MD (Path)", ParagraphStyle('SignRight', parent=subtitle_style, alignment=2)),
        ],
        [
            Paragraph("Electronically Verified - No Physical Signature Required", ParagraphStyle('Discl', parent=subtitle_style, fontSize=6, textColor=colors.HexColor('#94A3B8'))),
            Paragraph("", subtitle_style),
            Paragraph("End of Complete Diagnostic Report", ParagraphStyle('EndRep', parent=subtitle_style, alignment=2, fontSize=6.5, fontName='Helvetica-Bold')),
        ]
    ]
    sign_table = Table(sign_data, colWidths=[186, 186, 188])
    sign_table.setStyle(TableStyle([
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
        ('LINEABOVE', (0,0), (-1,0), 0.75, colors.HexColor('#94A3B8')),
        ('TOPPADDING', (0,0), (-1,-1), 2),
        ('BOTTOMPADDING', (0,0), (-1,-1), 1),
        ('LEFTPADDING', (0,0), (-1,-1), 0),
        ('RIGHTPADDING', (0,0), (-1,-1), 0),
    ]))
    story.append(sign_table)

    doc.build(story)
    print(f"Successfully generated 1-page lab report PDF: {output_path}")

if __name__ == '__main__':
    out = os.path.abspath(r'd:\Health\test_samples\comprehensive_clinical_lab_report.pdf')
    generate_lab_pdf(out)
