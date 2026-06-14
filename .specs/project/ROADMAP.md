# Roadmap

**Current Milestone:** M2 — Competição e contas
**Status:** In progress (Auth + Ranking entregues; Energia em Specify)

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
**Ranking (geral)** - DONE ✅ (`ranking_controller.rb`, rota `/ranking`)
**Mecânica de energia (5 jogadas/dia)** - IN PROGRESS 🔨 (Specify — 2026-06-14)
**Categorias por tema (Copa 2026, História, Seleção, Craques)** - PLANNED
**Badges / "Craque da Semana"** - PLANNED
**Ranking semanal** - PLANNED

> Nota: ranking semanal e badges foram separados do ranking geral (já entregue).

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
