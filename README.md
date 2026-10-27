<!-- Pasta de dados do usuário Godot: /home/samuka/.local/share/godot/app_userdata/"Guardiões da Cidade Digital"/ -->
# app-jogos

Aplicativo educativo 2D para Android, planejado como um hub que reúne minijogos independentes e sistemas compartilhados.

> **Estado atual:** o hub, o mapa, a tela de Perfil/Recompensas, a missão de perguntas e respostas, a Missão Anti-Bullying e o minijogo Defesa dos Dados estão implementados. O Bairro do Respeito abre o minijogo, que também pode ser executado diretamente no editor por Run Current Scene (F6). O botão “FAZER QUIZ DIÁRIO” está temporariamente removido da tela inicial para teste de composição; o quiz continua acessível pela opção Missões na barra inferior. O ícone do app usa a arte quadrada de `ideias/icone_app.png`, copiada para `icon.png` na raiz e referenciada pela configuração do projeto. As telas Inicial e Perfil usam como fundo a imagem importada `shared/ui/assets/backgrounds/fundo.png`. O painel de progresso inicial exibe “NÍVEL” acima do número grande (sem círculo) e identifica a barra de XP como “EXPERIÊNCIA”; ambos os rótulos têm margem superior de 20% da altura do painel. Em paisagem, o grupo de nível fica centralizado na coluna à esquerda da experiência e todo o painel de progresso alinha seu centro vertical ao centro da fala da capivara. No mapa, Privacidade, Comunicação e Conhecimento aparecem em cinza com “Em Breve”; selecionar qualquer bairro toca `shared/audio/assets/map_tap.wav`. A abertura de jogos pelo mapa aguarda 0,5 s e usa fade, sem zoom. O som `shared/audio/assets/click_3.mp3` toca uma vez por acionamento, sem loop. O preset Android versionado exclui a pasta de referências `ideias/` e inclui os JSONs necessários. O Perfil exibe as abas Distintivos e Equipamento; o bloco de Quiz Diário abre a tela do quiz ao tocar/clique nos textos. Nível e XP começam em 1 e 0 e são salvos em `user://progress.json`; os custos para avançar são 2.000 XP no nível 1, 500 nos níveis 2–3, 2.000 nos níveis 4–7 e 5.000 do nível 8 em diante. Saves existentes migram preservando o XP acumulado. Cada resposta correta do quiz vale 60 XP, creditados uma única vez após as cinco respostas do dia. A missão de quiz escolhe perguntas aleatoriamente do JSON e limita a cinco respostas por dia. As animações e regras de distintivos seguem as metas documentadas abaixo. Os 13 scripts automatizados passaram com Godot 3.6.3 e renderer llvmpipe; isso não substitui testes em Android.

## Tecnologias e plataforma

