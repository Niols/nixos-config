;; -*- no-byte-compile: t; -*-
;;; packages.el

(package! copilot
  :recipe (:host github :repo "copilot-emacs/copilot.el" :files ("*.el" "dist")))

(package! lilypond-mode
  :recipe (:host gitlab
           :repo "lilypond/lilypond"
           :files ("elisp/*.el")))
