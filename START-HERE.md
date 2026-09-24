# Démarrage — à lire avant de lancer Claude Code

1. Copie `.env.example` en `.env` et remplis toutes les valeurs (pas d'espace autour du `=`).
2. Colle ton catalogue complet des 20 tickets dans `tickets/catalog.md`.
3. Dans un terminal, depuis ce dossier :
   ```
   git init
   git add .
   git commit -m "Initial project structure"
   ```
   Vérifie avec `git status` que `.env` n'apparaît PAS.
4. Prends un instantané VirtualBox de chaque VM.
5. Ouvre Claude Code en local dans ce dossier, en mode plan, et colle la consigne ci-dessous.

## Consigne de départ (mode plan)

> Lis CLAUDE.md et tickets/catalog.md. Commence par exécuter `. .\scripts\Connect-Lab.ps1; Test-Lab`
> et montre-moi le résultat. Ensuite, applique le workflow de la section 5 de CLAUDE.md à TKT-001,
> TKT-002 et TKT-003, dans l'ordre, un ticket à la fois, puis arrête-toi pour que je valide ta
> méthode, les KB et les captures. Présente-moi d'abord ton plan pour TKT-001 avant d'exécuter quoi que ce soit.

Tu peux supprimer ce fichier une fois le projet lancé.
