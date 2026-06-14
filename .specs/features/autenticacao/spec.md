# Autenticação — Specification

**Feature ID prefix:** `AUTH`
**Milestone:** M2 — Competição e contas
**Status:** Specified

---

## Problem Statement

O quiz MVP funciona sem cadastro (zero fricção). Para o ranking, badges e assinatura, precisamos de uma identidade de usuário — mas sem quebrar o fluxo atual de "jogar agora sem conta". O desafio é introduzir auth de forma que o convidado entenda o valor de criar conta (entrar no ranking) sem ser bloqueado para jogar.

## Goals

- [ ] Qualquer pessoa pode jogar sem criar conta (zero fricção mantida)
- [ ] Usuário logado tem resultado salvo automaticamente no ranking
- [ ] Login com 1 clique via Google OAuth — sem senha para lembrar
- [ ] Convidado vê o ranking mas entende que não está nele

## Out of Scope

| Feature | Razão |
|---------|-------|
| Login com e-mail + senha | Mais fricção, mais suporte; OAuth cobre o público mobile |
| Login com Facebook / Apple | Escopo M2; pode entrar em M4 |
| Recuperação de senha | Não existe senha no fluxo OAuth |
| Verificação de e-mail | Google já valida o e-mail |
| Histórico de partidas no perfil | M4 — foco do M2 é ranking, não histórico |
| Exclusão de conta (LGPD) | Necessário antes do AdSense/monetização — marcar como TODO em STATE.md |
| Admin panel | Fora do escopo do produto |
| Converter resultado de convidado retroativamente | Muito complexo para M2; convidado joga "de graça", logado salva |

---

## User Stories

### P1: Jogar como convidado com consciência do ranking ⭐ MVP

**User Story:** Como torcedor sem conta, quero jogar o quiz livremente e entender que não estou no ranking, para decidir se vale criar conta.

**Why P1:** Mantém a proposta zero-fricção do MVP. Sem isso, quebramos o que já funciona.

**Acceptance Criteria:**

1. WHEN um visitante acessa a home THEN o sistema SHALL exibir o botão "Jogar agora" sem exigir login
2. WHEN um convidado termina uma partida THEN a tela de resultado SHALL exibir aviso "Você jogou como convidado — seu resultado não foi salvo no ranking"
3. WHEN um convidado acessa o ranking THEN o sistema SHALL exibir o ranking completo COM uma faixa no topo: "Faça login com Google para entrar no ranking"
4. WHEN um convidado clica em "Entrar no ranking" THEN o sistema SHALL iniciar o fluxo OAuth do Google

**Independent Test:** Abrir o app sem estar logado → jogar uma partida → ver aviso na tela de resultado → acessar ranking → ver faixa de CTA.

---

### P1: Login e logout com Google OAuth ⭐ MVP

**User Story:** Como torcedor que quer entrar no ranking, quero fazer login com meu Google em 1 clique, sem criar senha.

**Why P1:** É o método de auth escolhido — sem isso, nenhuma feature de M2 funciona.

**Acceptance Criteria:**

1. WHEN um usuário clica em "Login com Google" (home ou ranking) THEN o sistema SHALL redirecionar para OAuth do Google
2. WHEN o Google retorna com sucesso THEN o sistema SHALL criar ou recuperar o usuário e redirecionar para a página de origem
3. WHEN o e-mail do Google já está cadastrado THEN o sistema SHALL logar na conta existente (sem duplicar)
4. WHEN o OAuth falha ou é cancelado THEN o sistema SHALL retornar à página anterior com mensagem de erro amigável
5. WHEN um usuário logado clica em "Sair" THEN o sistema SHALL encerrar a sessão e redirecionar para a home

**Independent Test:** Clicar "Login com Google" → autenticar → estar logado → clicar "Sair" → estar deslogado.

---

### P1: Nickname editável na primeira entrada ⭐ MVP

**User Story:** Como novo usuário que acabou de logar com Google, quero escolher meu nickname para o ranking, usando meu nome do Google como sugestão.

**Why P1:** O nome completo do Google é inadequado para ranking (muito longo, dados pessoais). Nickname é a identidade no ranking.

**Acceptance Criteria:**

1. WHEN um usuário faz login pela primeira vez THEN o sistema SHALL exibir tela de "Escolha seu nickname" com o primeiro nome do Google pré-preenchido
2. WHEN o usuário confirma o nickname THEN o sistema SHALL validar: mín. 3 chars, máx. 18 chars, apenas letras/números/underline/hífen
3. WHEN o nickname já existe THEN o sistema SHALL sugerir variação (ex.: `Joao_42`) e pedir confirmação
4. WHEN o nickname é válido e único THEN o sistema SHALL salvar e redirecionar para a página de origem
5. WHEN o usuário já passou pela tela de nickname THEN o sistema SHALL pular esse passo em logins futuros

