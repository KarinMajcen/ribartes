# RIBARTes – Lovim, torej sem: funkcionalna specifikacija

| | |
|---|---|
| **Člani** | Karin Majcen (63240198) |
| **Repozitorij** | https://github.com/KarinMajcen/ribartes |
| **Platforma in orodja** | Android in iOS, Flutter (Dart), Firebase Authentication, Cloud Firestore |
| **Različica dokumenta** | 0.1, 24. 11. 2026 |

---

## 1. Uvod

### 1.1 Namen

Rekreativni ribič mora danes ribolovno dovolilnico kupiti pri ribiški družini ali na prodajnem mestu, jo nositi s seboj na papirju in ulov ročno vpisovati v dnevnik. RIBARTes združi nakup dovolilnice, elektronsko dovolilnico s QR kodo in dnevnik ulova v eno mobilno aplikacijo. Ribič tako dovolilnico kupi kadarkoli, tudi ob 5. uri zjutraj ob reki, čuvaj pa njeno veljavnost preveri s skeniranjem QR kode.

### 1.2 Uporabniki

| Vloga | Opis |
|---|---|
| Ribič | Rekreativni ribič, ki želi hitro kupiti dovolilnico za izbrani revir in beležiti svoj ulov. |
| Ribiški čuvaj | Nadzornik na revirju, ki želi na kraju preveriti, ali ima ribič veljavno dovolilnico. |
| Gostilna (partner) | Gostilna ob reki, ki ribičem ponudi pripravo njihovega ulova. V tej različici le kot podatek v aplikaciji (glej Could). |

### 1.3 Obseg

**Aplikacija omogoča:**

- registracijo in prijavo ribiča z e-pošto in geslom,
- pregled revirjev z vrstami rib, pravili in cenami ter iskanje po reki in vrsti ribe,
- nakup dnevne, tedenske ali letne dovolilnice s simuliranim plačilom,
- prikaz kupljenih dovolilnic s QR kodo in stanjem veljavnosti,
- vpis ulova (vrsta, dolžina, teža, fotografija) in ribji album, v katerem se kartica vrste odklene ob prvem ulovu,
- zbiranje točk za ribe, vrnjene v reko, in njihovo unovčenje kot popust pri dovolilnici,
- preverjanje veljavnosti dovolilnice s skeniranjem QR kode (vloga čuvaj).

**Izven obsega** (v tej različici aplikacija tega ne dela):

- pravega plačila s kartico ali drugim plačilnim sredstvom; plačilo je simulirano,
- urejanja revirjev, cen in pravil s strani ribiških družin; podatki so vneseni neposredno v bazo,
- ločene aplikacije za gostilne in upravljanja rezervacij s strani gostiln,
- izplačila nagrad sponzorjev.

### 1.4 Slovar pojmov

| Pojem | Pomen v tej aplikaciji |
|---|---|
| Revir | Odsek reke ali jezera, ki ga upravlja ribiška družina in za katerega se kupi dovolilnica. |
| Dovolilnica | Dovoljenje za ribolov na enem revirju za določeno obdobje (dnevna, tedenska, letna). |
| Veljavnost | Obdobje od `veljaOd` do `veljaDo`, v katerem dovolilnica velja. |
| Ulov | Zapis o ujeti ribi: vrsta, dolžina, teža, fotografija, revir, datum, ali je bila vrnjena v reko. |
| Ribji album | Zbirka kartic vseh vrst rib. Kartica je zaklenjena, dokler ribič te vrste ne ujame prvič. |
| Ujemi in spusti | Riba, ki jo ribič po ulovu vrne v reko. Zanjo prejme točke. |
| Točke | Nagrada za ujemi in spusti, ki jo ribič unovči kot popust pri nakupu dovolilnice. |
| Čuvaj | Ribiški nadzornik, ki preverja dovolilnice na revirju. |

---

## 2. Funkcionalne zahteve

