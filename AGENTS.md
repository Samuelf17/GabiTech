# AGENTS.md — Diretrizes do projeto

## Objetivo

Desenvolver um aplicativo educativo mobile composto por vários minijogos 2D. Cada minijogo pode ter tema, regras e jogabilidade próprios, mas o aplicativo deve compartilhar sistemas comuns, como progresso, configurações e persistência.

## Engine e tecnologias

- **Engine:** Godot Engine.
- **Linguagem principal:** GDScript.
- Priorizar desenvolvimento para dispositivos móveis, especialmente Android, mantendo atenção a telas de diferentes tamanhos, controles por toque, desempenho e ciclo de vida do aplicativo.
- **Antes de implementar ou alterar funcionalidades, pesquise e consulte a documentação oficial do Godot**, preferencialmente a documentação da mesma versão usada pelo projeto. Não presuma APIs, comportamentos ou boas práticas sem verificar quando houver dúvida.
- Documentação oficial:
  - Boas práticas: https://docs.godotengine.org/en/stable/tutorials/best_practices/index.html
  - Organização de cenas: https://docs.godotengine.org/en/stable/tutorials/best_practices/scene_organization.html
  - Guia de estilo GDScript: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html
  - Classe Resource: https://docs.godotengine.org/en/stable/classes/class_resource.html
  - Exportação para Android: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html

## Hardware-alvo: TV Box Android

O jogo deve considerar como dispositivo-alvo mínimo a TV Box descrita no planejamento: **MXQ-4K**, com as especificações abaixo. Há variantes desse modelo; trate os dados como a configuração de referência do projeto, não como garantia para todas as unidades vendidas com esse nome.

- **SoC/processador:** Rockchip RK3229.
- **CPU:** ARM Cortex-A7, quad-core, 32 bits.
- **GPU:** ARM Mali-400 MP2.
- **Memória RAM:** 1 GB DDR3.
- **Armazenamento:** 8 GB eMMC/NAND.
- **Sistema operacional:** Android 5.1.
- **Conectividade:** Ethernet por cabo.
- **Vídeo:** HDMI; o suporte anunciado a 4K não implica capacidade de renderizar o jogo em 4K com bom desempenho.

### Requisitos de compatibilidade e desempenho

1. Priorizar jogos 2D leves e baixo consumo de memória e processamento.
2. Não presumir suporte a APIs modernas do Android ou a recursos gráficos recentes; verificar a compatibilidade real do Godot e do renderer com Android 5.1 e com a GPU-alvo na documentação oficial da versão escolhida.
3. Antes de escolher a versão do Godot, pesquisar os requisitos oficiais de exportação Android e confirmar se ela pode gerar um build compatível com Android 5.1. Não assumir que a versão `stable` atual oferece suporte a esse sistema antigo.
4. Testar builds no hardware real ou em dispositivo equivalente. Medir FPS, uso de RAM, tempo de carregamento e estabilidade.
5. Evitar texturas grandes, efeitos caros, shaders complexos e muitas animações ou objetos simultâneos. Usar assets dimensionados para a resolução necessária.
6. Tratar teclado e mouse como opções possíveis de entrada, além do toque, porque a TV Box pode ser usada com periféricos USB ou Bluetooth. Planejar navegação por foco e controles direcionais quando aplicável.
7. Projetar a interface para televisão: leitura à distância, elementos grandes, margens seguras e navegação clara por controle remoto/teclado. Não depender exclusivamente de gestos de toque.
8. Considerar o espaço limitado de armazenamento e manter o pacote e os recursos enxutos.
9. A conectividade Ethernet não significa que o jogo possa depender de conexão contínua; priorizar funcionamento offline se os requisitos do produto permitirem.

## Arquitetura escolhida

Usar uma **arquitetura modular por funcionalidade (feature-based)**, combinada com **separação em camadas compartilhadas** e **composição de cenas** do Godot.

### Princípios

