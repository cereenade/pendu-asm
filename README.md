# Pendu en assembleur

Jeu du pendu en mode texte, écrit en assembleur NASM x86-64 pour Linux.

## Prérequis

- Linux 64 bits (ou WSL sous Windows)
- `nasm`, `make`, `ld` (paquet `binutils`)

```
sudo apt install nasm make binutils
```

## Compiler et lancer

```
make
./pendu
```

Nettoyer les fichiers compilés : `make clean`

## Règles

- Un mot est tiré au hasard.
- Propose une lettre puis appuie sur Entrée.
- 6 erreurs maximum avant d'être pendu.
- Trouve toutes les lettres pour gagner.
- `Ctrl+D` pour quitter.

## Ajouter des mots

Dans `pendu.asm`, section `.data` :

```
w10 db "nouveaumot",0
words dq w0, w1, ..., w9, w10
```

Mots en minuscules, sans accents, moins de 32 lettres.

## Structure du code

| Partie | Rôle |
|---|---|
| `section .data` | Textes, dessins du pendu, liste de mots |
| `section .bss` | État de la partie (lettres trouvées, jouées, erreurs) |
| `new_game` | Tire un mot au hasard et réinitialise la partie |
| `draw` | Affiche le pendu, le mot masqué et les erreurs |
| `_start` | Boucle de jeu : saisie, vérification, victoire/défaite |

## Auteur

Ceren Yikilmaz
