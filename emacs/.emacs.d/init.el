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

(require 'package)
;; melpa-stable first so it wins ties; gnu stays because built-in-adjacent
;; libraries (eldoc, seq, ...) are only distributed there.
(setq package-archives
      '(("melpa-stable" . "https://stable.melpa.org/packages/")
        ("melpa"        . "https://melpa.org/packages/")
        ("gnu"          . "https://elpa.gnu.org/packages/")))

;; `package-initialize' loads one autoloads file per installed package (~32 file
;; loads, 0.4-1.5s depending on the page cache). `package-quickstart' collects
;; all of them into a single pre-built file, which loads in ~0.08s. package.el
;; regenerates it automatically whenever a package is installed or deleted.
(setq package-quickstart t)

(defvar mrk/package-quickstart-used nil
  "Non-nil if packages were activated from the quickstart file.
When that happens `package-alist' is deliberately left empty, so anything
that needs it must call `package-initialize' first.")

(let ((quickstart (locate-user-emacs-file "package-quickstart.el")))
  (if (file-readable-p quickstart)
      (progn
        (load quickstart nil t)
        (setq mrk/package-quickstart-used t))
    ;; First run (or the file was deleted): do it the slow way once, then build
    ;; the quickstart file so subsequent boots are fast.
    (package-initialize)
    (package-quickstart-refresh)))

(defun mrk/rebuild-package-quickstart ()
  "Regenerate package-quickstart.el by hand.
Only needed if packages were installed by something other than package.el."
  (interactive)
  (package-initialize)
  (package-quickstart-refresh)
  (message "package-quickstart.el rebuilt"))

;;; use-package

;; Bootstrap use-package itself if this is a fresh machine.
(unless (locate-library "use-package")
  (package-initialize)
  (package-refresh-contents)
  (package-install 'use-package))

(require 'use-package)
(require 'use-package-ensure)
(setq use-package-always-ensure t)

;; `use-package-ensure-elpa' decides whether to install by calling
;; `package-installed-p', which reads `package-alist' -- and the quickstart path
;; above never populates it. Left alone, use-package would conclude that every
;; package is missing and try to reinstall all of them on every boot. Consult
;; the activation list and load-path first, and only fall back to real
;; package.el machinery (paying for `package-initialize') when a package is
;; genuinely absent.
(defun mrk/use-package-ensure (name args state &rest rest)
  "Ensure NAME is installed, trusting the quickstart activation list."
  (let* ((package (or (and (consp args) (not (eq (car args) t)) (car args))
                      name)))
    (unless (or (memq package package-activated-list)
                (package-built-in-p package)
                (locate-library (symbol-name package)))
      (when mrk/package-quickstart-used
        (package-initialize)
        (setq mrk/package-quickstart-used nil))
      (apply #'use-package-ensure-elpa name args state rest))))

(setq use-package-ensure-function #'mrk/use-package-ensure)

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
