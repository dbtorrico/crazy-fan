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
**Categorias por tema (Copa 2026, História, Seleção, Craques)** - PLANNED
**Badges / "Craque da Semana"** - PLANNED
**Ranking mensal / geral (agregado)** - PLANNED (infra de períodos pronta — ligar = +1 linha em `Quiz::Leaderboard::PERIODS`)

> Nota: o ranking passou a ser **por período agregado** (soma por usuário). O ranking geral
> antigo (por partida) foi substituído por esse modelo; mensal/geral ficam prontos para ligar.

---

## M3 — Monetização

**Goal:** Ativar receita e caminhar para a meta de R$500/mês.

### Features

**Assinatura R$5/mês via Pix (Mercado Pago)** - PLANNED
**Jogadas ilimitadas para assinantes** - PLANNED
**Remoção de anúncios no premium** - PLANNED
**Integração com Google AdSense (nível gratuito)** - PLANNED

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
