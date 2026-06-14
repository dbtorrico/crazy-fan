# State — Memory

Memória persistente do projeto: decisões, bloqueios, lições, todos e ideias adiadas.

## Decisions

- **Stack: Rails + Hotwire** (não Node+React) — ver ADR-001. Caminho convencional do Rails, melhor para iniciante e prazo curto.
- **Nome:** Torcedor Maluco (pasta de código: `crazy-fan`).
- **Partida = 5 perguntas, 4 alternativas** — jogo rápido e dinâmico, decisão do dono.
- **Banco de perguntas:** planilha mestre `banco-perguntas-torcedor-maluco.xlsx`, gerada/mantida pela skill `torcedor-maluco`, com checagem de duplicatas.
- **Monetização:** assinatura R$5/mês via Pix (Mercado Pago) + AdSense; mecânica de 5 jogadas/dia vira o gancho da assinatura.
- **Auth: OAuth-only (Google)** — sem senha, sem registro próprio. Devise com apenas `:omniauthable, :rememberable, :trackable`. `User.from_omniauth` faz `find_or_create_by(provider:, uid:)`. Branch `feat/quiz-mvp`, PR → main (2026-06-13).
- **Estratégia de testes:** Minitest confirmado. OmniAuth test mode em `test_helper.rb`.
- **GameResult** salvo em `MatchesController#next_question` (onde `finished?` é verdadeiro), não em `AnswersController`.
- **Nickname:** obrigatório só após `nickname_set = true` — validações condicionais `with_options if: :nickname_set?`.

## Open Decisions (confirmar)

- **Domínio:** verificar disponibilidade (ex.: `torcedormaluco.com.br`).

## Blockers

- Nenhum no momento.

## Lessons

- A janela da Copa é curta (~6 semanas): priorizar velocidade de lançamento sobre completude.
- OmniAuth 2.x + `omniauth-rails_csrf_protection` exige POST para iniciar OAuth. Links `link_to` (GET) ficam presos no path do provider em system tests; usar `visit "/users/auth/[provider]/callback"` diretamente nos testes.
- `has_many :game_results` deve estar no `User` model — ausência causa `NoMethodError` em testes de sistema.
- System tests (Capybara) não são parallel-safe — rodam em processo único.

## Todos / Deferred

- Importar as perguntas da planilha mestre para o banco (seed) — coberto no Milestone 1.
- Páginas institucionais (Sobre, Privacidade, Termos) para habilitar AdSense — Milestone 3.
- Deploy para produção (Railway/Fly.io) — pendente.
- Configurar Google OAuth app em console.cloud.google.com com domínio de produção.
- Avaliar trocar `link_to` (GET) por `button_to` (POST) nos CTAs de login OAuth — correto para OmniAuth 2.x em produção.
