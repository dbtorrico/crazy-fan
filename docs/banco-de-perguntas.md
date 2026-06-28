# Banco de perguntas

O conteúdo do jogo (as perguntas) **não vive no código** — vive numa planilha que é
importada para o banco de dados. Entender esse fluxo é essencial para adicionar ou
corrigir perguntas.

## Visão geral do fluxo

```
  planilha .xlsx            importer (seed)            banco de dados          partida
  ┌──────────────┐        ┌────────────────┐        ┌──────────────┐        ┌─────────┐
  │ banco-mestre │  →     │ QuestionsImporter│  →    │ Question +   │   →    │ no app  │
  │ (fonte da    │ seed   │  (tradutor)    │        │ Answer       │        │         │
  │  verdade)    │        └────────────────┘        └──────────────┘        └─────────┘
  └──────────────┘
   editar/revisar                                     o Rails lê aqui
   é fácil aqui                                        ao montar a partida
```

1. **A planilha é a fonte da verdade.** Todas as perguntas ficam em um único arquivo
   `banco-perguntas-torcedor-maluco.xlsx`. É lá que se cria, revisa e confere o
   conteúdo — com a comodidade de uma planilha, sem mexer em código.
2. **O importer traduz planilha → banco.** [`lib/import/questions_importer.rb`](../lib/import/questions_importer.rb),
   chamado por [`db/seeds.rb`](../db/seeds.rb), lê cada linha e cria um `Question` com
   suas 4 `Answer` (uma marcada como correta).
3. **O app lê do banco.** Na hora de montar uma partida, o Rails sorteia perguntas do
   banco de dados (`Quiz::Question.sample_ids`), nunca da planilha.

> Se a planilha não for encontrada na raiz do projeto, o seed é pulado e o jogo cai
> num conjunto mínimo de perguntas de emergência (`FALLBACK` em
> [`app/models/quiz/question.rb`](../app/models/quiz/question.rb)). Em produção, a
> planilha **precisa** estar versionada no repositório para o seed funcionar.

## Como a planilha é gerada

A planilha é produzida e mantida pela skill `torcedor-maluco`, que:

- gera as perguntas seguindo padrões fixos de formato e confiabilidade (fonte por
  pergunta, 4 alternativas, distratores plausíveis);
- roda um **verificador de duplicatas** (`check_duplicates.py`) que barra perguntas
  com redação repetida — dentro do lote novo **e** contra o banco já existente;
- é **cumulativa**: cada geração soma ao banco-mestre, nunca o substitui.

O banco-mestre canônico vive **fora do repositório**; uma cópia é colocada na raiz do
projeto para o seed/deploy enxergar.

## Formato da planilha (colunas)

```
ID | Tema | Dificuldade | Pergunta | Alternativa A | B | C | D | Resposta Correta | Fonte
```

- **Resposta Correta:** a letra (`A`/`B`/`C`/`D`). O importer também aceita índice
  numérico (`1`–`4`), por compatibilidade com o formato legado.
- **Tema:** os rótulos da planilha são normalizados pelo importer para as chaves
  canônicas do app (ver `TEMA_CANONICO` no importer):

  | Planilha (skill)          | Chave no app   |
  |---------------------------|----------------|
  | Copa 2026                 | Copa do Mundo  |
  | História das Copas        | História       |
  | Seleção Brasileira        | Seleção        |
  | Craques e curiosidades    | Craques        |

  Hoje o `tema` é apenas **metadado de organização do banco** — o jogador não escolhe
  categoria, e as partidas sorteiam perguntas aleatórias de todos os temas. A
  infraestrutura de filtro por tema (`sample_ids(tema:)`, `category_counts`,
  `CATEGORIES`) existe no código, mas está dormente. Manter os temas consistentes é o
  que deixa essa porta aberta caso a decisão mude no futuro.

## Adicionando perguntas

1. Gere/edite o banco-mestre com a skill `torcedor-maluco` (ela cuida do dedup e do
   formato).
2. Copie o `.xlsx` atualizado para a raiz do projeto, sobrescrevendo o existente.
3. Rode `bin/rails db:seed`. A saída informa quantas foram importadas e puladas.
4. O seed é idempotente: re-importar não duplica (casa pelo enunciado).
