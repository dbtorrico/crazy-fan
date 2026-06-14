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
- **Ranking geral entregue** (`ranking_controller.rb` + `/ranking`) junto com Auth no PR #14. Ranking semanal e badges ficam para depois.
- **Próxima feature M2 (2026-06-14): Mecânica de energia (5 jogadas/dia)** — gancho da assinatura do M3.

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

- ~~Importar as perguntas da planilha mestre para o banco (seed)~~ — DONE (M1).
- Páginas institucionais (Sobre, Privacidade, Termos) para habilitar AdSense — Milestone 3.
- ~~Deploy para produção (Railway/Fly.io)~~ — DONE: Railway configurado (commits 58c2472, 765b0e1).
- Configurar Google OAuth app em console.cloud.google.com com domínio de produção — verificar se já aponta para a URL do Railway.
- **[TECH DEBT - Deploy]** `ENV.fetch("GOOGLE_CLIENT_ID", "")` usa fallback vazio — o app sobe sem as variáveis de ambiente, sem erro. Antes do primeiro deploy, adicionar validação explícita em `config/initializers/` ou via `.env` + dotenv-rails para garantir que a ausência das vars seja detectada no boot de produção.
- **[TECH DEBT - Auth]** `User.from_omniauth` usa `find_or_create_by` com bloco — não atualiza `email` ou `avatar_url` em re-logins caso mudem no Google. Migrar para `find_or_initialize_by` + `save` condicional antes de ter usuários em produção.
- **[TECH DEBT - Auth]** Índice `nickname` no PostgreSQL é case-sensitive; validação de unicidade no model usa `case_sensitive: false`. Risco: `Joao` e `joao` coexistindo no banco. Fix: adicionar índice com `LOWER(nickname)` via migration ou normalizar o valor antes de salvar.
- **[TECH DEBT - Auth]** `devise.rb` tem ~316 linhas de boilerplate gerado (comentários padrão). Config real são ~5 linhas. Pode ser limpo sem risco funcional.
- **[TECH DEBT - Auth]** `config.mailer_sender` ainda é o placeholder padrão do Devise. Atualizar antes de qualquer feature que dispare e-mail.
- **[TECH DEBT - Auth]** `@is_guest = !user_signed_in?` duplicado em `MatchesController#show` e `#next_question`. Extrair para `before_action :set_guest_flag`.
- **[TECH DEBT - Auth]** Flash messages e logout no header (`layouts/matches.html.erb`) usam `style=""` inline; resto do app usa Tailwind. Unificar quando houver sprint de UI.
- **[TECH DEBT - Tests]** System tests de auth (`auth_flow_test.rb`) usam `sleep 2` para aguardar animações. Substituir por `assert_selector` com timeout do Capybara para tornar os testes menos frágeis em CI.
- **[TECH DEBT - Tests]** `game_result_saving_test.rb` não cobre "partida não terminada → `GameResult.count` permanece 0" (previsto na task spec T8). Adicionar quando houver tempo.