**Independent Test:** Primeiro login → ver tela de nickname com nome do Google → editar → confirmar → não ver mais essa tela no próximo login.

---

### P1: Resultado salvo no ranking automaticamente ⭐ MVP

**User Story:** Como usuário logado, quero que meu resultado seja salvo automaticamente ao terminar uma partida, sem ação extra.

**Why P1:** É o valor core do login — sem isso, não há incentivo para criar conta.

**Acceptance Criteria:**

1. WHEN um usuário logado termina uma partida THEN o sistema SHALL salvar o resultado (score, correct_count, timestamp, user_id) na tabela de resultados
2. WHEN o resultado é salvo THEN a tela de resultado SHALL exibir "Resultado salvo no ranking! 🏆" em vez do aviso de convidado
3. WHEN o usuário acessa o ranking THEN seu último resultado SHALL aparecer na lista
4. WHEN um usuário logado joga novamente THEN o sistema SHALL salvar cada resultado (histórico)

**Independent Test:** Logar → jogar → ver mensagem de confirmação → abrir ranking → ver resultado na lista.

---

### P2: Editar nickname após o cadastro

**User Story:** Como usuário logado, quero poder trocar meu nickname a qualquer momento.

**Why P2:** Importante para experiência, mas o ranking funciona sem isso no MVP.

**Acceptance Criteria:**

1. WHEN um usuário logado acessa configurações/perfil THEN o sistema SHALL exibir campo para editar nickname
2. WHEN o novo nickname é válido e único THEN o sistema SHALL atualizar e refletir imediatamente no ranking
3. WHEN o novo nickname já existe THEN o sistema SHALL informar e manter o atual

**Independent Test:** Ir em configurações → trocar nickname → ver novo nome no ranking.

---

### P2: Botões de login visíveis na home para usuários não logados

**User Story:** Como visitante na home, quero ver claramente a opção de login, para saber que existe ranking sem precisar terminar uma partida primeiro.

**Why P2:** Melhora o funil de conversão, mas a CTA pós-resultado (P1) já cobre o caso principal.

**Acceptance Criteria:**

1. WHEN um convidado está na home THEN o sistema SHALL exibir link/botão "Login" discreto (não concorre com "Jogar agora")
2. WHEN um usuário logado está na home THEN o sistema SHALL exibir seu nickname e link para "Sair"

**Independent Test:** Abrir home sem login → ver botão de login → logar → ver nickname na home.

---

## Edge Cases

- WHEN o Google retorna e-mail diferente de uma conta existente THEN o sistema SHALL criar conta nova (cada Google account = 1 conta)
- WHEN a sessão expira durante o jogo THEN o sistema SHALL salvar o resultado ao terminar, solicitando re-login antes de confirmar
- WHEN nickname tem caracteres inválidos (emoji, espaço, acento) THEN o sistema SHALL rejeitar com mensagem clara
- WHEN dois usuários tentam o mesmo nickname simultaneamente THEN o sistema SHALL garantir unicidade via constraint no banco

---

## Requirement Traceability

| Requirement ID | Story | Status |
|---------------|-------|--------|
| AUTH-01 | P1: Jogar como convidado — home sem bloqueio | Pending |
| AUTH-02 | P1: Jogar como convidado — aviso na tela de resultado | Pending |
| AUTH-03 | P1: Ranking visível para convidado com CTA | Pending |
| AUTH-04 | P1: Login com Google OAuth | Pending |
| AUTH-05 | P1: Recuperar conta existente no OAuth | Pending |
| AUTH-06 | P1: Erro no OAuth → mensagem amigável | Pending |
| AUTH-07 | P1: Logout | Pending |
| AUTH-08 | P1: Tela de nickname na primeira entrada | Pending |
| AUTH-09 | P1: Validação de nickname (3–18 chars, charset) | Pending |
| AUTH-10 | P1: Conflito de nickname → sugestão automática | Pending |
| AUTH-11 | P1: Salvar resultado automaticamente (usuário logado) | Pending |
| AUTH-12 | P1: Mensagem de confirmação na tela de resultado (logado vs convidado) | Pending |
| AUTH-13 | P2: Editar nickname pós-cadastro | Pending |
| AUTH-14 | P2: Botão de login visível na home | Pending |

---

## Success Criteria

- [ ] Um torcedor pode jogar do início ao fim sem criar conta (fluxo atual intacto)
- [ ] Um torcedor pode criar conta com Google em ≤ 2 cliques a partir da tela de resultado
- [ ] Um usuário logado termina uma partida e vê seu resultado no ranking sem ação extra
- [ ] Nenhum usuário duplicado no banco por re-login com o mesmo Google account
- [ ] Nickname único garantido por constraint de banco (não apenas validação de aplicação)