1. Cada minijogo deve ser independente, com suas próprias cenas, scripts, dados e recursos.
2. O aplicativo principal (hub) gerencia menus, seleção de minijogos, navegação e funcionalidades globais.
3. Sistemas compartilhados devem oferecer interfaces claras para funcionalidades como progresso, pontuação, áudio, acessibilidade, configurações e salvamento.
4. O hub pode iniciar um minijogo e receber seu resultado, mas não deve conhecer sua lógica interna.
5. Um minijogo não deve depender diretamente da implementação interna de outro minijogo.
6. Padronizar o formato dos resultados compartilhados, mas **não forçar todos os jogos a usar as mesmas regras ou fórmulas de pontuação**.
7. Manter as regras pedagógicas e a lógica do jogo separadas da interface sempre que isso for prático.
8. Evitar arquitetura excessiva: criar abstrações e camadas quando resolverem um problema real.

### Estrutura inicial sugerida

```text
res://
├── project.godot          # Configuração e ponto de entrada do projeto Godot
├── default_env.tres        # Ambiente padrão referenciado pela configuração
├── icon.png                # Ícone referenciado pela configuração
├── .gitignore
├── README.md
├── AGENTS.md
├── PROJECT_CONTEXT.md
├── app/
│   ├── main.tscn
│   ├── menus/
│   └── navigation/
├── games/
│   ├── quiz/
│   │   ├── scenes/
│   │   ├── scripts/
│   │   ├── data/
│   │   └── assets/
│   ├── puzzle/
│   │   ├── scenes/
│   │   ├── scripts/
│   │   ├── data/
│   │   └── assets/
│   └── simulation/
│       ├── scenes/
│       ├── scripts/
│       ├── data/
│       └── assets/
├── shared/
│   ├── progress/
│   ├── audio/
│   ├── accessibility/
│   ├── ui/
│   └── mascot/
├── data/
│   ├── lessons/
│   └── game_catalog/
├── tests/
└── ideias/                 # Referências visuais do app e dos minijogos
    └── (imagens de design)
```

Essa estrutura é uma referência inicial, não uma exigência rígida. Ajuste-a conforme o escopo real do projeto e as recomendações atuais da documentação do Godot.

## Padrão de código escolhido

Usar **GDScript com tipagem estática sempre que possível**, orientação a objetos pragmática, composição de cenas e separação clara de responsabilidades.

### Convenções

- Declarar tipos de variáveis, parâmetros e retornos quando possível.
- Seguir o guia de estilo oficial do GDScript.
- Usar nomes de classes em `PascalCase` e funções/variáveis em `snake_case`.
- Preferir scripts pequenos, coesos e com responsabilidade única.
- Separar dados configuráveis da lógica; considerar `Resource` para perguntas, níveis, configurações e conteúdo pedagógico.
- Usar `signal` para comunicar eventos entre componentes que não devem depender diretamente uns dos outros.
- Usar máquinas de estado quando houver fluxos explícitos, como `READY`, `PLAYING`, `FEEDBACK` e `FINISHED`.
- Usar Repository ou serviços de dados quando for útil isolar a origem e o formato do conteúdo.
- Passar dependências explicitamente quando isso reduzir acoplamento e facilitar testes.
- Usar Autoload apenas para serviços ou estados realmente globais; evitar singletons como solução padrão para toda comunicação.
- Não aplicar padrões de projeto apenas por formalidade. Preferir a solução mais simples que mantenha o código organizado.

### Padrões que podem ser usados

- **Composition:** construir funcionalidades a partir de cenas e componentes reutilizáveis.
- **Single Responsibility Principle (SRP):** cada script deve ter uma responsabilidade clara.
- **State Machine:** controlar estados e transições de uma atividade.
- **Observer via signals:** comunicar eventos sem acoplamento desnecessário.
- **Repository:** isolar carregamento e acesso ao conteúdo.
- **Dependency Injection:** fornecer serviços e dependências explicitamente quando útil.

Esses padrões são ferramentas, não obrigações para todos os scripts.

## Regras de implementação

### Confirmação antes de agir

- Antes de executar qualquer ação no projeto, descreva claramente o que será feito e como será feito; aguarde a confirmação explícita do usuário e só então execute.
- A confirmação cobre o escopo descrito. Se o plano ou o escopo mudar, descreva a mudança e aguarde nova confirmação.

