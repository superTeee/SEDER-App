-- Founding member-nummer for lanseringskampanjen (første 100 nye brukere).
-- Tidlige testere (is_founding_member = true) står UTENFOR og får null.
alter table public.profiles add column if not exists member_number int;

create sequence if not exists public.founding_member_seq;

create or replace function public.claim_founding_number()
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_num int;
  v_founding boolean;
begin
  if v_uid is null then return null; end if;
  select member_number, is_founding_member into v_num, v_founding
    from profiles where id = v_uid;
  if coalesce(v_founding, false) then return null; end if;
  if v_num is not null then return v_num; end if;
  v_num := nextval('public.founding_member_seq');
  update profiles set member_number = v_num where id = v_uid;
  return v_num;
end;
$$;

grant execute on function public.claim_founding_number() to authenticated;
