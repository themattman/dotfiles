;; Basic Config
;;
;; After messing with package managers and dependencies, I want to have a simple
;; subset of my emacs config that makes my working env usable, with my most
;; useful keybindings and preferences.
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


  (global-set-key (kbd "C-c z"   ) 'show-file-name            )
  (global-set-key (kbd "C-c i d" ) 'insert-datestring         )
  (global-set-key (kbd "C-c i t" ) 'insert-timestamp          )
  (global-set-key (kbd "C-c C-l" ) 'reload-init-file          ) ; Reload .emacs file
  (global-set-key (kbd "C-x C-b" ) 'buffer-menu               ) ; Buffer-Menu shouldn't open
  (global-set-key (kbd "C-j"     ) 'scroll-down-command       )
  (global-set-key (kbd "C-x p"   ) 'navigate-backwards        ) ; Navigate Buffers Backwards
  (global-set-key (kbd "C-c C-k" ) 'my-delete-line            )
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
  (global-set-key (kbd "C-c C-r" ) 'revert-buffer             ) ; Revert Buffer
  (global-set-key (kbd "C-c C-s" ) 'shell-script-mode         ) ; Shell-script-mode
  (global-set-key (kbd "M-g M-c" ) 'go-to-column              )
  (global-set-key (kbd "C-c C-a" ) 'copy-all                  ) ; Copy everything in buffer

;; Startup
(setq initial-scratch-message nil)      ; When opening emacs without a file,
                                        ;  suppress the dumb *scratch* message
                                        ;  in the buffer
(setq inhibit-startup-echo-area-message (lambda () (user-login-name)))
                                        ; Print "Welcome, USERNAME!" in the echo
                                        ;  area on startup
(setq vc-follow-symlinks nil)           ; don't warn when using GNU stow config

;; Code
;; Tabs
(setq-default indent-tabs-mode nil)     ; Use spaces not tabs
(setq-default tab-width 4)
(setq tab-width 4)
(setq c-default-style                   ; Sane C bracket style
      "bsd"                             ;  4 space tabs for all c-modes
      c-basic-offset 4)

(setq column-number-mode t)             ; Show column numbers
(blink-cursor-mode 0)                   ; Static cursor that doesn't blink

(which-function-mode 1)                 ; Show the function you are in
(fset 'yes-or-no-p 'y-or-n-p)           ; yes/no -> y/n

(setq redisplay-dont-pause t            ; Better Scrolling
      scroll-margin 1                   ;  http://stackoverflow.com
      scroll-step 1                     ;   /questions
      scroll-conservatively 10000       ;   /3631220
      scroll-preserve-screen-position 1);   /fix-to-get-smooth-scrolling-in-emacs



;; (setq package-check-signature nil)

;; ;; Configure package.el to include MELPA.
;; (require 'package)
;; (add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
;; (add-to-list 'package-archives
;;              '("melpa-stable" . "https://stable.melpa.org/packages/"))
;; ; Delete ELPA
;; (delete `gnu package-archives)

;; (package-initialize)

;; ;; Ensure that use-package is installed.
;; ;;
;; ;; If use-package isn't already installed, it's extremely likely that this is a
;; ;; fresh installation! So we'll want to update the package repository and
;; ;; install use-package before loading the literate configuration.
;; (when (not (package-installed-p 'use-package))
;;   (package-refresh-contents)
;;   (package-install 'use-package))

;; (setq vc-follow-symlinks nil)           ; don't warn when using GNU stow config
;; (if (eq t (file-exists-p "~/.emacs.d/configuration.el"))
;;     (load-file "~/.emacs.d/configuration.el")
;;   (org-babel-load-file "~/.emacs.d/configuration.org"))
;; (custom-set-variables
;;  ;; custom-set-variables was added by Custom.
;;  ;; If you edit it by hand, you could mess it up, so be careful.
;;  ;; Your init file should contain only one such instance.
;;  ;; If there is more than one, they won't work right.
;;  '(package-selected-packages
;;    (quote
;;     (yasnippet yaml-mode web-mode use-package symbol-overlay org-pomodoro multi-term moody mo-git-blame markdown-mode magit htmlize helpful flycheck expand-region engine-mode diff-hl auto-complete auto-compile))))
;; (custom-set-faces
;;  ;; custom-set-faces was added by Custom.
;;  ;; If you edit it by hand, you could mess it up, so be careful.
;;  ;; Your init file should contain only one such instance.
;;  ;; If there is more than one, they won't work right.
;;  )
