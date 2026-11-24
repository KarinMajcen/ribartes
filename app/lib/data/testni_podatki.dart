import 'package:cloud_firestore/cloud_firestore.dart';

/// TESTNI PODATKI za razvoj in zagovor.
/// Cene in pravila so izmišljeni zgledi, ne uradni podatki ribiških družin.
///
/// Vnesejo se samo, če je zbirka "revirji" prazna, zato jih lahko
/// v konzoli Firebase poljubno urejaš – ob naslednjem zagonu se ne prepišejo.
class TestniPodatki {
  static Future<void> vnesiCeJePrazno() async {
    final db = FirebaseFirestore.instance;
    final obstaja = await db.collection('revirji').limit(1).get();
    if (obstaja.docs.isNotEmpty) return;

    final batch = db.batch();

    for (final r in _revirji) {
      final podatki = Map<String, dynamic>.from(r)..remove('id');
      batch.set(db.collection('revirji').doc(r['id'] as String), podatki);
    }
    for (final v in _vrsteRib) {
      final podatki = Map<String, dynamic>.from(v)..remove('id');
      batch.set(db.collection('vrste_rib').doc(v['id'] as String), podatki);
    }

    await batch.commit();
  }

  static final List<Map<String, Object>> _revirji = [
    {
      'id': 'soca-tolmin',
      'ime': 'Soča – Tolmin',
      'reka': 'Soča',
      'ribiskaDruzina': 'RD Tolmin',
      'opis': 'Smaragdna alpska reka z bistro vodo, znana po soški postrvi.',
      'vrste': ['soška postrv', 'šarenka', 'lipan'],
      'pravila': [
        'Dovoljen samo muharjenje.',
        'Uporaba trnkov brez zalustja.',
        'Najmanjša lovna mera soške postrvi: 50 cm.',
        'Dnevni ulov največ 1 riba.',
      ],
      'cene': {'dnevna': 65, 'tedenska': 320, 'letna': 850},
    },
    {
      'id': 'sava-bohinjka',
      'ime': 'Sava Bohinjka – Bohinj',
      'reka': 'Sava Bohinjka',
      'ribiskaDruzina': 'RD Bohinj',
      'opis': 'Hladna reka iz Bohinjskega jezera, odlična za lipana.',
      'vrste': ['lipan', 'potočna postrv', 'šarenka'],
      'pravila': [
        'Dovoljeno muharjenje in lov s šibico.',
        'Najmanjša lovna mera lipana: 35 cm.',
        'Dnevni ulov največ 2 ribi.',
      ],
      'cene': {'dnevna': 55, 'tedenska': 260, 'letna': 700},
    },
    {
      'id': 'krka-zuzemberk',
      'ime': 'Krka – Žužemberk',
      'reka': 'Krka',
      'ribiskaDruzina': 'RD Novo mesto',
      'opis': 'Mirna kraška reka s slapišči in bogato ribjo populacijo.',
      'vrste': ['potočna postrv', 'lipan', 'klen', 'mrena', 'ščuka'],
      'pravila': [
        'Lov z umetnimi vabami.',
        'Najmanjša lovna mera ščuke: 60 cm.',
        'Dnevni ulov največ 3 ribe.',
      ],
      'cene': {'dnevna': 35, 'tedenska': 150, 'letna': 420},
    },
    {
      'id': 'kolpa-vinica',
      'ime': 'Kolpa – Vinica',
      'reka': 'Kolpa',
      'ribiskaDruzina': 'RD Črnomelj',
      'opis': 'Topla mejna reka, primerna za lov krapovcev in roparic.',
      'vrste': ['klen', 'mrena', 'podust', 'som', 'ščuka', 'sulec'],
      'pravila': [
        'Sulec: samo ujemi in spusti.',
        'Najmanjša lovna mera soma: 70 cm.',
        'Dnevni ulov največ 3 ribe.',
      ],
      'cene': {'dnevna': 25, 'tedenska': 110, 'letna': 300},
    },
    {
      'id': 'ljubljanica-vrhnika',
      'ime': 'Ljubljanica – Vrhnika',
      'reka': 'Ljubljanica',
      'ribiskaDruzina': 'RD Vrhnika',
      'opis': 'Počasna reka sedmerih imen, dom ščuke, krapa in linja.',
      'vrste': ['ščuka', 'krap', 'linj', 'platnica', 'smuč'],
      'pravila': [
        'Dovoljen lov s plovcem in z umetnimi vabami.',
        'Najmanjša lovna mera krapa: 40 cm.',
        'Dnevni ulov največ 3 ribe.',
      ],
      'cene': {'dnevna': 20, 'tedenska': 90, 'letna': 250},
    },
  ];

  static final List<Map<String, Object>> _vrsteRib = [
    {'id': 'soska-postrv', 'ime': 'soška postrv', 'latinsko': 'Salmo marmoratus'},
    {'id': 'potocna-postrv', 'ime': 'potočna postrv', 'latinsko': 'Salmo trutta fario'},
    {'id': 'sarenka', 'ime': 'šarenka', 'latinsko': 'Oncorhynchus mykiss'},
    {'id': 'lipan', 'ime': 'lipan', 'latinsko': 'Thymallus thymallus'},
    {'id': 'sulec', 'ime': 'sulec', 'latinsko': 'Hucho hucho'},
    {'id': 'jezerska-zlatovcica', 'ime': 'jezerska zlatovčica', 'latinsko': 'Salvelinus umbla'},
    {'id': 'klen', 'ime': 'klen', 'latinsko': 'Squalius cephalus'},
    {'id': 'mrena', 'ime': 'mrena', 'latinsko': 'Barbus barbus'},
    {'id': 'podust', 'ime': 'podust', 'latinsko': 'Chondrostoma nasus'},
    {'id': 'platnica', 'ime': 'platnica', 'latinsko': 'Rutilus virgo'},
    {'id': 'scuka', 'ime': 'ščuka', 'latinsko': 'Esox lucius'},
    {'id': 'smuc', 'ime': 'smuč', 'latinsko': 'Sander lucioperca'},
    {'id': 'som', 'ime': 'som', 'latinsko': 'Silurus glanis'},
    {'id': 'krap', 'ime': 'krap', 'latinsko': 'Cyprinus carpio'},
    {'id': 'linj', 'ime': 'linj', 'latinsko': 'Tinca tinca'},
  ];
}
