-- Migrasjon 027: Kontrollsjekket backfill av body_type, head_type, foot_type for ALLE 1103 sigarer
-- Taksonomi verifisert mot Cigar Aficionado / Klaro Cigars / Holt's sigarglossar:
--   head_type: "Round" (parejo-standard rundet kapp), "Pointed" (figurado-tupp), "Wedge" (Chisel-formet kapp)
--   foot_type: "Open" (standard rett snitt, det vanligste), "Closed" (tilsluttet/forseglet, må kuttes - sanne Perfecto/Diadema der begge ender smalner til en spiss),
--              "Tapered" (smalner men forblir åpent/rett avskåret - Salomon sin "flush-cut foot")
--   body_type: formkategori (Parejo, Box-Pressed, Torpedo, Torpedo Box-Pressed, Belicoso, Pyramid, Perfecto, Salomon, Diadema, Chisel, Culebra)
--
-- Klassifiseringen leser vitola/common_format/shape-tekst for kjente figurado-stikkord, med mest spesifikke
-- formnavn først (Culebra/Diadema/Salomon/Perfecto/Chisel/Pyramid/Belicoso/Torpedo), og faller tilbake til
-- standard Parejo (rundet kapp, åpen fot) for alt annet -- som dekker det store flertallet av rader
-- (Robusto/Toro/Churchill/Corona/Gordo/Lonsdale/Lancero osv., som alle er rette parejo-former uavhengig
-- av hvilket størrelsesnavn som historisk ble lagt i shape-kolonnen).

update cigars set
  body_type = case
    when vitola ilike '%culebra%' or common_format ilike '%culebra%' or shape ilike '%culebra%' then 'Culebra'
    when vitola ilike '%diadema%' or common_format ilike '%diadema%' or shape ilike '%diadema%' then 'Diadema'
    when vitola ilike '%salomon%' or common_format ilike '%salomon%' or shape ilike '%salomon%' then 'Salomon'
    when vitola ilike '%perfecto%' or common_format ilike '%perfecto%' or shape ilike '%perfecto%' then 'Perfecto'
    when vitola ilike '%chisel%' or common_format ilike '%chisel%' or shape ilike '%chisel%' then 'Chisel'
    when (vitola ilike '%pyramid%' or common_format ilike '%pyramid%' or shape ilike '%pyramid%'
      or vitola ilike '%piramide%' or common_format ilike '%piramide%' or shape ilike '%piramide%') then 'Pyramid'
    when vitola ilike '%belicoso%' or common_format ilike '%belicoso%' or shape ilike '%belicoso%' then 'Belicoso'
    when (vitola ilike '%torpedo%' or common_format ilike '%torpedo%' or shape ilike '%torpedo%')
      and (vitola ilike '%box%press%' or common_format ilike '%box%press%' or shape ilike '%box%press%') then 'Torpedo Box-Pressed'
    when vitola ilike '%torpedo%' or common_format ilike '%torpedo%' or shape ilike '%torpedo%' then 'Torpedo'
    when vitola ilike '%box%press%' or common_format ilike '%box%press%' or shape ilike '%box%press%' then 'Box-Pressed'
    else 'Parejo'
  end,
  head_type = case
    when vitola ilike '%chisel%' or common_format ilike '%chisel%' or shape ilike '%chisel%' then 'Wedge'
    when vitola ilike '%diadema%' or common_format ilike '%diadema%' or shape ilike '%diadema%'
      or vitola ilike '%salomon%' or common_format ilike '%salomon%' or shape ilike '%salomon%'
      or vitola ilike '%perfecto%' or common_format ilike '%perfecto%' or shape ilike '%perfecto%'
      or vitola ilike '%pyramid%' or common_format ilike '%pyramid%' or shape ilike '%pyramid%'
      or vitola ilike '%piramide%' or common_format ilike '%piramide%' or shape ilike '%piramide%'
      or vitola ilike '%belicoso%' or common_format ilike '%belicoso%' or shape ilike '%belicoso%'
      or vitola ilike '%torpedo%' or common_format ilike '%torpedo%' or shape ilike '%torpedo%' then 'Pointed'
    else 'Round'
  end,
  foot_type = case
    when vitola ilike '%diadema%' or common_format ilike '%diadema%' or shape ilike '%diadema%'
      or vitola ilike '%perfecto%' or common_format ilike '%perfecto%' or shape ilike '%perfecto%' then 'Closed'
    when vitola ilike '%salomon%' or common_format ilike '%salomon%' or shape ilike '%salomon%' then 'Tapered'
    else 'Open'
  end;