- Engine e linguagem planejadas: Godot Engine e GDScript.
- Renderer configurado em `project.godot`: GLES2.
- Plataforma-alvo: Android, com a TV Box MXQ-4K com Android 5.1 como referência mínima de hardware.
- A interface se adapta a retrato (celulares) e paisagem (TVs). `shared/ui/typography.gd` centraliza a escala de fontes, com base de 0,04 do menor lado do viewport; a mensagem “Pronto para proteger a cidade digital?” da tela inicial define o tamanho de referência. Todos os textos usam Jersey 10 pelo tema global e pelo serviço tipográfico compartilhado, que mantém a escala responsiva dos papéis. Os símbolos usados nos textos foram limitados aos glifos cobertos pela fonte. Labels e botões permanecem com `rect_scale=(1, 1)`, e as fontes redimensionadas são reutilizadas por tamanho. A fonte Jersey 10 e sua licença SIL OFL estão em `shared/ui/assets/fonts/`. A apresentação ainda não foi validada visualmente em dispositivos reais e não consulta recortes de câmera/notch do sistema operacional.
- A tela do mapa carrega `shared/map/assets/mapa.png` em retrato ou `shared/map/assets/mapa_horizontal.png` em paisagem, liberando a textura anterior e ignorando o cache ao trocar orientação. As imagens-fonte mantêm suas resoluções; o importador aplica compressão com perda leve (qualidade 0,85) sem limite de tamanho. O Godot desenha as áreas de Privacidade, Comunicação, Segurança, Conhecimento e Respeito, que aceitam toque e mouse e podem ser selecionadas por teclado/controle; seus rótulos de quantidade de missões foram removidos.
- A tela `app/menus/profile_screen.tscn` segue a referência `ideias/tela_perfil.png`, usa o fundo compartilhado `shared/ui/assets/backgrounds/fundo.png` e exibe resumo de recompensas, progresso de nível e seis distintivos com o mesmo tamanho responsivo dos gadgets em Equipamento. O painel inferior mostra a contagem diária do Quiz e a mensagem de conclusão; a aba Conquistas foi removida, e Distintivos e Equipamento permanecem. O título, a descrição e a contagem do Quiz Diário abrem o quiz ao toque/clique. Os seis distintivos usam artes próprias em `shared/progress/assets/badges/`, compartilhadas com os avisos de desbloqueio e subida de nível; ficam em escala de cinza no nível 0 e mostram as cores originais após o desbloqueio. Equipamento exibe os nove gadgets de `shared/progress/assets/gadgets/`, que desbloqueiam nos níveis 2 a 10 e ficam descoloridos até o nível correspondente. O cartão do perfil usa a capivara correspondente ao nível do usuário, compartilhada com a tela inicial, e mostra o nome Gabivara. Conhecimento usa o total persistente de acertos do quiz para desbloquear níveis.
- A missão em `games/quiz/scenes/quiz_screen.tscn` segue `ideias/tela_missoes.png` e mantém o fundo sólido azul-marinho tanto durante o quiz quanto na conclusão após cinco respostas; usa as 50 perguntas de `games/quiz/data/perguntas_e_respostas.json` e sorteia uma pergunta ainda não respondida no dia. O preset Android versionado em `export_presets.cfg` inclui arquivos `.json` não importados (`include_filter="*.json"`) e exclui `ideias/` (`exclude_filter="ideias/*"`). Todo texto não titulado da missão — incluindo pergunta, respostas, progresso, dica, botões, explicação e avisos — usa a mesma escala responsiva da fala da capivara, reduzida em 3%; em paisagem, a pergunta e o indicador “PERGUNTA n DE 5” recebem mais uma redução de 10%, enquanto respostas e escala em retrato permanecem iguais. A pergunta e os rótulos das respostas quebram linha; a área do botão preserva mais de 90% do espaço para o texto, e a numeração foi removida. Títulos continuam com escala própria. O cabeçalho (voltar, título e escudo) tem 5% adicionais de margem superior, e o progresso foi reposicionado abaixo dele. O escudo permanece 10% maior, sem sobrepor o título nos viewports cobertos pelos testes. Após confirmar, o botão da resposta correta fica preenchido de verde e o da resposta errada selecionada fica preenchido de vermelho, mantendo o texto preto; outras opções permanecem brancas. Ao concluir as cinco respostas, cada acerto concede 60 XP; a rotina de conclusão é idempotente. O distintivo de Conhecimento precisa de 3 acertos para o nível 1 e, depois, `(nível desejado × 3)` novos acertos para cada novo nível; por exemplo, 6 acertos adicionais para o nível 2. O aviso de distintivo permanece sobre o quiz e fecha após cinco segundos. A mensagem fica no topo da tela; no desbloqueio o distintivo pulsa e muda de cinza para sua cor, enquanto nos avanços de nível sua escala horizontal vai a quase zero e retorna com o centro e eixo vertical fixos. Eventos não vistos permanecem persistidos. Após responder à quinta questão, aparece um painel de confirmação antes da tela de conclusão do dia; SAIR fica oculto e o botão Continuar ocupa o espaço dos dois botões. A explicação abre somente após erro e fecha pelo botão FECHAR, após 10 segundos ou toque/clique fora. O botão Voltar do Android fecha a explicação se estiver aberta; caso contrário, navega para a tela anterior. A contagem diária de cinco respostas e os identificadores já usados persistem em `user://quiz_daily_progress.json`.
- A progressão compartilhada é gerenciada por `Progression` e persiste nível, XP atual, IDs de itens desbloqueados, níveis dos distintivos, acertos acumulados e notificações pendentes em `user://progress.json`. O custo para avançar é 2.000 XP no nível 1, 500 nos níveis 2 e 3, 2.000 nos níveis 4 a 7 e 5.000 do nível 8 em diante. Saves anteriores migram do modelo linear de 2.000 XP, preservando o XP total. Cada resposta correta do quiz vale 60 XP após concluir a sessão diária de cinco respostas. Quando uma recompensa eleva o nível, `LevelUpNotifications` mantém o popup global na fila até a tela de conclusão do jogo ativo estar visível; avisos de distintivo aparecem primeiro e, em seguida, o popup de nível do usuário. A animação tem título no topo, oito giros rápidos da capivara anterior, explosão azul média e a capivara do novo nível; cada aviso fecha após cinco segundos. O Anti-Bullying soma 100 XP por acerto e desconta 20 por erro ao fim de cada rodada, aplicando o saldo apenas se positivo; o minijogo também acumula acertos para o distintivo Respeito. Defesa dos Dados concede 5 XP por item coletado e bônus de 200 XP na vitória, acumulando itens para Segurança. Cada avanço registra um ID `level_reward_N`; os gadgets dos níveis 2 a 10 aparecem na aba Equipamento e são desbloqueados ao atingir o nível indicado pelo nome do arquivo.
- A suíte tem 13 scripts e roda com Godot 3.6.3 em desktop usando llvmpipe; os 13 passaram na execução mais recente. A exportação de um pacote PCK confirmou que o caminho do banco de perguntas está incluído. A criação de um APK Android não foi concluída neste ambiente porque o keystore de assinatura não foi encontrado; portanto, a instalação do APK corrigido ainda precisa ser validada. Compatibilidade, navegação pelo botão físico em dispositivo real e desempenho no hardware de referência também não foram validados.
- A exportação para Android 5.1 e o desempenho no hardware de referência ainda não foram validados.