**Prioritete (MoSCoW):** **Must**: brez tega aplikacija nima smisla, mora delovati na zagovoru. **Should**: pomembno, naredim, če je le mogoče. **Could**: dobrodošlo, če ostane čas. **Won't**: zavestno izpuščeno.

### US-01: Registracija

**Kot** ribič **želim** ustvariti račun z e-pošto in geslom, **da** so moje dovolilnice in ulovi shranjeni pod mojim imenom in dostopni z vsake naprave.

**Prioriteta:** Must

```gherkin
Scenario: uspešna registracija
  Given ribič je na zaslonu »Registracija«
  And vnese ime »Janez Novak«, e-pošto »janez@primer.si« in geslo »ribolov123«
  When tapne »Ustvari račun«
  Then račun se ustvari
  And odpre se »Domači zaslon« s pozdravom »Pozdravljen, Janez«

Scenario: e-pošta je že v uporabi
  Given račun z e-pošto »janez@primer.si« že obstaja
  And ribič je na zaslonu »Registracija«
  When vnese e-pošto »janez@primer.si« in tapne »Ustvari račun«
  Then račun se ne ustvari
  And izpiše se »Račun s to e-pošto že obstaja.«

Scenario: prekratko geslo
  Given ribič je na zaslonu »Registracija«
  When vnese geslo »abc« in tapne »Ustvari račun«
  Then račun se ne ustvari
  And izpiše se »Geslo mora imeti vsaj 6 znakov.«
```

### US-02: Prijava in odjava

**Kot** ribič **želim** se prijaviti v svoj račun in se iz njega odjaviti, **da** do mojih dovolilnic ne more dostopati nihče drug.

**Prioriteta:** Must

```gherkin
Scenario: uspešna prijava
  Given ribič ima račun z e-pošto »janez@primer.si«
  And je na zaslonu »Prijava«
  When vnese pravilno e-pošto in geslo ter tapne »Prijava«
  Then odpre se »Domači zaslon«

Scenario: napačno geslo
  Given ribič je na zaslonu »Prijava«
  When vnese napačno geslo in tapne »Prijava«
  Then ostane na zaslonu »Prijava«
  And izpiše se »Napačna e-pošta ali geslo.«

Scenario: ni internetne povezave
  Given naprava nima internetne povezave
  When ribič tapne »Prijava«
  Then izpiše se »Ni povezave. Preverite internet in poskusite znova.«

Scenario: ostane prijavljen
  Given ribič se je prijavil in zaprl aplikacijo
  When aplikacijo ponovno odpre
  Then takoj se odpre »Domači zaslon« brez ponovne prijave
```

### US-03: Pregled in iskanje revirjev

**Kot** ribič **želim** videti seznam revirjev in ga filtrirati po reki in vrsti ribe, **da** hitro najdem revir, kjer lahko lovim ribo, ki me zanima.

**Prioriteta:** Must

```gherkin
Scenario: prikaz seznama
  Given v bazi je 5 revirjev
  When ribič odpre zaslon »Revirji«
  Then prikaže se 5 revirjev z imenom, reko in ceno dnevne dovolilnice

Scenario: iskanje po vrsti ribe
  Given ribič je na zaslonu »Revirji«
  When v iskalno polje vpiše »lipan«
  Then prikažejo se samo revirji, v katerih živi lipan

Scenario: ni zadetkov
  Given ribič je na zaslonu »Revirji«
  When v iskalno polje vpiše »morski pes«
  Then izpiše se »Ni revirjev, ki ustrezajo iskanju.«
```

### US-04: Podrobnosti revirja

**Kot** ribič **želim** videti podrobnosti revirja (vrste rib, pravila, cene), **da** se pred nakupom prepričam, da revir ustreza mojemu načinu ribolova.

**Prioriteta:** Must

```gherkin
Scenario: prikaz podrobnosti
  Given ribič je na zaslonu »Revirji«
  When tapne revir »Soča – Tolmin«
  Then prikažejo se vrste rib, pravila revirja in cene dnevne, tedenske in letne dovolilnice
  And prikaže se gumb »Kupi dovolilnico«
```

