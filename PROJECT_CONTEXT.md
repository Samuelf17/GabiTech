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
- `shared/ui/bottom_navigation.tscn` e `bottom_navigation.gd` são o componente obrigatório de navegação inferior para telas existentes e novas. Ele define rótulos, ícones SVG, estados, foco e um papel tipográfico adaptativo baseado no texto de fala da tela inicial (`0.035995` do menor lado, limitado pela área disponível). As telas devem indicar `active_item` e responder ao sinal `item_selected`; essa API foi implementada nas telas Home, Mapa e Perfil. Os assets de interface compartilhados ficam em `shared/ui/assets/icons/`.
- `Progression` (`shared/progress/progression_service.gd`) é um Autoload para o estado compartilhado de nível, experiência atual e itens desbloqueados. A regra configurável em `data/progression/progression_rules.json` é 2.000 XP por nível; o estado inicial está em `default_progress.json` e a cópia persistente é `user://progress.json`. A API de avanço existe para integração futura e testes, mas nenhuma atividade do jogo concede XP ainda.
- Pastas base criadas para `app`, `games` (quiz, puzzle e simulation), `shared` (incluindo `mascot`), `data`, `tests` e `ideias`; a estrutura segue a referência de organização documentada em `AGENTS.md` e a orientação oficial do Godot para manter cenas independentes e com baixo acoplamento.
- Arquivos de configuração e documentação permanecem na raiz (`project.godot`, `default_env.tres`, `icon.png`, README e instruções); a configuração aponta diretamente para os recursos de ambiente e ícone por caminhos `res://` na raiz. Nenhum arquivo de implementação ou conteúdo de jogo existente precisou ser realocado.
- Os designs visuais feitos no Godot devem consultar as imagens de referência em `ideias/`; o turnaround `ideias/mascote.png` orienta o mascote 2D compartilhado.
- Priorizar jogos 2D leves, operação offline, interface legível à distância e entrada por toque, teclado e controle direcional.
- Usar GDScript com tipagem estática quando possível e consultar a documentação oficial correspondente à versão escolhida antes de implementar funcionalidades.

## Estado atual da implementação

