class DocumentData {
  const DocumentData({
    this.name,
    this.dob,
    this.gender,
    this.nameConfidence = 0.0,
    this.dobConfidence = 0.0,
    this.genderConfidence = 0.0,
  });

  final String? name;
  final String? dob;
  final String? gender;
  final double nameConfidence;
  final double dobConfidence;
  final double genderConfidence;
}