### US-05: Nakup dovolilnice

**Kot** ribič **želim** za izbrani revir kupiti dnevno, tedensko ali letno dovolilnico za izbrani datum, **da** lahko ribarim zakonito, ne da bi moral na prodajno mesto.

**Prioriteta:** Must

```gherkin
Scenario: uspešen nakup dnevne dovolilnice
  Given ribič je na podrobnostih revirja »Soča – Tolmin«
  When izbere vrsto »dnevna« in datum »28. 11. 2026«
  And tapne »Plačaj« in potrdi simulirano plačilo
  Then dovolilnica se shrani z veljavnostjo od 28. 11. 2026 00:00 do 28. 11. 2026 23:59
  And odpre se zaslon z QR kodo nove dovolilnice

Scenario: datum v preteklosti
  Given ribič je na zaslonu »Nakup dovolilnice«
  When izbere datum, ki je pred današnjim
  Then gumb »Plačaj« je onemogočen
  And izpiše se »Datum ne sme biti v preteklosti.«

Scenario: ni povezave ob plačilu
  Given naprava nima internetne povezave
  When ribič tapne »Plačaj«
  Then dovolilnica se ne ustvari
  And izpiše se »Nakup ni uspel, ni povezave. Denar ni bil bremenjen.«
```

### US-06: Moje dovolilnice s QR kodo

**Kot** ribič **želim** videti svoje dovolilnice s QR kodo in stanjem veljavnosti, **da** jo lahko pokažem čuvaju na revirju.

**Prioriteta:** Must

```gherkin
Scenario: prikaz veljavne dovolilnice
  Given ribič ima dovolilnico z veljavnostjo, ki vključuje današnji dan
  When odpre »Moje dovolilnice«
  Then dovolilnica je na vrhu seznama z oznako »Veljavna«
  And ob tapu se prikaže njena QR koda čez cel zaslon

Scenario: potekla dovolilnica
  Given ribič ima dovolilnico, ki je potekla včeraj
  When odpre »Moje dovolilnice«
  Then dovolilnica je prikazana pod »Zgodovina« z oznako »Potekla«

Scenario: brez povezave
  Given ribič je dovolilnice že enkrat odprl z internetno povezavo
  And naprava zdaj nima povezave
  When odpre »Moje dovolilnice«
  Then prikažejo se zadnje naložene dovolilnice z QR kodo
```

### US-07: Vpis ulova

**Kot** ribič **želim** vpisati ulov z vrsto, dolžino, težo in fotografijo, **da** imam pregled nad svojimi ulovi in dokaz o ujeti ribi.

**Prioriteta:** Must

```gherkin
Scenario: uspešen vpis ulova
  Given ribič je na zaslonu »Nov ulov«
  When izbere vrsto »soška postrv«, vpiše dolžino 42 cm in težo 0,9 kg
  And fotografira ribo in tapne »Shrani«
  Then ulov se shrani z današnjim datumom
  And prikaže se v seznamu ulovov

Scenario: manjka vrsta ribe
  Given ribič je na zaslonu »Nov ulov«
  And vrsta ribe ni izbrana
  When tapne »Shrani«
  Then ulov se ne shrani
  And izpiše se »Izberite vrsto ribe.«

Scenario: zavrnjeno dovoljenje za kamero
  Given ribič na zaslonu »Nov ulov« tapne »Dodaj fotografijo«
  When dovoljenje za kamero zavrne
  Then izpiše se »Brez dovoljenja za kamero fotografije ni mogoče dodati.«
  And ulov lahko shrani brez fotografije
```

### US-08: Ribji album

**Kot** ribič **želim** zbirko kartic vseh slovenskih vrst rib, ki se odklenejo ob prvem ulovu, **da** imam cilj in motivacijo za ribolov na različnih revirjih.

**Prioriteta:** Must

