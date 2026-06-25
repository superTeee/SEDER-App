# Gap-analyse: manglende sigarmerker i Vitola-databasen

**Dato:** 20. juni 2026
**Status nå:** 728 sigarer, ~49 merker/produsenter i databasen
**Metode:** Sammenlignet databasen mot Cigar Aficionado's 2025 Cigar Insider Retailer Survey (de 65 mest aktive tobacconistene i USA rangerer de "hotteste" og best-selgende merkene), samt generell kunnskap om premium sigarindustrien.

---

## 1. Helt fraværende — store, anerkjente merker

Disse er reelle, etablerte premium-merker som ikke finnes i databasen i det hele tatt. Sortert etter hvor mye det vil skade troverdigheten å mangle dem.

| Merke | Hvorfor det betyr noe |
|---|---|
| **J.C. Newman** | Tier-1 produsent. Eier Diamond Crown og Brick House (som *er* i basen, men feilkoblet — se pkt. 3), pluss egne linjer som Stogie, El Reloj, Perla del Mar. Nevnt i CA's topp 10 best-selgende 2025. |
| **Aging Room** | Anerkjent boutique-merke (Boon Doc Tobacco), vinner av flere "Cigar of the Year"-nominasjoner. |
| **CLE** | Christian Eiroa's merke — godt kjent, mellomsegment, høy synlighet i butikker. |
| **Viaje** | Kultmerke med svært lojal følgerskare, ofte utsolgt. |
| **Room101** | Etablert boutique-merke, samarbeid med Caldwell. |
| **Kristoff** | Solid mellomsegment-merke, god butikkdekning. |
| **Asylum / Black Label Trading Co** | Begge fra Island Industries — vanlige i amerikanske humidorer. |
| **Curivari** | Premium boutique, høy anmelderscore. |
| **Cuesta-Rey** | Et av de eldste amerikanske merkenavnene (140+ år), eies av M&N. |
| **Excalibur** | Hoyo de Monterrey-linje, klassiker i mellomsegmentet. |

---

## 2. Finnes i basen, men sterkt underrepresentert

Disse merkene har en rad i databasen — men bare **1 sigar registrert**, til tross for at de er store merker med brede portfolioer. Dette er nesten verre enn å mangle merket helt, fordi en bruker som søker får treff, men ser et tomt/feil bilde av merket.

| Merke | I basen nå | Mangler typisk |
|---|---|---|
| **Foundation Cigar Co** | 1 sigar (Charter Oak) | Flaggskipet **El Güegüense** og **Tabernacle** — Charter Oak er faktisk budsjettlinjen deres, ikke hovedproduktet |
| **La Flor Dominicana** | 1 sigar (Double Ligero) | **Air Bender**, **Andalusian Bull**, Cameroon-serien — nevnt blant CA's topp 10 hotteste 2025 |
| **Joya de Nicaragua** | 1 sigar (Antaño 1970) | Et av de eldste nicaraguanske husene (siden 1968) — mangler Cuatro Cinco, Joya Red/Black |
| **Quesada** | 1 sigar (España) | Mangler **Casa Magna**, deres mest kjente linje |
| **Padilla** | 1 sigar (1932) | Mangler Padilla Miami, Achilles, Dama |
| **Diamond Crown** | 1 sigar (Maximus) | Mangler Diamond Crown Classic og Robert Burns |

---

## 3. Datafeil oppdaget under scanningen

Fant en duplikat-/spøkelsesrad: **"Don Pepin Garcia"** finnes som sin egen rad (manufacturer = brand = "Don Pepin Garcia", 1 sigar) — i tillegg til at Don Pepin Garcia korrekt ligger som under-merke av **My Father Cigars** (31 sigarer, riktig modellert). Den første raden er sannsynligvis en rest fra før vi ryddet opp i My Father-dataene (samme mønster som vi fant og fikset for Padron/Arturo Fuente i forrige runde). Bør fjernes for å unngå forvirrende dupliserte søkeresultater.

**Bra nytt:** Arturo Fuente (OpusX, Don Carlos, Hemingway), Drew Estate (Liga Privada, Undercrown, Herrera Esteli) og Ashton er faktisk godt dekket — disse store linjene ligger riktig som *serier* under hovedmerket, ikke separate merker. Ingen handling nødvendig der.

---

## Anbefaling — neste skritt

Foreslår å følge samme oppskrift som for My Father/Padron/Arturo Fuente: researche sortiment og skrive seed-data, i denne prioriterte rekkefølgen:

1. **J.C. Newman** (mangler helt + fikser Brick House/Diamond Crown-kobling)
2. **La Flor Dominicana** (nevnt blant 2025s hotteste merker, kraftig underrepresentert)
3. **Foundation Cigar Co** (manglende flaggskip El Güegüense)
4. **Quesada** (mangler Casa Magna)
5. Rydde opp Don Pepin Garcia-duplikaten

Si til meg hvilket merke du vil starte med, og jeg setter opp researchen og migrasjonen — samme prosess som tidligere.

**Kilde:** [2025 Cigar Insider Retailer Survey: Top Brands In America – Cigar Aficionado](https://www.cigaraficionado.com/article/2025-cigar-insider-retailer-survey-top-brands-in-america)
