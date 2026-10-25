# Missão Anti-Bullying

Minijogo isolado do hub em cenas, scripts e dados próprios. A implementação segue a referência `ideias/ideia-minigame1.txt`: conversas fictícias sobre desrespeito, quatro ações possíveis por situação, consequências por escolha e uma mensagem final de aprendizado no chat.

## Abrir diretamente no Godot

Abra o projeto principal no editor, selecione `scenes/anti_bullying_screen.tscn` no painel FileSystem e use **Run Current Scene (F6)**. Isso inicia o minijogo sem passar pelo hub. No app, tocar ou selecionar com Enter o Bairro do Respeito no mapa abre essa mesma cena.

As situações ficam em `data/situations.json`; a validação e leitura são isoladas em `scripts/situation_repository.gd`. O minijogo não grava progresso nem altera XP, distintivos ou dados do quiz.
