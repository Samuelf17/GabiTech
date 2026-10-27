# HackatOhm

HackatOhm é um aplicativo educativo para crianças e adolescentes que ensina conceitos de segurança digital por meio de quizzes e minijogos. Os desafios abordam temas como proteção de dados, privacidade e convivência respeitosa na internet.

## Download do APK

[Baixar HackatOhm para Android (APK)](https://github.com/Samuelf17/app-jogos/releases/latest)

## O que você encontra no app

- **Quiz diário:** perguntas sobre segurança digital, com progresso e experiência registrados.
- **Missão Anti-Bullying:** situações interativas para praticar respostas seguras e respeitosas.
- **Defesa dos Dados:** labirinto em que a capivara coleta dados e evita os spywares.
- **Progresso e recompensas:** níveis, experiência, distintivos e equipamentos que são liberados durante o jogo.
- **Acessibilidade de uso:** interface adaptada para telas em retrato e paisagem, com controles por toque e suporte a teclado/controle em partes do app.

O aplicativo está sendo desenvolvido em Godot para Android. A compatibilidade e o desempenho em dispositivos físicos, incluindo a TV Box usada como referência, ainda precisam ser validados.

## Testes automatizados

O projeto inclui testes automatizados para progressão, quizzes, minijogos, navegação e layouts. Para executar a suíte, use Godot 3.6.3:

```bash
GODOT_BIN=/caminho/para/Godot tests/run_all_tests.sh
```

## Configuração do Ambiente de Desenvolvimento

- **Engine:** Godot 3.6.3, com GDScript e renderer GLES2.
- **Android:** para exportar, configure o Android SDK, Java e os Export Templates correspondentes à versão do Godot.
- **Compatibilidade:** os requisitos de exportação e a execução em Android 5.1 devem ser conferidos no dispositivo de destino; ainda não foram validados em hardware real.
