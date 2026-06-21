# Ranking Semanal — Tasks

**Design:** `.specs/features/ranking-semanal/design.md`
**Spec:** `.specs/features/ranking-semanal/spec.md`
**Testing:** `.specs/codebase/TESTING.md` (Minitest)
**Status:** ✅ DONE — T1 · T2 · T3 · T4 (2026-06-14)
**Baseline:** 61 → **79 testes** (T1+6 unit · T2+7 unit · T3+3 integ · T4+3 integ; full c/ system)

---

## Execution Plan

### Fase 1: Dados (Sequential)

```
T1 (GameResult: fuso + agregação por janela) → T2 (Quiz::Leaderboard: períodos + email mascarado)
```

### Fase 2: UI + fluxo (Parallel após T2)

```
T2 → T3 [ranking: controller + toggle + lista + integração]
T2 → T4 [nickname uma vez]   (T4 não depende de T3; ambos dependem do contexto de T2/home)
```

> T3 e T4 tocam arquivos diferentes (T3: ranking/*, controller de ranking; T4: matches/_home,
> matches_controller, nicknames). Podem ir em paralelo; num executor único, ordem T3→T4.

---

## Task Breakdown

### T1: Fuso `America/Sao_Paulo` + agregação por janela no `GameResult`

**What:** Fixar o fuso do app e adicionar `GameResult.leaderboard(window:, limit:)` que soma
`score` por usuário, filtrando por uma janela de `played_at` (ou tudo, se `nil`), com
`nickname` e `email` para exibição. Ordena por total desc, `user_id` como desempate.
**Where:**
- `config/application.rb` (`config.time_zone`)
- `app/models/game_result.rb`
- `test/models/game_result_test.rb` (novo/estender)
**Depends on:** None
**Reuses:** `played_at` + índice `[user_id, played_at]`; `belongs_to :user`
**Requirement:** RANKW-02, RANKW-03, RANKW-04, RANKW-05, RANKW-12

**Done when:**
- [ ] `config.time_zone = "America/Sao_Paulo"` (armazenamento segue `:utc`)
- [ ] `GameResult.leaderboard(window: nil, limit: 50)` agrega `SUM(score) AS total_score`,
      `COUNT(*) AS plays`, expõe `user_id`, `nickname`, `email`; ordena `SUM DESC, user_id ASC`
- [ ] `window` aplicado como `where(played_at: window)` só quando presente
- [ ] Testes unitários cobrem:
  - janela semanal: 2 partidas do mesmo usuário → 1 linha, `total_score` somado, `plays == 2`
  - partida fora da janela (semana anterior, via `played_at`) → não entra
  - `window: nil` → considera todas as partidas (futuro "geral")
  - ordenação por total desc entre dois usuários
  - janela vazia → relação vazia
  - fronteira `beginning_of_week` em `America/Sao_Paulo` (congelar relógio numa segunda)
- [ ] Regressão da energia OK (fuso não quebra `Quiz::Energy`/`User`): suíte verde
- [ ] Gate passa: `bin/rails test`
- [ ] Test count: 61 + ~6 = **~67 testes**

**Tests:** unit · **Gate:** quick
**Commit:** `feat(ranking): fuso BR + agregação por janela no GameResult`

---

### T2: PORO `Quiz::Leaderboard` — registro de períodos + email mascarado

**What:** Criar `Quiz::Leaderboard` com o registro `PERIODS` (só `:weekly` ativo; mensal/geral
comentados), `Entry` uniforme e o mascaramento de email. `for(period_key)` devolve a lista de
entries prontas para a view.
**Where:**
- `app/models/quiz/leaderboard.rb`
- `test/models/quiz/leaderboard_test.rb`
**Depends on:** T1
**Reuses:** `GameResult.leaderboard` (T1); padrão PORO de `Quiz::Energy`
**Requirement:** RANKW-06, RANKW-08, RANKW-09

**Done when:**
- [ ] `Period = Struct(:key, :label, :window)`; `PERIODS` com `:weekly`
      (`window: ->(now){ now.beginning_of_week.. }`) e mensal/geral **comentados** com nota
      "ligar = 1 linha"
- [ ] `Entry = Struct(:rank, :user_id, :nickname, :masked_email, :value, :detail)`
- [ ] `periods`, `find_period(key)` (default = 1º; chave inválida cai no default)
- [ ] `for(period_key, now:, limit: 50)` → entries: `value = total_score`,
      `detail = "#{plays} partida(s)"`, `nickname` ou "Anônimo", `rank` 1..N
- [ ] `mask_email(email)` → `"#{local[0]}***@#{domain}"`; vazio → ""; local de 1 char ainda oculta
- [ ] Testes unitários cobrem:
  - `for(:weekly)` soma por usuário e numera `rank`
  - `detail` no singular/plural ("1 partida" / "2 partidas")
  - `nickname` ausente → "Anônimo"
  - `mask_email`: `daniel@gmail.com → d***@gmail.com`; `a@x.com → a***@x.com`; vazio → ""
  - `find_period("invalido")` → período default (weekly)
- [ ] Gate passa: `bin/rails test`
- [ ] Test count: ~67 + ~5 = **~72 testes**

**Tests:** unit · **Gate:** quick
**Commit:** `feat(ranking): Quiz::Leaderboard — períodos plugáveis + email mascarado`

---

### T3: Ranking por período — controller + toggle automático + lista + integração

**What:** `RankingController#index` seleciona o período (`params[:period]`, default 1º) e monta
`@entries` via `Quiz::Leaderboard`. View ganha toggle automático (só com >1 período), parcial de
lista com nickname + email mascarado + "(você)", e estado vazio. Aposenta a listagem por
partida; atualiza os testes do ranking.
**Where:**
- `app/controllers/ranking_controller.rb` (modificar)
- `app/views/ranking/index.html.erb` (toggle + estado vazio + render do parcial)
- `app/views/ranking/_ranking_list.html.erb` (novo)
- `app/assets/stylesheets/torcedor_maluco.css` (estilo do toggle/linha, se necessário)
- `test/integration/ranking_test.rb` (atualizar p/ o modelo por período)
**Depends on:** T2
**Reuses:** `ranking_path`; CTA de login; estilos hi-fi
**Requirement:** RANKW-01, RANKW-07, RANKW-10, RANKW-11

**Done when:**
- [ ] `#index`: `@periods`, `@period = find_period(params[:period])`, `@entries = for(@period.key)`
- [ ] Toggle renderiza **só quando `@periods.size > 1`**, aba ativa destacada,
      links `ranking_path(period: p.key)`
- [ ] `_ranking_list.html.erb`: `entry.rank` (medalha/posição), `entry.nickname`,
      `entry.masked_email`, `entry.value`, `entry.detail`, destaque "(você)" por `entry.user_id`
- [ ] Estado vazio "Nenhum resultado nesta semana ainda"; CTA de convidado preservado
- [ ] Testes de integração:
  - `GET /ranking` → 200, lista do período semanal (fixtures dentro da semana)
  - usuário com 2 partidas na semana → aparece 1× com total somado
  - exibe email **mascarado**, nunca o completo (`assert_no_match` do email cru)
  - sem partidas na janela → estado vazio (sem erro)
  - convidado → vê a lista + CTA de login
- [ ] Gate passa: `bin/rails test:all`
- [ ] Test count: ~72 + ~4 = **~76 testes**

**Tests:** integration · **Gate:** full
**Commit:** `feat(ranking): ranking semanal por período (toggle automático + email mascarado)`

---

### T4: Nickname digitado uma única vez (logado + convidado) + "Mudar apelido"

**What:** Parar de pedir o apelido a cada rodada. Logado usa o `nickname` do cadastro e tem
"Mudar apelido" (reaproveita `nicknames#new`/`create`). Convidado informa uma vez, guardado em
`session[:nickname]` e reutilizado; troca por ação explícita.
**Where:**
- `app/views/matches/_home.html.erb` (campo condicional + links)
- `app/controllers/matches_controller.rb` (`#start` resolve o apelido)
- `config/routes.rb` (opcional: `get /nickname/edit` → `nicknames#new`)
- `app/views/nicknames/new.html.erb` (rótulo de edição, se editando)
- `test/integration/` (novo/estender — fluxo de nickname e start)
**Depends on:** T2 (contexto de home/ranking; sem dependência de código)
**Reuses:** `nicknames_controller` (`new`/`create` já fazem create+update); `session`
**Requirement:** NICK-01, NICK-02, NICK-03, NICK-04

**Done when:**
- [ ] Home **logado**: sem campo de apelido; mostra "Olá, {nickname}!", "Jogar agora" e link
      **"Mudar apelido"** → `new_nickname_path`
- [ ] Home **convidado com `session[:nickname]`**: sem campo; "Jogando como {apelido}" +
      "Jogar agora" + link **"Trocar apelido"** (`root_path(edit_nick: 1)` reabre o campo)
- [ ] Home **convidado sem apelido** (ou `params[:edit_nick]`): mostra o campo uma vez
- [ ] `#start`: logado usa `current_user.nickname`; convidado usa/persiste `session[:nickname]`
      (`params[:nickname].presence || session[:nickname]`)
- [ ] Testes de integração:
  - logado: `POST /match/start` sem `nickname` usa o nickname do cadastro na partida
  - logado: home não tem campo de apelido, tem link "Mudar apelido"
  - convidado: 1º start com `nickname` salva em `session[:nickname]`; 2º start sem `nickname`
    reutiliza o da sessão
- [ ] Gate passa: `bin/rails test:all`
- [ ] Test count: ~76 + ~3 = **~79 testes**

**Tests:** integration · **Gate:** full
**Commit:** `feat(nickname): apelido digitado uma única vez + opção mudar apelido`

---

## Sincronização de specs (parte do PR)

- [ ] `spec.md`/`tasks.md`: marcar RANKW-01..12 e NICK-01..04 e T1–T4 como Done ao concluir.
- [ ] `ROADMAP.md`: mover **Ranking semanal** para DONE ✅; nota de que o ranking geral por
      partida foi substituído pelo modelo por período (geral agregado fica pronto p/ ligar);
      corrigir o cabeçalho (`Status:` ainda diz "Energia em Specify").
- [ ] `STATE.md`: registrar fuso `America/Sao_Paulo`, métrica semanal (SUM), email mascarado,
      nickname uma vez, e a arquitetura de períodos plugáveis.

---

## Validação Pré-Aprovação

### Check 1 — Granularidade

| Task | Escopo | Status |
|------|--------|--------|
| T1 | fuso + agregação por janela no GameResult + unit | ✅ coeso (dados) |
| T2 | 1 PORO (registro de períodos + máscara) + unit | ✅ coeso |
| T3 | controller + toggle/lista + integração | ✅ coeso (UI/fluxo do ranking) |
| T4 | nickname uma vez (home + start + edição) + integração | ✅ coeso (concern de nickname) |

### Check 2 — Diagrama × Dependências

| Task | Depends on | Status |
|------|-----------|--------|
| T1 | None | ✅ |
| T2 | T1 | ✅ |
| T3 | T2 | ✅ |
| T4 | T2 (contexto) | ✅ |

### Check 3 — Co-localização de testes (matriz TESTING.md)

| Task | Camada | Matriz exige | Task diz | Status |
|------|--------|--------------|----------|--------|
| T1 | Model (recorte/agregação) | unit | unit | ✅ |
| T2 | Lógica de apresentação (PORO) | unit | unit | ✅ |
| T3 | Controller (fluxo de ranking) | integration | integration | ✅ |
| T4 | Controller (fluxo de partida/nickname) | integration | integration | ✅ |

> Sem system test: ranking e nickname são fluxos cobertos por integração (o ranking geral
> anterior shipou só com integração). Um system test do toggle pode entrar depois, se desejado.

---

## Pergunta antes de Executar (MCPs e Skills)

- **Todas as tasks:** apenas ferramentas nativas de edição + Bash (`bin/rails`); sem MCP externo.
- Commits atômicos por tarefa, em branch nova (`plan/ranking-semanal`), depois PR.
