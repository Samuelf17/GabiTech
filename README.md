# GabiTech

GabiTech é um aplicativo educativo para crianças e adolescentes que ensina conceitos de segurança digital por meio de quizzes e minijogos. Os desafios abordam temas como proteção de dados, privacidade e convivência respeitosa na internet.

## Download do APK

[Baixar GabiTech para Android (APK)](https://github.com/Samuelf17/GabiTech/releases/latest)

## O que você encontra no app

- **Quiz diário:** perguntas sobre segurança digital, com progresso e experiência registrados.
- **Missão Anti-Bullying:** situações interativas para praticar respostas seguras e respeitosas.
- **Defesa dos Dados:** labirinto em que a capivara coleta dados e evita os spywares.
- **Progresso e recompensas:** níveis, experiência, distintivos e equipamentos que são liberados durante o jogo.
- **Acessibilidade de uso:** interface adaptada para telas em retrato e paisagem, com controles por toque e suporte a teclado/controle em partes do app.

O aplicativo está sendo desenvolvido em Godot para Android. O app foi executado e testado em celulares reais, no PC pelo Godot e em um emulador do sistema Android configurado com limite de 1 GB de RAM e 2 núcleos de processador. Os modelos dos celulares e as versões do Android e do emulador não foram registrados. O teste em emulador não substitui a validação em uma TV Box: esse tipo de equipamento ainda não foi testado por falta de acesso a um aparelho.

## Testes automatizados

O projeto inclui testes automatizados para progressão, quizzes, minijogos, navegação e layouts. Para executar a suíte, use Godot 3.6.3:

```bash
GODOT_BIN=/caminho/para/Godot tests/run_all_tests.sh
```

## Configuração do Ambiente de Desenvolvimento

- **Engine:** Godot 3.6.3, com GDScript e renderer GLES2.
- **Android:** para exportar, configure o Android SDK, Java e os Export Templates correspondentes à versão do Godot.
- **Compatibilidade:** houve testes em celulares reais e em emulador Android limitado a 1 GB de RAM e 2 núcleos, além da execução no PC pelo Godot. Os modelos e versões usados não foram registrados. A execução em TV Box não foi testada por falta de equipamento; a compatibilidade específica com Android 5.1 e o desempenho nesse tipo de aparelho ainda precisam ser validados.
