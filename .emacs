; Matthew Kneiser's .emacs
;
; Date Compiled: 11/06/2014
; Date Modified: 06/30/2016

; Reload .emacs file
;; (global-set-key "\C-x\C-l" 'load-file "~/.emacs")

; Use spaces not tabs
(setq-default indent-tabs-mode nil)
(setq-default tab-width 4)
(setq tab-width 4)
;; (custom-set-variables
;;   ;; custom-set-variables was added by Custom.
;;   ;; If you edit it by hand, you could mess it up, so be careful.
;;   ;; Your init file should contain only one such instance.
;;   ;; If there is more than one, they won't work right.
;;  '(tab-stop-list (quote (4 8 12 16 20 24 28 32 36 40 44 48 52 56 60 64 68 72 76 80 84 88 92 96 100 104 108 112 116 120))))
;(setq indent-line-function 'insert-tab)

; Show column numbers
(setq column-number-mode t)

; Static cursor that doesn't blink (Doesn't work?)
(blink-cursor-mode 0)

; Enable Upper/Lower case region commands
(put 'upcase-region 'disabled nil)
(put 'downcase-region 'disabled nil)

; Buffer-Menu shouldn't open in another window
(global-set-key (kbd "C-x C-b") 'buffer-menu)

; Sane C bracket style
; 4 space tabs for all c-modes
(setq c-default-style "linux"
      c-basic-offset 4)


; Do not create tilde backup files
;  (Don't make annoying ~ files)
;(setq make-backup-files nil)
; Stop creating those #autosave# files
(setq auto-save-default nil)

; Tags File for current development
;(setq tags-file-name "<PATHNAME_TO_TAGS_FILE>")

; Consider putting all these tilde files into a dir under home
;  that has a structure that mirrors the fs. If a tilde file
;  needs to get saved, save it (as its full path) to something
;  under home.
;
; Example:
; When saving
;   /user/mattman/somedir/another/dir/file.txt
; Save its tilde file to
;  ~/.tildes/user/mattman/somedir/another/dir/file.txt~
;; (setq backup-directory "<PATHNAME_TO_BACKUP_DIR>")
(if (not (file-exists-p backup-directory))
    (make-directory backup-directory t))
(setq backup-directory-alist `(("." . ,backup-directory)))
(setq make-backup-files t ; backup of a file the first time it is saved
      backup-by-copying t ; don't clobber symlinks
      version-control t ; version numbers for backup files
      delete-old-versions t ; delete excess backup files silently
      delete-by-moving-to-trash t
      kept-old-versions 5 ; oldest versions to keep when a new numbered backup is
                          ;  made (default: 2)
      kept-new-versions 5 ; newest versions to keep when a new numbered backup is
                          ;  made (default: 2)
      auto-save-default t ; auto-save every buffer that visits a file
      ;auto-save-timeout 20 ; number of seconds idle time before auto-save
      ;                     ;  (default: 30)
      auto-save-interval 200 ; number of keystrokes between auto-saves
                             ;  (default: 300)
)

; Newline at end of file
(setq require-final-newline t)

; Show the function you are in
(which-function-mode 1)

; yes/no -> y/n
(fset 'yes-or-no-p 'y-or-n-p)

; Navigate Buffers Backwards
(global-set-key "\C-xp" (lambda ()
                          (interactive)
                          (other-window -1)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;The following section is from:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;https://sites.google.com/site/steveyegge2/effective-emacs;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Easier killing
(global-set-key "\C-w" 'backward-kill-word) ;Added Bonus: Matches shell behavior
(global-set-key "\C-x\C-k" 'kill-region)
(global-set-key "\C-c\C-k" 'kill-region)

; Bind Alternate M-x's
(global-set-key "\C-x\C-m" 'execute-extended-command)
(global-set-key "\C-c\C-m" 'execute-extended-command)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;End Section;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Proper Undo
;  since OSX doesn't default to the same shortcut as Ubuntu
;  C-_ is always undo, but it requires the user to press <shift>
;(global-set-key "\C-\/" 'undo);Doesn't work.
; This is an X11 issue on OSX:
;  http://apple.stackexchange.com/questions/24261/how-do-i-send-c-that-is-control
;  -slash-to-the-terminal#comment27461_24282

; Better Scrolling
; http://stackoverflow.com/questions/3631220/fix-to-get-smooth-scrolling-in-emacs
(setq redisplay-dont-pause t
  scroll-margin 1
  scroll-step 1
  scroll-conservatively 10000
  scroll-preserve-screen-position 1)

; On startup, open multiple files vertically instead of horizontally
;  http://stackoverflow.com/questions/6697514/when-opening-2-files-in-emacs-how-c
;  an-i-have-them-appear-side-by-side
(defun 2-windows-vertical-to-horizontal ()
  (let ((buffers (mapcar 'window-buffer (window-list))))
    (when (= 2 (length buffers))
      (delete-other-windows)
      (set-window-buffer (split-window-horizontally) (cadr buffers)))))
(add-hook 'emacs-startup-hook '2-windows-vertical-to-horizontal)

; For setting the mark in older versions of emacs
; Let's you do:
;     Ctrl-<space> + Ctrl-n + Esc-;
(transient-mark-mode 1)

; Take care of trailing whitespace
(setq-default show-trailing-whitespace t)
(setq whitespace-style '(trailing tabs newline tab-mark newline-mark))
;(add-hook 'before-save-hook 'delete-trailing-whitespace)
; http://stackoverflow.com/questions/6344474/how-can-i-make-emacs-highlight-lines
; -that-go-over-80-chars
; free of trailing whitespace and to use 80-column width, standard indentation
(setq whitespace-line-column 80)
(setq whitespace-style '(trailing
             lines
             space-before-tab
             indentation
             space-after-tab))

; Copy everything in current buffer w/C-c C-a
(defun copy-all ()
  (interactive)
  (clipboard-kill-ring-save (point-min) (point-max))
  (message "Copied to clipboard."))
(global-set-key (kbd "C-c C-a") 'copy-all)

; Revert Buffer
(global-set-key (kbd "C-c C-r") 'revert-buffer)

; Shell-script-mode
(global-set-key (kbd "C-c C-s") 'shell-script-mode)

; Makefile-mode (remap this)
;(global-set-key (kbd "C-c C-m") 'makefile-mode)

; Mark whole bugger
;(global-set-key (kbd "C-c C-") 'mark-whole-buffer) also (M-|)
; shell-command-on-region

; Line up all the = signs
;  http://stackoverflow.com/questions/915985/in-emacs-how-to-line-up-equals-signs
;  -in-a-series-of-initialization-statements
(global-set-key (kbd "C-c C-l") 'align-regexp)

(defun go-to-column ()
  (interactive)
  (move-to-column 81))
(global-set-key (kbd "M-g M-c") 'go-to-column)

; Load Emacs Libraries
(add-to-list 'load-path "~/.emacs.d/themes")
;; (add-to-list 'load-path "~/.emacs.d/") ; Not needed in Emacs 24.x

; Package Manager
(require 'package)
(add-to-list 'package-archives
             '("melpa" . "https://melpa.org/packages/"))
(add-to-list 'package-archives
             '("melpa-stable" . "https://stable.melpa.org/packages/"))
(when (< emacs-major-version 24)
  ;; For important compatibility libraries like cl-lib
  (add-to-list 'package-archives '("gnu" . "http://elpa.gnu.org/packages/")))
(package-initialize)

; Auto-Formatting Code
;; (require 'clang-format)
;; (global-set-key (kbd "C-c C-l") 'clang-format-region)

; Autocomplete
;; (require 'auto-complete-config)
;; (add-to-list 'ac-dictionary-directories "~/.emacs.d/ac-dict")
; there used to be an extra slash between .d//ac-dict
(ac-config-default)

(setq vc-handled-backends ())
(setq inhibit-startup-echo-area-message "mkneiser") ; Must hardcode username
(setq inhibit-startup-screen t) ; Don't show the welcome screen

; When opening emacs without a file, suppress the dumb *scratch* message
;  in the buffer
(setq initial-scratch-message nil)

; Java Mode file types
(setq auto-mode-alist (cons '("\\.aidl$" . java-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.proto$" . java-mode) auto-mode-alist))

; JavaScript major mode for .json diles
(setq auto-mode-alist (cons '("\\.json$" . js-mode) auto-mode-alist))

; Remaps Ctrl-h to backspace so Emacs respects Unix tradition
(global-set-key [(control h)] 'delete-backward-char)

; Linters
; https://raw.githubusercontent.com/illusori/emacs-flymake/master/flymake.el
;(add-hook 'python-mode-hook 'flymake-mode-on)
;(require 'flymake)

(add-hook 'after-init-hook #'global-flycheck-mode)
;; Customize Flycheck
(setq-default flycheck-disabled-checkers '(c/c++-gcc))

; Make file executable if shebang exists onSave
(add-hook 'after-save-hook 'executable-make-buffer-file-executable-if-script-p)

;; O'Reilly Emacs Book
; Don't let directory get changed from underneath you
(setq-default shell-cd-regexp nil)
(setq-default shell-pushd-regexp nil)
(setq-default shell-popd-regexp nil)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Shortcuts to Remember;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; C-x +: balance-windows
; M-t: transpose word (remap this)
; C-t: transpose letter
; fill-paragraph (wrap to 80 chars, map this!)
; C-x C-o: delete-blank-lines
; M-z: zap-to-char (remap this)
; M-^: delete-indentation (remap this)
; normal-mode (gets you out of the wrong mode)
; describe-variable
; buffer-menu / buffer-menu-other-window
; C-x k: kill-buffer

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Junkyard;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; 80 Char whitespace minor mode
;(load "column-enforce-mode")
;(add-hook 'prog-mode-hook 'column-enforce-mode)
;(global-column-enforce-mode t)

; Sublime-text color theme, likely doesn't work
;(setq color-theme-is-global t)
;(require 'sublime-text-2)
; (sublime-text-2)

; Python syntax highlighting
;;    (global-font-lock-mode t)
;;    (setq font-lock-maximum-decoration t)

; Python Linter (autopep8)
;(add-to-list 'load-path "~/.emacs.d/py-autopep8.el")
;(require 'py-autopep8)
;(add-hook 'before-save-hook 'py-autopep8-before-save)

;(add-to-list 'load-path "~/.emacs.d/python-autopep8.el")
;(require 'python-pep8)
;(add-hook 'before-save-hook 'py-autopep8-before-save)

; Run emacs in server mode, so that we can connect from commandline
;(server-start) ;Didn't initally work for me. Will figure out later.

; Show whitespace as a dot
; DO NOT TRY THIS AT HOME
;(standard-display-ascii ?\s " ")
