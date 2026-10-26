-- Execute uma vez no SQL Editor do seu projeto BRASIS cultural. Pode repetir.
-- Preserva contas, pontos, missões e conquistas.
begin;
create table if not exists public.cultural_rewards (
 achievement_id text primary key references public.achievements(id),
 name text not null, emoji text not null, profile_title text not null,
 color bigint not null, card_title text not null, card_body text not null,
 source_url text not null
);
alter table public.profiles add column if not exists equipped_reward text
 references public.cultural_rewards(achievement_id);
insert into public.cultural_rewards values
('culture_first','Primeiro embarque','🧭','Viajante curioso',4280572997,'O nome que vem do tambor','O nome carimbó vem do curimbó, o tambor que ocupa o centro das rodas. O nome do instrumento passou a identificar também essa expressão de música e dança.','https://bcr.iphan.gov.br/bens-culturais/carimbo/'),
('culture_region','Um novo olhar','🌿','Olhar de explorador',4280843419,'Uma tradição de muitos encontros','O carimbó reúne influências africanas, indígenas e ibéricas. Música, dança, instrumentos e modos de festejar fazem parte da mesma expressão cultural.','https://bcr.iphan.gov.br/bens-culturais/carimbo/'),
('culture_five','Caçador de histórias','📚','Colecionador de histórias',4291584582,'Uma capa também conta histórias','Muitos folhetos de cordel usam xilogravuras nas capas. As imagens ajudam a apresentar as histórias e dão identidade visual a essa literatura popular.','https://bcr.iphan.gov.br/bens-culturais/literatura-de-cordel/'),
('culture_three','Pé na estrada','☀️','Viajante dos caminhos',4285748384,'A sombrinha entra na dança','No frevo, a sombrinha colorida vai além da decoração: ela auxilia o equilíbrio dos movimentos e faz parte da identidade da dança.','https://bcr.iphan.gov.br/bens-culturais/frevo/'),
('culture_days','Sempre de partida','🎶','Companheiro de jornada',4288368499,'Versos que escondem enigmas','Os cantos do jongo são chamados de pontos e podem ter sentidos enigmáticos. Eles se encontram com os tambores e a dança em roda nessa expressão afro-brasileira.','https://bcr.iphan.gov.br/bens-culturais/jongo-no-sudeste/'),
('culture_all','Muitos Brasis','👑','Guardião de histórias',4288309528,'Patrimônio feito de versos','A literatura de cordel foi registrada como Patrimônio Cultural do Brasil em 19 de setembro de 2018. Sua tradição vive tanto nos folhetos quanto na leitura e na escuta dos versos.','https://bcr.iphan.gov.br/bens-culturais/literatura-de-cordel/')
on conflict(achievement_id) do update set name=excluded.name,emoji=excluded.emoji,
 profile_title=excluded.profile_title,color=excluded.color,card_title=excluded.card_title,
 card_body=excluded.card_body,source_url=excluded.source_url;
alter table public.cultural_rewards enable row level security;
drop policy if exists earned_rewards on public.cultural_rewards;
create policy earned_rewards on public.cultural_rewards for select to authenticated
 using(exists(select 1 from public.user_achievements ua
 where ua.user_id=auth.uid() and ua.achievement_id=cultural_rewards.achievement_id));
revoke all on public.cultural_rewards from anon,authenticated;
grant select on public.cultural_rewards to authenticated;
create or replace function public.equip_cultural_reward(p_reward_id text)
returns void language plpgsql security definer set search_path='' as $$
declare uid uuid := auth.uid();
begin
 if uid is null then raise exception 'Entre na sua conta para personalizar.'; end if;
 if p_reward_id is not null and not exists(
  select 1 from public.cultural_rewards r join public.user_achievements ua
  on ua.achievement_id=r.achievement_id
  where ua.user_id=uid and r.achievement_id=p_reward_id
 ) then raise exception 'Conquiste esta recompensa antes de equipar.'; end if;
 update public.profiles set equipped_reward=p_reward_id where id=uid;
end; $$;
revoke all on function public.equip_cultural_reward(text) from public,anon;
grant execute on function public.equip_cultural_reward(text) to authenticated;
notify pgrst,'reload schema';
commit;
