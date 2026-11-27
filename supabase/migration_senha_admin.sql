-- =============================================================================
-- Senha de acesso à edição das OS, guardada no banco (bcrypt).
-- Execute no SQL Editor do Supabase. Pode ser executado mais de uma vez.
-- A senha NUNCA aparece no código: a tabela não é legível pela chave pública.
-- =============================================================================

create extension if not exists pgcrypto with schema extensions;

create table if not exists public.admin_auth (
  id            boolean primary key default true check (id),
  password_hash text not null,
  updated_at    timestamptz not null default now()
);

alter table public.admin_auth enable row level security;
revoke all on public.admin_auth from anon, authenticated;

-- Confere a senha digitada (retorna true ou false)
create or replace function public.check_admin_password(p_password text)
returns boolean
language sql
security definer
set search_path = public, extensions
as $$
  select exists (
    select 1 from public.admin_auth a
    where a.id and a.password_hash = extensions.crypt(p_password, a.password_hash)
  );
$$;

-- Troca a senha (exige a senha atual)
create or replace function public.change_admin_password(p_current text, p_new text)
returns boolean
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  if length(coalesce(p_new, '')) < 6 then
    raise exception 'A senha precisa ter pelo menos 6 caracteres.';
  end if;
  if not public.check_admin_password(p_current) then
    return false;
  end if;
  update public.admin_auth
     set password_hash = extensions.crypt(p_new, extensions.gen_salt('bf')),
         updated_at = now()
   where id;
  return true;
end;
$$;

revoke all on function public.check_admin_password(text) from public;
revoke all on function public.change_admin_password(text, text) from public;
grant execute on function public.check_admin_password(text) to anon, authenticated;
grant execute on function public.change_admin_password(text, text) to anon, authenticated;

-- -----------------------------------------------------------------------------
-- DEFINIR A SENHA PELA PRIMEIRA VEZ (rode UMA vez, trocando a senha abaixo):
--
--   insert into public.admin_auth (id, password_hash)
--   values (true, extensions.crypt('SUA_SENHA_AQUI', extensions.gen_salt('bf')))
--   on conflict (id) do update set password_hash = excluded.password_hash;
-- -----------------------------------------------------------------------------
