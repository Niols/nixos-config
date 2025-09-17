;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!

;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets.
(setq user-full-name "Nicolas “Niols” Jeannerod"
      user-mail-address "niols@niols.fr")

;; Doom exposes five (optional) variables for controlling fonts in Doom. Here
;; are the three important ones:
;;
;; + `doom-font'
;; + `doom-variable-pitch-font'
;; + `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;;
;; They all accept either a font-spec, font string ("Input Mono-12"), or xlfd
;; font string. You generally only need these two:
;; (setq doom-font (font-spec :family "monospace" :size 12 :weight 'semi-light)
;;       doom-variable-pitch-font (font-spec :family "sans" :size 13))

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-one)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
;; (setq org-directory "~/.syncthing/Organiser/")
(setq org-directory "~/bla/di/blu/")

;; (setq org-agenda-files (directory-files "~/.syncthing/Organiser/" nil "\\.org$"))

(setq org-agenda-start-on-weekday 1)
(setq org-hide-emphasis-markers t)
(setq org-log-done 'time)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; Here are some additional functions/macros that could help you configure Doom:
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

;; Enable Treemacs' follow mode by default.
(after! treemacs
  (treemacs-follow-mode 1))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Magit

;; When switching project with Projectile (eg. with `SPC p p'), run Magit.
;; Depending on the configuration, there are several ways to configure that
;; behaviour, so we go for all of them.
(setq projectile-switch-project-action #'projectile-vc)
(setq counsel-projectile-switch-project-action #'projectile-vc)
(setq +workspaces-switch-project-function #'projectile-vc)

;; FIXME: disgusting hack to “fix” my problem when opening `magit'. cf for
;; instance: https://tweag.slack.com/archives/C0T4L4QPR/p1665592172497879
(defun doom-modeline-set-project-modeline () ())
(defun doom-modeline-set-vcs-modeline () ())

;; Tell forge (via ghub) where to find my GitHub token.
(setq auth-sources '("~/.netrc"))

;; Enable Gravar in Magit when showing eg. commits.
(setq magit-revision-show-gravatars '("^Author:     " . "^Commit:     "))

;; In Forge, show up to 20open topics and 0 closed topics.
(setq forge-topic-list-limit '(20 . 0))

(after! forge
  (use-package! gitea-forge)
  (add-to-list 'forge-alist '("git.fediversity.eu" "git.fediversity.eu/api/v1" "git.fediversity.eu" forge-gitea-repository))

  ;; FIXME: finish the local PR merge
  )

;; (defun forge-checkout-pullreq (pullreq)
;;   "Create, configure and checkout a new branch from a pull-request.
;; Please see the manual for more information."
;;   (interactive (list (forge-read-pullreq "Checkout pull request")))
;;   (magit--checkout (forge--branch-pullreq (forge-get-pullreq pullreq)))
;;   (forge-refresh-buffer))




;; (defun magit-merge-into (branch &optional args)
;;   "Merge the current branch into BRANCH and remove the former.

;; Before merging, force push the source branch to its push-remote,
;; provided the respective remote branch already exists, ensuring
;; that the respective pull-request (if any) won't get stuck on some
;; obsolete version of the commits that are being merged.  Finally
;; if `forge-branch-pullreq' was used to create the merged branch,
;; then also remove the respective remote branch."
;;   (interactive
;;    (list (magit-read-other-local-branch
;;           (format "Merge `%s' into"
;;                   (or (magit-get-current-branch)
;;                       (magit-rev-parse "HEAD")))
;;           nil
;;           (and-let* ((upstream (magit-get-upstream-branch))
;;                      (upstream (cdr (magit-split-branch-name upstream))))
;;             (and (magit-branch-p upstream) upstream)))
;;          (magit-merge-arguments)))
;;   (let ((current (magit-get-current-branch))
;;         (head (magit-rev-parse "HEAD")))
;;     (when (zerop (magit-call-git "checkout" branch))
;;       (if current
;;           (magit--merge-absorb current args)
;;         (magit-run-git-with-editor "merge" args head)))))

;;   (transient-define-suffix my-forge-merge-locally (pullreq method)
;;     "Merge PULLREQ locally using METHOD.

;; This command will perform the merge locally and then push the
;; target branch.  Forges detect that you have done that and
;; respond by automatically marking the pull-request as merged."

;;     ;; NOTE: The following code is copied from `forge-merge' in
;;     ;; `forge-commands.el'.

;;     (interactive
;;      (list (forge-read-pullreq "Merge pull-request")
;;            (if (forge--childp (forge-get-repository :tracked)
;;                               'forge-gitlab-repository)
;;                (magit-read-char-case "Merge method " t
;;                  (?m "[m]erge"  'merge)
;;                  (?s "[s]quash" 'squash))
;;              (magit-read-char-case "Merge method " t
;;                (?m "[m]erge"  'merge)
;;                (?s "[s]quash" 'squash)
;;                (?r "[r]ebase" 'rebase)))))

;;     (let* ((pullreq (forge-get-pullreq pullreq))
;;            (title (oref pullreq title))
;;            (slug (forge--format-topic-slug pullreq))
;;            (url (forge-get-url pullreq))
;;            (msg (format "%s (%s)\n\nTracked at %s.\n" title slug url))
;;            ;; FIXME: THIS IS NOT WHAT WE WANT. In case of forks, this will
;;            ;; collapse miserably. Instead, we want to find the remote of the PR
;;            ;; branch and the remote of the target branch. They might be
;;            ;; different. Not sure if it is even possible to link the PR branch
;;            ;; with the branch on the fork, because the link might be lost by the
;;            ;; forge. In that case, merge from `refs/pull/X/head'.
;;            (remote (forge--get-remote))
;;            (local-pr-branch (oref pullreq head-ref))
;;            (remote-pr-branch (concat remote "/" local-pr-branch))
;;            (local-target-branch (oref pullreq base-ref))
;;            (remote-target-branch (concat remote "/" local-target-branch)))

;;       ;; Sanity check that the local branches correspond to the remote ones.
;;       (when (!= (magit-get-push-branch local-pr-branch) remote-pr-branch)
;;         (error "The branch `%s' does not have the expected upstream, `%s'." local-pr-branch remote-pr-branch))
;;       (when (!= (magit-get-push-branch local-target-branch) remote-target-branch)
;;         (error "The branch `%s' does not have the expected upstream, `%s'." local-target-branch remote-target-branch))

;;       ;; Check that the branches are up-to-date with their upstreams.
;;       (magit-git-push local-target-branch remote-target-branch (list "--force-with-lease"))
;;       (magit-git-push local-pr-branch remote-pr-branch (list "--force-with-lease"))

;;       (when (zerop (magit-call-git "checkout" local-target-branch))

;;         ;; FIXME: push force-with-lease to check that we are up-to-date.
;;         ;; FIXME: Check that local `branch', IF IT EXISTS, is up-to-date with `<remote>/<branch>'.

;;         (magit-call-git "merge" remote-pr-branch "-m" msg
;;          ;; (cond ((= method "merge") "--no-ff")
;;          ;;       ((= method "squash") "--squash")
;;          ;;       ((= method "rebase") "--ff-only"))
;;          '()))

;;       (magit-refresh)
;;     ))

;;   ;; FIXME: Find a way to add to the existing `Actions'.
;;   ;; FIXME: Merge this PR when already visiting one.
;;   ;; FIXME: Figure out why `/M' (merge with API) isn't showing. Maybe because of `:level 7'?
;;   (transient-append-suffix 'forge-dispatch '()
;;     ["Actions"
;;      ("/N" "merge locally" my-forge-merge-locally)
;;      ])
;;   )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  _
;; | |____ __
;; | (_-< '_ \
;; |_/__/ .__/
;;      |_|

(after! lsp-ui
  ;; enable `lsp-ui-doc' with `lsp-ui'
  (setq lsp-ui-doc-enable t)

  ;; Where to display the doc; default is at point.
  ;; (setq lsp-ui-doc-position)

  ;; Delay before showing documentation, in seconds.
  (setq lsp-ui-doc-delay 0.75)

  ;; Whether to show the documentation when cursor or mouse move.
  (setq lsp-ui-doc-show-with-cursor t)
  (setq lsp-ui-doc-show-with-mouse t)
)

;; I do not want LSP to execute the action automatically if there is only one.
(setq lsp-auto-execute-action nil)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Copilot

;; accept completion from copilot and fallback to company
(use-package! copilot
  :hook (prog-mode . copilot-mode)
  :bind (:map copilot-completion-map
              ("<tab>" . 'copilot-accept-completion)
              ("TAB" . 'copilot-accept-completion)
              ("C-TAB" . 'copilot-accept-completion-by-word)
              ("C-<tab>" . 'copilot-accept-completion-by-word)))

(after! (evil copilot)

  ;; Disable warning about indent-offset not specified for certain modes.
  (add-to-list 'copilot-indentation-alist '(tuareg-mode 2))
  (add-to-list 'copilot-indentation-alist '(elisp-mode 2))
  (add-to-list 'copilot-indentation-alist '(nix-mode 2))

  ;; Define the custom function that either accepts the completion or does the default behavior
  (defun my/copilot-tab-or-default ()
    (interactive)
    (if (and (bound-and-true-p copilot-mode)
             ;; Add any other conditions to check for active copilot suggestions if necessary
             )
        (copilot-accept-completion)
      (evil-insert 1))) ; Default action to insert a tab. Adjust as needed.

  ;; Bind the custom function to <tab> in Evil's insert state
  (evil-define-key 'insert 'global (kbd "<tab>") 'my/copilot-tab-or-default))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; LilyPond

(use-package! lilypond-mode
  :mode "\\.ly\\'"
  :config
  (add-hook 'lilypond-mode-hook #'prettify-symbols-mode)
  (add-hook 'lilypond-mode-hook #'display-line-numbers-mode))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; config.el ends here
