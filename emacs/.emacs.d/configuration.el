(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(ansi-color-faces-vector
   [default default default italic underline success warning error])
 '(ansi-color-names-vector
   ["#242424" "#e5786d" "#95e454" "#cae682" "#8ac6f2" "#333366" "#ccaa8f" "#f6f3e8"])
 '(custom-enabled-themes (quote (whiteboard)))
 '(package-selected-packages (quote (mo-git-blame auto-complete flycheck))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

(require 'use-package-ensure)
(setq use-package-always-ensure t)

(use-package auto-compile
  :config (auto-compile-on-load-mode))

(setq load-prefer-newer t)

(use-package htmlize)
(use-package flyspell)
(use-package engine-mode)
;; (use-package magit)
(use-package yasnippet)
(use-package cmake-mode)
(use-package yaml-mode)
(use-package markdown-mode)
(use-package web-mode)
(use-package multi-term)
;; (use-package org-pomodoro)
;;  (use-package ivy-mode)
(use-package helpful)
(use-package expand-region) ;; C-= jumps to beginning of word at point
(use-package hi-lock)       ;; word highlighting
(use-package symbol-overlay)
(use-package clang-format)
(use-package auto-complete-clang)
(use-package lsp-mode
  :hook (
        (c++-mode . lsp-deferred)
	(lsp-mode . lsp-enable-which-key-integration))
  :commands (lsp lsp-deferred))
(use-package lsp-ui)
;;(use-package alert)
;; https://github.com/BobVul/GrowlToToast

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
  (setq package-list
        '(flycheck auto-complete mo-git-blame bookmark))
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
;; (add-to-list 'load-path "~/.emacs.d/mo-git-blame.el")
;; (autoload 'mo-git-blame-file "mo-git-blame" nil t)
;; (autoload 'mo-git-blame-current "mo-git-blame" nil t)

;; BOUND = (buffer-size)/2 or similar
(defun mrk/insert-diary-header ()
  (interactive)
  (end-of-buffer)
  (if (not (search-backward (mrk/get-timestamp) nil t))
    (progn
      (end-of-buffer)
      (insert "\n\n#\n# ")
      (insert-timestamp)
      (insert "\n#\nCommand")
      (insert-char ?  38)
      (insert "Comments\n")
      (insert-char ?- (mrk/get-diary-width))
      (insert "\n")
      (message "New Entry Created for Today"))
    (progn
      (end-of-buffer)
      (message "Today's entry already exists"))))

(defun mrk/get-diary-width ()
  (interactive)
  90)

(defun jpt-toggle-mark-word-at-point ()
  (interactive)
  (if hi-lock-interactive-patterns
      (unhighlight-regexp (car (car hi-lock-interactive-patterns)))
    (highlight-symbol-at-point)))
(defun generate-scratch-buffer ()
  "Create and switch to a temporary scratch buffer with a random
     name."
  (interactive)
  (switch-to-buffer (make-temp-name "scratch-")))
(defun hrs/kill-current-buffer ()
  "Kill the current buffer without prompting."
  (interactive)
  (kill-buffer (current-buffer)))
(defun insert-newline-before-line ()
  (interactive)
  (save-excursion
    (beginning-of-line)
    ; I've changed the order of (yank) and (indent-according-to-mode)
    ; in order to handle the case when yanked line comes with its own indent
    ; could be as well changed to simple (newline) it's metter of taste
    ; and of usage
    (newline)))
(defun mrk/get-timestamp ()
  (interactive)
  (format-time-string "%m/%d/%Y"))
(defun insert-timestamp ()
  (interactive)
  (insert (format-time-string "%m/%d/%Y")))
(defun insert-time ()
  (interactive)
  (insert (format-time-string "%m/%d/%Y @ %I:%M:%S %p")))
(defun insert-datestring ()
  (interactive)
  (insert "##############\n")
  (insert (format-time-string "# %m/%d/%Y #\n"))
  (insert "##############\n"))
(defun navigate-backwards ()
  (interactive)
  (other-window -1))
(defun open-emacs-file ()
  (interactive)
  (find-file "~/.emacs.d/configuration.org"))
(defun open-diary-file ()
  (interactive)
  (find-file "~/.diary")
  (goto-char (point-max)))
(defun open-bashrc-file ()
  (interactive)
  (find-file "~/.bashrc"))
(defun show-file-name ()
  "Show the full path file name in the minibuffer."
  (interactive)
  (message (buffer-file-name))
  (kill-new (file-truename buffer-file-name)))
(defun reload-init-file ()
  (interactive)
  (load-file "~/.emacs.d/init.el"))
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
(defun my-delete-word (arg)
  "Delete characters forward until encountering the end of a word.
With argument, do this that many times.
This command does not push text to `kill-ring'."
  (interactive "p")
  (delete-region
   (point)
   (progn
     (forward-word arg)
     (point))))

(defun my-backward-delete-word (arg)
  "Delete characters backward until encountering the beginning of a word.
With argument, do this that many times.
This command does not push text to `kill-ring'."
  (interactive "p")
  (my-delete-word (- arg)))

(defun my-delete-line ()
  "Delete text from current position to end of line char.
This command does not push text to `kill-ring'."
  (interactive)
  (delete-region
   (point)
   (progn (end-of-line 1) (point)))
  (delete-char 1))

(defun my-delete-line-backward ()
  "Delete text between the beginning of the line to the cursor position.
This command does not push text to `kill-ring'."
  (interactive)
  (let (p1 p2)
    (setq p1 (point))
    (beginning-of-line 1)
    (setq p2 (point))
    (delete-region p1 p2)))

(defun mrk/load-diary-for-append ()
  "Opens .diary with the pointer at the bottom line and dateline filled."
  (interactive)
  (if (string-match "[.]diary" buffer-file-name)
    (mrk/insert-diary-header)))

(defun mrk/c++-mode-hook ()
  (c-set-style "MongoDB-Style"))

(defun mrk/get-source-file ()
  (interactive)
  (find-file (concat (file-name-sans-extension buffer-file-name) ".cpp"))
)

(defun mrk/get-header-file ()
  (interactive)
  (find-file (concat (file-name-sans-extension buffer-file-name) ".h"))
)

(defun mrk/wrap-header-include ()
  (interactive)
  (beginning-of-line 1)
  (insert "#include ")
  (if (y-or-n-p "<Angled Brackets>? Y/n")
    (progn
      (insert "<")
      (end-of-line 1)
      (insert ">"))
    (progn
      (insert "\"")
      (end-of-line 1)
      (insert "\""))))

(defun mrk/save-without-hooks ()
  (interactive)
  (read-only-mode)
  (save-buffer)
  (read-only-mode)
)

;; <return> vs. <kp-enter> (keypad enter)
(global-set-key (kbd "C-x C-a"    ) 'mrk/save-without-hooks )

; swap windows
(global-set-key (kbd "C-c l"    ) 'windmove-swap-states-left )
(global-set-key (kbd "C-c r"    ) 'windmove-swap-states-right)
(global-set-key (kbd "C-c u"    ) 'windmove-swap-states-up   )
(global-set-key (kbd "C-c d"    ) 'windmove-swap-states-down )

(global-set-key (kbd "C-c C-h"  ) 'mrk/wrap-header-include   )
(global-set-key (kbd "C-c m"    ) 'xterm-mouse-mode          )

;; Scroll view with mouse?
(global-set-key (kbd "<M-up>") (lambda () (interactive) (scroll-up 1)))
(global-set-key (kbd "<M-down>") (lambda () (interactive) (scroll-down 1)))

(global-set-key (kbd "<f7>"    ) 'symbol-overlay-mode       )
(global-set-key (kbd "<f8>"    ) 'symbol-overlay-remove-all )
(global-set-key (kbd "<f9>"    ) 'symbol-overlay-put        )
(global-set-key (kbd "<f5>"    ) 'jpt-toggle-mark-word-at-point)
(global-set-key (kbd "C-="     ) 'er/expand-region          )
(global-set-key (kbd "C-c f"   ) 'eww-open-in-new-buffer    )
;; (global-set-key (kbd "<return>") 'newline                )
;; (global-set-key (kbd "C m"     ) 'insert-newline-before-line)
(global-set-key (kbd "C-c a"   ) 'org-agenda                )
(global-set-key (kbd "C-c z"   ) 'show-file-name            )
(global-set-key (kbd "C-c C-j" ) 'regenerate-tags-file      )
;;(global-set-key (kbd "C-c d"   ) 'open-diary-file           )
(global-set-key (kbd "C-c b"   ) 'open-bashrc-file          )
(global-set-key (kbd "C-c e"   ) 'open-emacs-file           )
(global-set-key (kbd "C-c C-e" ) 'open-emacs-file           )
(global-set-key (kbd "C-c i d" ) 'insert-datestring         )
(global-set-key (kbd "C-c i t" ) 'insert-timestamp          )
(global-set-key (kbd "C-c i i" ) 'insert-time               )
(global-set-key (kbd "C-c t"   ) 'delete-trailing-whitespace)
(global-set-key (kbd "C-c g c" ) 'mo-git-blame-current      ) ; Git-Blame
(global-set-key (kbd "C-c g f" ) 'mo-git-blame-file         ) ; Git-Blame
(global-set-key (kbd "C-c C-l" ) 'reload-init-file          ) ; Reload .emacs file
(global-set-key (kbd "C-x C-b" ) 'buffer-menu               ) ; Buffer-Menu shouldn't open
(global-set-key (kbd "C-c C-c" ) 'fundamental-mode          ) ;  in another window
(global-set-key (kbd "C-c h"   ) 'mrk/get-header-file       )
(global-set-key (kbd "C-c s"   ) 'mrk/get-source-file       )
(global-set-key (kbd "C-j"     ) 'scroll-down-command       )
(global-set-key (kbd "C-x p"   ) 'navigate-backwards        ) ; Navigate Buffers Backwards
; bind them to emacs's default shortcut keys:
(global-set-key (kbd "C-c C-u" ) 'my-delete-line-backward   )
(global-set-key (kbd "C-c C-k" ) 'my-delete-line            )
;; (global-set-key (kbd "M-d"     ) 'describe-key              )
;; (global-set-key (kbd "<M-backspace>") 'my-backward-delete-word)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;The following section is from:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;https://sites.google.com/site/steveyegge2/effective-emacs;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Easier killing
(global-set-key (kbd "C-w"     ) 'backward-kill-word        ) ; Added Bonus: Matches
                                                              ; shell behavior
(global-set-key (kbd "C-x C-k" ) 'kill-region               )
(global-set-key (kbd "C-c C-k" ) 'kill-region               )
; Bind Alternate M-x's
(global-set-key (kbd "C-x C-m" ) 'execute-extended-command  )
(global-set-key (kbd "C-c C-m" ) 'execute-extended-command  )
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;End Section;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(global-set-key (kbd "C-c C-a" ) 'copy-all                  ) ; Copy everything in buffer
(global-set-key (kbd "C-c C-r" ) 'revert-buffer             ) ; Revert Buffer
(global-set-key (kbd "C-c C-s" ) 'shell-script-mode         ) ; Shell-script-mode
;; (global-set-key (kbd "C-m"    ) 'scroll-up-command          )
;; (global-set-key (kbd "C-n"    ) 'next-line-and-recenter     )
;; (global-set-key (kbd "C-P"    ) 'previous-line-and-recenter )
;; (global-set-key (kbd "C-c C-m") 'makefile-mode              ) ; Makefile-mode (remap this)
;; (global-set-key (kbd "C-c C-l") 'align-regexp               ) ; Line up all the = signs
                                        ;  http://stackoverflow.com
                                        ;   /questions
                                        ;   /915985
                                        ;   /in-emacs-how-to-line-up-equals-signs
                                        ;  -in-a-series-of-initialization-statements
(global-set-key (kbd "M-g M-c" ) 'go-to-column              )
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

(c-add-style "MongoDB-Style"
	   '("gnu"
		 (c-basic-offset . 4)     ; Guessed value
		 (c-offsets-alist
		  (access-label . 0)      ; Guessed value
		  (arglist-cont . 0)      ; Guessed value
		  (arglist-intro . +)     ; Guessed value
		  (block-close . 0)       ; Guessed value
		  (brace-entry-open . 0)  ; Guessed value
		  (brace-list-close . 0)  ; Guessed value
		  (brace-list-entry . 0)  ; Guessed value
		  (brace-list-intro . +)  ; Guessed value
		  (case-label . +)        ; Guessed value
		  (class-close . 0)       ; Guessed value
		  (cpp-define-intro . +)  ; Guessed value
		  (defun-block-intro . +) ; Guessed value
		  (defun-close . 0)       ; Guessed value
		  (else-clause . 0)       ; Guessed value
		  (func-decl-cont . 0)    ; Guessed value
		  (inclass . +)           ; Guessed value
		  (inher-intro . +)       ; Guessed value
		  (inline-close . 0)      ; Guessed value
		  (innamespace . 0)       ; Guessed value
		  (member-init-cont . 0)  ; Guessed value
		  (member-init-intro . +) ; Guessed value
		  (namespace-close . 0)   ; Guessed value
		  (statement . 0)         ; Guessed value
		  (statement-block-intro . +) ; Guessed value
		  (statement-case-intro . +) ; Guessed value
		  (statement-cont . +)       ; Guessed value
		  (stream-op . 3)         ; Guessed value
		  (substatement . +)      ; Guessed value
		  (topmost-intro . 0)     ; Guessed value
		  (topmost-intro-cont . 0) ; Guessed value
		  (annotation-top-cont . 0)
		  (annotation-var-cont . +)
		  (arglist-close . c-lineup-close-paren)
		  (arglist-cont-nonempty . c-lineup-arglist)
		  (block-open . 0)
		  (brace-list-open . +)
		  (c . c-lineup-C-comments)
		  (catch-clause . 0)
		  (class-open . 0)
		  (comment-intro . c-lineup-comment)
		  (composition-close . 0)
		  (composition-open . 0)
		  (cpp-macro . -1000)
		  (cpp-macro-cont . +)
		  (defun-open . 0)
		  (do-while-closure . 0)
		  (extern-lang-close . 0)
		  (extern-lang-open . 0)
		  (friend . 0)
		  (incomposition . +)
		  (inexpr-class . +)
		  (inexpr-statement . +)
		  (inextern-lang . +)
		  (inher-cont . c-lineup-multi-inher)
		  (inlambda . 0)
		  (inline-open . 0)
		  (inmodule . +)
		  (knr-argdecl . 0)
		  (knr-argdecl-intro . 5)
		  (label . 0)
		  (lambda-intro-cont . +)
		  (module-close . 0)
		  (module-open . 0)
		  (namespace-open . 0)
		  (objc-method-args-cont . c-lineup-ObjC-method-args)
		  (objc-method-call-cont c-lineup-ObjC-method-call-colons c-lineup-ObjC-method-call +)
		  (objc-method-intro .
				     [0])
		  (statement-case-open . +)
		  (string . -1000)
		  (substatement-label . 0)
		  (substatement-open . +)
		  (template-args-cont c-lineup-template-args +))))

(setq shell-command-switch "-ic")
(setq lsp-clangd-binary-path "/usr/bin/clangd")
;;(setq lsp-clients-clangd-executable "/usr/bin/clangd")
(setq lsp-clients-clangd-args
  '("--header-insertion=iwyu" "--log=verbose" "--clang-tidy"))
;; (setq vc-follow-symlinks nil)           ; don't warn when using GNU stow config
(setq compilation-scroll-output t)
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
(defvar is-mac (eq system-type 'darwin)
    "Boolean that is true when the current system is detected to be Mac OS.")
(defvar is-linux (or (eq system-type 'gnu/linux) (eq system-type 'linux))
    "Boolean that is true when the current system is detected to be Linux.")
(setq browse-url-generic-program
    (cond
        (is-mac "open")
        (is-linux (executable-find "firefox"))
 ))
(setq tab-width 4)
;; Startup
(setq inhibit-startup-echo-area-message (lambda () (user-login-name)))
                                        ; Print "Welcome, USERNAME!" in the echo
                                        ;  area on startup
(setq initial-scratch-message nil)      ; When opening emacs without a file,
                                        ;  suppress the dumb *scratch* message
                                        ;  in the buffer
(setq auto-save-default nil)            ; Stop creating those #autosave# files
(setq make-backup-files nil)            ; Do not create tilde backup files
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

(add-hook 'after-init-hook #'global-flycheck-mode)
(add-hook 'after-save-hook 'executable-make-buffer-file-executable-if-script-p)
(add-hook 'c-mode-common-hook
          (function (lambda ()
          (add-hook 'before-save-hook
          'clang-format-buffer))))
(add-hook 'js-mode-hook
          (function (lambda ()
          (add-hook 'before-save-hook
          'clang-format-buffer))))
(add-hook 'c-mode-common-hook
          (function (lambda ()
          (add-hook 'before-save-hook
          'delete-trailing-whitespace))))
;; (add-hook 'before-save-hook 'delete-trailing-whitespace)
;; (add-hook 'before-save-hook 'py-autopep8-before-save)
;; (add-hook 'before-save-hook 'py-autopep8-before-save)
(add-hook 'emacs-startup-hook '2-windows-vertical-to-horizontal)
(add-hook 'emacs-startup-hook (lambda () (message "Welcome, %s!" (user-login-name))))
;; (add-hook 'prog-mode-hook 'column-enforce-mode)
;; (add-hook 'python-mode-hook 'flymake-mode-on)
;; Open the diary specially
(add-hook 'find-file-hook 'mrk/load-diary-for-append)
(add-hook 'c++-mode-hook 'mrk/c++-mode-hook)

(global-display-line-numbers-mode)
(setq column-number-mode t)             ; Show column numbers
(blink-cursor-mode 0)                   ; Static cursor that doesn't blink
(set-cursor-color "#116149")            ; MongoDB Color
;; (tool-bar-mode -1)                      ; Disable toolbar
(menu-bar-mode 0)
;; (setq require-final-newline t)          ; Newline at end of file
(which-function-mode 1)                 ; Show the function you are in
(fset 'yes-or-no-p 'y-or-n-p)           ; yes/no -> y/n
(setq redisplay-dont-pause t            ; Better Scrolling
      scroll-margin 1                   ;  http://stackoverflow.com
      scroll-step 1                     ;   /questions
      scroll-conservatively 10000       ;   /3631220
      scroll-preserve-screen-position 1);   /fix-to-get-smooth-scrolling-in-emacs
(setq vc-handled-backends ())
(setq inhibit-startup-screen t)         ; Don't show the welcome screen
;; (set-window-scroll-bars (mini-buffer-window) nil nil) ; Hide tiny scrollbar in minibuffer
(global-hl-line-mode)
(use-package diff-hl
  :config
  (add-hook 'prog-mode-hook 'turn-on-diff-hl-mode)
  (add-hook 'vc-dir-mode-hook 'turn-on-diff-hl-mode))

;; (use-package moody
;;   :config
;;   (setq x-underline-at-descent-line t)
;;   (moody-replace-mode-line-buffer-identification)
;;   (moody-replace-vc-mode))

(setq browse-url-browser-function 'w3m-browse-url)
(autoload 'w3m-browse-url "w3m" "Ask a WWW browser to show a URL." t)
;; optional keyboard short-cut
(global-set-key "\C-xm" 'browse-url-at-point)

;; Java Mode file types
(setq auto-mode-alist (cons '("\\.aidl$" . java-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.proto$" . java-mode) auto-mode-alist))
;; JavaScript major mode for .json files
(setq auto-mode-alist (cons '("\\.json$" . js-mode) auto-mode-alist))
;; Set dotfiles mode to shell-script
(setq auto-mode-alist (cons '(".machine" . shell-script-mode) auto-mode-alist))
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
(setq inhibit-splash-screen t)
(bookmark-bmenu-list)
(switch-to-buffer "*Bookmark List*")
(defengine duckduckgo
  "https://duckduckgo.com/?q=%s"
  :keybinding "d")
(defengine github
  "https://github.com/search?ref=simplesearch&q=%s"
  :keybinding "g")
(defengine wikipedia
  "http://www.wikipedia.org/search-redirect.php?language=en&go=Go&search=%s"
  :keybinding "w")
(defengine youtube
  "https://www.youtube.com/results?search_query=%s"
  :keybinding "y")
(engine-mode t)


; Load Emacs Libraries
(add-to-list 'load-path "~/.emacs.d/themes")
(add-to-list 'load-path "~/.emacs.d/elpa")
;; (add-to-list 'load-path "~/.emacs.d/") ; Not needed in Emacs 24.x

(setq clang-format-style "file")
;; Bind-key
;; (bind-key* "C-i" 'some-function)
;; Autocomplete
(ac-config-default)
;; from: https://github.com/brianjcj/auto-complete-clang
(defun mrk/ac-cc-mode-setup ()
  (setq ac-sources (append '(ac-source-clang ac-source-yasnippet) ac-sources)))
(add-hook 'c-mode-common-hook 'mrk/ac-cc-mode-setup)
(setq ac-clang-flags
      (mapcar (lambda (item)(concat "-I" item))
              (split-string
               "
 /usr/local/include
 /usr/include
"
               )))
;; (add-to-list 'ac-dictionary-directories "~/.emacs.d/ac-dict")
; there used to be an extra slash between .d//ac-dict
(setq whitespace-style '(trailing
                         lines
                         space-before-tab
                         indentation
                         space-after-tab))
;; (setq whitespace-style '(trailing tabs newline tab-mark newline-mark))
(global-set-key (kbd "C-h f") #'helpful-callable)
(global-set-key (kbd "C-h v") #'helpful-variable)
(global-set-key (kbd "C-h k") #'helpful-key)

(add-hook 'org-mode-hook
          (lambda ()
            (org-bullets-mode t)))
(setq org-hide-leading-stars t)
(setq org-todo-keywords
  (quote ((sequence "TODO(t)" "PAUSED(p)" "|" "ABANDONED(b)" "DONE(d)" "SUFFICIENT(s)"))))
(setq org-log-done t)

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

;; Handy
;; what-line
;; count-lines-page
;; current-column
