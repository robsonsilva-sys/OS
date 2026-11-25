-- =============================================================================
-- RobinhoNetCell — Estrutura do banco no Supabase
-- Execute este arquivo no Supabase: Dashboard > SQL Editor > New query > Run.
-- Pode ser executado mais de uma vez (idempotente).
-- =============================================================================

create extension if not exists pgcrypto;

-- -----------------------------------------------------------------------------
-- CLIENTES
-- -----------------------------------------------------------------------------
create table if not exists public.clients (
  id          text primary key,
  name        text not null default '' check (char_length(trim(name)) > 0),
  phone       text not null default '',
  cpf         text not null default '',
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- -----------------------------------------------------------------------------
-- ORDENS DE SERVIÇO
-- -----------------------------------------------------------------------------
create table if not exists public.orders (
  id              text primary key,
  number          text not null unique,
  client_id       text references public.clients(id) on delete set null,
  client_name     text not null default '',
  client_phone    text not null default '',
  client_cpf      text not null default '',
  device_brand    text not null default '',
  device_model    text not null default '',
  device_color    text not null default '',
  device_imei     text not null default '',
  device_pass     text not null default '',
  pattern         integer[] not null default '{}',
  checklist       text[] not null default '{}',
  defect          text not null default '',
  report          text not null default '',
  parts           text not null default '',
  price           numeric(12,2) not null default 0 check (price >= 0),
  deadline        text not null default '',
  status          text not null default 'Aberta'
                  check (status in ('Aberta','Em Manutenção','Aguardando Peça','Pronta para Retirada','Entregue')),
  paid            boolean not null default false,
  payment_method  text not null default 'PIX',
  paid_amount     numeric(12,2) not null default 0 check (paid_amount >= 0),
  paid_at         timestamptz,
  authorized_at   timestamptz,
  authorized_by   text not null default '',
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

-- -----------------------------------------------------------------------------
-- RECIBOS / PAGAMENTOS (histórico de quitações)
-- -----------------------------------------------------------------------------
create table if not exists public.receipts (
  id        uuid primary key default gen_random_uuid(),
  order_id  text not null references public.orders(id) on delete cascade,
  amount    numeric(12,2) not null check (amount >= 0),
  method    text not null default 'PIX',
  paid_at   timestamptz not null default now()
);

-- -----------------------------------------------------------------------------
-- CONFIGURAÇÕES DA LOJA (linha única)
-- -----------------------------------------------------------------------------
create table if not exists public.shop_settings (
  id            boolean primary key default true check (id),
  store_name    text not null default 'RobinhoNetCell',
  phone         text not null default '',
  address       text not null default '',
  warranty_days integer not null default 90 check (warranty_days > 0),
  updated_at    timestamptz not null default now()
);

insert into public.shop_settings (id) values (true) on conflict (id) do nothing;

-- -----------------------------------------------------------------------------
-- NUMERAÇÃO AUTOMÁTICA DAS OS (sequência no servidor)
-- -----------------------------------------------------------------------------
create sequence if not exists public.os_number_seq as bigint start with 1;

create or replace function public.next_os_number()
returns text
language sql
volatile
as $$
  select 'OS-' || lpad(nextval('public.os_number_seq')::text, 4, '0');
$$;

alter table public.orders alter column number set default public.next_os_number();

-- Chame esta função DEPOIS de importar OS antigas com número explícito,
-- para o servidor continuar a numeração a partir do maior número existente:
--   select public.sync_os_number_seq();
create or replace function public.sync_os_number_seq()
returns bigint
language plpgsql
as $$
declare
  max_n bigint;
begin
  select coalesce(max(nullif(regexp_replace(number, '\D', '', 'g'), '')::bigint), 0)
    into max_n
  from public.orders;
  if max_n < 1 then
    max_n := 1;
  end if;
  perform setval('public.os_number_seq', max_n, true);
  return max_n;
end;
$$;

-- -----------------------------------------------------------------------------
-- updated_at automático
-- -----------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists trg_clients_updated_at on public.clients;
create trigger trg_clients_updated_at
  before update on public.clients
  for each row execute function public.set_updated_at();

drop trigger if exists trg_orders_updated_at on public.orders;
create trigger trg_orders_updated_at
  before update on public.orders
  for each row execute function public.set_updated_at();

drop trigger if exists trg_shop_settings_updated_at on public.shop_settings;
create trigger trg_shop_settings_updated_at
  before update on public.shop_settings
  for each row execute function public.set_updated_at();

-- -----------------------------------------------------------------------------
-- ÍNDICES
-- -----------------------------------------------------------------------------
create index if not exists idx_orders_status on public.orders (status);
create index if not exists idx_orders_created_at on public.orders (created_at desc);
create index if not exists idx_orders_client_phone on public.orders ((regexp_replace(client_phone, '\D', '', 'g')));
create index if not exists idx_orders_client_id on public.orders (client_id);
create index if not exists idx_clients_phone on public.clients ((regexp_replace(phone, '\D', '', 'g')));
create index if not exists idx_receipts_order_id on public.receipts (order_id);

-- -----------------------------------------------------------------------------
-- SEGURANÇA (RLS)
-- -----------------------------------------------------------------------------
alter table public.clients        enable row level security;
alter table public.orders         enable row level security;
alter table public.receipts       enable row level security;
alter table public.shop_settings  enable row level security;

grant select, insert, update, delete on public.clients, public.orders, public.receipts, public.shop_settings to authenticated;
grant usage, select on sequence public.os_number_seq to authenticated;

-- Usuários logados (Supabase Auth) têm acesso total.
drop policy if exists "authenticated_all_clients" on public.clients;
create policy "authenticated_all_clients" on public.clients
  for all to authenticated using (true) with check (true);

drop policy if exists "authenticated_all_orders" on public.orders;
create policy "authenticated_all_orders" on public.orders
  for all to authenticated using (true) with check (true);

drop policy if exists "authenticated_all_receipts" on public.receipts;
create policy "authenticated_all_receipts" on public.receipts
  for all to authenticated using (true) with check (true);

drop policy if exists "authenticated_all_settings" on public.shop_settings;
create policy "authenticated_all_settings" on public.shop_settings
  for all to authenticated using (true) with check (true);

-- -----------------------------------------------------------------------------
-- ACESSO ANÔNIMO (ATIVADO — SEM LOGIN, CONFORME ESCOLHA DO PROJETO)
-- ATENÇÃO: a chave anon fica visível no index.html publicado; qualquer pessoa
-- com o link do site poderá LER E ALTERAR os dados da loja. Para produção com
-- mais segurança, habilite o login (Supabase Auth) e comente este bloco.
-- -----------------------------------------------------------------------------
grant select, insert, update, delete on public.clients, public.orders, public.receipts, public.shop_settings to anon;
grant usage, select, update on sequence public.os_number_seq to anon;
grant execute on function public.next_os_number() to anon;
grant execute on function public.sync_os_number_seq() to anon;

drop policy if exists "anon_all_clients" on public.clients;
create policy "anon_all_clients" on public.clients for all to anon using (true) with check (true);

drop policy if exists "anon_all_orders" on public.orders;
create policy "anon_all_orders" on public.orders for all to anon using (true) with check (true);

drop policy if exists "anon_all_receipts" on public.receipts;
create policy "anon_all_receipts" on public.receipts for all to anon using (true) with check (true);

drop policy if exists "anon_all_settings" on public.shop_settings;
create policy "anon_all_settings" on public.shop_settings for all to anon using (true) with check (true);

-- -----------------------------------------------------------------------------
-- FIM
-- -----------------------------------------------------------------------------
