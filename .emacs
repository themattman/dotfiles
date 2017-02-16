;;;; .emacs ---- Personal Configurations
;;; Commentary:
; Author:       Matt Kneiser
; Created:      11/06/2014
; Last updated: 02/15/2017
;;; Code:

;;
;;
;;
;; Packages Installed
;;
;;
;;
;; auto-complete
;; dash
;; epl
;; flycheck
;; let-alist
;; mo-git-blame
;; pkg-info
;; popup
;; seq

;;
;;
;;
;; Packages
;;
;;
;;
;; (require 'auto-complete-config)
;; (require 'auto-complete-etags)
;; (require 'bind-key)
;; (require 'clang-format)
;; (require 'flymake)
;; (require 'py-autopep8)
;; (require 'python-pep8)
;; (require 'sublime-text-2)
; Package Manager
(when (>= emacs-major-version 24)
  (require 'package)
  (add-to-list
   'package-archives
   '("melpa" . "https://melpa.org/packages/") t)
  (add-to-list
   'package-archives
   '("melpa-stable" . "https://stable.melpa.org/packages/") t)
  (add-to-list
   'package-archives
   '("gnu" . "http://elpa.gnu.org/packages/") t)
  (setq package-list)
        ;; '(flycheck auto-complete))
  (package-initialize)
  (unless package-archive-contents      ; fetch the list of packages available
    (package-refresh-contents))
  (dolist (package package-list)        ; install the missing packages
    (unless (package-installed-p package)
      (package-install package))))
;; (when (< emacs-major-version 24)
(require 'package) ; "~/.emacs.d/package.el")
(add-to-list 'package-archives
             '("melpa" . "https://melpa.org/packages/"))
(add-to-list 'package-archives
             '("melpa-stable" . "https://stable.melpa.org/packages/"))
;; For important compatibility libraries like cl-lib
(add-to-list 'package-archives '("gnu" . "http://elpa.gnu.org/packages/"))
(package-initialize)
;; (add-to-list 'load-path "~/.emacs.d/mo-git-blame.el")
;; (autoload 'mo-git-blame-file "mo-git-blame" nil t)
;; (autoload 'mo-git-blame-current "mo-git-blame" nil t)


;;
;;
;;
;; Functions
;;
;;
;;
(defun navigate-backwards ()
  (interactive)
  (other-window -1))
(defun open-emacs-file ()
  (interactive)
  (find-file "~/.emacs"))
(defun reload-init-file ()
  (interactive)
  (load-file "~/.emacs"))
(defun copy-all ()
  (interactive)
  (clipboard-kill-ring-save (point-min) (point-max))
  (message "Copied to clipboard."))
;  http://stackoverflow.com/questions/6697514/when-opening-2-files-in-emacs-how-c
;  an-i-have-them-appear-side-by-side
(defun 2-windows-vertical-to-horizontal ()
  (let ((buffers (mapcar 'window-buffer (window-list))))
    (when (= 2 (length buffers))
      (delete-other-windows)
      (set-window-buffer (split-window-horizontally) (cadr buffers)))))
(defun go-to-column ()
  (interactive)
  (move-to-column 81))
(defun next-line-and-recenter () (interactive) (next-line) (recenter))
(defun previous-line-and-recenter () (interactive) (previous-line) (recenter))
(defun gcm-scroll-down ()
  (interactive)
  (scroll-up 1))
(defun gcm-scroll-up ()
  (interactive)
  (scroll-down 1))
(defun find-file-upwards (file-to-find)
    "Recursively searches each parent directory starting from the current directory.
looking for a file with name file-to-find.  Returns the path to it
or nil if not found."
    (cl-labels
        ((find-file-r (path)
                      (let* ((parent (file-name-directory path))
                             (possible-file (concat parent file-to-find)))
                        (cond
                         ((file-exists-p possible-file) possible-file) ; Found
                         ;; The parent of ~ is nil and the parent of / is itself.
                         ;; Thus the terminating condition for not finding the file
                         ;; accounts for both.
                         ((or (null parent) (equal parent (directory-file-name parent))) nil) ; Not found
                         (t (find-file-r (directory-file-name parent))))))) ; Continue
      (find-file-r buffer-file-name)))
(defun find-tags-file ()
  (interactive)
  (find-file-upwards "TAGS"))
(defun cmd-regen-tags (tags-file)
  (interactive)
  (let ((tags-dir (file-name-directory tags-file)))
    (when tags-dir
      (message "Backing up old tags file: %s as %s" tags-file (format-time-string "%Y-%m-%d__%H-%M-%S"))
      (shell-command (concat "mv " tags-file " " tags-file "." (format-time-string "%Y-%m-%d__%H-%M-%S")))
      (message "Regenerating tags file: %s" tags-file)
      (shell-command (concat "find " tags-dir " -name '*.[ch]' -o -name '*.cpp' -o -name '*.cc' | xargs etags -a -o " tags-file  " 2>/dev/null")))))
(defun regenerate-tags-file ()
  (interactive)
  (let ((my-tags-file (find-tags-file)))
    (when my-tags-file
      (cmd-regen-tags my-tags-file)
      (message "Loading tags file: %s" (find-tags-file))
      (visit-tags-table (find-tags-file))
      (message "New tags file loaded successfully!")
      )
    (unless my-tags-file
    (message "No TAGS file found."))))


;;
;;
;;
;; Keybindings
;;
;;
;;
(global-set-key (kbd "C-c C-j") 'regenerate-tags-file)
(global-set-key (kbd "C-c e"  ) 'open-emacs-file)
(global-set-key (kbd "C-c C-e") 'open-emacs-file)
(global-set-key (kbd "C-c g c") 'mo-git-blame-current); Git-Blame
(global-set-key (kbd "C-c g f") 'mo-git-blame-file)   ; Git-Blame
(global-set-key (kbd "C-c C-l") 'reload-init-file)    ; Reload .emacs file
(global-set-key (kbd "C-x C-b") 'buffer-menu)         ; Buffer-Menu shouldn't open
(global-set-key (kbd "C-c C-c") 'fundamental-mode)    ;  in another window
(global-set-key (kbd "C-j"    ) 'scroll-down-command)
(global-set-key (kbd "C-x p"  ) 'navigate-backwards)  ; Navigate Buffers Backwards
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;The following section is from:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;https://sites.google.com/site/steveyegge2/effective-emacs;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Easier killing
(global-set-key (kbd "C-w"    ) 'backward-kill-word)  ; Added Bonus: Matches
                                                      ; shell behavior
(global-set-key (kbd "C-x C-k") 'kill-region)
(global-set-key (kbd "C-c C-k") 'kill-region)
; Bind Alternate M-x's
(global-set-key (kbd "C-x C-m") 'execute-extended-command)
(global-set-key (kbd "C-c C-m") 'execute-extended-command)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;End Section;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(global-set-key (kbd "C-c C-a") 'copy-all)          ; Copy everything in buffer
(global-set-key (kbd "C-c C-r") 'revert-buffer)     ; Revert Buffer
(global-set-key (kbd "C-c C-s") 'shell-script-mode) ; Shell-script-mode
;; (global-set-key (kbd "C-m"    ) 'scroll-up-command)
;; (global-set-key (kbd "C-n"    ) 'next-line-and-recenter)
;; (global-set-key (kbd "C-P"    ) 'previous-line-and-recenter)
;; (global-set-key (kbd "C-c C-m") 'makefile-mode)     ; Makefile-mode (remap this)
;; (global-set-key (kbd "C-c C-l") 'align-regexp)      ; Line up all the = signs
                                        ;  http://stackoverflow.com
                                        ;   /questions
                                        ;   /915985
                                        ;   /in-emacs-how-to-line-up-equals-signs
                                        ;  -in-a-series-of-initialization-statements
(global-set-key (kbd "M-g M-c") 'go-to-column)
;; (global-set-key [(control h)] 'delete-backward-char)
;; (global-set-key (kbd "C-h"    ) 'delete-backward-char)
;; (global-set-key (kbd "C-c C-l") 'clang-format-region) ; Auto-Formatting Code
; Proper Undo
;  since OSX doesn't default to the same shortcut as Ubuntu
;  C-_ is always undo, but it requires the user to press <shift>
;; (global-set-key (kbd "C-/"    ) 'undo)              ; Doesn't work
; This is an X11 issue on OSX:
;  http://apple.stackexchange.com/questions/24261/how-do-i-send-c-that-is-control
;  -slash-to-the-terminal#comment27461_24282
; Remaps Ctrl-h to backspace so Emacs respects Unix tradition


;;
;;
;;
;; Variables
;;
;;
;;
;; TAGS file
;; (setq tags-file-name "path/to/TAGS")
(setq tags-revert-without-query t)      ; Auto-update TAGS file if it changed on
                                        ; disk
; TODO see if bash pipe works with commands in emacs
;(defvar tags-regen-cmd "etags -R 2>/dev/null")
;; (defvar my-cmd "find . -maxdepth 1 | xargs -I{} echo 'hi' {}")
;; (defun call-my-cmd()
;;   (interactive)
;;   (shell-command my-cmd)
;;   )
;; (global-set-key (kbd "C-x C-j") 'call-my-cmd)
;; Tabs
(setq-default indent-tabs-mode nil)     ; Use spaces not tabs
(setq-default tab-width 4)
(setq tab-width 4)
;; Startup
(setq inhibit-startup-echo-area-message (lambda () (user-login-name)))
                                        ; Print "Welcome, USERNAME!" in the echo
                                        ;  area on startup
(setq initial-scratch-message nil)      ; When opening emacs without a file,
                                        ;  suppress the dumb *scratch* message
                                        ;  in the buffer
;; Code
(setq c-default-style                   ; Sane C bracket style
      "linux"                           ;  4 space tabs for all c-modes
      c-basic-offset 4)
(setq auto-save-default nil)            ; Stop creating those #autosave# files
;(setq make-backup-files nil)           ; Do not create tilde backup files
(setq max-mini-window-height 1)         ; Don't let echo area grow
                                        ;  This is useful for forcing
                                        ;  'shell-command-on-region' output to
                                        ;  be forced to a new buffer, and not
                                        ;  wasted in the echo area
;; Consider putting all these tilde files into a dir under home
;;  that has a structure that mirrors the fs. If a tilde file
;;  needs to get saved, save it (as its full path) to something
;;  under home.
;;
;; Example:
;; When saving
;;   /user/mattman/somedir/another/dir/file.txt
;; Save its tilde file to
;;  ~/.tildes/user/mattman/somedir/another/dir/file.txt~
(setq backup-directory "~/.tildes")
(if (not (file-exists-p backup-directory))
    (make-directory backup-directory t))
(setq backup-directory-alist `(("." . ,backup-directory)))
(setq make-backup-files t               ; backup of a file the first time it is saved
      backup-by-copying t               ; don't clobber symlinks
      version-control t                 ; version numbers for backup files
      delete-old-versions t             ; delete excess backup files silently
      delete-by-moving-to-trash t
      kept-old-versions 5               ; oldest versions to keep when a new
                                        ;  numbered backup is made (default: 2)
      kept-new-versions 5               ; newest versions to keep when a new
                                        ;  numbered backup is made (default: 2)
      auto-save-default t               ; auto-save every buffer that visits a file
      ;; auto-save-timeout 20              ; number of seconds idle time before auto-save
      ;;                                   ; (default: 30)
      auto-save-interval 200            ; number of keystrokes between auto-saves
                                        ;  (default: 300)
)
(setq Buffer-menu-name-width 40)        ; Width of buffer name in *buffer-list*

;;
;;
;;
;; Hooks
;;
;;
;;
(add-hook 'after-init-hook #'global-flycheck-mode)
(add-hook 'after-save-hook 'executable-make-buffer-file-executable-if-script-p)
;; (add-hook 'before-save-hook 'delete-trailing-whitespace)
;; (add-hook 'before-save-hook 'py-autopep8-before-save)
;; (add-hook 'before-save-hook 'py-autopep8-before-save)
(add-hook 'emacs-startup-hook '2-windows-vertical-to-horizontal)
(add-hook 'emacs-startup-hook (lambda () (message "Welcome, %s!" (user-login-name))))
;; (add-hook 'prog-mode-hook 'column-enforce-mode)
;; (add-hook 'python-mode-hook 'flymake-mode-on)


;;
;;
;;
;; Appearance
;;
;;
;;
(setq column-number-mode t)             ; Show column numbers
(blink-cursor-mode 0)                   ; Static cursor that doesn't blink
(tool-bar-mode -1)                      ; Disable toolbar
(setq require-final-newline t)          ; Newline at end of file
(which-function-mode 1)                 ; Show the function you are in
(fset 'yes-or-no-p 'y-or-n-p)           ; yes/no -> y/n
(setq redisplay-dont-pause t            ; Better Scrolling
      scroll-margin 1                   ;  http://stackoverflow.com
      scroll-step 1                     ;   /questions
      scroll-conservatively 10000       ;   /3631220
      scroll-preserve-screen-position 1);   /fix-to-get-smooth-scrolling-in-emacs
(setq vc-handled-backends ())
(setq inhibit-startup-screen t)         ; Don't show the welcome screen


;;
;;
;;
;; Behavior
;;
;;
;;
;; Java Mode file types
(setq auto-mode-alist (cons '("\\.aidl$" . java-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.proto$" . java-mode) auto-mode-alist))
;; JavaScript major mode for .json files
(setq auto-mode-alist (cons '("\\.json$" . js-mode) auto-mode-alist))
;; Linters
;; https://raw.githubusercontent.com/illusori/emacs-flymake/master/flymake.el
;; Customize Flycheck
(defvar flycheck-clang-include-path)
;; (add-to-list 'flycheck-clang-include-path "../include")
;; (setq-default flycheck-disabled-checkers '(c/c++-gcc))
;; O'Reilly Emacs Book
;; Don't let directory get changed from underneath you
(setq-default shell-cd-regexp nil)
(setq-default shell-pushd-regexp nil)
(setq-default shell-popd-regexp nil)
(put 'upcase-region 'disabled nil)      ; Enable Uppercase region commands
(put 'downcase-region 'disabled nil)    ; Enable Lowercase region commands
; For setting the mark in older versions of emacs
; Let's you do:
;     Ctrl-<space> + Ctrl-n + Esc-;
(transient-mark-mode 1)
(setq-default show-trailing-whitespace t)
; http://stackoverflow.com/questions/6344474/how-can-i-make-emacs-highlight-lines
; -that-go-over-80-chars
; free of trailing whitespace and to use 80-column width, standard indentation
(setq whitespace-line-column 80)

; Load Emacs Libraries
(add-to-list 'load-path "~/.emacs.d/themes")
(add-to-list 'load-path "~/.emacs.d/elpa")
;; (add-to-list 'load-path "~/.emacs.d/") ; Not needed in Emacs 24.x

;;
;;
;;
;; Package Customizations
;;
;;
;;
;; Bind-key
;; (bind-key* "C-i" 'some-function)
;; Autocomplete
(ac-config-default)
;; (add-to-list 'ac-dictionary-directories "~/.emacs.d/ac-dict")
; there used to be an extra slash between .d//ac-dict
(setq whitespace-style '(trailing
                         lines
                         space-before-tab
                         indentation
                         space-after-tab))
;; (setq whitespace-style '(trailing tabs newline tab-mark newline-mark))


;;
;;
;;
;; Shortcuts to Remember
;;
;;
;;
;; C-x +: balance-windows
;; M-t: transpose word (remap this)
;; C-t: transpose letter
;; fill-paragraph (wrap to 80 chars, map this!)
;; C-x C-o: delete-blank-lines
;; M-z: zap-to-char (remap this)
;; M-^: delete-indentation (remap this)
;; normal-mode (gets you out of the wrong mode)
;; describe-variable
;; buffer-menu / buffer-menu-other-window
;; C-x k: kill-buffer
;; M-|: shell-command-on-region
;; C-x C-p: mark-page

;;
;;
;;
;; Junkyard
;;
;;
;;
;; https://en.wikipedia.org/wiki/Common_Lisp#Comparison_with_other_Lisps
;;
; 80 Char whitespace minor mode
;(load "column-enforce-mode")
;(global-column-enforce-mode t)

; Sublime-text color theme, likely doesn't work
;(setq color-theme-is-global t)
; (sublime-text-2)

; Python syntax highlighting
;;    (global-font-lock-mode t)
;;    (setq font-lock-maximum-decoration t)

; Python Linter (autopep8)
;(add-to-list 'load-path "~/.emacs.d/py-autopep8.el")
;(add-to-list 'load-path "~/.emacs.d/python-autopep8.el")

; Run emacs in server mode, so that we can connect from commandline
;(server-start) ;Didn't initally work for me. Will figure out later.

; Show whitespace as a dot
; DO NOT TRY THIS AT HOME
;(standard-display-ascii ?\s " ")

;; LATER
;; https://stackoverflow.com/questions/3669511/the-function-to-show-current-files-full-path-in-mini-buffer
;; (defun show-file-name ()
;;   "Show the full path file name in the minibuffer."
;;   (interactive)
;;   (message (buffer-file-name))
;;   (kill-new (file-truename buffer-file-name))
;;   )
;; (global-set-key "\C-cz" 'show-file-name)
