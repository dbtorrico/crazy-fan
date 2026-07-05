# Roadmap

**Current Milestone:** M2 — Competição e contas
**Status:** In progress (Auth, Ranking, Energia e Ranking semanal entregues)

---

## M1 — Quiz jogável (MVP) ✅ DONE

**Goal:** Um quiz de futebol jogável e compartilhável no celular, no ar e divulgável durante a Copa, sem exigir cadastro.
**Concluído:** 2026-06-13

### Features

**Quiz MVP** - DONE ✅

- Partida de 5 perguntas com 4 alternativas e timer
- Cálculo e exibição de pontuação
- Banco de perguntas vindo da planilha mestre
- Jogar sem cadastro
- Compartilhar resultado
- UI mobile-first (design hi-fi com `torcedor_maluco.css`)

---

## M2 — Competição e contas

**Goal:** Transformar o passatempo solitário em competição social, fidelizando com ranking — o diferencial do produto.

### Features

**Autenticação (Google OAuth)** - DONE ✅ (PR #14, 2026-06-13) — OAuth-only, nickname, `User.from_omniauth`
**Mecânica de energia (5 jogadas/dia)** - DONE ✅ (2026-06-14) — regeneração 2h, gate logado/convidado, indicador ⚡
**Ranking semanal** - DONE ✅ (2026-06-14) — por período (`Quiz::Leaderboard`), soma da semana, fuso BR, email mascarado, nickname uma vez
**Categorias por tema (Copa 2026, História, Seleção, Craques)** - DESCARTADO ❌ (2026-06-28) — não haverá seleção de categoria pelo jogador. O tema fica apenas como metadado no banco (coluna `tema` em `Question`); as partidas seguem sorteando perguntas aleatórias de todos os temas. A infra de filtro (`sample_ids(tema:)`, `category_counts`, `CATEGORIES`) permanece no código, dormente, caso a decisão mude.
**Badges / "Craque da Semana"** - DONE ✅ — 5 conquistas acumuladas, craque_semanal por semana, coroa no ranking, callout no resultado
**Ranking mensal / geral (agregado)** - DONE ✅ — `PERIODS` com `:weekly`, `:monthly`, `:all_time`; toggle automático na view
**Redesign visual (Landing + Ranking + retheme global)** - DONE ✅ (2026-06-23) — Baloo 2 + paleta Copa 2026, Landing com saudação/prova social/Google login, Ranking com pódio 2-1-3 + loginbar, avatares-monograma. 115 testes verdes.

> Nota: o ranking passou a ser **por período agregado** (soma por usuário). O ranking geral
> antigo (por partida) foi substituído por esse modelo; mensal/geral ficam prontos para ligar.

---

## M3 — Monetização

**Goal:** Ativar receita e caminhar para a meta de R$500/mês.

### Features

**Assinatura R$5/mês via Pix (Mercado Pago)** - DONE ✅ (2026-06-28) — `premium_until` em `users`, `MpGateway` wrapper, `PaymentsController` (create + webhook), tela Pix QR code. Pendente: e2e com sandbox MP.
**Jogadas ilimitadas para assinantes** - DESCARTADO — decisão: benefício do premium é acesso ao ranking competitivo; energia permanece limitada para todos (5 jogadas/dia). Badge no header e CTA de conversão entregues como parte da feature de assinatura.
**Remoção de anúncios no premium** - PLANNED (aguarda AdSense)
**Integração com Google AdSense (nível gratuito)** - PLANNED (requer páginas institucionais primeiro)

---

## M3.5 — Qualidade e Experiência

**Goal:** Polir a experiência do jogador frequente: onboarding com regras claras, conteúdo de perguntas correto (siglas explícitas, verbos no tempo certo) e redução de repetição de perguntas.

### Features

**Página "Regras do Jogo"** - DONE ✅ (PR #27, 2026-07-04) — Rota `/rules`, `RulesController`, view com pontuação (60 pts + bônus velocidade até 40 pts), timer 15s, energia, badges. Link "Como funciona?" na home e no resultado. Bônus: páginas institucionais `/about`, `/privacy`, `/terms` + footer + script de verificação AdSense.

**Qualidade de conteúdo: siglas** - IN PROGRESS — Rake task `content:check_acronyms` implementada; gera CSV de candidatos em `tmp/acronyms_candidates.csv`. Siglas que recebem explicação entre parênteses: CBF, UEFA, CONMEBOL, CONCACAF, CAF, AFC, OFC, IFFHS, FPF. Mantidas sem explicação: FIFA, VAR. Pendente: revisão manual do CSV → migration de dados.

**Qualidade de conteúdo: tempo verbal 2026** - IN PROGRESS — Rake task `content:check_future_tense` implementada; gera CSV com sugestão de reescrita para o presente em `tmp/future_tense_candidates.csv`. Pendente: revisão manual do CSV → migration de dados.

**Anti-repetição de perguntas por jogador** - DONE ✅ (PR #27, 2026-07-04) — `question_ids` (jsonb) em `game_results`; ao iniciar partida, exclui IDs vistos nos últimos 10 jogos do usuário logado via `exclude_ids` em `Quiz::Question.sample_ids`. Fallback para pool completo quando o pool filtrado é insuficiente. Guests: sem mudança.

> Ver especificação detalhada em `.specs/features/polimento-qualidade/`.

---

## M4 — Sustentação pós-Copa

**Goal:** Manter tráfego e receita depois de julho.

### Features

**Temas perenes de futebol (Brasileirão, Champions)** - PLANNED
**Conteúdo editorial para SEO/AdSense** - PLANNED
**Otimização de conversão free → premium** - PLANNED

---

## Future Considerations

- Desafio direto entre amigos (link de duelo)
- Imagem de resultado gerada automaticamente para compartilhar
- Prêmios patrocinados (com validação jurídica)