1. Antes de começar uma tarefa, inspecione a estrutura e o código existentes para entender as convenções do projeto.
2. Consulte a documentação oficial do Godot antes de usar APIs desconhecidas ou decidir sobre arquitetura, exportação, ciclo de vida ou recursos específicos da engine.
3. Preserve os limites entre o aplicativo principal, cada minijogo e os sistemas compartilhados.
4. Não crie um controlador central gigante com condicionais para administrar a lógica de todos os minijogos.
5. Evite dependências circulares entre cenas, scripts e sistemas.
6. Considere entrada por toque, áreas seguras da tela, diferentes resoluções, suspensão e retomada do aplicativo.
7. Trate erros de carregamento e salvamento explicitamente.
8. Escreva ou atualize testes para regras importantes, especialmente lógica de avaliação, progressão e persistência.
9. Não introduza bibliotecas, padrões ou camadas adicionais sem justificar o benefício.
10. Ao finalizar uma tarefa, informe resumidamente o que foi alterado, quais testes foram executados e quaisquer limitações relevantes.
11. Antes de criar ou alterar designs visuais no Godot, consulte as imagens da pasta `ideias/` e use-as como referência para a interface e os elementos visuais do app e dos minijogos.
12. Mantenha `README.md` em formato claro e adequado ao GitHub, com objetivo, estado atual, requisitos confirmados, instruções de abertura/execução e estrutura do projeto. Atualize-o quando essas informações mudarem e identifique explicitamente o que ainda não foi validado; não invente funcionalidades, comandos ou requisitos.
13. Após cada mudança de código, execute testes direcionados às funções alteradas e verificações de regressão nas funções e fluxos relacionados. Cubra os modos de tela e entradas afetados e confira erros de execução; não declare sucesso para verificações que não puderam ser executadas.
14. Se algum teste falhar após uma mudança, reverta o código funcional afetado ao último estado anterior à mudança, registre e descreva a falha e qualquer alteração indesejada, e informe o usuário. Preserve mudanças independentes e não esconda a falha.
15. Não defina tamanhos absolutos de fonte por objeto. Use papéis tipográficos com escala calculada pelo tamanho do viewport e pelo espaço disponível no controle. Ao alterar uma interface, analise sempre primeiro a resolução e o posicionamento em retrato para celular e também a composição em paisagem para TV; inclua resoluções menores nos testes responsivos.
16. Avalie comandos, APIs, recursos e abordagens propostas contra os requisitos mínimos de hardware, sistema operacional, renderer e desempenho descritos neste documento. Se algo não for adequado ou não puder rodar no dispositivo de referência, informe isso e proponha alternativas viáveis; se nenhuma alternativa for viável, deixe essa limitação explícita.
17. Após cada mudança, revise o projeto como um todo em busca de funcionalidades ou elementos que possam ser otimizados. Relate cada oportunidade encontrada, explique como poderia ser otimizada e aguarde confirmação explícita antes de implementar otimizações fora do escopo autorizado.

### Navegação inferior compartilhada

- Todas as telas com navegação inferior devem instanciar `shared/ui/bottom_navigation.tscn`; não recrie os itens nem calcule outra escala tipográfica no script da tela.
- Antes de adicionar a cena à árvore, defina `active_item` como `home`, `map`, `missions` ou `profile`, e conecte o sinal `item_selected` para que a tela decida o destino.
- O componente compartilhado é a fonte única de rótulos, ícones, cores, foco e escala tipográfica do menu. Atualize-o se o padrão visual mudar, e valide todas as telas que o usam.
- Guarde novos ícones SVG reutilizáveis em `shared/ui/assets/icons/`; mantenha `ideias/` como referência e copie os assets que forem usados em runtime.
- Todas as telas devem usar os papéis responsivos de `shared/ui/typography.gd`, cuja base é a mensagem “Pronto para proteger a cidade digital?” da tela inicial. Não crie tabelas isoladas de escala tipográfica por tela.

## Persistência e dados

- Separar o estado temporário da partida do progresso persistente.
- Para protótipos offline, formatos locais como JSON podem ser suficientes; escolha o mecanismo com base nos requisitos e consulte a documentação oficial.
- Validar dados carregados e lidar com arquivos ausentes, inválidos ou incompatíveis.
- Não tratar dados locais como confiáveis em cenários competitivos ou com resultados online.

## Princípio geral

Priorizar código legível, modular, testável e adequado ao escopo. A arquitetura deve permitir adicionar minijogos com mecânicas diferentes sem reescrever o hub ou os sistemas compartilhados.

