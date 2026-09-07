# Dekningshull – norske sigarbutikker

Sist oppdatert: **7. september 2026**

Dette dokumentet erstatter den gamle baseline-en som ble laget da databasen hadde 2 132 sigarer / 183 merker.

## Live SEDER-status

- **4 060 sigarer**
- **261 unike brand-navn**
- **2 184 produsentverifiserte rader**
- **1 876 rader som fortsatt venter på produsentverifisering**

Viktig: `uverifisert` betyr ikke `mangler i katalogen`. Catalog gap betyr kun at et relevant merke eller en relevant linje som faktisk selges i Norge ikke finnes i SEDER.

## Metode

Baseline bygges mot dagens offentlige sortiment hos norske forhandlere/importører, med særlig vekt på:

- M. Sørensen – offentlig komplett merkeoversikt
- Augusto Cigars – offentlig importør-/merkeoversikt
- NoSmoke – aktuell sigarkategori og lagerførte produkter
- Nordic Cigars – aktuelle boutique-produkter og produsentsider
- Sol Cigar – supplerende kontroll der offentlige produktsider er tilgjengelige

Butikkilder brukes kun til å avgjøre **om noe selges/føres i Norge**. Wrapper, binder, filler, mål osv. skal fortsatt verifiseres mot produsentens egne kilder før innlegging/verifisering.

---

## ✅ Tidligere «hull» som nå er dekket

| Butikknavn / gammel betegnelse | Status i SEDER |
|---|---|
| 1881 | **4 nåværende standardvitolaer produsentverifisert** |
| Inca | **2 norske produkter lagt inn og produsentverifisert 07.09.2026** |
| Corrida | **3 aktuelle Robusto+-varianter lagt inn og produsentverifisert 07.09.2026** |
| Buena Vista | **9 aktuelle norske produkter lagt inn og produsentverifisert 07.09.2026** |
| Aliados | Finnes som **Cuba Aliados** – 5 rader |
| Eiroa | **23 rader** |
| Condega | **17 rader** |
| Nicarao | **17 rader** |
| Horacio | **44 rader** |
| Charatan | **20 rader** |
| Paradiso | **4 rader** |
| Furia | **1 rad** |
| Artesano del Tobacco / El Pulpo | **El Pulpo – 6 rader** |
| K by Karen | **K by Karen Berger – 8 rader** |
| Santa Clara / Madrigal | **Madrigal Picador – 4 rader** |
| Oz Family Cigars | **Ozgener Family Cigars – 20 rader** |
| Bolivar | **Bolívar – 10 rader** |
| Diplomaticos | **Diplomáticos – 2 rader** |
| Jose L. Piedra | **José L. Piedra – 5 rader** |
| Juan Lopez | **Juan López – 3 rader** |
| Por Larranaga | **Por Larrañaga – 7 rader** |
| Rafael Gonzalez | **Rafael González – 4 rader** |
| Ramon Allones | **Ramón Allones – 5 rader** |
| San Cristobal de la Habana | **San Cristóbal de la Habana – 5 rader** |
| Master Blends 3 | **Oliva / Master Blends 3 – 5 rader** |
| Signature | **Davidoff / Signature – 8 rader** |

---

## 🎯 Bekreftede aktuelle premium-/håndrullede catalog gaps

Dette er en konservativ minimumsliste: navn tas først inn når dagens norske sortiment kan dokumenteres og alternative brandnavn er kontrollert mot live Supabase.

| Merke / linje | Norsk kilde | Status | Prioritet |
|---|---|---|---|
| **Alonso Menendez** | M. Sørensen | 0 rader | Høy |
| **Bossner** | M. Sørensen | 0 rader | Høy |
| **Carlos André** | M. Sørensen | 0 rader | Medium |
| **DJU / Don Juan Urquijo** | M. Sørensen | 0 rader | Høy |
| **La Libertad** | M. Sørensen | 0 rader | Høy |
| **Reposado 96** | M. Sørensen + NoSmoke | 0 rader | Høy – produsentkilde ikke funnet ennå |
| **Don Kiki** | Augusto | 0 rader | Medium |
| **Viva la Vida** | Augusto / Artesano del Tobacco | 0 rader | Høy |
| **Smoking Jacket** | Nordic Cigars | 0 rader | Medium |
| **Xhaxhi Bobi** | Nordic Cigars | 0 rader | Medium |

---

## 🟡 Kandidater som må klassifiseres før de regnes som premium-gap

Alejandro Lopez · Alhambra · Backwoods · Bellman · Chazz · Clubmaster · Combinaciones · De Olifant · J. Cortès · J.H.A · La Paz · Meharis · Montosa · Parcero · Perla de Calvano · Ritmeester · Tabacalera · WTF · Platinum Nova · Lunatic

---

## Neste databasebatch

1. **Alonso Menendez** – 4 aktuelle produkter
2. **DJU / Don Juan Urquijo** – 11 aktuelle produkter
3. **La Libertad** – liten og avgrenset serie
4. **Bossner** – større katalog
5. **Carlos André** – aktuell norsk serie må avgrenses
6. **Reposado 96** – beholdes som catalog lead til produsenteid kilde kan dokumentere spesifikasjonene
7. **Viva la Vida / Don Kiki / Nordic boutique-hull** – produsentkilde må finnes før innlegging

Alle nye cigar-rader skal følge SEDER-regelen: **produsentens egne kilder er eneste endelige autoritet for cigar-spesifikasjoner. Ikke gjett manglende data.**
