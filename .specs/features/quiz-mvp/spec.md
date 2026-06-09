# Quiz MVP — Specification

## Problem Statement

O torcedor casual quer competir e provar que sabe de futebol, mas hoje faz isso de forma solta em conversas. Falta um lugar rápido, no celular, para jogar um quiz no clima da Copa de 2026 e ver sua pontuação. Precisamos disso no ar logo, enquanto dura o hype, sem fricção de cadastro.

## Goals

- [ ] Um jogador anônimo consegue jogar uma partida completa (5 perguntas) e ver sua pontuação em menos de 2 minutos.
- [ ] O jogo é divertido e compartilhável o suficiente para gerar tráfego orgânico (botão de compartilhar no resultado).
- [ ] Funciona muito bem no celular ("teste do polegar": jogar uma partida inteira com uma mão, sem zoom).

## Out of Scope

| Feature | Reason |
| --- | --- |
| Cadastro, login e ranking | Entra no Milestone 2; MVP joga anônimo para zero fricção |
| Assinatura / remoção de anúncios | Entra no Milestone 3 |
| Mecânica de 5 jogadas/dia (energia) | Depende de identificar o usuário; Milestone 2 |
| Categorias por tema selecionáveis | MVP sorteia de todo o banco; seleção de tema vem depois |
| Painel administrativo de perguntas | Perguntas entram via seed da planilha mestre |

---

## User Stories

### P1: Jogar uma partida de quiz ⭐ MVP

**User Story**: Como torcedor, quero responder um quiz rápido de futebol e ver minha pontuação, para me divertir e medir meu conhecimento.

**Why P1**: É o coração do produto — sem isso não há jogo. É o vertical slice que prova o valor.

**Acceptance Criteria**:

1. WHEN o jogador abre a página inicial e inicia uma partida THEN o sistema SHALL apresentar a 1ª de 5 perguntas com 4 alternativas.
2. WHEN o jogador seleciona uma alternativa THEN o sistema SHALL registrar a resposta e avançar para a próxima pergunta sem recarregar a página.
3. WHEN o jogador responde a 5ª pergunta THEN o sistema SHALL exibir a pontuação final (número de acertos de 5).
4. WHEN as perguntas são apresentadas THEN o sistema SHALL sorteá-las do banco sem repetir pergunta dentro da mesma partida.
5. WHEN nenhuma alternativa foi escolhida THEN o sistema SHALL impedir o avanço (ou contar como erro, conforme decisão de design).

**Independent Test**: Abrir a home, jogar 5 perguntas clicando nas alternativas, e ver a tela de pontuação ao final.

---

### P1: Pontuação por partida ⭐ MVP

**User Story**: Como torcedor, quero ver quantas acertei ao final, para saber como me sai.

**Why P1**: Sem feedback de pontuação, o quiz não tem graça nem motivo para repetir.

**Acceptance Criteria**:

1. WHEN o jogador acerta uma pergunta THEN o sistema SHALL contabilizar +1 ponto.
2. WHEN a partida termina THEN o sistema SHALL exibir a pontuação no formato "X de 5".
3. WHEN o jogador erra THEN o sistema SHALL (conforme design) indicar a resposta correta ou apenas seguir, mas nunca contar ponto.

**Independent Test**: Responder propositalmente 3 certas e 2 erradas e verificar que a tela final mostra "3 de 5".

---

### P1: Cronômetro por pergunta ⭐ MVP

**User Story**: Como torcedor, quero um tempo limite por pergunta, para o jogo ser dinâmico e emocionante.

**Why P1**: O dono definiu o jogo como "rápido e dinâmico"; o timer é parte da identidade.

**Acceptance Criteria**:

1. WHEN uma pergunta é exibida THEN o sistema SHALL iniciar um cronômetro visível (ex.: 15s).
2. WHEN o tempo se esgota sem resposta THEN o sistema SHALL contar a pergunta como erro e avançar.
3. WHEN o jogador responde antes do tempo THEN o sistema SHALL parar o cronômetro e avançar.

**Independent Test**: Deixar o tempo de uma pergunta esgotar e confirmar que ela vira erro e o jogo avança.

