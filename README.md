# app-jogos

Aplicativo educativo 2D para Android, planejado como um hub que reúne minijogos independentes e sistemas compartilhados.

> **Estado atual:** primeira tela do hub implementada como cena principal: “Guardiões da Cidade Digital”. O layout reorganiza os elementos em retrato e paisagem; telas de missão, mini games, aprendizado e perfil ainda não foram implementadas.

## Tecnologias e plataforma

- Engine e linguagem planejadas: Godot Engine e GDScript.
- Renderer configurado em `project.godot`: GLES2.
- Plataforma-alvo: Android, com a TV Box MXQ-4K com Android 5.1 como referência mínima de hardware.
- A interface se adapta a retrato (celulares) e paisagem (TVs), usando margens proporcionais e redimensionando textos e controles. A apresentação ainda não foi validada em dispositivos reais e não consulta recortes de câmera/notch do sistema operacional.
- A versão do editor Godot, a exportação para Android 5.1 e o desempenho no hardware de referência ainda não foram validados.

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

1. Abra o Godot Project Manager.
2. Importe a pasta deste repositório, que contém `project.godot`, e abra o projeto no editor.

Ao executar o projeto no Godot, a cena inicial abre a tela principal do hub. A composição se ajusta à orientação do viewport: retrato em celulares e paisagem em telas horizontais, como TVs. Os botões respondem ao toque/clique e ao foco por teclado/controle; as opções sem telas implementadas mostram uma mensagem de disponibilidade futura.

## Estrutura

```text
app/                         # Hub, menus e navegação
  menus/
    home_screen.tscn         # Tela principal e ponto de entrada do app
    home_screen.gd
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
ideias/                      # Referências visuais e sprite transparente do mascote
tests/                       # Testes de regressão da tela principal
```

Os designs criados no Godot devem consultar as imagens disponíveis em `ideias/`. As regras permanentes de desenvolvimento e as decisões de arquitetura estão em [AGENTS.md](AGENTS.md); o estado de implementação está em [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md).
