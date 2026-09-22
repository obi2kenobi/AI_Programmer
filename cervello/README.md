# Il secondo cervello

La memoria **stabilizzata** del sistema: le decisioni prese, i concetti con un
nome, le famiglie d'errore, gli sospesi dichiarati. Una nota per concetto,
per sempre, collegata con `[[wikilink]]`.

Non è il diario (quello è la SAL) e non è la moglia degli errori (quella è
`docs/errori/REGISTRO.md`): è ciò che resta quando il diario è passato e gli
errori sono diventati vaccini. Il grafo non si naviga a mano — si interroga:

```bash
bash tools/cervello-domanda.sh in-sospeso        # gli sospesi di oggi (deterministica)
bash tools/cervello-domanda.sh archeologia wedge # la storia di un termine, con citazioni verificate
bash tools/cervello-domanda.sh collegami e002    # il sotto-grafo di un termine
```

## Come nasce una nota

```bash
printf 'corpo con [[altri-link]]' | bash tools/cervello-annota.sh mio-slug decisione "Il titolo"
```

- **tipo**: `decisione` (una scelta fatta, con il perché) · `concetto` (un'idea
  con un nome) · `famiglia` (una classe d'errore) · `sospeso` (una cosa
  dichiarata aperta) · `repo` (una verità su un repo) · `lezione` (distillata dal
  turno col /learn, nasce «da approvare»: decide il mattino)
- i wikilink rotti vengono **rifiutati**: un pensiero che punta nel vuoto non
  entra nel cervello
- l'indice si rigenera da solo; il guardiano (`tests/test-cervello.sh`)
  boccia link rotti e indici stantii

## Chi scrive, chi legge

- **scrive**: il mattino (decisioni di Luca), le sessioni sull'hub, il turno
  quando una decisione matura — mai il rumore di ogni ciclo
- **legge**: la domanda del giorno del turno (`in-sospeso`, una al giorno),
  chiunque chieda archeologia o collegamenti
- ogni affermazione del modello sulle note deve citare `percorso:riga`, e le
  citazioni si verificano a macchina — il cervello non allucina, o lo dichiara