- A primeira tela do hub, “Guardiões da Cidade Digital”, está implementada em `app/menus/home_screen.tscn` e `app/menus/home_screen.gd`; ela mostra cabeçalho, sprite do mascote, saudação, chamada principal para missão, barra inferior e progresso de nível/XP carregado do Autoload `Progression`. Um arco circular em `shared/progress/progress_ring.gd` envolve o círculo do nível e reflete a fração de XP até o próximo nível; ele é redesenhado somente em mudança de progresso ou tamanho.
- A tela `app/menus/map_screen.tscn` e seu script constroem a tela do mapa a partir da referência `ideias/tela_mapa.png`: título, mensagem fixa “Escolha um bairro para aceitar a missão!”, cinco distritos coloridos interativos em octógonos adaptativos (altura ampliada em 10% na escala anterior) e navegação inferior Início, Mapa, Missões e Perfil. O painel do título mantém margem superior de 5% da altura do viewport; o aviso abaixo é reposicionado para não sobrepor o cabeçalho. Em paisagem, Conhecimento e Respeito ficam mais próximos das extremidades laterais. Foram omitidos os ícones de seta e notificação da referência. As artes `ideias/mapa.png` e `ideias/mapa_horizontal.png` foram copiadas para `shared/map/assets/`; apenas a textura da orientação ativa é carregada com cache ignorado e a anterior é liberada ao girar. Os imports usam compressão lossy 0,85 e `size_limit=0`, preservando as resoluções das fontes (1024×1536 e 1672×941); as referências originais foram mantidas.
- As telas do hub, mapa e Perfil instanciam a mesma barra inferior `shared/ui/bottom_navigation.tscn` com Início, Mapa, Missões e Perfil; o item correspondente fica ativo. No hub, Mapa e o botão “Começar missão” abrem o mapa, Perfil abre `profile_screen.tscn` e Missões abre a missão de quiz. No mapa e no Perfil, Início retorna ao hub e os itens Mapa/Perfil navegam entre as telas; Missões abre o quiz. O mapa aceita toque/mouse nas formas dos bairros e seleção por setas/Enter com foco.
- A barra inferior usa ícones de casa, mapa, bandeira de missão e perfil a partir de `shared/ui/assets/icons/`; o botão principal do hub não exibe ícone. Os bairros Privacidade, Comunicação, Segurança e Respeito exibem os SVGs correspondentes de cadeado, conversa, escudo e grupo. Os SVGs originais permanecem em `ideias/`; o ícone de controle foi copiado para uso futuro, pois não há atualmente um botão de Mini games.
- O mascote é exibido por um `TextureRect` que carrega `shared/mascot/mascote.png` e preserva a proporção dentro da área responsiva, conforme a documentação da classe TextureRect no Godot 3.6. O arquivo original permanece em `ideias/` como referência visual.
- A tela inicial usa duas composições responsivas: retrato mantém a referência mobile; paisagem distribui mascote/saudação à esquerda e missão/progresso à direita. Em paisagem, o botão de missão e o painel de nível/XP formam um conjunto com espaçamento curto, centralizado verticalmente ao painel de fala da capivara. Posições, margens e escalas tipográficas usam o tamanho do viewport. O progresso fica acima da barra inferior sem sobreposição. A área da saudação foi ampliada e o corpo limitado a 88% da escala adaptativa do título para manter “Olá, Guardião!” maior que a mensagem.
- A tela `app/menus/profile_screen.tscn` e seu script seguem a composição de `ideias/tela_perfil.png`: total de XP, nível atual, XP para o próximo nível, quantidade de itens desbloqueados, abas, seis distintivos e desafio semanal. O título “Recompensas” mantém margem superior adicional de 2% da altura do viewport. Os campos de nível, XP e inventário vêm de `Progression`; distintivos e desafio ainda são demonstrativos. Os IDs `level_reward_N` são registrados ao avançar de nível, sem nomes ou assets definidos ainda. Layout adaptativo cobre retrato e paisagem, e Perfil fica ativo no menu compartilhado.
- A missão de quiz em `games/quiz/scenes/quiz_screen.tscn` segue `ideias/tela_missoes.png`, com cabeçalho da missão, progresso diário em cinco segmentos, pergunta, opções, dica e confirmação; a composição adapta os controles ao viewport retrato/paisagem. Todos os textos, inclusive os títulos, usam o papel `body` baseado na fala “Pronto para proteger a cidade digital?” da tela inicial. `games/quiz/data/perguntas_e_respostas.json` contém as 50 perguntas copiadas da pasta de referências. O preset Android precisa de `include_filter="*.json"` para empacotar dados JSON não importados; `export_presets.cfg` é ignorado pelo Git para não versionar configurações de assinatura. `quiz_question_repository.gd` valida o esquema (`tema`, `pergunta`, `opcoes`, `respostaCorreta`, `explicacao`) e sorteia perguntas aleatórias entre as ainda não respondidas no dia. `quiz_daily_progress.gd` grava índices respondidos e a data em `user://quiz_daily_progress.json`, reseta no próximo dia local e impede uma sexta resposta. O feedback pinta a resposta correta de verde e, se a selecionada estiver errada, pinta-a de vermelho. O pop-up mostra a explicação do JSON e fecha com timer de 10 s ou toque/clique fora; depois abre a pergunta inferior para continuar ou sair. Após cinco respostas, informa que haverá mais perguntas no dia seguinte, oculta os dois controles de voltar e exibe `shared/ui/bottom_navigation.tscn` com Missões ativo. Nas perguntas, a seta superior usa `shared/ui/assets/icons/arrow_back_icon.svg`, cuja referência original está em `ideias/arrow_back_icon.svg`; a tipografia usa os mesmos papéis adaptativos compartilhados.
- `shared/ui/typography.gd` centraliza os papéis e multiplicadores tipográficos adaptativos usados pela Home, Mapa, Perfil e navegação inferior. O texto “Pronto para proteger a cidade digital?” é a base (`0.035995` do menor lado do viewport); todos os textos que não são títulos usam esse tamanho como referência e se ajustam ao espaço dos controles. Os títulos GUARDIÕES e DA CIDADE DIGITAL continuam 30% maiores; “Olá, Guardião!” e o texto da saudação continuam 15% maiores. Os distintivos do Perfil cresceram 20% em relação ao tamanho anterior (38% sobre a base anterior ao primeiro aumento).
- Os controles aceitam foco, mouse e toque. A tela de Perfil agora existe; Mini games não faz parte da barra inferior atual.
- O sprite do mascote foi copiado para `shared/mascot/` para uso em runtime; a imagem original em `ideias/` foi mantida como referência. O metadado de importação acompanha a cópia.
- `ideias/README.md` explica o uso da pasta para guardar referências visuais.
- `CHANGELOG.md` registra as mudanças importantes em formato conciso.
- Ainda não há atividades que concedam XP. `tests/test_progression.gd` cobre nível inicial, validação e preservação de salvamento inválido, limites de entrada, XP parcial, avanço exato, overflow de vários níveis, IDs de item, cópia defensiva e falha de gravação. `tests/test_quiz_screen.gd` cobre carregamento/sorteio e validação do JSON, limite e persistência diária, feedback certo/errado, pop-up, saída por clique externo e composições responsivas. `tests/test_home_screen.gd`, `tests/test_map_screen.gd`, `tests/test_profile_screen.gd` e `tests/test_bottom_navigation.gd` verificam papéis tipográficos e layouts adaptativos; `tests/test_progress_ring.gd` e `tests/test_typography.gd` cobrem os serviços compartilhados. `tests/run_all_tests.sh` executa os oito scripts sequencialmente.
- `tests/test_map_screen.gd` verifica a imagem correspondente à orientação, ausência da textura inativa no cache, dimensões originais após importação, margem superior de 5% do painel de título sem sobreposição ao aviso, o componente de navegação compartilhado, os cinco distritos octogonais, a escala de altura 10% maior e suas áreas de seleção em retrato/paisagem, além do feedback das opções sem destino.
- `tests/test_bottom_navigation.gd` compara conteúdo, escala tipográfica e área dos itens entre instâncias com diferentes itens ativos, nas resoluções de teste do projeto; também verifica a emissão do sinal.
- O README está em português e documenta o estado atual, abertura do projeto, estrutura e itens ainda não validados.

