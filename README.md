# app-jogos

Aplicativo educativo 2D para Android, planejado como um hub que reúne minijogos independentes e sistemas compartilhados.

> **Estado atual:** estrutura inicial do projeto Godot. Ainda não há cena principal, menus ou minijogos implementados.

## Tecnologias e plataforma

- Engine e linguagem planejadas: Godot Engine e GDScript.
- Renderer configurado em `project.godot`: GLES2.
- Plataforma-alvo: Android, com a TV Box MXQ-4K com Android 5.1 como referência mínima de hardware.
- A versão do editor Godot, a exportação para Android 5.1 e o desempenho no hardware de referência ainda não foram validados.

## Como abrir

1. Abra o Godot Project Manager.
2. Importe a pasta deste repositório, que contém `project.godot`, e abra o projeto no editor.

O projeto ainda não tem uma cena principal configurada; por isso, não há um jogo executável para iniciar neste estágio.

## Estrutura

```text
app/                         # Hub, menus e navegação
games/                       # Minijogos independentes
  quiz/
  puzzle/
  simulation/
shared/                      # Sistemas e componentes compartilhados
  accessibility/
  audio/
  mascot/
  progress/
  ui/
data/                        # Catálogo e conteúdo pedagógico
ideias/                      # Imagens de referência visual
tests/                       # Testes do projeto
```

Os designs criados no Godot devem consultar as imagens disponíveis em `ideias/`. As regras permanentes de desenvolvimento e as decisões de arquitetura estão em [AGENTS.md](AGENTS.md); o estado de implementação está em [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md).
