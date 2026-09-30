-- VolleyStats EPS : historique des séries partagé par classe.
--
-- À exécuter une fois dans Supabase : Dashboard > SQL Editor > New query >
-- coller ce fichier > Run. Le script peut être relancé sans risque.
--
-- Principe : il n'y a pas de compte. Le nom de la classe (ex. « 2e1 ») sert
-- de clé : l'appli ne peut lire que les séries d'une classe dont elle connaît
-- le nom. La table n'est jamais accessible directement avec la clé publique
-- (anon) ; tout passe par les trois fonctions ci-dessous.

create table if not exists public.sessions (
  id          text primary key,
  class_key   text not null,          -- nom de classe normalisé (minuscules, espaces simplifiés)
  class_name  text not null,          -- nom de classe tel que saisi
  student     text not null,
  date        timestamptz not null,
  data        jsonb not null,         -- la série complète (Session.toJson())
  updated_at  timestamptz not null default now()
);

create index if not exists sessions_class_key_date_idx on public.sessions (class_key, date desc);

-- RLS activée sans aucune policy : aucun accès direct à la table pour anon.
alter table public.sessions enable row level security;
revoke all on public.sessions from anon, authenticated;

create or replace function public.class_key(p_class text)
returns text
language sql
immutable
as $$
  select lower(regexp_replace(trim(coalesce(p_class, '')), '\s+', ' ', 'g'));
$$;

-- Toutes les séries d'une classe, de la plus récente à la plus ancienne.
create or replace function public.get_class_sessions(p_class text)
returns setof jsonb
language sql
stable
security definer
set search_path = public
as $$
  select data
  from public.sessions
  where class_key = public.class_key(p_class)
    and class_key <> ''
  order by date desc
  limit 1000;
$$;

-- Crée ou met à jour une série. La classe est lue dans la série elle-même.
create or replace function public.upsert_session(p_session jsonb)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_class text := trim(coalesce(p_session->'student'->>'className', ''));
begin
  if public.class_key(v_class) = '' then
    raise exception 'La série doit avoir une classe.';
  end if;
  if coalesce(p_session->>'id', '') = '' then
    raise exception 'La série doit avoir un identifiant.';
  end if;
  if length(p_session::text) > 200000 then
    raise exception 'Série trop volumineuse.';
  end if;

  insert into public.sessions (id, class_key, class_name, student, date, data, updated_at)
  values (
    p_session->>'id',
    public.class_key(v_class),
    v_class,
    coalesce(p_session->'student'->>'name', ''),
    (p_session->>'date')::timestamptz,
    p_session,
    now()
  )
  on conflict (id) do update
    set class_name = excluded.class_name,
        student    = excluded.student,
        date       = excluded.date,
        data       = excluded.data,
        updated_at = now()
    -- une série existante ne peut être modifiée que depuis sa propre classe
    where sessions.class_key = excluded.class_key;
end;
$$;

-- Supprime une série (il faut connaître sa classe).
create or replace function public.delete_session(p_class text, p_id text)
returns void
language sql
security definer
set search_path = public
as $$
  delete from public.sessions
  where id = p_id
    and class_key = public.class_key(p_class);
$$;

revoke all on function public.get_class_sessions(text) from public;
revoke all on function public.upsert_session(jsonb) from public;
revoke all on function public.delete_session(text, text) from public;
grant execute on function public.get_class_sessions(text) to anon, authenticated;
grant execute on function public.upsert_session(jsonb) to anon, authenticated;
grant execute on function public.delete_session(text, text) to anon, authenticated;