## Testes executados e resultados

- Em 2026-10-23, `GODOT_BIN=/home/samuka/Applications/Godot/Godot.64 tests/run_all_tests.sh` executou as oito suítes com Godot 3.6.3 e renderer llvmpipe; todas passaram. Uma exportação PCK de verificação confirmou que `games/quiz/data/perguntas_e_respostas.json` está empacotado com `include_filter="*.json"` no preset Android local. A tentativa de exportar APK não concluiu porque o keystore de assinatura não foi encontrado; instalação em aparelho ainda não validada. As verificações negativas de progressão imprimem erros esperados ao testar JSON inválido e falha de escrita.
- Git 2.53.0 está disponível. O diretório reporta arquivos não rastreados, incluindo o projeto e este contexto.

## Oportunidades de otimização identificadas

- As artes do mapa foram configuradas com compressão lossy 0,85 sem reduzir resolução e carregamento exclusivo da orientação ativa. A redução real do tamanho do pacote e a qualidade visual precisam ser verificadas após reimportar no editor Godot. A compressão lossy reduz tamanho em disco, mas não memória de textura; a liberação da imagem inativa reduz a memória simultânea.
- O novo anel de progresso usa dois `draw_arc` sem antialiasing e chama `update()` somente ao mudar XP ou tamanho, sem processamento por frame; não foi identificada otimização adicional necessária nesse componente.
- A tela de quiz usa controles 2D leves e um JSON local com 50 registros; não foi identificada otimização específica adicional para o escopo desta tarefa. O layout e o tamanho de texto ainda precisam de inspeção visual no editor.

## Problemas conhecidos e riscos

- A versão do Godot, requisitos de exportação Android 5.1, compatibilidade do GLES2 e layout responsivo no hardware de referência ainda precisam de validação prática.
- Não há build nem teste em dispositivo real ou equivalente. Os testes automatizados passaram em ambiente desktop com renderer llvmpipe, mas isso não valida desempenho, compatibilidade Android nem apresentação em hardware real.

## Pendências e próximos passos

- Confirmar a versão do Godot e renderer apropriados ao dispositivo de referência consultando a documentação oficial.
- Implementar os destinos Missões e Mini games, substituir os dados de recompensas demonstrativos por dados reais e trocar o escudo temporário pelos distintivos finais quando os assets forem disponibilizados.
- Validar build e medir desempenho, memória, carregamento e estabilidade em hardware real ou equivalente.

## Decisões em aberto

- Versão final do Godot e configuração de exportação Android.
- Minijogos e funcionalidades do escopo inicial.
