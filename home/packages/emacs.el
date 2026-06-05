;; -*- lexical-binding: t; -*-

;; NOTE: the old Doom Emacs configuration can be found here:
;; https://github.com/Niols/nixos-config/tree/7e7b7d0e6337b655aa46a02b592b9b312218a5f8/home/doom

;; NOTE: most of Doom Emacs's bindings can be found here:
;; https://github.com/doomemacs/doomemacs/blob/1d7a94b96b4410a3747ec579c728a79413379e64/modules/config/default/%2Bevil-bindings.el

;; GC Magic Hack: prevents GC happening mid-typing and restores it
;; during idle time. Reinitialises the GC that we disabled in early-init.
(use-package gcmh
  :ensure t
  :hook (after-init . gcmh-mode))

;; To get a breakdown of what takes time on startup.
(use-package esup
  :ensure t
  :defer t)

;; ==================== [ Looks ] ==================== ;;

(defun my/require-magit-and-project-status ()
  (interactive)
  (require 'magit)
  (magit-project-status))

(use-package emacs
  :custom
  (inhibit-startup-screen t)
  (project-switch-commands 'my/require-magit-and-project-status)
  (auto-revert-verbose nil)
  :config
  (menu-bar-mode -1)
  (tool-bar-mode -1)
  (scroll-bar-mode -1)
  (column-number-mode 1)
  (global-auto-revert-mode 1)
  (global-display-line-numbers-mode 1)
  (global-hl-line-mode 1))

(use-package doom-themes
  :ensure t
  :config
  (load-theme 'doom-one t))

(set-face-attribute
  'default nil
  :font "Fira Code Nerd Font" ; NOTE: Fira Code does not support italic
  :height 100) ; in 1/10 of pt

(use-package doom-modeline
  :ensure t
  :hook (after-init . doom-modeline-mode))

;; ==================== [ Feel ] ==================== ;;

(use-package undo-fu
  :ensure t)

(use-package undo-fu-session
  :ensure t
  :config (undo-fu-session-global-mode))

(defun my/evil-shift-right ()
  (interactive)
  (call-interactively #'evil-shift-right)
  (evil-normal-state)
  (evil-visual-restore))

(defun my/evil-shift-left ()
  (interactive)
  (call-interactively #'evil-shift-left)
  (call-interactively fn)
  (evil-normal-state)
  (evil-visual-restore))

(use-package evil
  :ensure t
  :init
  (setq evil-want-keybinding nil) ; required for evil-collection
  :config
  (evil-mode 1)
  (define-key evil-visual-state-map (kbd ">") #'my/evil-shift-right)
  (define-key evil-visual-state-map (kbd "<") #'my/evil-shift-left)
  :custom
  (evil-shift-width 2)
  (evil-undo-system 'undo-fu))

(use-package evil-collection
  :ensure t
  :after evil
  :config
  (evil-collection-init)
  :custom
  (evil-collection-magit-use-z-for-folds t))

(use-package crux
  :ensure t
  :hook (after-init . (lambda () (require 'crux))))

(use-package general
  :ensure t
  :config
  (general-create-definer my/leader
    :keymaps 'override
    :states '(normal visual)
    :prefix "SPC")
  (my/leader
    ;; Convention: lowercase for safe operations; uppercase for
    ;; destructive/dangerous operations.

    "SPC" #'project-find-file
    "*"  #'consult-ripgrep

    "b"  '(:ignore t :which-key "buffers")
    "bb" #'consult-buffer
    "bd" #'kill-current-buffer

    "c"  '(:ignore t :which-key "code")
    "ca" #'eglot-code-actions
    "cd" #'xref-find-definitions
    "cD" #'xref-find-references
    "ci" #'ff-get-other-file
    "cr" #'eglot-rename
    "cw" #'delete-trailing-whitespace
    "cx" #'consult-flymake

    "f"  '(:ignore t :which-key "files")
    "fc" #'crux-copy-file-preserve-attributes
    "fD" #'crux-delete-file-and-buffer
    "ff" #'find-file
    "fR" #'crux-rename-file-and-buffer
    "fs" #'save-buffer

    "g"  '(:ignore t :which-key "git")
    "gg" #'my/require-magit-and-project-status

    "p"  '(:ignore t :which-key "projects")
    "pp" #'project-switch-project
    ))

(use-package which-key
  :ensure t
  :hook (after-init . which-key-mode))

;; ==================== [ Global ] ==================== ;;
;; Some things that simply must be everywhere in Emacs.

(use-package envrc
  :ensure t
  :hook (after-init . envrc-global-mode))

(use-package hl-todo
  :ensure t
  :hook (prog-mode . hl-todo-mode))

;; Corfu for completion. Company is the old solution, very
;; stable and battle-tested, but Corfu uses more modern
;; Emacs infrastructure.
(use-package corfu
  :ensure t
  :hook (prog-mode . corfu-mode)
  :custom
  (corfu-auto t))

(use-package consult
  :ensure t
  :after project
  :custom
  (consult-project-function
   (lambda (may-prompt)
     (when-let (project (project-current nil))
       (project-root project))))
  :config
  (require 'consult-xref)
  (require 'consult-flymake)
  (setq xref-show-xrefs-function #'consult-xref
	xref-show-definitions-function #'consult-xref))

(use-package vertico
  :ensure t
  :hook (after-init . vertico-mode)
  :config
  (require 'vertico-directory)
  (define-key vertico-map (kbd "C-j") #'vertico-next)
  (define-key vertico-map (kbd "C-k") #'vertico-previous)
  (define-key vertico-map (kbd "DEL") #'vertico-directory-delete-char))

(use-package orderless
  :ensure t
  :after vertico
  :custom
  (completion-styles '(orderless basic)))

;; ==================== [ Magit ] ==================== ;;

(use-package magit
  :ensure t
  :defer t
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
     (issues . hide)))
  (magit-process-finish-apply-ansi-colors t)
  :config
  (add-hook 'git-commit-mode-hook #'evil-insert-state)
  (add-hook 'magit-mode-hook (lambda () (display-line-numbers-mode 0))))

(use-package forge
  :ensure t
  :after magit
  :custom
  (forge-add-default-bindings nil)
  :config
  (set-face-attribute 'forge-pullreq-draft nil
    :background 'unspecified
    :inherit '(italic forge-dimmed)))

;; ==================== [ Prog ] ==================== ;;

(defun my/eglot-ensure-if-server ()
  (require 'eglot)
  (if (eglot--lookup-mode major-mode)
      (eglot-ensure)
    (message "[eglot] (info) no LSP server configured for %s" major-mode)))

(use-package eglot
  :hook (prog-mode . my/eglot-ensure-if-server))

(use-package cram-mode
  :mode "\\.t\\'")

(use-package tuareg
  :ensure t
  :mode ("\\.ml\\'" . tuareg-mode)
        ("\\.mli\\'" . tuareg-mode))

(use-package nix-mode
  :ensure t
  :mode "\\.nix\\'")

(use-package yaml-ts-mode
  :mode "\\.ya?ml\\'")

(use-package toml-ts-mode
  :mode "\\.toml\\'")

(use-package d-mode
  :ensure t
  :mode "\\.d\\'")

(use-package lilypond-mode
  ;; NOTE: no `:ensure t` here because it ships with LilyPond and not
  ;; in *ELPA, so it needs to be provided by the Nix environment.
  :mode "\\.ly\\'")

(use-package flycheck-lilypond
  :ensure t
  :after lilypond-mode)
