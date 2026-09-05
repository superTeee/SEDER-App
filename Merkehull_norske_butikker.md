# Dekningshull – norske sigarbutikker

Sist oppdatert: **5. september 2026**

Dette dokumentet erstatter den gamle baseline-en som ble laget da databasen hadde 2 132 sigarer / 183 merker.
Dagens live SEDER-database har:

- **3 859 sigarer**
- **257 unike brand-navn**
- **1 948 produsentverifiserte rader**
- **1 911 rader som fortsatt venter på produsentverifisering**

Viktig: `uverifisert` betyr ikke `mangler i katalogen`. Catalog gap betyr kun at et relevant merke eller en relevant linje som faktisk selges i Norge ikke finnes i SEDER.

## Metode

Baseline er bygget mot dagens offentlige sortiment hos norske forhandlere/importører, med særlig vekt på:

- M. Sørensen – offentlig komplett merkeoversikt
- Augusto Cigars – offentlig importør-/merkeoversikt
- NoSmoke – aktuell sigarkategori og lagerførte produkter
- Nordic Cigars – aktuelle boutique-produkter og produsentsider
- Sol Cigar – brukes som supplerende kontroll der offentlige produktsider er tilgjengelige

Butikkilder brukes kun til å avgjøre **om noe selges/føres i Norge**. De skal ikke brukes som endelig kilde for cigar-spesifikasjoner i SEDER. Wrapper, binder, filler, mål osv. skal fortsatt verifiseres mot produsentens egne kilder før innlegging/verifisering.

---

## ✅ Tidligere «hull» som nå er dekket

Flere punkter fra den gamle listen var utdaterte eller skyldtes navneforskjeller:

| Butikknavn / gammel betegnelse | Status i SEDER |
|---|---|
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
| Bolivar | Finnes som **Bolívar – 10 rader** |
| Diplomaticos | Finnes som **Diplomáticos – 2 rader** |
| Jose L. Piedra | Finnes som **José L. Piedra – 5 rader** |
| Juan Lopez | Finnes som **Juan López – 3 rader** |
| Por Larranaga | Finnes som **Por Larrañaga – 7 rader** |
| Rafael Gonzalez | Finnes som **Rafael González – 4 rader** |
| Ramon Allones | Finnes som **Ramón Allones – 5 rader** |
| San Cristobal de la Habana | Finnes som **San Cristóbal de la Habana – 5 rader** |
| Master Blends 3 | Finnes korrekt som **Oliva / Master Blends 3 – 5 rader** |
| Signature | Finnes bl.a. som **Davidoff / Signature – 8 rader** |

---

## 🎯 Bekreftede aktuelle premium-/håndrullede catalog gaps

Dette er **minimumslisten** over hull vi per 5. september 2026 kan dokumentere som aktuelle i norsk sortiment og som ikke finnes i SEDER under et rimelig alternativt navn.

| Merke / linje | Norsk kilde | Status | Prioritet |
|---|---|---|---|
| **1881** | M. Sørensen | 0 rader | Høy |
| **Alonso Menendez** | M. Sørensen | 0 rader | Høy |
| **Bossner** | M. Sørensen | 0 rader | Høy |
| **Buena Vista** | M. Sørensen | 0 rader | Høy |
| **Carlos André** | M. Sørensen | 0 rader | Medium |
| **Corrida** | M. Sørensen | 0 rader | Høy |
| **DJU / Don Juan Urquijo** | M. Sørensen | 0 rader | Høy |
| **Inca** | M. Sørensen | 0 rader | Høy |
| **La Libertad** | M. Sørensen | 0 rader | Høy |
| **Reposado 96** | M. Sørensen + NoSmoke | 0 rader | Høy |
| **Don Kiki** | Augusto | 0 rader | Medium |
| **Viva la Vida** | Augusto / Artesano del Tobacco | 0 rader | Høy |
| **Smoking Jacket** | Nordic Cigars | 0 rader | Medium |
| **Xhaxhi Bobi** | Nordic Cigars | 0 rader | Medium |

Dette er ikke nødvendigvis den komplette norske gap-listen. Den er med vilje konservativ: et navn tas først inn her når dagens norske sortiment kan dokumenteres og navnekollisjoner/alternative brandnavn er kontrollert mot live Supabase.

---

## 🟡 Kandidater som må klassifiseres før de regnes som premium-gap

Følgende finnes i norske butikkoversikter, men bør ikke automatisk telles som premium catalog gap før vi har avgjort om de passer SEDERs katalogprofil, om de er maskinrullede/cigarillos, eller om butikknavnet egentlig er en serie/produsent:

Alejandro Lopez · Alhambra · Backwoods · Bellman · Chazz · Clubmaster · Combinaciones · De Olifant · J. Cortès · J.H.A · La Paz · Meharis · Montosa · Parcero · Perla de Calvano · Ritmeester · Tabacalera · WTF · Platinum Nova · Lunatic

---

## Neste databasebatch

Prioritert rekkefølge:

1. **1881** – 12 aktuelle produkter hos M. Sørensen, tydelig produktfamilie
2. **Reposado 96** – kun 2 aktuelle Robusto-varianter, rask å komplettere dersom produsentkilde finnes
3. **Inca** – 2 aktuelle produkter
4. **Corrida** – liten og avgrenset serie
5. **Buena Vista** – 9 aktuelle produkter hos M. Sørensen
6. **Alonso Menendez** – 4 aktuelle produkter
7. **DJU / Don Juan Urquijo** – 11 aktuelle produkter
8. **Bossner** – større katalog, tas etter de mindre batchene
9. **Viva la Vida / Don Kiki / Nordic boutique-hull** – produsentkilde må finnes før innlegging

Alle nye cigar-rader skal følge SEDER-regelen: **produsentens egne kilder er eneste endelige autoritet for cigar-spesifikasjoner. Ikke gjett manglende data.**
