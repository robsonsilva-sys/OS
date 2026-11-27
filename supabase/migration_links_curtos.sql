-- =============================================================================
-- Links curtos de acompanhamento do cliente (r.html?c=CODIGO -> cliente.html)
-- Execute no SQL Editor do Supabase. Pode ser executado mais de uma vez.
-- =============================================================================

create table if not exists public.short_links (
  code          text primary key,
  order_number  text not null,
  pin           text not null,
  created_at    timestamptz not null default now()
);

create index if not exists idx_short_links_os on public.short_links (order_number, pin);

alter table public.short_links enable row level security;
revoke all on public.short_links from anon, authenticated;

-- Gera (ou reaproveita) o código curto de uma OS
create or replace function public.create_short_link(p_order_number text, p_pin text)
returns text
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  alfabeto constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  v_code text;
  v_existing text;
begin
  select code into v_existing
    from public.short_links
   where order_number = p_order_number and pin = p_pin
   limit 1;
  if v_existing is not null then
    return v_existing;
  end if;

  loop
    v_code := '';
    for i in 1..6 loop
      v_code := v_code || substr(alfabeto, 1 + floor(random() * length(alfabeto))::int, 1);
    end loop;
    begin
      insert into public.short_links (code, order_number, pin) values (v_code, p_order_number, p_pin);
      return v_code;
    exception when unique_violation then
      -- código repetido: tenta outro
    end;
  end loop;
end;
$$;

-- Resolve o código para número da OS e PIN
create or replace function public.resolve_short_link(p_code text)
returns table (order_number text, pin text)
language sql
security definer
set search_path = public
as $$
  select s.order_number, s.pin
    from public.short_links s
   where s.code = upper(p_code)
   limit 1;
$$;

revoke all on function public.create_short_link(text, text) from public;
revoke all on function public.resolve_short_link(text) from public;
grant execute on function public.create_short_link(text, text) to anon, authenticated;
grant execute on function public.resolve_short_link(text) to anon, authenticated;
