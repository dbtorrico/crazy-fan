# Testing Strategy

**Status:** Proposto (assumido Minitest — confirmar com o dono antes de executar)

Projeto greenfield em Ruby on Rails. Estratégia escolhida: **Minitest**, o framework de testes que já vem com o Rails — mais simples para um desenvolvedor iniciante e suficiente para o escopo do MVP.

## Test Coverage Matrix

Define o tipo de teste exigido por camada de código. Cada tarefa que cria/altera uma camada DEVE incluir o teste correspondente na própria tarefa (testes co-localizados, não são tarefas separadas).

| Camada de código | Tipo de teste exigido | Por quê |
| --- | --- | --- |
| Models (ex.: Question, GameSession) | unit | Validações e regras (ex.: uma resposta correta) precisam ser garantidas |
| Lógica de pontuação | unit | É o coração do jogo; erro aqui quebra a experiência |
| Controllers / fluxo de partida | integration | Garantir que o fluxo pergunta→resposta→pontuação responde certo |
| Telas (jogar uma partida no navegador) | system (Capybara) | Validar o fluxo real no celular, incluindo o "teste do polegar" |
| Views/partials estáticas | none | Sem lógica para testar |
| Seed de importação de perguntas | unit | Garantir que a planilha mestre é importada sem perda/duplicata |

## Gate Check Commands

| Gate | Comando | Quando |
| --- | --- | --- |
| quick | `bin/rails test` | Após cada tarefa de model/lógica |
| full | `bin/rails test:all` (inclui system tests) | Após tarefas de fluxo/tela |
| build | `bin/rails test && bin/rails assets:precompile` | Antes de deploy |

## Parallelism Assessment

| Tipo de teste | Parallel-Safe | Observação |
| --- | --- | --- |
| unit | Sim | Isolados, sem estado compartilhado |
| integration | Sim | Usam transações por teste |
| system (Capybara) | Não | Sobem servidor/navegador; rodar em série para evitar flutuação |

> Como é greenfield, esta matriz é a referência inicial. Se o dono optar por RSpec, trocar os comandos (`bundle exec rspec`) e os tipos (request specs / system specs) mantendo a mesma matriz de cobertura.
