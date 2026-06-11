# Quiz MVP — Tasks

**Design**: `.specs/features/quiz-mvp/design.md`
**Testing**: `.specs/codebase/TESTING.md` (Minitest — confirmar)
**Status**: Draft

---

## Execution Plan

### Phase 1: Fundação (Sequential)

```
T1
```

### Phase 2: Dados (Sequential → Parallel)

```
T1 → T2 → T3 ──┬→ T4 [P]
               └→ T5 [P]
```

### Phase 3: Partida e telas

```
T5 → T6 ──┬→ T7 [P] → T8 [P]
          └→ T9 [P] → T10 [P]
T7, T9 → T11
```

---

## Task Breakdown

### T1: Inicializar app Rails (Postgres + Hotwire + Tailwind)

**What**: Criar o projeto Rails 7+ configurado com PostgreSQL, Hotwire e Tailwind.
**Where**: raiz do repo `crazy-fan/`
**Depends on**: None
**Reuses**: geradores do Rails
**Requirement**: (base de todos)

**Tools**: MCP: NONE · Skill: NONE

**Done when**:
- [x] `rails new . -d postgresql --css tailwind` executado; app sobe com `bin/dev`
- [x] Hotwire (turbo-rails, stimulus-rails) presente no Gemfile
- [x] `bin/rails db:create` funciona
- [x] Tag viewport mobile presente no layout

**Tests**: none · **Gate**: build
**Commit**: `chore: inicializa app Rails com Postgres, Hotwire e Tailwind`

---

### T2: Model Question

**What**: Model `Question` (tema, dificuldade, enunciado) com validação de unicidade e de "exatamente uma alternativa correta".
**Where**: `app/models/question.rb`, migration, `test/models/question_test.rb`
**Depends on**: T1
**Reuses**: `rails g model`
**Requirement**: QUIZ-06, QUIZ-07

**Tools**: MCP: NONE · Skill: NONE

**Done when**:
- [x] Migration cria tabela `questions`
- [x] Validações: enunciado presente e único; `exactly_one_correct_answer`
- [x] Teste unit cobre válido / inválido (0 ou 2 corretas)
- [x] Gate passa: `bin/rails test`
- [x] Test count: 5 testes passam

**Tests**: unit · **Gate**: quick
**Commit**: `feat(quiz): model Question com validações`

---

### T3: Model Answer

**What**: Model `Answer` (texto, correta:boolean, fonte) com `belongs_to :question`.
**Where**: `app/models/answer.rb`, migration, `test/models/answer_test.rb`
**Depends on**: T2
**Reuses**: `rails g model`
**Requirement**: QUIZ-06

**Tools**: MCP: NONE · Skill: NONE

**Done when**:
- [x] Migration cria `answers` com FK para questions
- [x] Validação de presença de texto
- [x] Teste unit do vínculo e validação
- [x] Gate passa: `bin/rails test`
- [x] Test count: 3 testes passam

**Tests**: unit · **Gate**: quick
**Commit**: `feat(quiz): model Answer vinculado a Question`

---

### T4: Seed importer da planilha mestre [P]

**What**: Importar perguntas válidas de `banco-perguntas-torcedor-maluco.xlsx` para o banco, sem duplicar.
**Where**: `db/seeds.rb` (+ `lib/import/questions_importer.rb`), `test/models/questions_importer_test.rb`
**Depends on**: T2, T3
**Reuses**: gem `roo`; models Question/Answer
**Requirement**: QUIZ-06, QUIZ-07

**Tools**: MCP: NONE · Skill: `torcedor-maluco` (fonte/manutenção da planilha)

**Done when**:
- [ ] Lê o `.xlsx` e cria Question + 4 Answers (1 correta) por linha
- [ ] Pula linhas inválidas e loga
- [ ] Upsert por enunciado — rodar 2x não duplica
- [ ] Teste unit com planilha de exemplo (válida + inválida)
- [ ] Gate passa: `bin/rails test`
- [ ] Test count: 3+ testes passam

**Tests**: unit · **Gate**: quick
**Commit**: `feat(quiz): importa perguntas da planilha mestre via seed`

---

### T5: GamesController#create — iniciar partida [P]

**What**: Sortear 5 perguntas distintas, iniciar estado na sessão (ids, índice=0, score=0) e renderizar a 1ª.
**Where**: `app/controllers/games_controller.rb`, rota, `test/integration/game_flow_test.rb`
**Depends on**: T2, T3
**Reuses**: sessão do Rails; controller RESTful
**Requirement**: QUIZ-01, QUIZ-04

**Tools**: MCP: NONE · Skill: NONE

