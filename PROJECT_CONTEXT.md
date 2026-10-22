# Contexto atual do projeto

## Objetivo e escopo

Aplicativo educativo Android com hub e minijogos independentes, conforme definido em [AGENTS.md](./AGENTS.md).

## Ambiente e restrições técnicas

- O projeto contém `project.godot` com `config_version=4`, renderer GLES2 e cena inicial `res://app/menus/home_screen.tscn`.
- A janela base está configurada em 720×1280, com viewport de teste desktop em 1280×720, orientação móvel `sensor`, stretch 2D e aspecto expandido. A tela muda entre composições de retrato e paisagem a partir do tamanho do viewport; a apresentação em celulares, TVs e diferentes proporções ainda não foi validada em hardware.
- O README documenta o objetivo, a tela principal atual, como abrir o projeto no Godot, a estrutura de pastas e as limitações ainda não validadas. Não confirma a versão efetivamente usada para abrir ou exportar o projeto.
- Dispositivo de referência: TV Box MXQ-4K com Android 5.1; compatibilidade e desempenho ainda não foram validados.

## Arquitetura e decisões vigentes

- Arquitetura modular por funcionalidade, com cenas independentes por minijogo e sistemas compartilhados pelo hub.
- Pastas base criadas para `app`, `games` (quiz, puzzle e simulation), `shared` (incluindo `mascot`), `data`, `tests` e `ideias`; a estrutura segue a referência de organização documentada em `AGENTS.md` e a orientação oficial do Godot para manter cenas independentes e com baixo acoplamento.
- Arquivos de configuração e documentação permanecem na raiz (`project.godot`, `default_env.tres`, `icon.png`, README e instruções); a configuração aponta diretamente para os recursos de ambiente e ícone por caminhos `res://` na raiz. Nenhum arquivo de implementação ou conteúdo de jogo existente precisou ser realocado.
- Os designs visuais feitos no Godot devem consultar as imagens de referência em `ideias/`; o turnaround `ideias/mascote.png` orienta o mascote 2D compartilhado.
- Priorizar jogos 2D leves, operação offline, interface legível à distância e entrada por toque, teclado e controle direcional.
- Usar GDScript com tipagem estática quando possível e consultar a documentação oficial correspondente à versão escolhida antes de implementar funcionalidades.

## Estado atual da implementação

- A primeira tela do hub, “Guardiões da Cidade Digital”, está implementada em `app/menus/home_screen.tscn` e `app/menus/home_screen.gd`; ela mostra cabeçalho, sprite do mascote, fala de boas-vindas, chamada para missão, atalhos e progresso ilustrativo.
- O mascote é exibido como `TextureRect` a partir da imagem transparente `ideias/mascote.png`, preservando a proporção dentro da área responsiva. A implementação segue a classe TextureRect documentada pelo Godot 3.6; ainda não foi executada no editor.
- A tela usa duas composições responsivas: retrato mantém a referência mobile; paisagem distribui mascote/saudação à esquerda e missão/atalhos/progresso à direita. Posições, margens e escalas tipográficas usam o tamanho do viewport.
- A tipografia da tela foi ampliada: títulos estão em 2× e os demais textos em 1,5× os tamanhos que já haviam sido aumentados em 25%; áreas do cabeçalho e textos permanecem posicionadas conforme o viewport. Os quatro atalhos usam como preenchimento a cor anteriormente aplicada às bordas e texto azul-marinho para manter contraste.
- Os botões aceitam interação por foco, mouse e toque. Como as telas de destino ainda não existem, mostram mensagens temporárias em vez de navegar.
- Os arquivos gerados para modelagem do mascote em `shared/mascot/` foram removidos a pedido; a pasta de funcionalidade está sem implementação e `ideias/mascote.png` foi preservada como referência.
- `ideias/README.md` explica o uso da pasta para guardar referências visuais.
- `CHANGELOG.md` registra as mudanças importantes em formato conciso.
- Ainda não há cenas de jogo ou scripts de gameplay. `tests/test_home_screen.gd` verifica a apresentação dos controles em três proporções, centralização dos botões, limites dos rótulos dos atalhos e feedback da ação.
- O README está em português e documenta o estado atual, abertura do projeto, estrutura e itens ainda não validados.

## Testes executados e resultados

- `git diff --check` passou. A suíte `tests/test_home_screen.gd` foi criada, mas não executou: Godot 3.6.3 encerrou ao inicializar por falta de display X11 (`X11 Display is not available`), inclusive com `--no-window`. A execução no editor/display continua pendente.
- Git 2.53.0 está disponível. O diretório reporta arquivos não rastreados, incluindo o projeto e este contexto.

## Problemas conhecidos e riscos

- A versão do Godot, requisitos de exportação Android 5.1, compatibilidade do GLES2 e layout responsivo no hardware de referência ainda precisam de validação prática.
- Não há build nem teste em dispositivo real ou equivalente; os testes automatizados da tela também aguardam um ambiente com display X11 compatível.

## Pendências e próximos passos

- Confirmar a versão do Godot e renderer apropriados ao dispositivo de referência consultando a documentação oficial.
- Implementar as telas de destino dos atalhos do hub e substituir os dados de progresso demonstrativos por dados reais.
- Validar build e medir desempenho, memória, carregamento e estabilidade em hardware real ou equivalente.

## Decisões em aberto

- Versão final do Godot e configuração de exportação Android.
- Minijogos e funcionalidades do escopo inicial.
