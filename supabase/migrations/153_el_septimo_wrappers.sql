-- 153: El Septimo — sett Costa Rica-dekkblad for de tre linjene som er dokumenterte costaricanske puroer.
-- Kilder: halfwheel (Gilgamesh/Aqua Anu "made entirely of Costa Rican tobaccos"),
--         cigar-coop (Zaya "Costa Rican wrapper"), cigarpublic (Alexandra/Coco "Wrapper: Costa Rica").
-- Sortsnavn er ikke offentliggjort; bruker landnavn som dekkblad (samme praksis som Byron='Ecuador', Macanudo='Honduran').
-- Luxus og Sacred Arts forblir tomme: dekkblad ikke oppgitt av produsent eller anmeldere (verifisert via halfwheel/cigar-coop/blindmanspuff).
-- Idempotent (COALESCE).
UPDATE public.cigars
  SET wrapper_country = COALESCE(wrapper_country,'Costa Rica'),
      wrapper_leaf    = COALESCE(wrapper_leaf,'Costa Rican')
  WHERE brand='El Septimo' AND series IN ('Alexandra','Gilgamesh','Zaya');
