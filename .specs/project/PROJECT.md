# Torcedor Maluco

**Vision:** Um jogo web de quizzes de futebol, rápido e competitivo, que aproveita o hype da Copa do Mundo de 2026 para entreter o torcedor e gerar renda via assinatura e anúncios.
**For:** Torcedor casual brasileiro, que se anima na Copa e joga pelo celular vindo de redes sociais e grupos de WhatsApp.
**Solves:** A vontade de competir e provar conhecimento de futebol — hoje feita de forma solta em discussões de mesa de bar — num lugar que mede, registra e ranqueia, com diversão rápida no clima da Copa.

## Goals

- **Faturamento:** atingir R$500/mês (ex.: ~100 assinantes a R$5, ou misto de assinatura + anúncios).
- **Engajamento:** taxa de compartilhamento alta (motor de crescimento orgânico) e retorno diário puxado pelo ranking e pela mecânica de 5 jogadas/dia.
- **Aprendizado/portfólio:** dominar Ruby on Rails construindo um produto real, documentado de ponta a ponta.

## Tech Stack

**Core:**

- Framework: Ruby on Rails 7+
- Language: Ruby 3.x
- Database: PostgreSQL

**Key dependencies:**

- Hotwire (Turbo + Stimulus) — interatividade sem recarregar a página
- Tailwind CSS — UI mobile-first
- Devise — autenticação (necessário para ranking e assinatura)
- Mercado Pago (assinatura via Pix) — monetização recorrente

## Scope

**v1 includes:**

- Quiz jogável: 5 perguntas por partida, 4 alternativas, timer e pontuação
- Jogar sem cadastro (zero fricção)
- Banco de perguntas importado da planilha mestre
- Compartilhamento do resultado (crescimento orgânico)
- Experiência mobile-first (critério do "teste do polegar")

**Explicitly out of scope (v1):**

- Pagamento/assinatura e remoção de anúncios (entra no Milestone 3)
- Cadastro, login e ranking (entra no Milestone 2)
- Prêmios materiais/dinheiro (risco legal e de custo)
- App nativo, multiplayer em tempo real, temas fora de futebol

## Constraints

- **Timeline:** a Copa vai até 19/07/2026; o hype dura ~6 semanas. Lançar o MVP rápido é mais importante que lançar perfeito.
- **Technical:** desenvolvedor iniciante em Rails; preferir o caminho convencional do framework (Hotwire em vez de React).
- **Resources:** equipe de uma pessoa; orçamento mínimo (free tiers de hospedagem, domínio ~R$40/ano).
- **Legal:** evitar logos/marcas oficiais da FIFA e fotos protegidas.
