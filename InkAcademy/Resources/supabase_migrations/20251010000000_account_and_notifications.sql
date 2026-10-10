-- Hesap silme talebi + bildirim tercihleri (profiles genişletmesi)
alter table public.profiles
    add column if not exists username text,
    add column if not exists deletion_requested boolean not null default false,
    add column if not exists deleted_at timestamptz,
    add column if not exists notify_announcements boolean not null default true,
    add column if not exists notify_homework boolean not null default true,
    add column if not exists notify_messages boolean not null default true;

-- Destek mesajları (Bize Ulaş — isteğe bağlı sunucu kaydı)
create table if not exists public.support_tickets (
    id         uuid primary key default gen_random_uuid(),
    user_id    text references public.profiles(id) on delete set null,
    email      text not null,
    message    text not null,
    status     text not null default 'open',
    created_at timestamptz not null default now()
);

alter table public.support_tickets enable row level security;

create policy "Users can insert own support tickets"
    on public.support_tickets for insert
    with check (auth.uid()::text = user_id or user_id is null);

create policy "Users can read own support tickets"
    on public.support_tickets for select
    using (auth.uid()::text = user_id);
