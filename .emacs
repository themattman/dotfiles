; Matthew Kneiser's .emacs
;
; Date Compiled: 11/06/2014
; Date Modified: 12/09/2014

; Show column numbers
(setq column-number-mode t)

; Static cursor that doesn't blink (Doesn't work?)
(blink-cursor-mode 0)

; Do not create tilde backup files
;(setq make-backup-files nil) ;(Don't make annoying ~ files)
(setq auto-save-default nil) ;stop creating those #autosave# files

; Run emacs in server mode, so that we can connect from commandline
;(server-start)

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
(setq backup-directory "~/.tildes/")
(if (not (file-exists-p backup-directory))
    (make-directory backup-directory t))
(setq backup-directory-alist `(("." . ,backup-directory)))
(setq make-backup-files t ;backup of a file the first time it is saved.
      backup-by-copying t ; don't clobber symlinks
      version-control t ; version numbers for backup files
      delete-old-versions t ; delete excess backup files silently
      delete-by-moving-to-trash t
      kept-old-versions 5 ; oldest versions to keep when a new numbered backup is made (default: 2)
      kept-new-versions 5 ; newest versions to keep when a new numbered backup is made (default: 2)
      auto-save-default t ; auto-save every buffer that visits a file
      ;auto-save-timeout 20 ; number of seconds idle time before auto-save (default: 30)
      auto-save-interval 200 ; number of keystrokes between auto-saves (default: 300)
)

; Newline at end of file
(setq require-final-newline t)

; Show the function you are in
(which-function-mode 1)

; yes/no -> y/n
(fset 'yes-or-no-p 'y-or-n-p)

; Better Scrolling
; http://stackoverflow.com/questions/3631220/fix-to-get-smooth-scrolling-in-emacs
(setq redisplay-dont-pause t
  scroll-margin 1
  scroll-step 1
  scroll-conservatively 10000
  scroll-preserve-screen-position 1)

; On startup, open multiple files vertically instead of horizontally
; http://stackoverflow.com/questions/6697514/when-opening-2-files-in-emacs-how-can-i-have-them-appear-side-by-side
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

; Revert Buffer
(global-set-key (kbd "C-c C-r") 'revert-buffer)

; Take care of trailing whitespace
(setq-default show-trailing-whitespace t)
(add-hook 'before-save-hook 'delete-trailing-whitespace)
;; http://stackoverflow.com/questions/6344474/how-can-i-make-emacs-highlight-lines-that-go-over-80-chars
;; free of trailing whitespace and to use 80-column width, standard indentation
(setq whitespace-style '(trailing lines space-before-tab
                                  indentation space-after-tab)
      whitespace-line-column 80)

; Copy everything in current buffer w/C-c C-a
(defun copy-all ()
  (interactive)
  (clipboard-kill-ring-save (point-min) (point-max))
  (message "Copied to clipboard."))
(global-set-key (kbd "C-c C-a") 'copy-all)

; Load Emacs Libraries
(add-to-list 'load-path "~/.emacs.d")
(add-to-list 'load-path "~/.emacs.d/themes")

; Autocomplete
(require 'auto-complete-config)
(add-to-list 'ac-dictionary-directories "~/.emacs.d/ac-dict")
; there used to be an extra slash between .d//ac-dict
(ac-config-default)

(setq vc-handled-backends ())
(setq inhibit-startup-echo-area-message t) ; USERNAME instead of t, must hardcode
(setq inhibit-startup-message t)

; When opening emacs without a file, suppress the dumb *scratch* message
;  in the buffer
(setq initial-scratch-message nil)

; Python major mode
;  (for .py files)
(setq auto-mode-alist (cons '("\\.py$" . python-mode) auto-mode-alist))
(setq interpreter-mode-alist (cons '("python" . python-mode)
				   interpreter-mode-alist))
(autoload 'python-mode "python-mode" "Python editing mode." t)

; Remaps Ctrl-h to backspace so Emacs respects Unix tradition
;(global-set-key [(control h)] 'delete-backward-char)

;
; Junkyard
;

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

; Show whitespace as a dot
; DO NOT TRY THIS AT HOME
;(standard-display-ascii ?\s " ")
