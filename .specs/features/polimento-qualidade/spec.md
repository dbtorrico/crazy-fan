# Spec: M3.5 — Qualidade e Experiência

**Milestone:** M3.5  
**Status:** PLANNED

---

## Contexto

Quatro melhorias independentes para polir a experiência do jogador frequente e a qualidade do conteúdo, sem depender de features de monetização ou infra nova.

---

## Requisitos

### PQ-1 — Página "Regras do Jogo"

**Como** jogador novo,  
**quero** entender as regras antes de jogar,  
**para** saber como a pontuação funciona e não me frustrar.

**Critérios de aceite:**
- `GET /rules` retorna página acessível sem login
- Página explica: 5 perguntas por partida, timer 15s, pontuação base 60 pts + bônus velocidade (até 40 pts), sistema de energia (5 logados / 3 guests / ilimitado Premium), badges disponíveis
- Link "Como funciona?" visível na tela de home e na tela de resultado
- Botão "‹ Voltar" retorna à raiz (padrão do ranking)
- Layout responsivo, usa `torcedor_maluco.css` existente

**Arquivos:**
- `config/routes.rb`
- `app/controllers/rules_controller.rb` (novo)
- `app/views/rules/index.html.erb` (novo)
- `app/views/matches/_home.html.erb`
- `app/views/matches/_result.html.erb`

---

### PQ-2 — Siglas sem explicação

**Como** jogador,  
**quero** entender todas as siglas nas perguntas,  
**para** não errar por desconhecer uma abreviação, não por falta de conhecimento de futebol.

**Critérios de aceite:**
- Rake task `rails content:check_acronyms` executa sem erro
- Task gera CSV em `tmp/` com colunas: `id`, `enunciado`, `campo` (enunciado/resposta), `texto_detectado`, `sigla`
- Siglas que recebem explicação entre parênteses: CBF, UEFA, CONMEBOL, CONCACAF, CAF, AFC, OFC, IFFHS, FPF
- Siglas mantidas sem explicação (amplamente conhecidas): FIFA, VAR
- Após revisão manual e aplicação de correções, nenhuma sigla da lista aparece sem parênteses no banco

**Arquivos:**
- `lib/tasks/content/check_acronyms.rake` (novo)

---

### PQ-3 — Perguntas em tempo futuro sobre 2026

**Como** jogador,  
**quero** que as perguntas sobre a Copa 2026 façam sentido gramaticalmente,  
**para** não me confundir com verbos no futuro para um evento que já está acontecendo.

**Critérios de aceite:**
- Rake task `rails content:check_future_tense` executa sem erro
- Task detecta padrão: verbos no futuro (`sediará`, `será`, `terá`, `disputará`, `acontecerá`, `ocorrerá`) + menção a `2026`
- Gera CSV em `tmp/` com: `id`, `enunciado`, `texto_detectado`, `sugestão`
- Após revisão e correção, nenhuma pergunta sobre 2026 usa futuro do indicativo

**Arquivos:**
- `lib/tasks/content/check_future_tense.rake` (novo)

---

### PQ-4 — Anti-repetição de perguntas por jogador

**Como** jogador frequente,  
**quero** ver perguntas novas a cada partida,  
**para** continuar aprendendo e não me entediar.

**Critérios de aceite:**
- `game_results` armazena os IDs das 5 perguntas de cada partida (coluna `question_ids` JSON)
- Ao iniciar nova partida, usuário logado não recebe perguntas vistas nos últimos 10 jogos (se o pool pós-filtro for ≥ 5)
- Se o pool filtrado for < 5, sistema usa o pool completo (fallback silencioso)
- Guests continuam com seleção aleatória sem histórico (sem mudança de comportamento)
- Testes: partida iniciada para usuário com 10 jogos exclui os 50 IDs vistos; partida iniciada sem usuário não exclui nada

**Arquivos:**
- `db/migrate/XXXX_add_question_ids_to_game_results.rb` (nova migration)
- `app/models/game_result.rb` — `serialize :question_ids`
- `app/models/quiz/question.rb` — `sample_ids(n, tema:, exclude_ids: [])`
- `app/controllers/matches_controller.rb` — passar `exclude_ids`, gravar `question_ids`

---

## Ordem de implementação sugerida

1. PQ-1 (independente, valor imediato)
2. PQ-4 (maior impacto na retenção)
3. PQ-2 + PQ-3 (executar tasks → revisar CSVs → aplicar correções)
