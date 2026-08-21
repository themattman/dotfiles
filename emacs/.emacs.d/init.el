;;; init.el --- Bootstrap for the literate config in configuration.org  -*- lexical-binding: t; -*-

;; Everything interesting lives in configuration.org. This file only does the
;; four things that have to happen before that file can be loaded:
;;   1. activate installed packages (cheaply)
;;   2. set up use-package
;;   3. keep Custom's bookkeeping out of this file
;;   4. tangle, byte-compile, and load configuration.org

;; Don't warn when visiting a symlinked config (GNU stow).
(setq vc-follow-symlinks nil)

;; Prefer newer .el over stale .elc.
(setq load-prefer-newer t)

;;; Packages

;; package.el itself costs ~0.28s to load, and on a normal boot it is not needed
;; at all: package-quickstart.el already contains every autoload and load-path
;; entry. The only thing it references from package.el is one variable, so stub
;; that and skip the require entirely. package.el is loaded lazily below, and
;; only when a package is actually missing.
(defvar package-activated-list nil
  "Stubbed so package-quickstart.el can load without package.el.
package.el's own `defvar' will not clobber this once it is non-nil.")

(defvar mrk/packages
  '(auto-complete auto-complete-clang clang-format diff-hl engine-mode
    expand-region flycheck gnu-elpa-keyring-update helpful htmlize lsp-mode
    lsp-ui markdown-mode mo-git-blame multi-term org-bullets symbol-overlay
    use-package web-mode yaml-mode yasnippet)
  "Packages this configuration expects to be installed.")

(defvar mrk/package-archives
  '(("melpa-stable" . "https://stable.melpa.org/packages/")
    ("melpa"        . "https://melpa.org/packages/")
    ("gnu"          . "https://elpa.gnu.org/packages/"))
  "Archives to use when something actually has to be installed.
melpa-stable is first so it wins ties; gnu stays because built-in-adjacent
libraries (eldoc, seq, ...) are only distributed there.")

(defun mrk/install-missing-packages (missing)
  "Load package.el the slow way and install MISSING, then refresh quickstart."
  (require 'package)
  (setq package-archives mrk/package-archives
        package-quickstart t)
  (package-initialize)
  (package-refresh-contents)
  (dolist (pkg missing)
    (unless (package-installed-p pkg)
      (package-install pkg)))
  (package-quickstart-refresh))

(let ((quickstart (locate-user-emacs-file "package-quickstart.el")))
  (if (file-readable-p quickstart)
      (load quickstart nil t)
    ;; First run, or the file was deleted: build it once.
    (require 'package)
    (setq package-archives mrk/package-archives
          package-quickstart t)
    (package-initialize)
    (package-quickstart-refresh)))

;; Cheap membership test against the list quickstart just populated -- no
;; filesystem work, no package.el. Only a genuinely missing package pays.
;; Hand-rolled with dolist rather than `seq-remove': requiring seq for one
;; filter costs 0.068s, which is more than everything else in this file.
(let ((missing nil))
  (dolist (pkg mrk/packages)
    (unless (memq pkg package-activated-list)
      (push pkg missing)))
  (when missing
    (message "Installing missing packages: %s" missing)
    (mrk/install-missing-packages missing)))

(defun mrk/rebuild-package-quickstart ()
  "Regenerate package-quickstart.el by hand.
Needed if packages were installed by something other than package.el, or after
deleting a package."
  (interactive)
  (require 'package)
  (setq package-archives mrk/package-archives
        package-quickstart t)
  (package-initialize)
  (package-quickstart-refresh)
  (message "package-quickstart.el rebuilt"))

;; NOTE: use-package is deliberately *not* required here. configuration.org is
;; byte-compiled, and its own `eval-when-compile' pulls use-package in at
;; compile time to expand the macros. The compiled output contains only plain
;; autoload/add-hook/define-key forms, so nothing needs use-package at runtime.
;; `use-package--warning' is the one exception -- it appears inside the error
;; handlers of each expansion -- so provide a fallback rather than loading the
;; whole library for a code path that should never run.
(unless (fboundp 'use-package--warning)
  (defun use-package--warning (keyword err)
    (message "use-package error (%s): %S" keyword err)))

;;; Custom

;; Custom rewrites whatever file `custom-file' points at. Give it its own file
;; so it can never clobber hand-written config.
(setq custom-file (locate-user-emacs-file "custom.el"))
(when (file-exists-p custom-file)
  (load custom-file nil t))

;;; The literate configuration

(defun mrk/load-literate-config (org-file)
  "Tangle ORG-FILE if stale, byte-compile the result if stale, then load it.
`org-babel-load-file' only tangles; it always loads the .el as *source*, which
costs about a second on a config this size. Loading a .elc instead is free, and
org itself is only pulled in on the rare boot where a retangle is needed."
  (let* ((el  (concat (file-name-sans-extension org-file) ".el"))
         (elc (concat el "c")))
    (when (or (not (file-exists-p el))
              (file-newer-than-file-p org-file el))
      (require 'ob-tangle)
      ;; Third arg is an exact LANG in org 9.3 (only a regexp in org 9.5+), so
      ;; pass the plain string -- same value org-babel-load-file uses.
      (org-babel-tangle-file org-file el "emacs-lisp"))
    (when (or (not (file-exists-p elc))
              (file-newer-than-file-p el elc))
      ;; Warnings here are about the config, not about this boot; keep them out
      ;; of the way but leave the *Compile-Log* buffer for when it matters.
      (let ((byte-compile-verbose nil)
            (byte-compile-warnings '(not free-vars unresolved noruntime lexical)))
        (byte-compile-file el)))
    ;; No extension: honours load-prefer-newer and picks the .elc when current.
    (load (file-name-sans-extension el) nil t)))

(mrk/load-literate-config (locate-user-emacs-file "configuration.org"))

;;; init.el ends here
