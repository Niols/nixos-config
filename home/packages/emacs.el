;; -*- lexical-binding: t; -*-

;; NOTE: the old Doom Emacs configuration can be found here:
;; https://github.com/Niols/nixos-config/tree/7e7b7d0e6337b655aa46a02b592b9b312218a5f8/home/doom

;; NOTE: most of Doom Emacs's bindings can be found here:
;; https://github.com/doomemacs/doomemacs/blob/1d7a94b96b4410a3747ec579c728a79413379e64/modules/config/default/%2Bevil-bindings.el

;; ==================== [ Looks ] ==================== ;;

(use-package doom-themes
  :ensure t
  :config
  (load-theme 'doom-one t))

;; Remove menu, toolbar, and scrollbar.
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)

(set-face-attribute
  'default nil
  :font "FiraCode Nerd Font"
  :height 100) ; in 1/10 of pt

(use-package doom-modeline
  :ensure t
  :hook (after-init . doom-modeline-mode))

(setq inhibit-startup-screen t)

;; ==================== [ Feel ] ==================== ;;

(use-package evil
  :ensure t
  :init (setq evil-want-integration t)
        (setq evil-want-keybinding nil) ; required for evil-collection
  :config
    (evil-mode 1))

(use-package evil-collection
  :ensure t
  :after evil
  :config
  (evil-collection-init)
  :custom
  (evil-collection-magit-use-z-for-folds t))

(use-package crux
  :ensure t)

(use-package general
  :ensure t
  :config
  (general-create-definer my/leader
    :keymaps 'override
    :states '(normal visual)
    :prefix "SPC")

  (my/leader
    "SPC" #'project-find-file

    "b"  '(:ignore t :which-key "buffers")
    "bb" #'consult-buffer
    "bd" #'kill-current-buffer

    "c"  '(:ignore t :which-key "code")
    "ca" #'lsp-execute-code-action
    "cd" #'+lookup/definition
    "cD" #'+lookup/references
    "cr" #'lsp-rename
    "cw" #'delete-trailing-whitespace

    "f"  '(:ignore t :which-key "files")
    "fc" #'crux-copy-file-preserve-attributes
    "ff" #'find-file
    "fr" #'crux-rename-file-and-buffer
    "fs" #'save-buffer

    "g"  '(:ignore t :which-key "git")
    "gg" #'magit-project-status

    "p"  '(:ignore t :which-key "projects")
    "pp" #'project-switch-project
    ))

(use-package which-key
  :ensure t
  :config
    (which-key-mode))

(setq confirm-kill-emacs #'y-or-n-p)

;; ==================== [ Global ] ==================== ;;
;; Some things that simply must be everywhere in Emacs.

(use-package envrc
  :ensure t
  :hook (after-init . envrc-global-mode))

(use-package hl-todo
  :ensure t
  :hook (prog-mode . hl-todo-mode))

(show-paren-mode 1)

;; When switching project, go to Magit buffer
(setq project-switch-commands 'magit-project-status)

;; Corfu for completion. Company is the old solution, very
;; stable and battle-tested, but Corfu uses more modern
;; Emacs infrastructure.
(use-package corfu
  :ensure t
  :hook (prog-mode . corfu-mode))

(use-package consult
  :ensure t
  :config
  (setq consult-project-function #'project-root))

(use-package vertico
  :ensure t
  :config
  (vertico-mode)
  (define-key vertico-map (kbd "C-j") #'vertico-next)
  (define-key vertico-map (kbd "C-k") #'vertico-previous))

(use-package orderless
  :ensure t
  :config
  (setq completion-styles '(orderless basic)))

;; ==================== [ Magit ] ==================== ;;

(use-package magit
  :ensure t
  :custom
  (magit-display-buffer-function #'magit-display-buffer-fullframe-status-v1)
  (magit-section-initial-visibility-alist
   '((stashes . hide)
     (untracked . show)
     (unstaged . show)
     (unpushed . show)
     (unpulled . show)
     (staged . show)
     (todos . hide)
     (pullreqs . show)
     (issues . hide))))

(use-package forge
  :ensure t
  :after magit)

(use-package magit-todos
  :ensure t
  :after magit
  :config (magit-todos-mode))

;; ==================== [ OCaml ] ==================== ;;

(use-package tuareg
  :ensure t
  :mode ("\\.ml\\'" . tuareg-mode)
        ("\\.mli\\'" . tuareg-mode))

;; ==================== [ Nix ] ==================== ;;

(use-package nix-mode
  :ensure t
  :mode "\\.nix\\'")
