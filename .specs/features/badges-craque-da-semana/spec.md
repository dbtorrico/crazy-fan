# Spec — Badges & Craque da Semana

**Feature:** Conquistas acumuladas + título de Craque da Semana  
**Milestone:** M2 — Competição e contas  
**Escopo:** Large  
**Decisões do dono:**
- "Craque da Semana" = título no perfil, exibido no ranking e na tela de resultado
- Badges = conquistas acumuladas, persistidas no banco

---

## Visão geral

Jogadores logados ganham badges ao atingir marcos. O badge mais prestigioso — **Craque da Semana** — é concedido ao jogador que terminar uma partida em 1º lugar no ranking semanal. Os badges aparecem na tela de resultado (recém-conquistados) e no ranking (ícones na linha do jogador).

---

## Catálogo de badges

| key | Emoji | Label | Condição |
|---|---|---|---|
| `first_game` | 🎯 | Estreante | 1ª partida concluída |
| `perfect_game` | ⭐ | Perfeito | 5/5 corretas em uma partida |
| `ten_games` | ⚽ | Viciado | 10 partidas no total |
| `fifty_games` | 🎟️ | Fã de Carteirinha | 50 partidas no total |
| `craque_semanal` | 🏆 | Craque da Semana | Terminar 1º no ranking semanal |

---

## Requisitos

### Modelo de dados

**BAD-01** — Existe uma tabela `user_achievements` com colunas: `user_id` (FK), `badge_key` (string), `week` (string, default `""`), `earned_at` (datetime).  
**BAD-02** — Índice único em `(user_id, badge_key, week)`. Para badges one-time, `week = ""` (string vazia); para `craque_semanal`, `week = "YYYY-Www"` (ISO 8601, ex.: `"2026-W25"`). Isso garante: um badge one-time por usuário, e um `craque_semanal` por usuário por semana.  
**BAD-03** — `User has_many :user_achievements`.

### Lógica de award

**BAD-04** — `Quiz::Badge.check_and_award!(user, game_result)` avalia todos os badges e cria os registros ausentes; retorna array com os badges recém-conquistados (pode ser vazio).  
**BAD-05** — `first_game`: concedido se for o 1º `GameResult` do usuário.  
**BAD-06** — `perfect_game`: concedido se `game_result.correct_count == game_result.questions_count`.  
**BAD-07** — `ten_games`: concedido quando o usuário completa a 10ª partida.  
**BAD-08** — `fifty_games`: concedido quando o usuário completa a 50ª partida.  
**BAD-09** — `craque_semanal`: concedido se, após salvar o resultado, o usuário estiver em 1º no ranking semanal. `week` é preenchido com o código ISO da semana atual (ex.: `"2026-W25"`). O constraint único em `(user_id, badge_key, week)` garante no máximo um registro por usuário por semana.  
**BAD-10** — A checagem ocorre em `MatchesController` imediatamente após salvar o `GameResult`; convidados (sem `current_user`) pulam a checagem.

### Tela de resultado

**BAD-11** — Se `newly_earned` não for vazio, a tela de resultado exibe uma seção "Conquistas desbloqueadas 🎉" com emoji + label de cada badge.  
**BAD-12** — Se o usuário for 1º no ranking semanal ao concluir a partida, exibe um callout "🏆 Craque da Semana!" independentemente de `newly_earned` (pode ter ganho o badge antes).

### Ranking

**BAD-13** — A entrada de rank 1 no ranking **semanal** exibe uma coroa 👑 antes do nickname.  
**BAD-14** — Cada linha do ranking exibe os badges acumulados do usuário como ícones pequenos (apenas emoji, sem label), limitados a 5 ícones visíveis.  
**BAD-15** — Os badges são carregados em batch junto com os entries (sem N+1).

---

## Fora do escopo

- Página de perfil dedicada com lista de todos os badges
- Push notifications
- Badges para categorias específicas (ex.: "Mestre da Copa")
- Exibição de badges para convidados

---

## Critérios de aceite

1. Jogar a 1ª partida logado → badge "Estreante" aparece no resultado
2. Acertar 5/5 → badge "Perfeito ⭐" aparece no resultado
3. Jogar 10× → badge "Viciado ⚽" aparece no resultado (somente na 10ª)
4. Ser #1 semanal → "🏆 Craque da Semana!" aparece no resultado + coroa no ranking
5. Badges não são duplicados (exceto `craque_semanal` que pode repetir por semana)
6. Convidado termina partida → sem erro, sem badge
