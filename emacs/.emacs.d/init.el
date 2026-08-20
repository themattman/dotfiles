;;; init.el --- Bootstrap for the literate config in configuration.org  -*- lexical-binding: t; -*-

;; Everything interesting lives in configuration.org. This file only does the
;; three things that have to happen before that file can be loaded:
;;   1. set up package.el + use-package
;;   2. keep Custom's bookkeeping out of this file
;;   3. tangle and load configuration.org

;; Don't warn when visiting a symlinked config (GNU stow).
(setq vc-follow-symlinks nil)

;; Prefer newer .el over stale .elc.
(setq load-prefer-newer t)

;;; Packages

(require 'package)
;; melpa-stable first so it wins ties; gnu stays because built-in-adjacent
;; libraries (eldoc, seq, ...) are only distributed there.
(setq package-archives
      '(("melpa-stable" . "https://stable.melpa.org/packages/")
        ("melpa"        . "https://melpa.org/packages/")
        ("gnu"          . "https://elpa.gnu.org/packages/")))

(package-initialize)

;; If use-package is missing this is almost certainly a fresh install, so
;; refresh the archives once before configuration.org starts installing things.
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(require 'use-package)

;;; Custom

;; Custom rewrites whatever file `custom-file' points at. Give it its own file
;; so it can never clobber hand-written config.
(setq custom-file (locate-user-emacs-file "custom.el"))
(when (file-exists-p custom-file)
  (load custom-file nil t))

;;; The literate configuration

;; `org-babel-load-file' tangles configuration.org to configuration.el only when
;; the .org file is newer, then loads the .el. Calling it unconditionally is what
;; makes edits to configuration.org actually take effect.
(org-babel-load-file (locate-user-emacs-file "configuration.org"))

;;; init.el ends here
