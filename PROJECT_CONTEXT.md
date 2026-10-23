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
- `shared/ui/bottom_navigation.tscn` e `bottom_navigation.gd` são o componente obrigatório de navegação inferior para telas existentes e novas. Ele define rótulos, ícones SVG, estados, foco e um único papel tipográfico adaptativo baseado no padrão da tela inicial (`0.02717` do menor lado, limitado pela área disponível). As telas devem indicar `active_item` e responder ao sinal `item_selected`; essa API foi implementada nas telas Home e Mapa. Os assets de interface compartilhados ficam em `shared/ui/assets/icons/`.
- `Progression` (`shared/progress/progression_service.gd`) é um Autoload para o estado compartilhado de nível, experiência atual e itens desbloqueados. A regra configurável em `data/progression/progression_rules.json` é 2.000 XP por nível; o estado inicial está em `default_progress.json` e a cópia persistente é `user://progress.json`. A API de avanço existe para integração futura e testes, mas nenhuma atividade do jogo concede XP ainda.
- Pastas base criadas para `app`, `games` (quiz, puzzle e simulation), `shared` (incluindo `mascot`), `data`, `tests` e `ideias`; a estrutura segue a referência de organização documentada em `AGENTS.md` e a orientação oficial do Godot para manter cenas independentes e com baixo acoplamento.
- Arquivos de configuração e documentação permanecem na raiz (`project.godot`, `default_env.tres`, `icon.png`, README e instruções); a configuração aponta diretamente para os recursos de ambiente e ícone por caminhos `res://` na raiz. Nenhum arquivo de implementação ou conteúdo de jogo existente precisou ser realocado.
- Os designs visuais feitos no Godot devem consultar as imagens de referência em `ideias/`; o turnaround `ideias/mascote.png` orienta o mascote 2D compartilhado.
- Priorizar jogos 2D leves, operação offline, interface legível à distância e entrada por toque, teclado e controle direcional.
- Usar GDScript com tipagem estática quando possível e consultar a documentação oficial correspondente à versão escolhida antes de implementar funcionalidades.

## Estado atual da implementação

