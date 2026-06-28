# Torcedor Maluco

Quiz de futebol rápido e competitivo, feito para o torcedor casual brasileiro no
clima da Copa do Mundo de 2026. Partidas de 5 perguntas, ranking semanal, energia
diária e conquistas. Mobile-first.

## Stack

- **Ruby** 3.3.6 · **Rails** 7.2
- **PostgreSQL**
- **Hotwire** (Turbo + Stimulus) · **Tailwind CSS**
- **Devise** (Google OAuth) · **Minitest** + Capybara

## Rodando localmente

```bash
bin/setup            # instala dependências e prepara o banco
bin/dev              # sobe o servidor + watch do Tailwind (http://localhost:3000)
bin/rails db:seed    # popula o banco de perguntas (ver seção abaixo)
bin/rails test       # suíte de testes (unit + integração)
```

> Postgres local: se `bin/rails` falhar com `ConnectionNotEstablished`, suba o
> serviço manualmente — ver `.specs/project/STATE.md` (seção Lessons).

## Banco de perguntas

As perguntas do jogo vivem numa planilha que é importada para o banco de dados — não
no código. Para adicionar ou corrigir perguntas, veja
[docs/banco-de-perguntas.md](docs/banco-de-perguntas.md).
