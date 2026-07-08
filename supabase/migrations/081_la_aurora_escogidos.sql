-- 081_la_aurora_escogidos.sql
-- La Aurora Escogidos ("de utvalgte") — opprinnelig kun tilgjengelig på
-- fabrikkturen i Santiago. Natural = afrikansk Cameroon-dekkblad,
-- Maduro = brasiliansk Mata Fino. Dominikansk innmat.
-- Idempotent: fjerner ev. eksisterende Escogidos-rader før innsett.

delete from cigars
where brand = 'La Aurora'
  and series in ('Escogidos', 'Escogidos Maduro');

insert into cigars (manufacturer, brand, series, vitola, common_format, ring_gauge, length_inches, shape, body_type, head_type, foot_type, wrapper_country, wrapper_leaf, binder, filler, country_origin, strength, price_range, description, flavor_notes) values
-- Escogidos Natural (Cameroon-dekkblad)
('La Aurora','La Aurora','Escogidos','Robusto','Robusto',50,5.0,'Parejo',null,null,null,'Cameroon','Cameroon','Dominican',array['Dominican Republic'],'Dominican Republic',3,null,'La Aurora Escogidos med afrikansk Cameroon-dekkblad og dominikansk innmat — en hyllest til Den dominikanske republikks eldste sigarfabrikk. Medium, med sedertre, lær og en mild krydret sødme.',array['cedar','leather','sweet spice','coffee','pepper']),
('La Aurora','La Aurora','Escogidos','Short Robusto','Robusto',50,4.5,'Parejo',null,null,null,'Cameroon','Cameroon','Dominican',array['Dominican Republic'],'Dominican Republic',3,null,'La Aurora Escogidos Short Robusto — kortere format av Cameroon-utgaven. Medium, sedertre og lær med et snev av pepper.',array['cedar','leather','sweet spice','coffee','pepper']),
('La Aurora','La Aurora','Escogidos','Belicoso','Belicoso',54,6.1,'Figurado','Belicoso','Pointed',null,'Cameroon','Cameroon','Dominican',array['Dominican Republic'],'Dominican Republic',3,null,'La Aurora Escogidos Belicoso — figurado i Cameroon-blenden. Medium og balansert med sedertre, lær og kaffe.',array['cedar','leather','coffee','sweet spice']),
-- Escogidos Maduro (brasiliansk Mata Fino-dekkblad)
('La Aurora','La Aurora','Escogidos Maduro','Robusto','Robusto',50,5.0,'Parejo',null,null,null,'Brazil','Brazilian Mata Fino Maduro','Dominican',array['Dominican Republic'],'Dominican Republic',3,null,'La Aurora Escogidos Maduro med brasiliansk Mata Fino-dekkblad. Fyldigere og mørkere enn Cameroon-utgaven: mørk ristet kaffe, tørket frukt og lær med en snert vaniljekrydder.',array['coffee','dried fruit','leather','cedar','vanilla']),
('La Aurora','La Aurora','Escogidos Maduro','Belicoso','Belicoso',54,6.1,'Figurado','Belicoso','Pointed',null,'Brazil','Brazilian Maduro','Dominican',array['Brazil','Nicaragua','Dominican Republic'],'Dominican Republic',4,null,'La Aurora Escogidos Maduro Belicoso — egen blend med brasiliansk dekkblad og innmat fra Brasil, Nicaragua og Den dominikanske republikk. Fyldig, med mørk kaffe, tørket frukt og kakao.',array['coffee','dried fruit','cocoa','leather','black pepper']);
