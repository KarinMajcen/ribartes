/// Približne koordinate revirjev in gostiln (zemljepisna širina, dolžina).
/// Uporabijo se, če dokument v bazi nima polj `lat` in `lng`.
/// Testni podatki – lokacije so približne, za prikaz na zemljevidu in vreme.
const Map<String, (double, double)> koordinateRevirjev = {
  'soca-tolmin': (46.1830, 13.7330),
  'sava-bohinjka': (46.2740, 13.9540),
  'krka-zuzemberk': (45.8330, 14.9290),
  'kolpa-vinica': (45.4580, 15.2490),
  'ljubljanica-vrhnika': (45.9650, 14.2950),
};

const Map<String, (double, double)> koordinateGostiln = {
  'pri-soci': (46.1790, 13.7400),
  'bohinjski-kot': (46.2770, 13.9420),
  'ob-krki': (45.8370, 14.9350),
  'domacija-kolpa': (45.4620, 15.2420),
};