---

### P1: Banco de perguntas via seed ⭐ MVP

**User Story**: Como dono, quero que as perguntas da planilha mestre populem o banco de dados, para o jogo ter conteúdo confiável.

**Why P1**: Sem perguntas no banco, não há partida.

**Acceptance Criteria**:

1. WHEN o seed de importação roda THEN o sistema SHALL criar no banco cada pergunta da planilha com suas 4 alternativas e a correta.
2. WHEN a planilha tem uma pergunta inválida (sem resposta correta marcada) THEN o sistema SHALL rejeitá-la e reportar, sem importar dado quebrado.
3. WHEN o seed roda novamente THEN o sistema SHALL NÃO duplicar perguntas já existentes.

**Independent Test**: Rodar o seed apontando para a planilha mestre e conferir a contagem de perguntas no banco.

---

### P2: Compartilhar o resultado

**User Story**: Como torcedor, quero compartilhar minha pontuação, para desafiar amigos no WhatsApp.

**Why P2**: É o motor de crescimento orgânico, mas o jogo funciona sem ele — por isso não bloqueia o vertical slice mínimo.

**Acceptance Criteria**:

1. WHEN a tela de pontuação é exibida THEN o sistema SHALL oferecer um botão de compartilhar com um texto pronto (ex.: "Fiz X de 5 no Torcedor Maluco, e você?").
2. WHEN o jogador toca em compartilhar no celular THEN o sistema SHALL abrir o compartilhamento nativo (Web Share API) ou um link copiável como fallback.

**Independent Test**: Na tela final, tocar em compartilhar e ver o texto/link correto.

---

### P3: Jogar de novo

**User Story**: Como torcedor, quero um botão "jogar de novo" na tela final, para emendar outra partida.

**Why P3**: Conveniência que aumenta o tempo de sessão; trivial, mas não essencial ao slice mínimo.

**Acceptance Criteria**:

1. WHEN a tela de pontuação é exibida THEN o sistema SHALL oferecer "jogar de novo", iniciando uma nova partida com novo sorteio de perguntas.

---

## Edge Cases

- WHEN o banco tem menos de 5 perguntas THEN o sistema SHALL exibir mensagem amigável em vez de quebrar.
- WHEN o jogador recarrega a página no meio da partida THEN o sistema SHALL (conforme design) reiniciar a partida — estado mínimo no MVP.
- WHEN duas perguntas sorteadas seriam iguais THEN o sistema SHALL garantir 5 perguntas distintas.
- WHEN o jogador abre em tela muito pequena THEN o layout SHALL permanecer em uma coluna, com alternativas tocáveis (mín. ~44px).

---

## Requirement Traceability

| Requirement ID | Story | Phase | Status |
| --- | --- | --- | --- |
| QUIZ-01 | P1: Jogar partida (fluxo 5 perguntas) | Design | Pending |
| QUIZ-02 | P1: Avançar sem recarregar (Turbo) | Design | Pending |
| QUIZ-03 | P1: Pontuação "X de 5" | Design | Pending |
| QUIZ-04 | P1: Sorteio sem repetir na partida | Design | Pending |
| QUIZ-05 | P1: Cronômetro por pergunta | Design | Pending |
| QUIZ-06 | P1: Seed da planilha mestre | Design | Pending |
| QUIZ-07 | P1: Validação de pergunta inválida no seed | Design | Pending |
| QUIZ-08 | P2: Compartilhar resultado | Design | Pending |
| QUIZ-09 | P3: Jogar de novo | Design | Pending |
| QUIZ-10 | Edge: mobile-first / teste do polegar | Design | Pending |

**Coverage:** 10 total, 0 mapeadas para tarefas ainda (preenchido no tasks.md).

---

## Success Criteria

- [ ] Um jogador novo completa uma partida em < 2 minutos.
- [ ] A pontuação final está sempre correta (acertos contados certos, zero erro de cálculo).
- [ ] É possível jogar a partida inteira no celular com uma mão, sem zoom ("teste do polegar").
- [ ] O seed importa 100% das perguntas válidas da planilha mestre, sem duplicar.