**Done when**:
- [ ] `POST /games` sorteia 5 ids distintos e salva na sessão
- [ ] Renderiza a 1ª pergunta com 4 alternativas
- [ ] Banco com <5 perguntas → renderiza aviso (sem erro 500)
- [ ] Teste integration cobre início e o caso <5
- [ ] Gate passa: `bin/rails test`
- [ ] Test count: 2+ testes passam

**Tests**: integration · **Gate**: full
**Commit**: `feat(quiz): inicia partida sorteando 5 perguntas`

---

### T6: GamesController#answer — responder, pontuar, avançar (Turbo)

**What**: Receber alternativa (ou timeout), somar acerto, avançar índice e responder via Turbo com a próxima pergunta ou o resultado.
**Where**: `app/controllers/games_controller.rb` (modificar), `test/integration/game_flow_test.rb`
**Depends on**: T5
**Reuses**: Turbo Streams
**Requirement**: QUIZ-02, QUIZ-03, QUIZ-05

**Tools**: MCP: NONE · Skill: NONE

**Done when**:
- [ ] Resposta correta soma +1; errada/timeout soma 0
- [ ] Avança sem recarregar (Turbo); na 5ª, leva ao resultado
- [ ] Pontuação final correta ("X de 5") validada no fluxo
- [ ] Teste integration: 3 certas + 2 erradas → "3 de 5"
- [ ] Gate passa: `bin/rails test`
- [ ] Test count: 3+ testes passam

**Tests**: integration · **Gate**: full
**Commit**: `feat(quiz): registra resposta, pontua e avança via Turbo`

---

### T7: View da pergunta (partial + Turbo frame) [P]

**What**: Partial da pergunta com 4 alternativas tocáveis dentro de um `turbo_frame`.
**Where**: `app/views/games/_question.html.erb`, `_question` frame
**Depends on**: T6
**Reuses**: Tailwind; Turbo
**Requirement**: QUIZ-02, QUIZ-10

**Tools**: MCP: NONE · Skill: NONE

**Done when**:
- [ ] Layout em uma coluna, alternativas como botões grandes (~44px)
- [ ] Envolto em `turbo_frame_tag` para troca sem reload
- [ ] (Verificação visual coberta pelo system test T11)

**Tests**: none · **Gate**: build
**Commit**: `feat(quiz): tela da pergunta mobile-first com turbo frame`

---

### T8: Stimulus timer_controller (cronômetro) [P]

**What**: Cronômetro regressivo por pergunta; ao zerar, submete como "tempo esgotado".
**Where**: `app/javascript/controllers/timer_controller.js`
**Depends on**: T7
**Reuses**: Stimulus
**Requirement**: QUIZ-05

**Tools**: MCP: NONE · Skill: NONE

**Done when**:
- [ ] Mostra contagem (ex.: 15s) e atualiza a cada segundo
- [ ] Ao zerar, envia o form sem alternativa (timeout = erro)
- [ ] Para ao responder antes do tempo
- [ ] (Comportamento validado no system test T11 — cenário de timeout)

**Tests**: none (co-localizado no system test T11) · **Gate**: build
**Commit**: `feat(quiz): cronômetro por pergunta com Stimulus`

---

### T9: Tela de resultado + "jogar de novo" [P]

**What**: View final mostrando "X de 5" e botão de jogar de novo.
**Where**: `app/views/games/result.html.erb`
**Depends on**: T6
**Reuses**: Tailwind
**Requirement**: QUIZ-03, QUIZ-09

**Tools**: MCP: NONE · Skill: NONE

**Done when**:
- [ ] Exibe a pontuação no formato "X de 5"
- [ ] Botão "jogar de novo" inicia nova partida
- [ ] (Fluxo coberto pelo system test T11)

**Tests**: none · **Gate**: build
**Commit**: `feat(quiz): tela de resultado com jogar de novo`

---

### T10: Botão compartilhar resultado [P]

**What**: Botão de compartilhar com texto pronto via Web Share API, com fallback de copiar link.
**Where**: `app/views/games/result.html.erb` (modificar), `app/javascript/controllers/share_controller.js`
**Depends on**: T9
**Reuses**: Stimulus; Web Share API
**Requirement**: QUIZ-08

**Tools**: MCP: NONE · Skill: NONE

**Done when**:
- [ ] Texto: "Fiz X de 5 no Torcedor Maluco, e você?"
- [ ] Usa `navigator.share` no mobile; fallback copia o link
- [ ] (Verificado no system test T11)

**Tests**: none · **Gate**: build
**Commit**: `feat(quiz): compartilhar resultado (Web Share + fallback)`

---

### T11: System test — jogar partida completa no celular

