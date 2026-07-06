-- Migration 050: Casa de Garcia — Connecticut + Maduro full lineup
-- Laget av General Cigar Co. / Tabacalera de Garcia i La Romana, DR
-- To linjer: Connecticut Shade (mild/str 2) og Maduro (medium/str 3)

INSERT INTO cigars (
  manufacturer, brand, series, vitola, common_format,
  ring_gauge, length_inches, shape,
  body_type, head_type, foot_type,
  wrapper_country, wrapper_leaf, binder, filler,
  country_origin, strength, price_range,
  description, flavor_notes, avg_rating
)
VALUES
-- Connecticut line
('General Cigar Co.','Casa de Garcia','Connecticut','Churchill','Churchill',52,6.25,'Parejo',null,null,null,'United States','Connecticut Shade','Dominican Republic',ARRAY['Dominican Republic'],'Dominican Republic',2,'$3-5','Casa de Garcia Connecticut Churchill — klassisk budsjettsigar fra La Romana. Mild og kremet Connecticut Shade over dominikansk fylt.',ARRAY['cream','cedar','hay','mild earth','toasted nuts'],8.0),
('General Cigar Co.','Casa de Garcia','Connecticut','Belicoso','Belicoso',52,6.125,'Torpedo',null,'Torpedo',null,'United States','Connecticut Shade','Dominican Republic',ARRAY['Dominican Republic'],'Dominican Republic',2,'$3-5','Casa de Garcia Connecticut Belicoso — smalnet hode gir mer konsentrert kremet smak med Connecticut Shade.',ARRAY['cream','cedar','hay','mild spice','toasted nuts'],8.0),
('General Cigar Co.','Casa de Garcia','Connecticut','Toro','Toro',52,5.5,'Parejo',null,null,null,'United States','Connecticut Shade','Dominican Republic',ARRAY['Dominican Republic'],'Dominican Republic',2,'$3-5','Casa de Garcia Connecticut Toro — 5½x52, allsidig hverdagsformat med god balanse og kremet Connecticut Shade-karakter.',ARRAY['cream','cedar','hay','gentle earth','mild pepper'],8.1),
('General Cigar Co.','Casa de Garcia','Connecticut','Robusto','Robusto',50,4.75,'Parejo',null,null,null,'United States','Connecticut Shade','Dominican Republic',ARRAY['Dominican Republic'],'Dominican Republic',2,'$3-5','Casa de Garcia Connecticut Robusto — kompakt 4¾x50 med konsentrert kremet smak. En av seriens mest solgte varianter.',ARRAY['cream','cedar','hay','mild earth','toasted nuts'],8.2),
('General Cigar Co.','Casa de Garcia','Connecticut','Short Robusto','Petit Robusto',50,4.5,'Parejo',null,null,null,'United States','Connecticut Shade','Dominican Republic',ARRAY['Dominican Republic'],'Dominican Republic',2,'$3-5','Casa de Garcia Connecticut Short Robusto — Petit Robusto for en rask og kremet hverdagsrøyk.',ARRAY['cream','cedar','hay','mild earth'],7.9),
('General Cigar Co.','Casa de Garcia','Connecticut','Corona','Corona',44,5.5,'Parejo',null,null,null,'United States','Connecticut Shade','Dominican Republic',ARRAY['Dominican Republic'],'Dominican Republic',2,'$3-5','Casa de Garcia Connecticut Corona — smalere 44 ringgauge fremhever Connecticut Shade-dekkbladets kremet-søte profil.',ARRAY['cream','cedar','hay','toasted nuts','gentle floral'],7.9),
-- Maduro line
('General Cigar Co.','Casa de Garcia','Maduro','Churchill','Churchill',52,6.25,'Parejo',null,null,null,'United States','Connecticut Broadleaf Maduro','Dominican Republic',ARRAY['Dominican Republic'],'Dominican Republic',3,'$3-5','Casa de Garcia Maduro Churchill — mørkt Connecticut Broadleaf Maduro-dekkblad tilfører sjokolade- og kaffetoner til dominikansk blend.',ARRAY['dark chocolate','coffee','cedar','earth','sweet spice'],8.1),
('General Cigar Co.','Casa de Garcia','Maduro','Belicoso','Belicoso',52,6.125,'Torpedo',null,'Torpedo',null,'United States','Connecticut Broadleaf Maduro','Dominican Republic',ARRAY['Dominican Republic'],'Dominican Republic',3,'$3-5','Casa de Garcia Maduro Belicoso — Torpedo med mørkt Maduro-dekkblad. Konsentrert sjokolade og søt krydder.',ARRAY['dark chocolate','coffee','cedar','sweet spice','earth'],8.1),
('General Cigar Co.','Casa de Garcia','Maduro','Toro','Toro',52,5.5,'Parejo',null,null,null,'United States','Connecticut Broadleaf Maduro','Dominican Republic',ARRAY['Dominican Republic'],'Dominican Republic',3,'$3-5','Casa de Garcia Maduro Toro — 5½x52 med Connecticut Broadleaf Maduro. Rik sjokolade- og kaffeprofil i populært midtformat.',ARRAY['dark chocolate','coffee','cedar','earth','sweet spice'],8.2),
('General Cigar Co.','Casa de Garcia','Maduro','Robusto','Robusto',50,4.75,'Parejo',null,null,null,'United States','Connecticut Broadleaf Maduro','Dominican Republic',ARRAY['Dominican Republic'],'Dominican Republic',3,'$3-5','Casa de Garcia Maduro Robusto — kompakt 4¾x50 med konsentrert Maduro-smak. Sjokolade, kaffe og søt krydder.',ARRAY['dark chocolate','coffee','earth','sweet spice','leather'],8.3),
('General Cigar Co.','Casa de Garcia','Maduro','Short Robusto','Petit Robusto',50,4.5,'Parejo',null,null,null,'United States','Connecticut Broadleaf Maduro','Dominican Republic',ARRAY['Dominican Republic'],'Dominican Republic',3,'$3-5','Casa de Garcia Maduro Short Robusto — Petit Robusto med mørkt Maduro-dekkblad for en rask konsentrert røyk.',ARRAY['dark chocolate','coffee','earth','sweet spice'],8.0),
('General Cigar Co.','Casa de Garcia','Maduro','Corona','Corona',44,5.5,'Parejo',null,null,null,'United States','Connecticut Broadleaf Maduro','Dominican Republic',ARRAY['Dominican Republic'],'Dominican Republic',3,'$3-5','Casa de Garcia Maduro Corona — smalere Corona-format fremhever Maduro-dekkbladets søte og mørke karakter.',ARRAY['dark chocolate','coffee','cedar','sweet earth','mild spice'],7.9)
ON CONFLICT DO NOTHING;
