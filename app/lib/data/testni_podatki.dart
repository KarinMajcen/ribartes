import 'package:cloud_firestore/cloud_firestore.dart';

/// TESTNI PODATKI za razvoj in zagovor.
/// Cene, pravila in gostilne so izmišljeni zgledi, ne uradni podatki.
///
/// Vnesejo se samo, če je zbirka "revirji" prazna, zato jih lahko
/// v konzoli Firebase poljubno urejaš – ob naslednjem zagonu se ne prepišejo.
class TestniPodatki {
  /// Vsako zbirko napolni posebej, če je prazna (tako se nove zbirke,
  /// npr. gostilne, dodajo tudi v bazo, ki že ima revirje).
  static Future<void> vnesiCeJePrazno() async {
    await _vnesiZbirko('revirji', _revirji);
    await _vnesiZbirko('vrste_rib', _vrsteRib);
    await _vnesiZbirko('gostilne', _gostilne);
  }

  static Future<void> _vnesiZbirko(
      String zbirka, List<Map<String, Object>> podatki) async {
    final db = FirebaseFirestore.instance;
    final obstaja = await db.collection(zbirka).limit(1).get();
    if (obstaja.docs.isNotEmpty) return;

    final batch = db.batch();
    for (final p in podatki) {
      final dokument = Map<String, dynamic>.from(p)..remove('id');
      batch.set(db.collection(zbirka).doc(p['id'] as String), dokument);
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

  static final List<Map<String, Object>> _gostilne = [
    {
      'id': 'pri-soci',
      'ime': 'Gostilna Pri Soči',
      'kraj': 'Tolmin',
      'reka': 'Soča',
      'revirId': 'soca-tolmin',
      'opis': 'Družinska gostilna z vrtom tik ob reki.',
      'ponudba': 'Postrv na žaru s krompirjem in blitvo',
      'cenaPriprave': 12,
      'odpreOb': 11,
      'zapreOb': 21,
    },
    {
      'id': 'bohinjski-kot',
      'ime': 'Gostišče Bohinjski kot',
      'kraj': 'Bohinj',
      'reka': 'Sava Bohinjka',
      'revirId': 'sava-bohinjka',
      'opis': 'Planinsko gostišče s pogledom na jezero.',
      'ponudba': 'Lipan v masleni omaki s polento',
      'cenaPriprave': 14,
      'odpreOb': 12,
      'zapreOb': 20,
    },
    {
      'id': 'ob-krki',
      'ime': 'Gostilna Ob Krki',
      'kraj': 'Žužemberk',
      'reka': 'Krka',
      'revirId': 'krka-zuzemberk',
      'opis': 'Gostilna pod gradom z domačo kuhinjo.',
      'ponudba': 'Ocvrta riba s krompirjevo solato',
      'cenaPriprave': 11,
      'odpreOb': 10,
      'zapreOb': 22,
    },
    {
      'id': 'domacija-kolpa',
      'ime': 'Domačija Kolpa',
      'kraj': 'Vinica',
      'reka': 'Kolpa',
      'revirId': 'kolpa-vinica',
      'opis': 'Turistična kmetija ob kopališču na Kolpi.',
      'ponudba': 'Riba v pečici z zelenjavo',
      'cenaPriprave': 10,
      'odpreOb': 11,
      'zapreOb': 21,
    },
  ];
}