```gherkin
Scenario: odklep nove kartice
  Given ribič še ni ujel nobene soške postrvi
  When shrani ulov vrste »soška postrv«
  Then izpiše se »Nova kartica: soška postrv!«
  And v »Ribjem albumu« je kartica soške postrvi odklenjena

Scenario: prikaz napredka
  Given v bazi je 15 vrst rib
  And ribič je ujel 4 različne vrste
  When odpre »Ribji album«
  Then prikaže se »Zbranih 4 / 15«
  And 11 kartic je prikazanih kot zaklenjenih (siva silhueta)
```

### US-09: Točke ujemi in spusti

**Kot** ribič **želim** za vsako ribo, ki jo vrnem v reko, prejeti točke, **da** sem nagrajen za trajnostni ribolov.

**Prioriteta:** Should

```gherkin
Scenario: točke za spuščeno ribo
  Given ribič ima 30 točk
  When vpiše ulov in označi »Vrnjena v reko«
  Then ribič ima 40 točk
  And izpiše se »+10 točk za ujemi in spusti!«

Scenario: riba ni vrnjena
  Given ribič ima 30 točk
  When vpiše ulov brez oznake »Vrnjena v reko«
  Then ribič ima še vedno 30 točk
```

### US-10: Popust s točkami

**Kot** ribič **želim** pri nakupu dovolilnice unovčiti točke kot popust, **da** imam od zbranih točk konkreten prihranek.

**Prioriteta:** Should

```gherkin
Scenario: unovčenje točk
  Given ribič ima 250 točk
  And dnevna dovolilnica stane 25,00 €
  When na zaslonu »Nakup dovolilnice« vklopi »Unovči točke«
  Then cena se zniža na 23,00 €
  And po nakupu ima ribič 50 točk

Scenario: premalo točk
  Given ribič ima 60 točk
  When odpre zaslon »Nakup dovolilnice«
  Then stikalo »Unovči točke« je onemogočeno
  And izpiše se »Za popust potrebujete vsaj 100 točk.«
```

### US-11: Preverjanje dovolilnice (čuvaj)

**Kot** ribiški čuvaj **želim** skenirati QR kodo na ribičevem telefonu, **da** takoj vidim, ali ima veljavno dovolilnico za ta revir.

**Prioriteta:** Should

```gherkin
Scenario: veljavna dovolilnica
  Given čuvaj je na zaslonu »Preveri dovolilnico«
  When skenira QR kodo dovolilnice, ki velja danes
  Then prikaže se zeleno sporočilo »Veljavna« z imenom ribiča, revirjem in datumom veljavnosti

Scenario: potekla dovolilnica
  Given čuvaj je na zaslonu »Preveri dovolilnico«
  When skenira QR kodo dovolilnice, ki je potekla
  Then prikaže se rdeče sporočilo »Ni veljavna – potekla 27. 11. 2026«

Scenario: neznana koda
  Given čuvaj je na zaslonu »Preveri dovolilnico«
  When skenira QR kodo, ki ni dovolilnica RIBARTes
  Then prikaže se »Neznana koda«
```

### US-12: Tedenska lestvica

**Kot** ribič **želim** videti lestvico največjih ulovov tega tedna po rekah, **da** se lahko primerjam z drugimi ribiči.

**Prioriteta:** Could

```gherkin
Scenario: prikaz lestvice
  Given ta teden je bilo na Soči vpisanih 8 ulovov
  When ribič odpre »Lestvica« in izbere reko »Soča«
  Then prikaže se 8 ulovov, razvrščenih po dolžini od največje do najmanjše

Scenario: ni ulovov
  Given ta teden na Krki ni bilo vpisanih ulovov
  When ribič izbere reko »Krka«
  Then izpiše se »Ta teden še ni ulovov. Bodi prvi!«
```

### US-13: Rezervacija priprave ulova v gostilni

**Kot** ribič **želim** v partnerski gostilni ob reki rezervirati pripravo svojega ulova, **da** ga lahko pojem sveže pripravljenega takoj po ribolovu.

**Prioriteta:** Could

