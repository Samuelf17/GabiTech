# Changelog

## Unreleased

- Criada a tela do mapa com a ilustração copiada para `shared/map/assets/`, cinco áreas de bairro interativas desenhadas no Godot e seleção por toque, mouse ou teclado/controle. Mantida a mensagem de missão e criada a navegação Início, Mapa, Missões e Perfil; hub encaminha Começar missão e Missões ao mapa. Adicionados testes direcionados; não executados porque o Godot não encontra um display X11.
- Aumentados em 30% os títulos da marca e em 15% o título e a mensagem da saudação, preservando a escala responsiva e o ajuste ao espaço dos controles.
- Corrigida a baixa visibilidade dos rótulos Missões e Perfil: os três rótulos dos atalhos agora usam branco de alto contraste sobre o fundo escuro.
- Removido o atalho Aprender; os botões de Missões, Mini games e Perfil agora reservam o espaço colorido para ícones futuros e mostram rótulos centralizados abaixo com fonte adaptativa 10% maior.
- Copiado `ideias/mascote.png` para `shared/mascot/mascote.png`, mantida a referência original e atualizado o caminho usado pela tela principal.
- Recolocado `ideias/mascote.png` como sprite da tela inicial, com proporção preservada. Mantida a tipografia adaptativa por viewport e espaço do controle; os testes cobrem escalas em retrato e paisagem e o sprite, mas aguardam ambiente com display para execução.
- Desfeitos na tela principal o aumento tipográfico de 2×/1,5× e a substituição do robô pelo sprite; os papéis de fonte adaptativos retornaram a fatores menores, e o robô responsivo foi recriado em desenho vetorial. A suíte adicionou verificações de regressão, mas continua sem execução por falta de display X11.
- Corrigida a hierarquia tipográfica da saudação em paisagem: o título ganhou área maior e a mensagem é limitada a 88% da escala do título; testes agora comparam os tamanhos e o encaixe em 1280×720 e 960×540. A execução automatizada continua bloqueada pela ausência de display X11.
- Refatorados os textos da tela inicial para papéis tipográficos adaptativos calculados pelo viewport e pelo espaço disponível em cada controle; adicionada ao `AGENTS.md` a exigência de avaliar retrato em celular e paisagem em TV.
- Ampliada a suíte responsiva com testes de retrato compacto, limites do conteúdo, feedback e redução de escala tipográfica conforme viewport menor. A execução segue pendente pela ausência de display X11; as verificações estáticas e de diff passaram.
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
