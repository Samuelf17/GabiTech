# Missão Anti-Bullying

Minijogo isolado do hub em cenas, scripts e dados próprios. A implementação segue a referência `ideias/ideia-minigame1.txt`: conversas fictícias sobre desrespeito, quatro ações possíveis por situação, consequências por escolha e uma mensagem final de aprendizado no chat.

## Abrir diretamente no Godot

Abra o projeto principal no editor, selecione `scenes/anti_bullying_screen.tscn` no painel FileSystem e use **Run Current Scene (F6)**. Isso inicia o minijogo sem passar pelo hub. No app, tocar ou selecionar com Enter o Bairro do Respeito no mapa abre essa mesma cena.

As 31 situações ficam em `data/situations.json`; a validação, leitura e seleção aleatória de cinco situações sem repetição por rodada são isoladas em `scripts/situation_repository.gd`. Durante a leitura, o campo `feedback` é aceito como explicação e normalizado para `explanation`, sem modificar o JSON original. A avaliação usa o booleano `correct` de cada opção; os 31 registros marcam as escolhas seguras como corretas. Ao abrir, um tutorial explica a rodada e o botão FECHAR TUTORIAL o dispensa; o tutorial não reaparece ao jogar novamente. Cada acerto concede 100 XP e cada erro desconta 20 XP; ao final da rodada, aplica-se o saldo somente se for positivo. O resultado mostra o XP bruto ganho, o XP bruto perdido e o saldo aplicado ao perfil. Acertos corretos acumulados desbloqueiam o distintivo Respeito com 4 respostas para o nível 1, depois mais 6, 8, 10… para cada nível seguinte. O popup compartilhado de progressão aparece sobre a tela de resultado. O estado é salvo por `Progression` em `user://progress.json`.
