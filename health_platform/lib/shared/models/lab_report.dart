class LabReport {
  final String reportId;
  final String patientId;
  final String reportName;
  final String reportDate;
  final String? facilityName;
  final String? doctorName;
  final List<TestParameter> testParameters;
  final String? summary;
  final String? status;
  final String? fileUrl;

  LabReport({
    required this.reportId,
    required this.patientId,
    required this.reportName,
    required this.reportDate,
    this.facilityName,
    this.doctorName,
    required this.testParameters,
    this.summary,
    this.status,
    this.fileUrl,
  });

  factory LabReport.fromJson(Map<String, dynamic> json) {
    final rawParams = json['test_parameters'] ?? json['parameters'];
    return LabReport(
      reportId: json['report_id']?.toString() ?? json['id']?.toString() ?? '',
      patientId: json['patient_id']?.toString() ?? json['patient']?.toString() ?? '',
      reportName: json['report_name'] ?? '',
      reportDate: json['report_date']?.toString() ?? '',
      facilityName: json['facility_name'],
      doctorName: json['doctor_name'],
      testParameters: rawParams != null
          ? (rawParams as List)
              .map((e) => TestParameter.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      summary: json['summary'],
      status: json['status'],
      fileUrl: json['file_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final paramsList = testParameters.map((e) => e.toJson()).toList();
    return {
      'report_id': reportId,
      'patient_id': patientId,
      'report_name': reportName,
      'report_date': reportDate,
      'facility_name': facilityName,
      'doctor_name': doctorName,
      'parameters': paramsList,
      'test_parameters': paramsList,
      'summary': summary,
      'status': status,
    };
  }
}

class TestParameter {
  final String parameterName;
  final String value;
  final String? unit;
  final String? referenceRange;
  final String flag;

  TestParameter({
    required this.parameterName,
    required this.value,
    this.unit,
    this.referenceRange,
    required this.flag,
  });

  factory TestParameter.fromJson(Map<String, dynamic> json) {
    String flag = json['flag']?.toString() ?? '';
    if (flag.isEmpty) {
      if (json['is_abnormal'] == true) {
        flag = 'abnormal';
      } else {
        flag = 'normal';
      }
    }
    return TestParameter(
      parameterName: json['parameter_name'] ?? '',
      value: json['value']?.toString() ?? '',
      unit: json['unit'],
      referenceRange: json['reference_range'],
      flag: flag,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'parameter_name': parameterName,
      'value': value,
      'unit': unit,
      'reference_range': referenceRange,
      'flag': flag,
      'is_abnormal': flag.toLowerCase() == 'abnormal' || flag.toLowerCase() == 'critical',
    };
  }
}
