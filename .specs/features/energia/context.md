# Energia — Context (decisões do Discuss)

Decisões do usuário (dono) em 2026-06-14, fase Discuss dentro do Specify.

## Gray areas resolvidas

1. **Escopo do limite:** Somente **usuários logados** têm o sistema completo de energia (5 jogadas, persistido no BD). **Convidados** (guest, sem login) têm um limite **menor por sessão** + CTA "faça login para jogar mais". → empurra cadastro, alinhado ao gancho de assinatura do M3.

2. **Modelo de recarga:** **Regeneração por intervalo** (estilo "vidas" de jogo mobile), NÃO reset diário. Cada energia gasta regenera após um **intervalo configurável** — default inicial **2 horas** por energia, até o teto de 5. O dono pediu explicitamente que **a regra do intervalo seja trivial de mudar no código** (uma constante/config, não espalhada).

3. **Consumo:** 1 energia é debitada **ao iniciar a partida** (`POST /match/start`), não ao terminar. Evita reinício infinito / fuga de perguntas difíceis.

## Implicações de design

- A energia atual é **computada sob demanda** a partir de `(energia_armazenada, timestamp_da_última_atualização, intervalo)` — não há job de background recarregando. Fórmula: `regenerada = floor((agora - ts) / intervalo)`, `energia = min(MAX, armazenada + regenerada)`, avançar `ts` proporcionalmente.
- Parâmetros centralizados (sugestão): `Quiz::Energy::MAX = 5`, `Quiz::Energy::RECHARGE_INTERVAL = 2.hours`, `Quiz::Energy::GUEST_MAX = 2` (ajustável). Mudar a regra = mudar a constante.
- Assinante (M3) → energia ilimitada; deixar um gancho (`user.unlimited_energy?`) já previsto, default `false`.

## Deferido

- Recarga por assistir anúncio / convite de amigo — M3+.
- Notificação push "sua energia encheu" — futuro.
