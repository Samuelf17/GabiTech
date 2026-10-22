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
- O mascote é exibido por um `TextureRect` que carrega `ideias/mascote.png` e preserva a proporção dentro da área responsiva, conforme a documentação da classe TextureRect no Godot 3.6.
- A tela usa duas composições responsivas: retrato mantém a referência mobile; paisagem distribui mascote/saudação à esquerda e missão/atalhos/progresso à direita. Posições, margens e escalas tipográficas usam o tamanho do viewport. Em paisagem, a área da saudação foi ampliada e o corpo limitado a 88% da escala adaptativa do título para manter “Olá, Guardião!” maior que a mensagem.
- A tipografia usa papéis semânticos e deriva o tamanho de fonte do menor lado do viewport e dos limites do controle, sem tamanho-base fixo por objeto. Títulos e textos ajustam-se a diferentes resoluções e ao espaço disponível em cada controle. Os quatro atalhos usam como preenchimento a cor anteriormente aplicada às bordas e texto azul-marinho para manter contraste.
- Os botões aceitam interação por foco, mouse e toque. Como as telas de destino ainda não existem, mostram mensagens temporárias em vez de navegar.
- Os arquivos gerados para modelagem do mascote em `shared/mascot/` foram removidos a pedido; a pasta de funcionalidade está sem implementação e `ideias/mascote.png` foi preservada como referência.
- `ideias/README.md` explica o uso da pasta para guardar referências visuais.
- `CHANGELOG.md` registra as mudanças importantes em formato conciso.
- Ainda não há cenas de jogo ou scripts de gameplay. `tests/test_home_screen.gd` verifica retrato, paisagem em 1280×720 e 960×540, retrato compacto, adaptação tipográfica, relação de tamanho e encaixe da saudação em paisagem, centralização dos botões, limites dos rótulos dos atalhos e feedback da ação.
- O README está em português e documenta o estado atual, abertura do projeto, estrutura e itens ainda não validados.

## Testes executados e resultados

- `tests/test_home_screen.gd` verifica o sprite e a preservação da proporção, escalas tipográficas adaptativas em retrato e paisagem, limites de texto, layouts responsivos e feedback. Na última execução, a suíte não iniciou: Godot 3.6.3 encerrou por falta de display X11 (`X11 Display is not available`), inclusive com `--no-window`; a execução após as alterações atuais ainda está pendente.
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
