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
  });

  factory LabReport.fromJson(Map<String, dynamic> json) {
    return LabReport(
      reportId: json['report_id'] ?? '',
      patientId: json['patient_id'] ?? '',
      reportName: json['report_name'] ?? '',
      reportDate: json['report_date'] ?? '',
      facilityName: json['facility_name'],
      doctorName: json['doctor_name'],
      testParameters: json['test_parameters'] != null
          ? (json['test_parameters'] as List)
              .map((e) => TestParameter.fromJson(e))
              .toList()
          : [],
      summary: json['summary'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'report_id': reportId,
      'patient_id': patientId,
      'report_name': reportName,
      'report_date': reportDate,
      'facility_name': facilityName,
      'doctor_name': doctorName,
      'test_parameters': testParameters.map((e) => e.toJson()).toList(),
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
    return TestParameter(
      parameterName: json['parameter_name'] ?? '',
      value: json['value'] ?? '',
      unit: json['unit'],
      referenceRange: json['reference_range'],
      flag: json['flag'] ?? 'normal',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'parameter_name': parameterName,
      'value': value,
      'unit': unit,
      'reference_range': referenceRange,
      'flag': flag,
    };
  }
}
