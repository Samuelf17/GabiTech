# Changelog

## Unreleased

- Adicionada ao `AGENTS.md` a regra de testar funções alteradas e áreas relacionadas; falhas devem ser revertidas ao último estado funcional, registradas e comunicadas.
- Corrigido o desaparecimento dos títulos nos atalhos: o botão de fundo escalava novamente os rótulos filhos. O contêiner agora não aplica escala extra; adicionada uma suíte de regressão para layouts retrato, paisagem e estreito, texto centralizado, áreas da tela e feedback.
- O teste automatizado ainda não pôde ser executado: Godot 3.6.3 está instalado, mas o ambiente não fornece display X11 e esta build não inicializa sem ele.
- Implementada a primeira tela do hub “Guardiões da Cidade Digital” e configurada como cena inicial em `project.godot`; adicionados o sprite do mascote e botões com foco para teclado/controle, toque e mouse.
- Adaptado o hub para layouts de retrato e paisagem, com reposicionamento e escala conforme viewport; configuração do projeto agora permite orientação por sensor e expansão sem barras laterais.
- Ampliadas as fontes em 25% e aplicadas aos atalhos as cores que antes apareciam somente nas bordas, com texto azul-marinho para contraste.
- Centralizado o texto de todos os botões e aumentado o título para 2× e os demais textos para 1,5× os tamanhos anteriores; ajustadas as áreas do cabeçalho para essas fontes nas composições retrato e paisagem.
- Substituído o mascote procedural pelo sprite transparente de `ideias/mascote.png`, exibido com proporção preservada; removido o script de desenho antigo.
- Atualizados README e PROJECT_CONTEXT.md com o estado da tela principal e as funcionalidades que ainda são apenas demonstrativas.
- Criada a estrutura inicial de pastas modulares e a pasta `ideias/` para referências visuais; o `AGENTS.md` passou a orientar designs do Godot por essas referências.
- Os arquivos gerados para o protótipo do mascote em `shared/mascot/` foram removidos a pedido; a imagem-fonte `ideias/mascote.png` foi preservada.
- Adicionada ao `AGENTS.md` a exigência de descrever ações e aguardar confirmação explícita antes de executá-las.
