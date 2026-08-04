-- 139: Utvid smaksnote-utledningen med nye ord lært fra smaksnote-CSV-en
-- (røyk->Smoke, tobakk->Tobacco, rom->Rum, kirsebær->Cherry, mynte->Mint m.fl.).
-- Samme mengdebaserte ordbok-oppslag som 138, men utvidet vokabular. Idempotent:
-- fyller kun rader der flavor_notes fortsatt er tom og >=1 note finnes (maks 5).
UPDATE public.cigars c
SET flavor_notes = sub.notes
FROM (
  SELECT id,
    (array_remove(ARRAY[
      CASE WHEN description ~* '(sort|svart|black)[[:space:]]*pepper' THEN 'Black Pepper' END,
      CASE WHEN description ~* 'pepper' AND description !~* '(sort|svart|black)[[:space:]]*pepper' THEN 'Pepper' END,
      CASE WHEN description ~* 'm(o|ø)rk[[:space:]]*sjokolade|dark chocolate|sjokolade|chocolate|kokesjokolade' THEN 'Dark Chocolate' END,
      CASE WHEN description ~* 'kakao|cocoa' THEN 'Cocoa' END,
      CASE WHEN description ~* 'espresso' THEN 'Espresso' END,
      CASE WHEN description ~* 'kaffe|coffee|mokka' THEN 'Coffee' END,
      CASE WHEN description ~* 'lær|leather' THEN 'Leather' END,
      CASE WHEN description ~* 'seder|sedertre|cedar' THEN 'Cedar' END,
      CASE WHEN description ~* 'jord|earth' THEN 'Earth' END,
      CASE WHEN description ~* 'kremet|kremete|krem|fløte|cream' THEN 'Cream' END,
      CASE WHEN description ~* 'ristede?[[:space:]]*nøtter|toasted[[:space:]]*nuts' THEN 'Toasted Nuts' END,
      CASE WHEN description ~* 'mandel|mandler|almond|amaretto' THEN 'Almonds' END,
      CASE WHEN description ~* 'nøtter|nøtt|nuts|pekan|pecan|valnøtt|cashew|hasselnøtt|hazelnut' THEN 'Nuts' END,
      CASE WHEN description ~* 'honning|honey' THEN 'Honey' END,
      CASE WHEN description ~* 'vanilje|vanilla' THEN 'Vanilla' END,
      CASE WHEN description ~* 'karamell|caramel|toffee' THEN 'Caramel' END,
      CASE WHEN description ~* 'melasse|molasses|sirup' THEN 'Molasses' END,
      CASE WHEN description ~* 'kanel|cinnamon|muskat|nutmeg|nellik|clove' THEN 'Baking Spice' END,
      CASE WHEN description ~* 'sitrus|citrus|sitron|lemon|grapefrukt|grapefruit|appelsin|orange' THEN 'Citrus' END,
      CASE WHEN description ~* 'tørket[[:space:]]*frukt|dried[[:space:]]*fruit|rosin|raisin|fiken|\mfig\M|aprikos|apricot|dadler|dates' THEN 'Dried Fruit' END,
      CASE WHEN description ~* 'mørk[[:space:]]*frukt|dark[[:space:]]*fruit|plomme|\mplum\M|bjørnebær|blackberry' THEN 'Dark Fruit' END,
      CASE WHEN description ~* 'floral|blomst|flower' THEN 'Floral' END,
      CASE WHEN description ~* '\mhø\M|\mhay\M' THEN 'Hay' END,
      CASE WHEN description ~* 'urteaktig|urter|herbal|gress|grass' THEN 'Herbal' END,
      CASE WHEN description ~* '\meik\M|\moak\M|bourbon' THEN 'Oak' END,
      CASE WHEN description ~* 'treverk|forkullet|\mwood\M' THEN 'Wood' END,
      CASE WHEN description ~* 'smør|butter' THEN 'Butter' END,
      CASE WHEN description ~* '\mmalt\M' THEN 'Malt' END,
      CASE WHEN description ~* 'røyk|\msmoke' THEN 'Smoke' END,
      CASE WHEN description ~* 'tobakk|tobacco' THEN 'Tobacco' END,
      CASE WHEN description ~* '\mrom\M|\mrum\M' THEN 'Rum' END,
      CASE WHEN description ~* 'kirsebær|cherry' THEN 'Cherry' END,
      CASE WHEN description ~* 'mynte|\mmint\M' THEN 'Mint' END,
      CASE WHEN description ~* '\mtoast\M' THEN 'Toast' END,
      CASE WHEN description ~* '\meple\M|\mapple\M' THEN 'Apple' END,
      CASE WHEN description ~* '\mdrue\M|\mgrape\M' THEN 'Grape' END,
      CASE WHEN description ~* 'whisky|whiskey' THEN 'Whiskey' END,
      CASE WHEN description ~* 'konjakk|cognac' THEN 'Cognac' END,
      CASE WHEN description ~* 'kokos|coconut' THEN 'Coconut' END,
      CASE WHEN description ~* 'søtlig|sødme|søtt|\msøt\M|sweet|sweetness' THEN 'Sweetness' END,
      CASE WHEN description ~* 'krydret|krydder|\mspice|spicy' THEN 'Spice' END
    ], NULL))[1:5] AS notes
  FROM public.cigars
  WHERE coalesce(is_public, true) = true
    AND (flavor_notes IS NULL OR array_length(flavor_notes, 1) IS NULL)
    AND description IS NOT NULL AND length(trim(description)) > 0
) sub
WHERE c.id = sub.id
  AND array_length(sub.notes, 1) >= 1;
