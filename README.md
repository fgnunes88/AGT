# Arthur, O Guardião dos Tubarões

Jogo 2D (visto de lado) para crianças de 6 a 10 anos, feito em **Godot 4.3**.
Arthur pilota o mini-submarino **Manta** pelas camadas do arquipélago das Marianas,
cataloga tubarões com microchips, solta tubarões presos, foge dos drones do
Sindicato e da Corporação e, no fim, encontra o Megalodon e o Santuário Perdido.

## Como abrir

1. Baixe o Godot 4.3 (ou mais novo, versão padrão) em godotengine.org.
2. Abra o Godot, clique em **Importar** e escolha o arquivo `project.godot` desta pasta.
3. Aperte **F5** para jogar.

Não há arquivos de imagem: tudo é desenhado por código, então é fácil mudar cores e formas.

## Jogar na internet

- **Versão web pronta** na pasta `docs/` (exportada do Godot 4.3, sem threads, funciona em qualquer servidor).
- **GitHub Pages:** dê dois cliques em `publicar_github.bat`. Depois, no GitHub: *Settings > Pages >
  Deploy from a branch > main > /docs*. O jogo fica em **https://fgnunes88.github.io/AGT/**.
  (No plano grátis, o repositório precisa ser público para o Pages funcionar.)
- **Do seu PC:** dê dois cliques em `iniciar_servidor.bat` (precisa de Python; para abrir para a internet,
  instale o `cloudflared` com `winget install --id Cloudflare.cloudflared`).
- **Atualizar a versão web** depois de mudar o jogo: no Godot, *Projeto > Exportar > Web > Exportar Projeto*
  (o caminho já está configurado para `docs/index.html`), e rode `publicar_github.bat` de novo.
- **Celular e tablet:** aparecem um joystick e botões na tela (CATALOGAR, CHIP, SOLTAR, EMP, CATÁLOGO e pausa).

## Controles

| Ação | Teclado | Comando |
|---|---|---|
| Pilotar | Setas / WASD | Analógico esquerdo |
| Catalogar espécie (segurar) | Espaço | A |
| Disparar chip de proteção | F | RB |
| Soltar rede (segurar) | E | X |
| Pulso EMP | Q | B |
| Catálogo | C / Tab | Y |
| Pausa | Esc / P | Start |
| Ligar/desligar música | N | — |

## Catalogar x proteger

- **Catalogar** (segurar Espaço perto do tubarão): registra a **espécie** no catálogo. Basta uma vez por espécie.
- **Proteger** (tecla F): dispara um dardo com **chip de proteção** em cada **tubarão**. Só funciona em espécies já catalogadas.
  A mira ajuda só um pouco: tubarões rápidos exigem chegar alinhado com eles.
- Para liberar a zona seguinte são precisos **3 peças da Corporação + 6 chips** na zona (na Fossa, 3 chips liberam o ataque à antena).
- Cada espécie tem velocidade própria (o **Mako** é o mais rápido, mais veloz que o Manta). Se o Manta chegar depressa,
  o tubarão se assusta (`!`) e foge ainda mais rápido: é preciso se aproximar devagar.

## A história em 3 partes

- **Início, Recife de Coral (0 a 40 m):** aprender a pilotar, escanear e soltar tubarões. Drones laranja do Sindicato.
- **Meio, Mar Aberto e Penumbra (40 a 1000 m):** tubarões maiores e mais raros, drones brancos da Corporação. Cada zona tem 3 peças da Corporação que reforçam o casco e liberam a zona seguinte.
- **Fim, Fossa das Marianas:** Arthur sobrecarrega a antena da megabase com o EMP, as sirenes acordam o Megalodon, que destrói a base. Arthur cataloga a lenda, desce pela fenda até o Santuário Perdido, escolhe **não** registrar a descoberta e sobe para a superfície... enquanto um vulto ainda maior passa lá no fundo.

## Sistema de alerta dos drones (inspirado em Metal Gear)

- **Patrulha** (cone amarelo): o drone vai e volta.
- **Suspeita `?`** (cone laranja): Arthur ficou perto ou dentro do cone; a barrinha enche.
- **Alerta `!`** (cone vermelho): o drone persegue. Passar bem na frente dele liga o alerta na hora.
- **Busca:** o drone perdeu Arthur e procura por uns segundos antes de voltar a patrulhar.
- Dentro das **algas** Arthur fica escondido. O **EMP** desliga os drones por 4,5 s.
- Se for apanhado, ninguém se machuca: o Manta volta ao início da zona.

## Outros inimigos

- **Barco do Sindicato** (superfície, Recife): navega de um lado para o outro varrendo o mar com um holofote.
  Se o Manta ficar na luz, o barco para (`?`) e depois baixa uma **garra** (`!`) que persegue o Manta por 7 s.
  Fuja para fundo, esconda-se nas algas ou use o EMP perto da garra.
- **Boia-sonar da Corporação** (Penumbra e Fossa): fica parada e solta uma **onda de sonar** a cada 4 s.
  A luz pisca rápido e fica amarela antes da onda. Se a onda acertar o Manta fora das algas,
  os drones próximos vêm direto para lá. O EMP desliga a boia por 8 s.

## Músicas e vinhetas

Coloque os arquivos nas pastas `music/` e `sfx/` com os nomes que estão no `LEIAME.txt` de cada pasta
(ex.: `music/recife.mp3`, `sfx/nova_especie.wav`). O Godot importa sozinho quando você abre o projeto.

A pasta `sfx/` aceita 21 efeitos: vinhetas de recompensa, motor e scanner do Manta (em loop), EMP,
sons dos inimigos (suspeita, alerta, garra, sonar), sirenes, rugido e impactos do Megalodon e sons do menu.
A lista completa está em `sfx/LEIAME.txt`. Sons dos inimigos ficam mais baixos quanto mais longe do Manta.

- As músicas tocam em loop e trocam com transição suave (1,5 s) ao mudar de zona.
- Quando um drone entra em alerta, toca `perigo` e volta à música da zona 4 s depois que o alerta acaba.
- Do alarme da megabase até escanear o Megalodon, toca `megalodon`.
- Se faltar uma música, o jogo usa uma reserva (ex.: sem `mar_aberto`, toca `recife`) ou fica em silêncio.
- O volume e as reservas ficam em `scripts/music.gd`.

## Onde mexer

| Arquivo | O que tem |
|---|---|
| `scripts/data.gd` | Espécies, curiosidades, posições de algas, drones, peças, redes e gravações do pai |
| `scripts/shark_art.gd` | Desenho dos tubarões e plesiossauros |
| `scripts/drone.gd` | Inteligência artificial dos drones |
| `scripts/boat.gd`, `scripts/sonar_buoy.gd` | Barco com garra e boia-sonar |
| `scripts/main.gd` | Regras do jogo, progressão e cenas finais |
| `scripts/hud.gd`, `catalog.gd`, `title.gd`, `ending.gd` | Interface, catálogo, menu inicial e cena final |

Para **adicionar uma espécie**, acrescente uma entrada em `SPECIES` e a quantidade em `SPAWNS` (arquivo `data.gd`).

## Próximos passos sugeridos

- Missões em terra nas ilhas (sabotagem com o drone Albatroz).
- Trocar os desenhos por sprites próprios dos personagens.
