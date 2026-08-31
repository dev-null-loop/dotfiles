;;; packages
;;; 9. Modes and integrations
;;; 9.1 Project and search

(use-package projectile
  ;;:custom (projectile-project-search-path '("~/projects/" "~/work/" "~/playground"))
  :bind-keymap (
		("C-c C-p" . projectile-command-map)
		("C-c p" . projectile-command-map)
		("s-p" . projectile-command-map))
  :hook (after-init . projectile-mode)
  :init
  (defun bd/tags-query-replace-compile-replacement (fun &rest args)
    "Apply `q-r-compile-replacement' to `tags-query-replace' in FUN with ARGS."
    (cl-letf* ((old-tags-query-replace (symbol-function 'tags-query-replace))
	       ((symbol-function 'tags-query-replace)
		(lambda (from to &rest other-args)
		  (apply old-tags-query-replace
			 from
			 (query-replace-compile-replacement to t)
			 other-args))))
      (apply fun args)))
  :custom
  (projectile-completion-system 'helm)
  (projectile-enable-caching 0)
  (projectile-require-project-root nil)
  (projectile-switch-project-action 'projectile-dired)
  :config
  (advice-add 'projectile-replace-regexp :around
	      #'bd/tags-query-replace-compile-replacement)
  (projectile-register-project-type
   'terraform
   '("versions.tf")
   :project-file "versions.tf"
   :compile "terraform plan"))
;;; https://docs.projectile.mx/projectile/projects.html#adding-custom-project-types
;;; https://ag91.github.io/blog/2022/09/13/hacking-projectile-to-search-in-all-my-projects/

(use-package helm-projectile
  :ensure t
  :after (helm projectile)
  :config
  (helm-projectile-on))

;;; 9.2 YAML / Ansible / Jinja2

(use-package smartparens
  :ensure t)
(use-package ansible
  :ensure t)
(use-package jinja2-mode
  :ensure t)
(use-package yaml-mode
  :ensure t
  :mode (("\\.yml\\'" . yaml-mode)
	 ("\\.yaml\\'" . yaml-mode)
	 ("/group_vars/.*\\'" . yaml-mode))
  :preface
  (defun bd/yaml-next-field ()
    "Jump to the next YAML field separator."
    (interactive)
    (search-forward-regexp ": *"))
  (defun bd/yaml-prev-field ()
    "Jump to the previous YAML field separator."
    (interactive)
    (search-backward-regexp ": *"))
  (defun bd/yaml-mode-setup ()
    "Apply local editing setup for `yaml-mode'."
    (smartparens-mode)
    (highlight-indentation-mode 1))
  :hook ((yaml-mode . flymake-yamllint-setup)
	 (yaml-mode . bd/yaml-mode-setup))
  :bind (:map yaml-mode-map
	      ("C-m" . newline-and-indent)
	      ("M-<return>" . insert-ts)
	      ("C-c n" . bd/yaml-next-field)
	      ("C-c p" . bd/yaml-prev-field)))

(use-package highlight-indentation
  :ensure t
  :custom-face
  (highlight-indentation-face ((t (:background "#ebdbb2")))))


;;; 9.3 Helm / minibuffer / navigation

;;; helm-mode https://tuhdo.github.io/helm-intro.html
;;; helm https://www.reddit.com/r/emacs/comments/zmg16j/how_to_configure_helm_after_recent_update_using/
(use-package helm
  :ensure t
  :init
  (defun bd/helm-fonts ()
    (face-remap-add-relative 'default :family "Monaco for Powerline"))
  :bind (("C-x C-f" . helm-find-files)
	 ("C-x C-b" . helm-buffers-list)
	 ("M-x" . helm-M-x)
	 ("M-y" . helm-show-kill-ring)
	 ("C-c h" . helm-command-prefix)
	 ("C-c C-i" . helm-copy-to-buffer)
	 ("C-c r" . helm-recentf)
	 ("M-s o" . helm-occur)
	 ("M-s i" . helm-imenu)
	 ("M-s I" . helm-imenu-in-all-buffers)
	 ("M-s m" . helm-mini)
	 ("M-s b" . helm-bookmarks)
	 ("M-l" . helm-eshell-history)
	 :map helm-map
	 ("<tab>" . helm-execute-persistent-action)
	 ("C-i" . helm-execute-persistent-action)
	 ("C-z" . helm-select-action))
  :hook ((helm-major-mode . bd/helm-fonts)
	 (helm-after-initialize . helm-init-relative-display-line-numbers))
  :custom
  (helm-candidate-separator "***")
  (helm-candidate-number-limit 200)
  (helm-M-x-fuzzy-match t)
  (helm-ff-keep-cached-candidates nil)
  (helm-find-noerrors t)
  (helm-semantic-fuzzy-match t)
  (helm-imenu-fuzzy-match t)
  (helm-buffers-fuzzy-matching t)
  (helm-recentf-fuzzy-match t)
  (helm-follow-mode-persistent t)
  ;; Keep Helm inside the selected pane and only split horizontally.
  (helm-split-window-inside-p t)
  (helm-split-window-default-side 'below)
  (helm-move-to-line-cycle-in-source t)
  (helm-ff-search-library-in-lsexp t)
  (helm-scroll-amount 8)
  (helm-ff-file-name-history-use-recentf t)
  (helm-echo-input-in-header-line t)
  (helm-display-header-line nil)
  (helm-autoresize-max-height 30)
  (helm-autoresize-min-height 30)
  (helm-show-completion-display-function
   #'helm-show-completion-default-display-function)
  :config
  (global-unset-key (kbd "C-x c"))
  (set-frame-parameter nil 'background-mode 'dark)
  (set-face-attribute 'helm-source-header nil
		      :font "Monaco for Powerline")
  (set-face-attribute 'helm-selection nil
		      :background "red"
		      :foreground "#ebdbb2")
  (set-face-font 'helm-source-header "Monaco for Powerline-10")
  (helm-mode 1)
  (helm-autoresize-mode 1))
(use-package helm-xref
  :ensure t)

(use-package helm-pass
  :ensure t)

(use-package helm-exwm
  :ensure t
  :config
  (setq helm-exwm-emacs-buffers-source (helm-exwm-build-emacs-buffers-source))
  (setq helm-exwm-source (helm-exwm-build-source))
  (setq helm-mini-default-sources `(helm-exwm-emacs-buffers-source
					helm-exwm-source
					helm-source-recentf)))

;;; 9.4 Git and code review

;;; git-link / forge / transient / magit

(use-package git-link
  :ensure t
  :config
  (dolist (host '("orahub\\.oci\\.oraclecorp\\.com"
		  "devops\\.scmservice\\.eu-frankfurt-1\\.oci\\.oraclecloud\\.com"))
    (add-to-list 'git-link-remote-alist (list host #'git-link-github))
    (add-to-list 'git-link-commit-remote-alist (list host #'git-link-commit-github))))

(use-package forge
  :ensure t
  :after magit)
(use-package transient
  :ensure t
  :config
  (transient-bind-q-to-quit))
(use-package magit
  :ensure t
  :bind (("C-x g"   . magit-status)
	 ("C-c g"   . magit-file-dispatch)
	 ("C-c c l" . git-link))
  :custom
  (magit-log-section-commit-count 20) ;; https://magit.vc/manual/magit/Status-Sections.html
  (magit-log-margin '(t "%Y-%m-%d %H:%M " magit-log-margin-width t 18))
  (git-link-use-commit t)             ;; generate permalink
  (global-magit-file-mode t)
  (magit-display-buffer-function
   (lambda (buffer)
     (display-buffer buffer '(display-buffer-same-window))))
  :config
  ;; Recent Magit splits some status-section functions into separate files.
  ;; Load them before the status hook is consumed so stale/void hook entries
  ;; don't break `magit-status' during startup or refresh.
  (require 'magit-sequence)
  (require 'magit-bisect)
  (require 'magit-stash)
  (dolist (cmd '(magit-edit-line-commit magit-clean))
    (put cmd 'disabled nil)))
;;; 9.5 Editing helpers and local tools

(use-package pulseaudio-control
  :ensure t
  :bind (("<XF86AudioRaiseVolume>" . pulseaudio-control-increase-sink-volume)
	 ("<XF86AudioLowerVolume>" . pulseaudio-control-decrease-sink-volume)
	 ("<XF86AudioMute>" . pulseaudio-control-toggle-current-sink-mute)
	 ("C-c v" . hydra-pulseaudio-control/body)
	 :map exwm-mode-map
	 ("<XF86AudioRaiseVolume>" . pulseaudio-control-increase-sink-volume)
	 ("<XF86AudioLowerVolume>" . pulseaudio-control-decrease-sink-volume)
	 ("<XF86AudioMute>" . pulseaudio-control-toggle-current-sink-mute))
  :bind-keymap ("C-c v" . pulseaudio-control-map)
  :custom
  (pulseaudio-control-volume-step "5%")
  (pulseaudio-control-use-default-sink t)
  (pulseaudio-control-use-default-source t)
  :config
  (defhydra hydra-pulseaudio-control (:hint nil)
	"Pulseaudio Control"
	("+" pulseaudio-control-increase-sink-kvolume "Increase Volume")
	("i" pulseaudio-control-increase-sink-volume "Increase Volume")
	("-" pulseaudio-control-decrease-sink-volume "Decrease Volume")
	("d" pulseaudio-control-decrease-sink-volume "Decrease Volume")
	("m" pulseaudio-control-toggle-current-sink-mute "Toggle Mute")
	("s" pulseaudio-control-select-sink-by-name "Select Sink")
	("q" nil "quit"))
  (pulseaudio-control-default-keybindings))
(use-package hydra
  :ensure t)
;;; vterm https://github.com/akermu/emacs-libvterm
(use-package vterm
  :ensure t
  :custom
  (vterm-always-compile-module t)
  (vterm-max-scrollback 1000000)
  :bind (:map vterm-mode-map
	    ("M-2" . split-window-vertically)))
;;; markdown
;;; https://emacs.stackexchange.com/questions/5418/github-markdown-mode
;;; https://jblevins.org/projects/markdown-mode/
(use-package markdown-mode
  :ensure t
  :mode (("README\\.md\\'" . gfm-mode)
	 ("\\.markdown\\'" . gfm-mode)
	 ("\\.md\\'" . gfm-mode)
	 ("\\.\\(?:mkd\\|mdown\\|mkdn\\|mdwn\\)\\'" . markdown-mode))
  :custom
  (markdown-command "multimarkdown")
  :hook (markdown-mode . (lambda () (font-lock-mode -1))))
;;; groovy
(use-package groovy-mode
  :mode ("\\.groovy\\'" . groovy-mode))

;;; ace-mode https://github.com/abo-abo/ace-window
(use-package ace-window
  :ensure t
  :bind (("s-o" . ace-window))
  :custom
  (aw-scope 'frame))
;; x - delete window
;; m - swap windows
;; M - move window
;; c - copy window
;; j - select buffer
;; n - select the previous window
;; u - select buffer in the other window
;; c - split window fairly, either vertically or horizontally
;; v - split window vertically
;; b - split window horizontally
;; o - maximize current window
;; ? - show these command bindings


;;; 9.6 Shells, terminals, and completion

;;; eshell:remote:tramps ssh $ cd /ssh:user@remote-machine:~
;;; /ssh:opc@141.148.224.142:~
;;; /ssh:user@ip_OR_Host#port:/
;;;; cd /ssh:bob@initech:/srv/tps-reports/

(use-package eshell
  :bind (:map eshell-mode-map
	      ("C-a" . eshell-maybe-bol)
	      ("M-l" . helm-eshell-history))
  :init
  (defun eshell-maybe-bol()
    "Go to beginning of Eshell input, then to true line beginning."
    (interactive)
    (let ((p (point)))
	  (eshell-bol)
	  (when (= p (point))
	    (let ((inhibit-field-text-motion t))
	      (beginning-of-line)))))
  (defun eshell-append-history ()
    "Call `eshell-write-history' with the `append' parameter set to `t'."
    (when eshell-history-ring
	  (let ((newest-cmd-ring (make-ring 1)))
	    (ring-insert newest-cmd-ring (car (ring-elements eshell-history-ring)))
	    (let ((eshell-history-ring newest-cmd-ring))
	      (eshell-write-history eshell-history-file-name t)))))
  (defun bd/eshell-mode-setup ()
    "Set up Eshell behavior for this config."
    (setenv "LANG" "en_US.UTF-8")
    (setenv "LC_ALL" "C")
    (setenv "ORACLE_PATH" "/home/bd/sqlplus")
    (prefer-coding-system 'utf-8)
    (display-line-numbers-mode -1)
    (setq pcomplete-cycle-completions nil)
    (setq eshell-exit-hook nil)
    (add-to-list 'eshell-visual-commands "ssh")
    (add-to-list 'eshell-visual-commands "tail")
    (add-to-list 'eshell-visual-commands "wget")
    (add-to-list 'eshell-visual-commands "top"))
  :hook ((eshell-mode . bd/eshell-mode-setup)
	 (eshell-pre-command . eshell-append-history))
  :custom
  (eshell-scroll-to-bottom-on-input 'all)
  (eshell-error-if-no-glob t)
  (eshell-hist-ignoredups t)
  (eshell-save-history-on-exit nil)
  (eshell-cmpl-cycle-completions nil)
  (eshell-prefer-lisp-functions nil)
  (eshell-buffer-maximum-lines 1048576)
  (eshell-destroy-buffer-when-process-dies t)
  :config
  (require 'eshell-z nil t)
  (add-to-list 'eshell-modules-list 'eshell-tramp)
  (add-to-list 'eshell-command-aliases-list
	       '("spq" "runcon unconfined_u:unconfined_r:unconfined_t:s0 steampipe query --output csv $*"))
  ;; `dnf` updates its progress bar with carriage returns. In plain eshell
  ;; output those become separate lines, so run it through a real terminal.
  (with-eval-after-load 'em-term
    (setq eshell-visual-subcommands
	  (cl-delete-duplicates eshell-visual-subcommands :test #'equal))))
;;; 9.6.1 Eshell hooks

(use-package bash-completion
  :ensure t
  :init
  (defun bash-completion-from-eshell ()
    (interactive)
    (let ((completion-at-point-functions
	   '(bash-completion-eshell-capf)))
	  (completion-at-point)))
  (defun bash-completion-eshell-capf ()
    (bash-completion-dynamic-complete-nocomint
     (save-excursion (eshell-bol) (point))
     (point) t))
  (defun bd/bash-completion-eshell-setup ()
    "Enable bash-completion CAPF integration in Eshell."
    (add-hook 'completion-at-point-functions
	      #'bash-completion-capf-nonexclusive nil t))
  :hook (eshell-mode . bd/bash-completion-eshell-setup)
  :config
  (bash-completion-setup))
(use-package em-hist
  :custom
  (eshell-hist-ignoredups t)
  ;; Set the history file.
  (eshell-history-file-name "~/.bash_history")
  ;; If nil, use HISTSIZE as the history size.
  (eshell-history-size 10000000))


;; dictionary https://irreal.org/blog/?p=10824
(use-package dictionary
;; :bind (("M-#" . dictionary-lookup-definition))
  :bind (("C-c l" . dictionary-lookup-definition))
  :custom
  (dictionary-use-single-buffer t)
  (dictionary-server "dict.org"))

;;; 9.7 Language and file-type support

;;; 9.7.1 Terraform

;;; terraform
(use-package terraform-mode
  :ensure t
  :hook (terraform-mode . terraform-format-on-save-mode))


;;; 9.7.2 Go

;;; Go
(use-package go-mode
	:ensure t
	:hook ((before-save . gofmt-before-save))
	:bind (:map go-mode-map
				("M-." . godef-jump)
				("<f6>"  . gofmt)
				("C-c 6" . gofmt))
	:custom
	(gofmt-command "goimports"))

;;; 9.7.3 Python

;;; python
(use-package blacken
  :ensure t
  :custom
  (blacken-line-length 88))

;;; 9.7.4 Translation and text helpers

;;; 9.8 Documents, media, and desktop integrations

;;; 9.8.1 Documents and completion

;;; pdf-tools https://github.com/vedang/pdf-tools
(use-package pdf-tools
  :ensure t
  :init
  (defun bd/pdf-view-mode-setup ()
    "Disable line numbers in PDF buffers."
    (display-line-numbers-mode -1))
  :hook (pdf-view-mode . bd/pdf-view-mode-setup)
  :config
  (pdf-tools-install))

;;;; Code Completion
(use-package corfu
  :ensure t
  :custom
  (corfu-cycle t)                 ; Allows cycling through candidates
  (corfu-auto t)                  ; Enable auto completion
  (corfu-auto-prefix 0)
  (corfu-auto-delay 0)
  (corfu-echo-documentation 0.25) ; Enable documentation for completions
  (corfu-preview-current 'insert) ; Do not preview current candidate
  (corfu-preselect-first nil)
  (corfu-on-exact-match nil)      ; Don't auto expand tempel snippets
  (tab-always-indent 'complete)
  :hook (eshell-mode . bd/corfu-eshell-setup)
  :config
  (defun bd/corfu-eshell-setup ()
    "Use manual Corfu completion in Eshell."
    (setq-local corfu-auto nil)
    (corfu-mode)))

(use-package vlf
  :ensure t)

;;; 9.8.2 Desktop and media helpers

;;; 9.8.4 Window manager integration

;;; exwm
;;; customization of exwm-input-global-keys should be done before calling exwm-wm-mode
;;; any changing to exwm-input-global-keys after EXWM has finished initialization won't take effect.
(use-package exwm
  :if (and (eq system-type 'gnu/linux)
	   (not noninteractive)
	   (display-graphic-p))
  :ensure t
  :preface
  (defun bd/scrot ()
    "Capture the current screen with scrot."
    (interactive)
    (shell-command "scrot ~/Screenshots/%b%d::%H%M%S.png -q 100"))
  (defun bd/sscrot ()
    "Capture a selected screen region with scrot."
    (interactive)
    (shell-command "scrot ~/Screenshots/%b%d::%H%M%S.png --select -q 100"))
  :init
  (defun bd/exwm-rename-buffer ()
    "Rename the current EXWM buffer to its X class name."
    (exwm-workspace-rename-buffer exwm-class-name))
    (setq exwm-input-global-keys
	  `(([?\s-r] . exwm-reset)
	    ([?\s-x] . bd/scrot)
	    ([?\s-s] . bd/sscrot)
	    (,(kbd "s-<f5>") . xset)
	    ([?\s-w] . exwm-workspace-switch)
	    ([?\s-h] . windmove-left)
	    ([?\s-l] . windmove-right)
	    ([?\s-k] . windmove-up)
	    ([?\s-j] . windmove-down)
	  ([?\s-&] . (lambda (command)
		       (interactive (list (read-shell-command "$ ")))
		       (start-process-shell-command command nil command)))
	  ,@(mapcar (lambda (i)
		      `(,(kbd (format "s-%d" i)) .
			(lambda ()
			  (interactive)
			  (exwm-workspace-switch-create ,i))))
		    (number-sequence 0 9))))
  (unless (get 'exwm-input-simulation-keys 'saved-value)
    (setq exwm-input-simulation-keys
	  '(([?\C-b] . [left])
	    ([?\C-f] . [right])
	    ([?\C-p] . [up])
	    ([?\C-n] . [down])
	    ([?\C-a] . [home])
	    ([?\C-e] . [end])
	    ([?\M-v] . [prior])
	    ([?\C-v] . [next])
	    ([?\C-d] . [delete])
	    ([?\C-k] . [S-end delete]))))
  :hook ((exwm-update-class . bd/exwm-rename-buffer)
	 (exwm-init . xset))
  :custom
  (mouse-autoselect-window nil)
  (exwm-workspace-number 0)
  (exwm-manage-force-tiling nil)
  :config
  (exwm-wm-mode))



;;; 9.8.5 Database and terminal color helpers

;;; 9.8.5.1 ANSI color and SQL

(use-package ansi-color
  :init
  (defun bd/display-ansi-colors ()
    "Apply ANSI color escapes in the current buffer."
    (interactive)
    (ansi-color-apply-on-region (point-min) (point-max)))
  (defalias 'display-ansi-colors #'bd/display-ansi-colors)
  :hook (compilation-filter . ansi-color-compilation-filter))

;;; 9.8.5.2 Snippets and edit helpers

(use-package yasnippet
  :ensure t
  :hook (prog-mode . yas-minor-mode)
  :config
  (yas-global-mode 1)
  (yas-reload-all))

(use-package recentf
  :hook (after-init . recentf-mode)
  :custom (recentf-max-saved-items 50))

;;; 9.8.6.2 Battery and desktop environment

;;; https://github.com/jasonmj/battery-notifier/tree/main
(use-package battery-notifier
  :ensure t
  :custom
  (battery-notifier-timer-interval 30)
  (battery-notifier-capacity-low-threshold 20)
  (battery-notifier-capacity-critical-threshold 5)
  :config
  (battery-notifier-mode 1))

;;; 9.8.6.3 Environment import and shell aliases

(use-package exec-path-from-shell
  :ensure t
  :demand t
  :config
  (exec-path-from-shell-initialize)
  (exec-path-from-shell-copy-envs '("HYPRLAND_CMD"
				    "XDG_DESKTOP_SESSION"
				    "XDG_BACKEND"
				    "TERM"
				    "GOPRIVATE"
				    "HELM_CHART_PATH"
				    "WAYLAND_DISPLAY"
				    "MOZ_ENABLE_WAYLAND"
				    "DISPLAY"
				    "SSH_TTY"
				    "SSH_AUTH_SOCK"
				    "SSH_AGENT_PID"
				    "HYPRLAND_INSTANCE_SIGNATURE")))
