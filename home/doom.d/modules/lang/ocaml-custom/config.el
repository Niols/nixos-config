;;; lang/ocaml-custom/config.el -*- lexical-binding: t; -*-

;;
;;; Packages

(when (modulep! +lsp)
  (add-hook! '(tuareg-mode-local-vars-hook
               reason-mode-local-vars-hook)
             :append #'lsp!))


(after! tuareg
  ;; tuareg-mode has the prettify symbols itself
  (set-ligatures! 'tuareg-mode :alist
    (append tuareg-prettify-symbols-basic-alist
            tuareg-prettify-symbols-extra-alist))
  ;; harmless if `prettify-symbols-mode' isn't active
  (setq tuareg-prettify-symbols-full t)

  ;; FIXME: THIS IS WHERE THE CUSTOMIZATION TAKES PLACE
  ;;
  ;; We disable using OPAM for the environment because we trust that Nix, on the
  ;; outside, will take care of it.
  ;;
  (setq tuareg-opam-insinuate nil)
  ;(tuareg-opam-update-env (tuareg-opam-current-compiler))

  (setq-hook! 'tuareg-mode-hook
    comment-line-break-function #'+ocaml-custom/comment-indent-new-line)

  (map! :localleader
        :map tuareg-mode-map
        "a" #'tuareg-find-alternate-file)

  (use-package! utop
    :when (modulep! :tools eval)
    :hook (tuareg-mode-local-vars . +ocaml-custom-init-utop-h)
    :init
    (set-repl-handler! 'tuareg-mode #'utop)
    (set-eval-handler! 'tuareg-mode #'utop-eval-region)
    (defun +ocaml-custom-init-utop-h ()
      (when (executable-find "utop")
        (utop-minor-mode)))
    :config
    (set-popup-rule! "^\\*utop\\*" :quit nil)))


(use-package! merlin
  :unless (modulep! +lsp)
  :hook (tuareg-mode-local-vars . +ocaml-custom-init-merlin-h)
  :init
  (defun +ocaml-custom-init-merlin-h ()
    "Activate `merlin-mode' if the ocamlmerlin executable exists."
    (when (executable-find "ocamlmerlin")
      (merlin-mode)))

  (after! tuareg
    (set-company-backend! 'tuareg-mode 'merlin-company-backend)
    (set-lookup-handlers! 'tuareg-mode :async t
      :definition #'merlin-locate
      :references #'merlin-occurrences
      :documentation #'merlin-document))
  :config
  (setq merlin-completion-with-doc t)

  (map! :localleader
        :map tuareg-mode-map
        "t" #'merlin-type-enclosing)

  (use-package! flycheck-ocaml
    :when (modulep! :checkers syntax)
    :hook (merlin-mode . +ocaml-custom-init-flycheck-h)
    :config
    (defun +ocaml-custom-init-flycheck-h ()
      "Activate `flycheck-ocaml`"
      ;; Disable Merlin's own error checking
      (setq merlin-error-after-save nil)
      ;; Enable Flycheck checker
      (flycheck-ocaml-setup)))

  (use-package! merlin-eldoc
    :hook (merlin-mode . merlin-eldoc-setup))

  (use-package! merlin-iedit
    :when (modulep! :editor multiple-cursors)
    :defer t
    :init
    (map! :map tuareg-mode-map
          :v "R" #'merlin-iedit-occurrences))

  (use-package! merlin-imenu
    :when (modulep! :emacs imenu)
    :hook (merlin-mode . merlin-use-merlin-imenu)))


(use-package! ocp-indent
  ;; must be careful to always defer this, it has autoloads that adds hooks
  ;; which we do not want if the executable can't be found
  :hook (tuareg-mode-local-vars . +ocaml-custom-init-ocp-indent-h)
  :config
  (defun +ocaml-custom-init-ocp-indent-h ()
    "Run `ocp-setup-indent', so long as the ocp-indent binary exists."
    (when (executable-find "ocp-indent")
      (ocp-setup-indent))))


(use-package! ocamlformat
  :when (modulep! :editor format)
  :commands ocamlformat
  :hook (tuareg-mode-local-vars . +ocaml-custom-init-ocamlformat-h)
  :config
  (set-formatter! 'ocamlformat #'ocamlformat
    :modes '(caml-mode tuareg-mode))
  ;; TODO Fix region-based formatting support
  (defun +ocaml-custom-init-ocamlformat-h ()
    (setq +format-with 'ocp-indent)
    (when (and (executable-find "ocamlformat")
               (locate-dominating-file default-directory ".ocamlformat"))
      (when buffer-file-name
        (let ((ext (file-name-extension buffer-file-name t)))
          (cond ((equal ext ".eliom")
                 (setq-local ocamlformat-file-kind 'implementation))
                ((equal ext ".eliomi")
                 (setq-local ocamlformat-file-kind 'interface)))))
      (setq +format-with 'ocamlformat))))

;; Tree sitter
(eval-when! (modulep! +tree-sitter)
  (add-hook! 'tuareg-mode-local-vars-hook #'tree-sitter!))
