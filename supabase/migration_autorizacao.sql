-- =============================================================================
-- Autorização do serviço pelo cliente (página cliente.html)
-- Execute no SQL Editor do Supabase. Pode ser executado mais de uma vez.
-- =============================================================================

alter table public.orders add column if not exists authorized_at timestamptz;
alter table public.orders add column if not exists authorized_by text not null default '';

create index if not exists idx_orders_authorized_at on public.orders (authorized_at);

-- As permissões já existentes (anon/authenticated) cobrem as novas colunas.
-- Confira:
select column_name, data_type
from information_schema.columns
where table_schema = 'public' and table_name = 'orders'
  and column_name in ('authorized_at', 'authorized_by');