# Configuração do Ambiente de Desenvolvimento

Este documento descreve o processo de configuração do ambiente de desenvolvimento do projeto HackatOhm, utilizando Ubuntu no WSL, Godot Engine 3.6.3 e Android SDK para exportação de jogos para dispositivos Android.

## 1. Pré-requisitos

- Windows com WSL 2 e Ubuntu instalado.
- Godot Engine 3.6.3.
- OpenJDK 17.
- Android SDK Command-line Tools.
- Export Templates correspondentes ao Godot 3.6.3.

## 2. Instalação do Java JDK 17

O Java Development Kit (JDK) é necessário para utilizar as ferramentas de compilação e exportação para Android.

Atualize os pacotes e instale o OpenJDK 17:

```bash
sudo apt update
sudo apt install openjdk-17-jdk
```

Verifique a versão instalada:

```bash
java -version
javac -version
```

Configure a variável `JAVA_HOME` no arquivo `~/.bashrc`:

```bash
echo 'export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64' >> ~/.bashrc
echo 'export PATH="$JAVA_HOME/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

Verifique o caminho configurado:

```bash
echo $JAVA_HOME
```

## 3. Instalação do Godot Engine 3.6.3

O Godot pode ser executado diretamente a partir do arquivo disponibilizado no site oficial, sem necessidade de instalação tradicional.

### 3.1. Download

Acesse o arquivo oficial da versão 3.6.3:

https://godotengine.org/download/archive/3.6.3-stable/

Baixe a versão **Linux x86_64**.

### 3.2. Extração e execução

Instale o utilitário de extração:

```bash
sudo apt install unzip
```

Crie uma pasta para o Godot:

```bash
mkdir -p ~/Applications/Godot
```

Acesse a pasta em que o arquivo ZIP foi baixado. Caso ele esteja na pasta Downloads do Windows:

```bash
cd /mnt/c/Users/SEU_USUARIO/Downloads
```

Substitua `SEU_USUARIO` pelo nome do usuário do Windows.

Extraia o arquivo:

```bash
unzip Godot_v3.6.3-stable_linux.x86_64.zip -d ~/Applications/Godot
```

O nome do arquivo ZIP pode variar. Ajuste o comando conforme o arquivo baixado.

Dê permissão de execução ao binário:

```bash
chmod +x ~/Applications/Godot/Godot_v3.6.3-stable_linux.x86_64
```

Para facilitar a execução pelo terminal, crie um link simbólico:

```bash
sudo ln -s ~/Applications/Godot/Godot_v3.6.3-stable_linux.x86_64 /usr/local/bin/godot
```

Execute o editor:

```bash
godot
```

O WSL precisa oferecer suporte a aplicativos gráficos, normalmente por meio do WSLg.

## 4. Instalação do Android SDK

O Android SDK contém as ferramentas necessárias para compilar e exportar o projeto para dispositivos Android.

### 4.1. Download das ferramentas

Acesse:

https://developer.android.com/studio#command-line-tools-only

Baixe **Command line tools only — Linux**.

Não utilize a versão Windows, pois as ferramentas serão executadas dentro do Ubuntu no WSL.

### 4.2. Extração e organização

Acesse a pasta onde o arquivo foi baixado e crie a estrutura necessária:

```bash
mkdir -p ~/Android/cmdline-tools/latest
```

Extraia o arquivo ZIP em um diretório temporário:

```bash
unzip commandlinetools-linux-*_latest.zip -d /tmp/android-sdk
```

Mova o conteúdo da pasta `cmdline-tools` para o diretório definitivo:

```bash
mv /tmp/android-sdk/cmdline-tools/* ~/Android/cmdline-tools/latest/
```

A estrutura esperada é:

```text
~/Android/
└── cmdline-tools/
    └── latest/
        ├── bin/
        ├── lib/
        ├── NOTICE.txt
        └── source.properties
```

### 4.3. Configuração das variáveis de ambiente

Adicione as variáveis ao arquivo `~/.bashrc`:

```bash
echo 'export ANDROID_HOME="$HOME/Android"' >> ~/.bashrc
echo 'export ANDROID_SDK_ROOT="$ANDROID_HOME"' >> ~/.bashrc
echo 'export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"' >> ~/.bashrc
source ~/.bashrc
```

Verifique se o gerenciador do SDK está acessível:

```bash
sdkmanager --version
```

### 4.4. Instalação dos componentes do SDK

Aceite as licenças:

```bash
sdkmanager --licenses
```

Instale os componentes básicos:

```bash
sdkmanager "platform-tools" "platforms;android-33" "build-tools;33.0.2"
```

Os pacotes definitivos devem respeitar os requisitos de exportação do Godot 3.6.3 e a compatibilidade com os dispositivos Android de destino, incluindo Android 5.1.

## 5. Configuração do Godot para Android

### 5.1. Export Templates

Os Export Templates são necessários para gerar os executáveis do jogo.

Acesse a página oficial:

https://godotengine.org/download/archive/3.6.3-stable/

Baixe os templates correspondentes exatamente à versão 3.6.3 e instale-os em:

**Editor → Manage Export Templates → Install from File**

Selecione o arquivo de templates baixado.

### 5.2. Caminhos do SDK e Java

No editor, acesse:

**Editor → Editor Settings → Export → Android**

Configure os seguintes campos:

| Campo | Caminho |
|---|---|
| Android SDK Path | `/home/SEU_USUARIO/Android` |
| Java SDK Path | `/usr/lib/jvm/java-17-openjdk-amd64` |
| Debug Keystore | `/home/SEU_USUARIO/.android/debug.keystore` |

Substitua `SEU_USUARIO` pelo nome do usuário do Ubuntu no WSL.

O caminho do Java deve apontar para o diretório do JDK, e não para o executável `java`.

### 5.3. Geração da Debug Keystore

A Debug Keystore é utilizada para assinar os APKs de desenvolvimento.

Crie o diretório:

```bash
mkdir -p ~/.android
```

Gere a chave:

```bash
keytool -genkeypair -v \
  -keystore ~/.android/debug.keystore \
  -storepass android \
  -alias androiddebugkey \
  -keypass android \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -dname "CN=Android Debug,O=Android,C=US"
```

Essa chave é destinada a testes. Para distribuir uma versão final do aplicativo, deve-se utilizar uma chave de publicação própria e mantê-la protegida.

## 6. Verificação do ambiente

Execute os comandos abaixo para verificar as instalações:

```bash
java -version
javac -version
godot --version
sdkmanager --version
```

Após configurar os caminhos e instalar os templates, abra o projeto no Godot e acesse:

**Project → Export → Add → Android**

Configure a exportação Android e gere um APK de teste.

## 7. Observações sobre compatibilidade

- O desenvolvimento é realizado no Ubuntu por meio do WSL.
- O Godot utilizado neste projeto é a versão 3.6.3.
- O renderizador GLES2 é indicado para ampliar a compatibilidade com dispositivos antigos.
- O Android 5.1 é uma versão antiga. As versões das ferramentas de compilação, as configurações de exportação e as APIs utilizadas devem ser verificadas por meio de testes no dispositivo de destino.
- A Debug Keystore não deve ser utilizada como chave definitiva de publicação.


## Como abrir e executar

### Abrir a Missão Anti-Bullying diretamente

No editor Godot, selecione `games/anti_bullying/scenes/anti_bullying_screen.tscn` e use **Run Current Scene (F6)** para iniciar o minijogo sem passar pelo hub. No app, toque ou selecione com Enter o Bairro do Respeito no mapa. O fluxo, a leitura/validação das 31 situações e o arquivo JSON ficam isolados em `games/anti_bullying/`; cada rodada sorteia cinco situações sem repetição e Jogar Novamente faz novo sorteio. Cada resposta correta concede 100 XP e cada errada subtrai 20 XP; o saldo da rodada é aplicado ao terminar, somente quando positivo. Quatro acertos acumulados desbloqueiam Respeito; cada nível seguinte exige mais 6, 8, 10… acertos. A interface segue o exemplo de chat: cabeçalho com status online 15% maior que antes (38% acima da escala-base), além dos textos “Escolha como agir nesta conversa” e “Escolha uma resposta acima...” ampliados em 15%, participantes com nomes coloridos no mesmo tamanho das mensagens, balões recebidos escuros e escolhas em verde sobre o fundo de circuitos. Na entrada, um tutorial escurece a tela e explica as cinco situações; o botão FECHAR TUTORIAL o fecha e inicia a primeira. A explicação da resposta anterior é ocultada antes das próximas opções. O resultado final mostra XP bruto ganho, XP bruto perdido e saldo aplicado ao perfil; notificações de distintivo ficam sobre esse resultado. A conclusão também oferece Jogar Novamente ou Voltar para o Mapa; os layouts se adaptam a retrato e paisagem.

### Abrir o minijogo Defesa dos Dados diretamente

No editor Godot, selecione `games/data_protection/scenes/data_protection_screen.tscn` e use **Run Current Scene (F6)**. No app, selecione o Bairro da Segurança no mapa. A introdução usa a mensagem sobre coletar arquivos e fugir dos spywares e oferece o botão **FECHAR TUTORIAL**. Fechá-la não inicia a partida: o jogo só começa após o primeiro movimento válido. Ao jogar novamente, a introdução não reaparece, mas a partida continua aguardando movimento. Colete os dados representados pelo ícone planilha tingido de verde e evite os três hackers com arte de olhos, extraída de `ideias/olho.svg` e reduzida para 256×171; os sprites hackers antigos foram removidos por não serem usados. A música `MusicaPacMan.mp3` toca em loop a 50% de volume durante a cena, e `collectable.wav` toca a cada dado coletado. O botão de volume no cabeçalho silencia ou restaura música e efeitos; todos os textos que não são títulos usam fonte 15% maior, incluindo HUD, tutorial, resultado, botões e o nome no aviso de distintivo. Cada dado concede 5 XP e vencer a rodada concede bônus de 200 XP. A cada 300 dados protegidos acumulados desbloqueia Segurança; os níveis seguintes exigem mais 500, 700, 900… dados. A contagem de dados e o XP são gravados em lotes de dez coletas, ao concluir uma rodada ou quando o app pausa; uma interrupção abrupta pode perder até nove coletas ainda em memória. O swipe só é reconhecido quando começa e termina dentro do labirinto; ao voltar pelo botão da tela ou pelo comando Voltar do dispositivo, a rodada temporária é reiniciada antes da navegação. O resultado final apresenta XP ganho pelos dados e bônus de vitória; o total recebido aparece em um rótulo separado, com espaço livre de 5% da altura da tela antes dos botões. Os olhos dos hackers preservam as cores originais da imagem e caminham aleatoriamente, sem perseguir o jogador. Avisos de distintivo ficam sobre a tela final, sem interromper a partida. O labirinto fica vertical em retrato e horizontal em paisagem, ocupando aproximadamente 90% da largura e 76% da altura da tela em ambas as orientações. Cada abertura e cada reinício geram um labirinto procedural com novo percurso. Ao perder, a mensagem informa quantos dados foram protegidos e por que é importante manter informações pessoais seguras; ao vencer, parabeniza e confirma que todos os dados estão protegidos. O minijogo usa a capivara correspondente ao nível do usuário, oferece três vidas e mantém seus arquivos e regras isolados em `games/data_protection/`.

1. Abra o Godot Project Manager.
2. Importe a pasta deste repositório, que contém `project.godot`, e abra o projeto no editor.

Ao executar o projeto no Godot, a cena inicial abre a tela principal do hub. A composição se ajusta à orientação do viewport: retrato em celulares e paisagem em telas horizontais, como TVs. A barra inferior oferece Início, Mapa, Missões e Perfil; Mapa abre o mapa, Perfil abre as recompensas, e Missões abre o minijogo de perguntas e respostas. O botão principal da tela inicial está temporariamente removido para teste de composição. A navegação responde ao toque/clique e ao foco por teclado/controle. As transições entre telas usam fade; abrir um minijogo pelo mapa aguarda 0,5 s e não usa zoom.

Todas as telas devem reutilizar `shared/ui/bottom_navigation.tscn` para a barra inferior. Antes de adicionar o componente à tela, defina `active_item` com `home`, `map`, `missions` ou `profile`; conecte o sinal `item_selected` para tratar a navegação. O componente centraliza ícones, cores, foco e escala tipográfica responsiva.

Os ícones SVG compartilhados ficam em `shared/ui/assets/icons/`; os ícones específicos do jogo Defesa dos Dados ficam em `games/data_protection/assets/icons/`, incluindo os estados de volume ligado e mudo copiados de `ideias/`. A barra inferior usa casa, mapa, missão e perfil; os bairros do mapa usam os símbolos disponíveis de privacidade, comunicação, segurança e respeito. O botão “FAZER QUIZ DIÁRIO” está temporariamente removido da tela inicial. `ideias/` mantém os arquivos de referência originais.

## Estrutura

## Testes automatizados (obrigatório)

Toda funcionalidade nova deve incluir testes automatizados que cubram suas regras e fluxos relevantes. Após qualquer mudança no projeto, execute a suíte completa; corrija falhas e rode a suíte novamente antes de considerar a mudança concluída. Se o ambiente impedir a execução, registre o bloqueio específico e não declare os testes aprovados.

Execute todos os testes GDScript com:

```bash
GODOT_BIN=/caminho/para/Godot tests/run_all_tests.sh
```

Se `godot` estiver no `PATH`, basta executar `tests/run_all_tests.sh`. O runner encontra automaticamente todos os arquivos `tests/test_*.gd`, executa as suítes em sequência e retorna código diferente de zero se alguma falhar.

```text
app/                         # Hub, menus e navegação
  menus/
    home_screen.tscn         # Tela principal e ponto de entrada do app
    home_screen.gd
    map_screen.tscn         # Mapa ilustrado com bairros interativos
    map_screen.gd
    profile_screen.tscn     # Perfil e recompensas com distintivos temporários
    profile_screen.gd
games/                       # Minijogos independentes
  quiz/
    scenes/quiz_screen.tscn  # Missão adaptativa de perguntas e respostas
    scripts/                 # Tela, sorteio e limite diário
    data/perguntas_e_respostas.json # Banco de perguntas usado pela missão
  anti_bullying/
    scenes/anti_bullying_screen.tscn # Minijogo isolado, também iniciado pelo Bairro do Respeito
    scripts/                 # Interface e validador de dados
    data/situations.json     # Conversas, escolhas e consequências
  data_protection/
    scenes/data_protection_screen.tscn # Labirinto acessível pelo Bairro da Segurança
    scripts/                 # Tela e geração/navegação do labirinto
    assets/                  # Planilha, hacker de runtime e PNG anterior preservado
  puzzle/
  simulation/
shared/                      # Sistemas e componentes compartilhados
  ui/
    bottom_navigation.tscn   # Menu inferior reutilizável e tipografia padronizada
    bottom_navigation.gd
    badge_unlock_popup.gd   # Aviso temporário de desbloqueio e nível de distintivo
    typography.gd            # Escala tipográfica adaptativa compartilhada
    assets/
      icons/                 # Símbolos SVG reutilizáveis da interface
  accessibility/
  audio/
  mascot/
  map/
    assets/                  # Ilustração da cidade usada no mapa
  progress/
    progression_service.gd # Nível, XP, distintivos e persistência JSON
    level_up_notification_service.gd # Popups globais quando o nível aumenta
    badge_catalog.gd       # IDs, nomes e cores dos distintivos
data/                        # Catálogo e conteúdo pedagógico
  progression/
    default_progress.json   # Estado inicial: nível 1, 0 XP e inventário vazio
    progression_rules.json  # XP variável por nível: 2.000, 500, 2.000 ou 5.000
ideias/                      # Referências de desenvolvimento; excluída do preset Android
tests/                       # Testes automatizados das funcionalidades e fluxos do app
  run_all_tests.sh           # Executa os 13 scripts automatizados
```

Os designs criados no Godot devem consultar as imagens disponíveis em `ideias/`. As regras permanentes de desenvolvimento e as decisões de arquitetura estão em [AGENTS.md](AGENTS.md); o estado de implementação está em [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md).

A tela inicial escolhe uma entre dez ilustrações em `shared/mascot/levels/` conforme o nível do usuário; acima do nível 10, mantém a ilustração 10. Os arquivos-fonte permanecem em `ideias/Capivarinhas/`.
