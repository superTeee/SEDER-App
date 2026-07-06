-- 038_tasting_logs_cut_type.sql
-- Legger til cut_type på tasting_logs.
-- Verdier: 'straight_cut', 'v_cut', 'punch_cut', 'other'

alter table tasting_logs
  add column if not exists cut_type text
    check (cut_type in ('straight_cut', 'v_cut', 'punch_cut', 'other'));
