class WardCitizen {
  final String name;
  final String id;
  final String phone;
  final String village;
  bool consent;
  WardCitizen({required this.name, required this.id, required this.phone, required this.village, this.consent = false});
}

class AssistanceCase {
  final String citizen;
  final String scheme;
  final String status;
  final String missingDocuments;
  final String followUp;
  AssistanceCase({required this.citizen, required this.scheme, required this.status, required this.missingDocuments, required this.followUp});
}