**What**: Teste de sistema (Capybara) que joga uma partida inteira em viewport mobile, incluindo o cenário de timeout, e o "teste do polegar".
**Where**: `test/system/play_quiz_test.rb`
**Depends on**: T7, T9
**Reuses**: Capybara (system tests do Rails)
**Requirement**: QUIZ-01, QUIZ-02, QUIZ-03, QUIZ-05, QUIZ-08, QUIZ-09, QUIZ-10

**Tools**: MCP: NONE · Skill: NONE

**Done when**:
- [ ] Joga 5 perguntas e chega ao resultado "X de 5"
- [ ] Cobre timeout de uma pergunta (vira erro e avança)
- [ ] Cobre "jogar de novo" e o botão compartilhar visível
- [ ] Roda em viewport estreito (mobile)
- [ ] Gate passa: `bin/rails test:all`
- [ ] Test count: 2+ system tests passam

**Tests**: system · **Gate**: full
**Commit**: `test(quiz): system test da partida completa mobile`

---

## Parallel Execution Map

```
Phase 1: T1
Phase 2: T1 → T2 → T3 → { T4 [P], T5 [P] }
Phase 3: T5 → T6 → { T7 [P] → T8 [P] ; T9 [P] → T10 [P] } ; (T7,T9) → T11
```

Restrição: T11 é **system test** (Parallel-Safe: Não) → roda em série, nunca `[P]`.

---

## Validação pré-aprovação

### Check 1 — Granularidade

| Task | Escopo | Status |
| --- | --- | --- |
| T1 | setup do app | ✅ coeso |
| T2 | 1 model | ✅ |
| T3 | 1 model | ✅ |
| T4 | 1 importador | ✅ |
| T5 | 1 action (create) | ✅ |
| T6 | 1 action (answer) | ✅ |
| T7 | 1 partial | ✅ |
| T8 | 1 controller Stimulus | ✅ |
| T9 | 1 view | ✅ |
| T10 | 1 botão/controller | ✅ |
| T11 | 1 system test | ✅ |

### Check 2 — Diagrama × Dependências

| Task | Depends on (corpo) | Diagrama mostra | Status |
| --- | --- | --- | --- |
| T1 | None | — | ✅ |
| T2 | T1 | T1→T2 | ✅ |
| T3 | T2 | T2→T3 | ✅ |
| T4 | T2,T3 | T3→T4 | ✅ |
| T5 | T2,T3 | T3→T5 | ✅ |
| T6 | T5 | T5→T6 | ✅ |
| T7 | T6 | T6→T7 | ✅ |
| T8 | T7 | T7→T8 | ✅ |
| T9 | T6 | T6→T9 | ✅ |
| T10 | T9 | T9→T10 | ✅ |
| T11 | T7,T9 | T7,T9→T11 | ✅ |

Tarefas `[P]` no mesmo nível (T4/T5; T7/T9; T8/T10) não dependem entre si. ✅

### Check 3 — Co-localização de testes (matriz TESTING.md)

| Task | Camada criada | Matriz exige | Task diz | Status |
| --- | --- | --- | --- | --- |
| T2 | Model | unit | unit | ✅ |
| T3 | Model | unit | unit | ✅ |
| T4 | Seed import | unit | unit | ✅ |
| T5 | Controller | integration | integration | ✅ |
| T6 | Controller + pontuação | integration | integration | ✅ |
| T7 | View estática | none | none | ✅ |
| T8 | JS (Stimulus) | none* | none | ✅ |
| T9 | View estática | none | none | ✅ |
| T10 | JS (Stimulus) | none* | none | ✅ |
| T11 | Tela (fluxo) | system | system | ✅ |

\* JS de cliente não está na matriz como unit; o comportamento das telas (T7–T10) é validado pelo **system test T11** — padrão "merge forward" da skill (o teste vive onde se torna executável: o fluxo completo). Não é deferimento indevido.

---

## Pergunta antes de Executar (MCPs e Skills)

A skill pede confirmar, por tarefa, quais ferramentas usar. Proposta:

- **MCP `github`**: para criar o repositório e os commits atômicos por tarefa (opcional).
- **Skill `torcedor-maluco`**: na T4, como fonte/manutenção da planilha mestre de perguntas.
- **Context7 / web**: ao implementar, para confirmar APIs atuais de Hotwire/Turbo/Stimulus (cadeia de verificação de conhecimento).

Demais tarefas: apenas as ferramentas nativas de edição de arquivos.

**Decisão pendente do dono:** confirmar Minitest (vs RSpec), o tempo do cronômetro (15s) e se mostramos a resposta certa ao errar.
