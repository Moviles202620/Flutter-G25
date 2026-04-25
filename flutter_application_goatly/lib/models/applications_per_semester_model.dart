class ApplicationsPerSemesterModel {
  final int semester;
  final int totalApplications;
  final int uniqueStudents;
  final double avgApplicationsPerStudent;

  const ApplicationsPerSemesterModel({
    required this.semester,
    required this.totalApplications,
    required this.uniqueStudents,
    required this.avgApplicationsPerStudent,
  });

  factory ApplicationsPerSemesterModel.fromJson(Map<String, dynamic> json) =>
      ApplicationsPerSemesterModel(
        semester: json['semester'] as int,
        totalApplications: json['total_applications'] as int,
        uniqueStudents: json['unique_students'] as int,
        avgApplicationsPerStudent:
            (json['avg_applications_per_student'] as num).toDouble(),
      );
}
