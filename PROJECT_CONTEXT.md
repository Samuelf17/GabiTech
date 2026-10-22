# Contexto atual do projeto

## Objetivo e escopo

Aplicativo educativo Android com hub e minijogos independentes, conforme definido em [AGENTS.md](./AGENTS.md).

## Ambiente e restrições técnicas

- O projeto contém `project.godot` com `config_version=4` e renderer GLES2.
- O README menciona `Godot_v3.6.3-stable_x11.64`, mas não confirma a versão efetivamente usada para abrir ou exportar o projeto.
- Dispositivo de referência: TV Box MXQ-4K com Android 5.1; compatibilidade e desempenho ainda não foram validados.

## Arquitetura e decisões vigentes

- Arquitetura modular por funcionalidade, com cenas independentes por minijogo e sistemas compartilhados pelo hub.
- Pastas base criadas para `app`, `games` (quiz, puzzle e simulation), `shared` (incluindo `mascot`), `data`, `tests` e `ideias`; a estrutura segue a referência de organização documentada em `AGENTS.md` e a orientação oficial do Godot para manter cenas independentes e com baixo acoplamento.
- Arquivos de configuração e documentação permanecem na raiz (`project.godot`, `default_env.tres`, `icon.png`, README e instruções); a configuração aponta diretamente para os recursos de ambiente e ícone por caminhos `res://` na raiz. Nenhum arquivo de implementação ou conteúdo de jogo existente precisou ser realocado.
- Os designs visuais feitos no Godot devem consultar as imagens de referência em `ideias/`; o turnaround `ideias/mascote.png` orienta o mascote 2D compartilhado.
- Priorizar jogos 2D leves, operação offline, interface legível à distância e entrada por toque, teclado e controle direcional.
- Usar GDScript com tipagem estática quando possível e consultar a documentação oficial correspondente à versão escolhida antes de implementar funcionalidades.

## Estado atual da implementação

- Estrutura inicial de um projeto Godot: configuração, ambiente padrão e ícone na raiz, além das pastas base da arquitetura.
- Os arquivos gerados para modelagem do mascote em `shared/mascot/` foram removidos a pedido; a pasta de funcionalidade está sem implementação e `ideias/mascote.png` foi preservada como referência.
- `ideias/README.md` explica o uso da pasta para guardar referências visuais.
- `CHANGELOG.md` registra as mudanças importantes em formato conciso.
- Ainda não há cenas de jogo, scripts de gameplay ou testes.
- O README contém apenas o título `app-jogos`, uma nota sobre agente de IA e uma referência a Godot 3.6.3.

## Testes executados e resultados

- Nenhum teste executado nesta tarefa; ela alterou documentação e removeu arquivos do protótipo do mascote.
- Git 2.53.0 está disponível. O diretório reporta arquivos não rastreados, incluindo o projeto e este contexto.

## Problemas conhecidos e riscos

- A versão do Godot, requisitos de exportação Android 5.1 e compatibilidade do GLES2 com o hardware de referência ainda precisam de validação oficial e prática.
- Não há build ou teste em dispositivo real ou equivalente.

## Pendências e próximos passos

- Confirmar a versão do Godot e renderer apropriados ao dispositivo de referência consultando a documentação oficial.
- Definir a primeira funcionalidade do hub e criar as cenas/scripts correspondentes.
- Validar build e medir desempenho, memória, carregamento e estabilidade em hardware real ou equivalente.

## Decisões em aberto

- Versão final do Godot e configuração de exportação Android.
- Minijogos e funcionalidades do escopo inicial.
