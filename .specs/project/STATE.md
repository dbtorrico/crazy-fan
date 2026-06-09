# State — Memory

Memória persistente do projeto: decisões, bloqueios, lições, todos e ideias adiadas.

## Decisions

- **Stack: Rails + Hotwire** (não Node+React) — ver ADR-001. Caminho convencional do Rails, melhor para iniciante e prazo curto.
- **Nome:** Torcedor Maluco (pasta de código: `crazy-fan`).
- **Partida = 5 perguntas, 4 alternativas** — jogo rápido e dinâmico, decisão do dono.
- **Banco de perguntas:** planilha mestre `banco-perguntas-torcedor-maluco.xlsx`, gerada/mantida pela skill `torcedor-maluco`, com checagem de duplicatas.
- **Monetização:** assinatura R$5/mês via Pix (Mercado Pago) + AdSense; mecânica de 5 jogadas/dia vira o gancho da assinatura.

## Open Decisions (confirmar)

- **Estratégia de testes:** assumido **Minitest (padrão do Rails)** por ser mais simples para iniciante. Confirmar ou trocar por RSpec antes de executar as tarefas.
- **Domínio:** verificar disponibilidade (ex.: `torcedormaluco.com.br`).

## Blockers

- Nenhum no momento.

## Lessons

- A janela da Copa é curta (~6 semanas): priorizar velocidade de lançamento sobre completude.

## Todos / Deferred

- Importar as perguntas da planilha mestre para o banco (seed) — coberto no Milestone 1.
- Páginas institucionais (Sobre, Privacidade, Termos) para habilitar AdSense — Milestone 3.