```gherkin
Scenario: uspešna rezervacija
  Given ribič je na zaslonu »Gostilne«
  When izbere gostilno »Pri Soči«, uro 13:00 in tapne »Rezerviraj«
  Then rezervacija se shrani
  And izpiše se »Rezervacija potrjena za 13:00.«

Scenario: ura v preteklosti
  Given ura je 14:00
  When ribič izbere uro 13:00 za danes
  Then gumb »Rezerviraj« je onemogočen
```

### Won't (zavestno izpuščeno)

- Pravo plačilo (kartica, Apple Pay, Google Pay): zahteva pogodbo s plačilnim ponudnikom in varnostni pregled, kar presega obseg seminarske naloge. Plačilo je simulirano.
- Upravljanje revirjev za ribiške družine: zahteva ločeno vlogo in skrbniški vmesnik. Revirji so vneseni neposredno v bazo.
- Nagrade sponzorjev za zmagovalca tedna: zahteva dogovore s sponzorji.
- Aplikacija za gostilne (sprejem in potrjevanje rezervacij): ločena aplikacija.

---

## 3. Nefunkcionalne zahteve

‹dopolnimo kasneje›

### 3.1 Osebni podatki in dovoljenja

‹dopolnimo kasneje›

---

## 4. Uporabniški vmesnik

### 4.1 Tok zaslonov

‹dopolnimo kasneje›

### 4.2 Zasloni

‹dopolnimo kasneje›

---

## 5. Arhitektura

### 5.1 Kontekst (C4, raven 1)

‹dopolnimo kasneje›

### 5.2 Vsebniki (C4, raven 2)

‹dopolnimo kasneje›

### 5.3 Plasti aplikacije

‹dopolnimo kasneje›

---

## 6. Podatkovni model

‹dopolnimo kasneje›

---

## 7. Zunanji vmesniki

‹dopolnimo kasneje›

---

## 8. Dinamika

### 8.1 Nakup dovolilnice

‹dopolnimo kasneje›

### 8.2 Prijava uporabnika

‹dopolnimo kasneje›

### 8.3 Stanja: dovolilnica

‹dopolnimo kasneje›

### 8.4 Algoritem: točke in popust

‹dopolnimo kasneje›

---

## 9. Sledljivost

| Zgodba | Prioriteta | Zasloni | Preverjanje | Stanje |
|---|---|---|---|---|
| US-01 Registracija | Must | Registracija | ročni test po scenarijih | načrtovano |
| US-02 Prijava in odjava | Must | Prijava, Profil | ročni test po scenarijih | načrtovano |
| US-03 Pregled in iskanje revirjev | Must | Revirji | ročni test po scenarijih | načrtovano |
| US-04 Podrobnosti revirja | Must | Podrobnosti revirja | ročni test po scenarijih | načrtovano |
| US-05 Nakup dovolilnice | Must | Nakup dovolilnice | ročni test po scenarijih | načrtovano |
| US-06 Moje dovolilnice s QR kodo | Must | Moje dovolilnice, QR koda | ročni test po scenarijih | načrtovano |
| US-07 Vpis ulova | Must | Nov ulov | ročni test po scenarijih | načrtovano |
| US-08 Ribji album | Must | Ribji album | ročni test po scenarijih | načrtovano |
| US-09 Točke ujemi in spusti | Should | Nov ulov, Profil | ročni test po scenarijih | načrtovano |
| US-10 Popust s točkami | Should | Nakup dovolilnice | ročni test po scenarijih | načrtovano |
| US-11 Preverjanje dovolilnice | Should | Preveri dovolilnico | demonstracija na zagovoru | načrtovano |
| US-12 Tedenska lestvica | Could | Lestvica | ročni test po scenarijih | načrtovano |
| US-13 Rezervacija v gostilni | Could | Gostilne | ročni test po scenarijih | načrtovano |

---

## 10. Zgodovina sprememb

| Različica | Datum | Spremembe |
|---|---|---|
| 0.1 | 24. 11. 2026 | Prva različica: uvod, uporabniške zgodbe, sledljivost |