- A primeira tela do hub, “Guardiões da Cidade Digital”, está implementada em `app/menus/home_screen.tscn` e `app/menus/home_screen.gd`; ela mostra cabeçalho, sprite do mascote, saudação, chamada principal para missão, barra inferior e progresso de nível/XP carregado do Autoload `Progression`. Um arco circular em `shared/progress/progress_ring.gd` envolve o círculo do nível e reflete a fração de XP até o próximo nível; ele é redesenhado somente em mudança de progresso ou tamanho.
- A tela `app/menus/map_screen.tscn` e seu script constroem a tela do mapa a partir da referência `ideias/tela_mapa.png`: título, mensagem fixa “Escolha um bairro para aceitar a missão!”, cinco distritos coloridos interativos em octógonos adaptativos (altura ampliada em 10% na escala anterior) e navegação inferior Início, Mapa, Missões e Perfil. O painel do título mantém margem superior de 5% da altura do viewport; o aviso abaixo é reposicionado para não sobrepor o cabeçalho. Em paisagem, Conhecimento e Respeito ficam mais próximos das extremidades laterais. Foram omitidos os ícones de seta e notificação da referência. As artes `ideias/mapa.png` e `ideias/mapa_horizontal.png` foram copiadas para `shared/map/assets/`; apenas a textura da orientação ativa é carregada com cache ignorado e a anterior é liberada ao girar. Os imports usam compressão lossy 0,85 e `size_limit=0`, preservando as resoluções das fontes (1024×1536 e 1672×941); as referências originais foram mantidas.
- As telas do hub, mapa e Perfil instanciam a mesma barra inferior `shared/ui/bottom_navigation.tscn` com Início, Mapa, Missões e Perfil; o item correspondente fica ativo. No hub, Mapa e o botão “Começar missão” abrem o mapa, e Perfil abre `profile_screen.tscn`; Missões mostra aviso provisório. No mapa e no Perfil, Início retorna ao hub e os itens Mapa/Perfil navegam entre as telas; Missões mostra aviso provisório. O mapa aceita toque/mouse nas formas dos bairros e seleção por setas/Enter com foco.
- A barra inferior usa ícones de casa, mapa, bandeira de missão e perfil a partir de `shared/ui/assets/icons/`; o botão principal do hub não exibe ícone. Os bairros Privacidade, Comunicação, Segurança e Respeito exibem os SVGs correspondentes de cadeado, conversa, escudo e grupo. Os SVGs originais permanecem em `ideias/`; o ícone de controle foi copiado para uso futuro, pois não há atualmente um botão de Mini games.
- O mascote é exibido por um `TextureRect` que carrega `shared/mascot/mascote.png` e preserva a proporção dentro da área responsiva, conforme a documentação da classe TextureRect no Godot 3.6. O arquivo original permanece em `ideias/` como referência visual.
- A tela inicial usa duas composições responsivas: retrato mantém a referência mobile; paisagem distribui mascote/saudação à esquerda e missão/progresso à direita. Em paisagem, o botão de missão e o painel de nível/XP formam um conjunto com espaçamento curto, centralizado verticalmente ao painel de fala da capivara. Posições, margens e escalas tipográficas usam o tamanho do viewport. O progresso fica acima da barra inferior sem sobreposição. A área da saudação foi ampliada e o corpo limitado a 88% da escala adaptativa do título para manter “Olá, Guardião!” maior que a mensagem.
- A tela `app/menus/profile_screen.tscn` e seu script seguem a composição de `ideias/tela_perfil.png`: total de XP, nível atual, XP para o próximo nível, quantidade de itens desbloqueados, abas, seis distintivos e desafio semanal. Os campos de nível, XP e inventário vêm de `Progression`; distintivos e desafio ainda são demonstrativos. Os IDs `level_reward_N` são registrados ao avançar de nível, sem nomes ou assets definidos ainda. Layout adaptativo cobre retrato e paisagem, e Perfil fica ativo no menu compartilhado.
- A tipografia usa papéis semânticos e deriva o tamanho de fonte do menor lado do viewport e dos limites do controle, sem tamanho-base fixo por objeto. Títulos e textos ajustam-se a diferentes resoluções e ao espaço disponível em cada controle. Os papéis dos títulos GUARDIÕES e DA CIDADE DIGITAL estão 30% maiores; os papéis de título e corpo da saudação estão 15% maiores. O símbolo da marca mantém seu papel tipográfico anterior. A navegação inferior usa o mesmo componente e papel tipográfico nas telas Home e Mapa.
- Os controles aceitam foco, mouse e toque. A tela de Perfil agora existe; Mini games não faz parte da barra inferior atual.
- O sprite do mascote foi copiado para `shared/mascot/` para uso em runtime; a imagem original em `ideias/` foi mantida como referência. O metadado de importação acompanha a cópia.
- `ideias/README.md` explica o uso da pasta para guardar referências visuais.
- `CHANGELOG.md` registra as mudanças importantes em formato conciso.
- Ainda não há cenas de jogo ou scripts que concedam XP. `tests/test_progression.gd` cobre nível inicial, limites de entrada, XP parcial, avanço exato, overflow de vários níveis, IDs de item e leitura/escrita JSON. `tests/test_home_screen.gd` e `tests/test_profile_screen.gd` verificam consumo do estado compartilhado e atualizações por sinal, além de layouts em retrato/paisagem e resoluções compactas.
- `tests/test_map_screen.gd` verifica a imagem correspondente à orientação, ausência da textura inativa no cache, dimensões originais após importação, margem superior de 5% do painel de título sem sobreposição ao aviso, o componente de navegação compartilhado, os cinco distritos octogonais, a escala de altura 10% maior e suas áreas de seleção em retrato/paisagem, além do feedback das opções sem destino.
- `tests/test_bottom_navigation.gd` compara conteúdo, escala tipográfica e área dos itens entre instâncias com diferentes itens ativos, nas resoluções de teste do projeto; também verifica a emissão do sinal.
- O README está em português e documenta o estado atual, abertura do projeto, estrutura e itens ainda não validados.

## Testes executados e resultados

- Os testes GDScript para progressão, Home, Perfil, mapa e navegação estão escritos. A suíte de mapa valida carregamento por orientação, ausência da textura inativa no cache, dimensões das artes, margem superior de 5% para o título e não sobreposição com o aviso. Nesta sessão os testes e a reimportação não puderam ser executados porque o executável Godot não está disponível; nenhuma asserção ou inspeção visual pós-compressão foi executada. `git diff --check` passou.
- Git 2.53.0 está disponível. O diretório reporta arquivos não rastreados, incluindo o projeto e este contexto.

## Oportunidades de otimização identificadas

- As artes do mapa foram configuradas com compressão lossy 0,85 sem reduzir resolução e carregamento exclusivo da orientação ativa. A redução real do tamanho do pacote e a qualidade visual precisam ser verificadas após reimportar no editor Godot. A compressão lossy reduz tamanho em disco, mas não memória de textura; a liberação da imagem inativa reduz a memória simultânea.
- O novo anel de progresso usa dois `draw_arc` sem antialiasing e chama `update()` somente ao mudar XP ou tamanho, sem processamento por frame; não foi identificada otimização adicional necessária nesse componente.

## Problemas conhecidos e riscos

- A versão do Godot, requisitos de exportação Android 5.1, compatibilidade do GLES2 e layout responsivo no hardware de referência ainda precisam de validação prática.
- Não há build nem teste em dispositivo real ou equivalente; os testes automatizados da tela também aguardam um ambiente com display X11 compatível.

## Pendências e próximos passos

- Confirmar a versão do Godot e renderer apropriados ao dispositivo de referência consultando a documentação oficial.
- Implementar os destinos Missões e Mini games, substituir os dados de recompensas demonstrativos por dados reais e trocar o escudo temporário pelos distintivos finais quando os assets forem disponibilizados.
- Validar build e medir desempenho, memória, carregamento e estabilidade em hardware real ou equivalente.

## Decisões em aberto

- Versão final do Godot e configuração de exportação Android.
- Minijogos e funcionalidades do escopo inicial.
