-- 102_store_purchase_location.sql
--
-- «Hvor kjøpte du den?» — butikk på humidor-oppføringer og røykelogger.
--
-- Et fritekstfelt brukeren fyller selv (butikknavn, evt. reise/anledning).
-- Rent personlig loggføring — ikke knyttet til catalog_leads eller noe
-- kommersielt. NB: en «hvor får man tak i den»-funksjon med butikklenker/
-- samarbeid er en egen sak som må vurderes mot tobakksreklameforbudet først.
--
-- humidor.store        hvor sigaren ble kjøpt (ved anskaffelse)
-- tasting_logs.store   hvor sigaren ble kjøpt (for logger uten humidor-kobling)

alter table public.humidor      add column if not exists store text;
alter table public.tasting_logs add column if not exists store text;
