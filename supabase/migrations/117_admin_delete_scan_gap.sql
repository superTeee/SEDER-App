-- 117_admin_delete_scan_gap
-- Lar admin fjerne en støyete/ugyldig bom fra dekning-listen (f.eks. skjermbilder
-- som ble skannet). Sletter kun bom-radene (hit=false) for den normaliserte teksten.
-- Applied to prod via MCP apply_migration (admin_delete_scan_gap).

create or replace function public.admin_delete_scan_gap(p_norm_text text)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  n integer;
begin
  if not public.is_admin() then
    raise exception 'not authorized';
  end if;
  delete from public.scan_events
   where norm_text = p_norm_text and hit = false;
  get diagnostics n = row_count;
  return n;
end
$$;

grant execute on function public.admin_delete_scan_gap(text) to authenticated;
