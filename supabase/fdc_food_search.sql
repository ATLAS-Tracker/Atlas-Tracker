-- Accent-insensitive, typo-tolerant search on generic foods (fdc_food).
-- Apply this in Supabase SQL editor: the app calls search_fdc_food() and
-- shows no generic foods until it exists.

create extension if not exists unaccent with schema extensions;
create extension if not exists pg_trgm with schema extensions;

-- unaccent() is only STABLE; the wrapper lets it be used in ordering/indexes.
create or replace function public.immutable_unaccent(value text)
returns text
language sql
immutable
parallel safe
strict
as $$
  select extensions.unaccent('extensions.unaccent'::regdictionary, value)
$$;

-- Matches "pate" -> "Pâte", "pome" -> "Pomme", "boeuf" -> "Bœuf".
-- Ranked: label starting with the search, then word similarity, then shortest.
-- ponytail: sequential scan, add a GIN trigram index on the folded label if
-- fdc_food grows past a few tens of thousands of rows.
-- French only: the production fdc_food table has no other description column.
create or replace function public.search_fdc_food(search text)
returns setof public.fdc_food
language sql
stable
set search_path = public, extensions
as $$
  select f.*
  from public.fdc_food f,
    lateral (
      select public.immutable_unaccent(lower(replace(trim(search), 'œ', 'oe'))) as term
    ) q,
    lateral (
      select public.immutable_unaccent(
        lower(replace(coalesce(f.description_fr, ''), 'œ', 'oe'))) as label
    ) l
  where l.label like '%' || q.term || '%'
     or q.term <% l.label
  order by l.label like q.term || '%' desc,
    word_similarity(q.term, l.label) desc,
    length(l.label)
$$;

grant execute on function public.search_fdc_food(text) to anon, authenticated;
