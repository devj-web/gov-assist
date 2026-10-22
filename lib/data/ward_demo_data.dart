import '../models/ward_models.dart';

final demoCitizens = <WardCitizen>[
  WardCitizen(name: 'Anitha S.', id: 'CIT-1001', phone: '•••• •• 2418', village: 'Ward 04', consent: true),
  WardCitizen(name: 'Rajan K.', id: 'CIT-1002', phone: '•••• •• 8062', village: 'Ward 04'),
  WardCitizen(name: 'Meera P.', id: 'CIT-1003', phone: '•••• •• 1195', village: 'Ward 04', consent: true),
  WardCitizen(name: 'Suresh B.', id: 'CIT-1004', phone: '•••• •• 4730', village: 'Ward 04'),
  WardCitizen(name: 'Latha R.', id: 'CIT-1005', phone: '•••• •• 6621', village: 'Ward 04', consent: true),
];

final demoCases = <AssistanceCase>[
  AssistanceCase(citizen: 'Anitha S.', scheme: 'Housing assistance', status: 'Documents pending', missingDocuments: 'Income certificate', followUp: '22 Oct 2026'),
  AssistanceCase(citizen: 'Rajan K.', scheme: 'Old age pension', status: 'Needs review', missingDocuments: 'Age proof, bank passbook', followUp: '24 Oct 2026'),
  AssistanceCase(citizen: 'Meera P.', scheme: 'Education scholarship', status: 'In progress', missingDocuments: 'None listed', followUp: '28 Oct 2026'),
  AssistanceCase(citizen: 'Suresh B.', scheme: 'Farmer support', status: 'New request', missingDocuments: 'Land record', followUp: '30 Oct 2026'),
];