## Memória compartilhada entre agentes

Manter um arquivo `PROJECT_CONTEXT.md` na raiz do repositório como contexto compartilhado para agentes de programação (por exemplo, Codex e GitHub Copilot). O objetivo é permitir continuidade entre ferramentas usando o próprio repositório, sem presumir que os agentes conversem diretamente entre si.

### Responsabilidades dos arquivos

- `AGENTS.md`: instruções permanentes de trabalho, arquitetura, convenções e restrições do projeto.
- `PROJECT_CONTEXT.md`: estado atual do projeto, decisões técnicas vigentes, justificativas, pendências, problemas conhecidos e próximos passos relevantes.
- `CHANGELOG.md`: histórico conciso de mudanças importantes e entregas, quando for útil ao projeto.

### Regras para consultar e atualizar o contexto

1. No início de uma tarefa, leia este `AGENTS.md` e consulte `PROJECT_CONTEXT.md` se existir; inspecione também o código e os arquivos reais antes de confiar em descrições anteriores.
2. Ao concluir uma tarefa que altere a arquitetura, decisões técnicas, dependências, compatibilidade, estrutura, funcionalidades relevantes ou estado de implementação, atualize `PROJECT_CONTEXT.md` para refletir o estado resultante.
3. Registre apenas informações úteis para continuar o trabalho: resumo do estado atual, decisões e motivos, arquivos ou módulos relevantes, testes executados e seus resultados, limitações, riscos e pendências.
4. Diferencie fatos verificados de hipóteses e decisões ainda não validadas. Não registre compatibilidade como confirmada sem evidência ou teste adequado.
5. Não use a memória como substituta do código, dos testes ou da documentação oficial. Se houver conflito, verifique o repositório e o comportamento real; corrija o contexto desatualizado.
6. Não registre transcrições completas de conversas, logs extensos ou detalhes triviais. Mantenha o arquivo conciso, organizado e atualizado.
7. Não invente tarefas concluídas, resultados de testes, arquivos existentes ou decisões atribuídas a outro agente. Informe explicitamente quando algo não foi testado.
8. Antes de editar o contexto, leia sua versão atual e preserve informações válidas. Evite sobrescrever mudanças recentes feitas por outra ferramenta ou pessoa.
9. Se houver trabalho simultâneo, conflitos ou incerteza sobre uma decisão, não resolva silenciosamente por suposição: sinalize o conflito e peça revisão quando necessário. Use commits e revisão de diff para coordenar alterações concorrentes.
10. Ao final da tarefa, informe brevemente se o contexto compartilhado foi atualizado e resuma o que foi registrado. Se a tarefa não alterar o estado duradouro do projeto, não atualize o arquivo sem necessidade.

### Formato sugerido para `PROJECT_CONTEXT.md`

Quando esse arquivo ainda não existir e uma tarefa relevante exigir sua criação, use uma estrutura concisa semelhante a esta, adaptada ao estágio real do projeto:

```markdown
# Contexto atual do projeto

## Objetivo e escopo
## Ambiente e restrições técnicas
## Arquitetura e decisões vigentes
## Estado atual da implementação
## Testes executados e resultados
## Problemas conhecidos e riscos
## Pendências e próximos passos
## Decisões em aberto
```

Inclua datas quando ajudarem a entender decisões ou pendências. Para cada decisão importante, registre a justificativa e se ela foi validada na prática. Não crie `PROJECT_CONTEXT.md` apenas para preencher seções sem conteúdo útil; crie-o quando houver contexto duradouro a compartilhar.

### Fluxo de trabalho entre agentes

- Qualquer agente que comece uma tarefa deve ler o contexto compartilhado e confirmar os pontos importantes contra o estado real do projeto.
- O agente que concluir uma alteração relevante deve atualizar o contexto compartilhado antes de encerrar a tarefa, sem afirmar que outro agente foi notificado automaticamente.
- O agente seguinte deve revisar as alterações no código e no contexto, em vez de confiar cegamente no resumo deixado pelo agente anterior.
- Manter as instruções específicas de cada ferramenta separadas apenas quando necessário; as decisões centrais do projeto devem permanecer consistentes e, de preferência, registradas em um único lugar.
