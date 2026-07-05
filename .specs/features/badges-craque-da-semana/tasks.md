# Tasks — Badges & Craque da Semana

**Spec:** spec.md  
**Gate rápido:** `bin/rails test`  
**Gate completo:** `bin/rails test:all`

---

## T1 — Migration: tabela `user_achievements` · [BAD-01, BAD-02, BAD-03]

**O que:** Criar migration com `user_id`, `badge_key`, `week` (default `""`), `earned_at`, e índice único em `(user_id, badge_key, week)`. Adicionar `has_many :user_achievements` no `User`.  
**Onde:** `db/migrate/`, `app/models/user.rb`  
**Depende de:** —  
**Done when:** `bin/rails db:migrate` roda sem erro; `User.first.user_achievements` não lança exceção  
**Testes:** nenhum (migration pura)  
**Gate:** `bin/rails db:migrate && bin/rails db:migrate:status`

---

## T2 — Model `UserAchievement` + `Quiz::Badge` catalog · [BAD-01..BAD-09]

**O que:**
- `UserAchievement < ApplicationRecord`: `belongs_to :user`, validações básicas
- `Quiz::Badge` PORO: constante `CATALOG` (array de `{key, emoji, label}`), método `award!(user:, key:, week: "")` (find_or_create + retorna novo registro ou nil), método `check_and_award!(user, game_result)` → avalia os 5 badges e retorna array com recém-concedidos  
**Onde:** `app/models/user_achievement.rb`, `app/models/quiz/badge.rb`  
**Depende de:** T1  
**Reutiliza:** padrão PORO de `Quiz::Energy`, `Quiz::Leaderboard`  
**Done when:** `Quiz::Badge.check_and_award!(user, result)` retorna badges corretos para cada condição  
**Testes:** `test/models/quiz/badge_test.rb` — 7 casos unitários (one per badge + retorno vazio se já concedido + craque_semanal por semana)  
**Gate:** `bin/rails test test/models/quiz/badge_test.rb`

---

## T3 — Wire-up no controller · [BAD-10]

**O que:** Em `MatchesController`, logo após salvar o `GameResult` (onde `match.finished?`), chamar `newly_earned = Quiz::Badge.check_and_award!(current_user, result)` se `user_signed_in?`. Verificar se usuário é #1 semanal (`is_craque`). Passar ambos para a view via instância ou locals.  
**Onde:** `app/controllers/matches_controller.rb`  
**Depende de:** T2  
**Done when:** Ao terminar partida logado, controller não lança erro; `@newly_earned` e `@is_craque` disponíveis na view  
**Testes:** `test/integration/matches_flow_test.rb` ou arquivo novo — 2 casos: convidado termina sem erro; logado recebe `@newly_earned`  
**Gate:** `bin/rails test`

---

## T4 — Tela de resultado: badges conquistados + callout Craque · [BAD-11, BAD-12]

**O que:** Em `_result.html.erb`, adicionar:
1. Bloco condicional "Conquistas desbloqueadas 🎉" com emoji+label de cada badge em `@newly_earned`
2. Callout "🏆 Craque da Semana!" se `@is_craque`
CSS: `.badge-strip`, `.badge-chip`, `.craque-callout` (inline no `torcedor_maluco.css`)  
**Onde:** `app/views/matches/_result.html.erb`, `app/assets/stylesheets/torcedor_maluco.css`  
**Depende de:** T3  
**Done when:** Tela de resultado exibe badges e callout quando aplicável; nada renderiza quando vazio  
**Testes:** nenhum (partial estática conforme TESTING.md)  
**Gate:** `bin/rails test`

---

## T5 — Ranking: coroa no #1 semanal + ícones de badge · [BAD-13, BAD-14, BAD-15]

**O que:**
- `Quiz::Leaderboard::Entry` ganha campo `badges` (array de `{emoji, label}`)
- `Quiz::Leaderboard.for` carrega badges de todos os entries em batch (1 query) e popula o campo
- `_ranking_list.html.erb`: exibe 👑 antes do nickname na linha de rank 1 (só no período `:weekly`); exibe até 5 ícones de badge por linha  
**Onde:** `app/models/quiz/leaderboard.rb`, `app/views/ranking/_ranking_list.html.erb`, `app/assets/stylesheets/torcedor_maluco.css`  
**Depende de:** T2  
**Done when:** Ranking semanal mostra coroa no #1; badges aparecem; query de leaderboard não dispara N+1  
**Testes:** `test/models/quiz/leaderboard_test.rb` — 2 novos casos: badges presentes no entry; sem N+1 (assert query count)  
**Gate:** `bin/rails test`

---

## Ordem de execução

```
T1 → T2 → T3 → T4
              ↘
         T2 → T5
```

T4 e T5 podem rodar em paralelo após T3 (T4) e T2 (T5).
