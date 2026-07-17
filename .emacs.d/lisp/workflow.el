(use-package projectile
  :bind-keymap (("C-c C-p" . projectile-command-map)
                ("C-c p" . projectile-command-map)
                ("s-p" . projectile-command-map))
  :hook (after-init . projectile-mode)
  :config
  (setq projectile-completion-system 'helm
        projectile-enable-caching 0
        projectile-require-project-root nil
        projectile-switch-project-action 'projectile-dired)
  (projectile-register-project-type
   'terraform
   '("versions.tf")
   :project-file '("versions.tf")
   :compile "terraform plan"))

(use-package smartparens
  :ensure t)

(use-package ansible
  :ensure t)

(use-package jinja2-mode
  :ensure t)

(defun bd/yaml-next-field ()
  "Jump to the next YAML field separator."
  (interactive)
  (search-forward-regexp ": *"))

(defun bd/yaml-prev-field ()
  "Jump to the previous YAML field separator."
  (interactive)
  (search-backward-regexp ": *"))

(defun bd/toggle-fold ()
  "Toggle simple indentation-based folding."
  (interactive)
  (let ((col 1))
    (save-excursion
      (back-to-indentation)
      (setq col (+ 1 (current-column)))
      (set-selective-display
       (if selective-display nil (or col 1))))))

(global-set-key [(C M i)] #'bd/toggle-fold)

(use-package highlight-indentation
  :ensure t
  :config
  (set-face-background 'highlight-indentation-face "#ebdbb2"))

(add-hook 'yaml-mode-hook #'flymake-yamllint-setup)
(use-package yaml-mode
  :ensure t
  :config
  (add-to-list 'auto-mode-alist '("\\.yml$" . yaml-mode))
  (add-hook 'yaml-mode-hook
            (lambda ()
              (smartparens-mode)
              (highlight-indentation-mode 1)
              (define-key yaml-mode-map "\C-m" #'newline-and-indent)
              (define-key yaml-mode-map "\C-c n" #'bd/yaml-next-field)
              (define-key yaml-mode-map "\C-c p" #'bd/yaml-prev-field))))

(use-package git-link
  :ensure t)

(use-package forge
  :ensure t
  :after magit)

(use-package transient
  :ensure t
  :config
  (transient-bind-q-to-quit))

(use-package magit
  :ensure t
  :bind (("C-x g" . magit-status)
         ("C-c g" . magit-file-dispatch)
         ("C-c c l" . git-link))
  :custom
  (magit-log-section-commit-count 20)
  (magit-log-margin '(t "%Y-%m-%d %H:%M " magit-log-margin-width t 18))
  (git-link-use-commit t)
  (global-magit-file-mode t)
  (magit-display-buffer-function
   (lambda (buffer)
     (display-buffer buffer '(display-buffer-same-window))))
  :config
  (dolist (cmd '(magit-edit-line-commit magit-clean))
    (put cmd 'disabled nil)))

(with-eval-after-load 'magit-status
  (require 'magit-sequence)
  (require 'magit-bisect)
  (require 'magit-stash))

(with-eval-after-load 'git-link
  (dolist (host '("orahub\\.oci\\.oraclecorp\\.com"
                  "devops\\.scmservice\\.eu-frankfurt-1\\.oci\\.oraclecloud\\.com"))
    (add-to-list 'git-link-remote-alist (list host #'git-link-github))
    (add-to-list 'git-link-commit-remote-alist (list host #'git-link-commit-github))))

(use-package visual-regexp
  :defer t
  :config
  (define-key global-map (kbd "C-c r") #'vr/replace)
  (define-key global-map (kbd "C-c q") #'vr/query-replace)
  (define-key global-map (kbd "C-c m") #'vr/mc-mark))

(when bd/linux
  (use-package pulseaudio-control
    :ensure t
    :bind (("<XF86AudioRaiseVolume>" . pulseaudio-control-increase-sink-volume)
           ("<XF86AudioLowerVolume>" . pulseaudio-control-decrease-sink-volume)
           ("<XF86AudioMute>" . pulseaudio-control-toggle-current-sink-mute)
           ("C-c v" . hydra-pulseaudio-control/body))
    :bind-keymap ("C-c v" . pulseaudio-control-map)
    :config
    (use-package hydra :ensure t)
    (defhydra hydra-pulseaudio-control (:hint nil)
      "Pulseaudio Control"
      ("+" pulseaudio-control-increase-sink-kvolume "Increase Volume")
      ("i" pulseaudio-control-increase-sink-volume "Increase Volume")
      ("-" pulseaudio-control-decrease-sink-volume "Decrease Volume")
      ("d" pulseaudio-control-decrease-sink-volume "Decrease Volume")
      ("m" pulseaudio-control-toggle-current-sink-mute "Toggle Mute")
      ("s" pulseaudio-control-select-sink-by-name "Select Sink")
      ("q" nil "quit"))
    (setq pulseaudio-control-volume-step "5%"
          pulseaudio-control-use-default-sink t
          pulseaudio-control-use-default-source t))
  (pulseaudio-control-default-keybindings))

(use-package vterm
  :ensure t
  :custom
  (vterm-always-compile-module t)
  (vterm-max-scrollback 1000000)
  :bind (:map vterm-mode-map
              ("M-2" . split-window-vertically))
  :config
  (global-set-key (kbd "C-c C-n") #'vterm-next-prompt)
  (global-set-key (kbd "C-c C-p") #'vterm-previous-prompt)
  (global-set-key (kbd "C-c C-t") #'vterm-copy-mode))

(use-package markdown-mode
  :ensure t
  :mode (("README\\.md\\'" . gfm-mode)
         ("\\.markdown\\'" . gfm-mode)
         ("\\.md\\'" . gfm-mode))
  :init
  (setq markdown-command "multimarkdown")
  :config
  (font-lock-mode -1))

(autoload 'markdown-mode "markdown-mode" "Major mode for Markdown." t)
(autoload 'gfm-mode "markdown-mode" "Major mode for GitHub Markdown." t)

(use-package groovy-mode
  :mode ("\\.groovy\\'" . groovy-mode))

(use-package ace-window
  :ensure t
  :config
  (global-set-key (kbd "s-o") #'ace-window)
  (setq aw-scope 'frame))

(use-package macro-math
  :defer t
  :bind (("C-x =" . macro-math-eval-region)
         ("C-x ~" . macro-math-eval-and-round-region)))

(setq tramp-default-method "ssh")

(use-package eshell
  :init
  (setq eshell-scroll-to-bottom-on-input 'all
        eshell-error-if-no-glob t
        eshell-hist-ignoredups t
        eshell-save-history-on-exit t
        eshell-prefer-lisp-functions nil
        eshell-destroy-buffer-when-process-dies t
        eshell-cmpl-cycle-completions nil
        eshell-buffer-maximum-lines 1048576)
  :config
  (add-hook 'eshell-mode-hook
            (lambda ()
              (dolist (cmd '("ssh" "tail" "wget" "top"))
                (add-to-list 'eshell-visual-commands cmd))
              (setq pcomplete-cycle-completions nil)))
  (add-to-list 'eshell-modules-list 'eshell-tramp)
  (with-eval-after-load 'em-term
    (setq eshell-visual-subcommands
          (cl-delete-duplicates eshell-visual-subcommands :test #'equal))))

(use-package bash-completion
  :ensure t
  :config
  (bash-completion-setup)
  (add-hook 'eshell-mode-hook
            (lambda ()
              (add-hook 'completion-at-point-functions
                        #'bash-completion-capf-nonexclusive nil t))))

(use-package em-hist
  :ensure nil)

(use-package dictionary
  :ensure t)

(use-package terraform-doc
  :ensure t)

(use-package terraform-mode
  :ensure t
  :hook (terraform-mode . terraform-format-on-save-mode))

(global-auto-revert-mode 1)
(global-font-lock-mode 1)
(ido-mode 0)
(helm-mode 1)
(setq completion-styles '(flex)
      helm-follow-mode-persistent t
      helm-find-noerrors 1)
(when (fboundp 'helm-projectile-on)
  (helm-projectile-on))

(global-set-key (kbd "C-w") #'backward-kill-word)
(global-set-key (kbd "C-x C-k") #'kill-region)
(global-set-key (kbd "M-0") #'delete-window)
(global-set-key (kbd "M-1") #'delete-other-windows)
(global-set-key (kbd "M-2") #'split-window-vertically)
(global-set-key (kbd "M-3") #'split-window-horizontally)
(global-set-key (kbd "C-x C-n") #'other-window)
(global-set-key (kbd "C-x r u") #'revert-buffer)
(global-set-key (kbd "C-x m") #'list-bookmarks)
(global-set-key (kbd "C-x C-b") #'bs-show)
(global-set-key (kbd "M-g") #'goto-line)
(global-set-key (kbd "C-c C-o") #'browse-url-at-point)
(global-set-key (kbd "C-x C-c") #'save-buffers-kill-emacs)

(use-package pdf-tools
  :ensure t
  :config
  (pdf-tools-install))

(add-hook 'pdf-view-mode-hook
          (lambda ()
            (display-line-numbers-mode -1)))

(use-package corfu
  :ensure t
  :custom
  (corfu-cycle t)
  (corfu-auto t)
  (corfu-auto-prefix 0)
  (corfu-auto-delay 0)
  (corfu-echo-documentation 0.25)
  (corfu-preview-current 'insert)
  (corfu-preselect-first nil)
  (corfu-on-exact-match nil)
  :config
  (setq tab-always-indent 'complete)
  (add-hook 'eshell-mode-hook
            (lambda ()
              (setq-local corfu-auto nil)
              (corfu-mode))))

(use-package vlf
  :ensure t)

(use-package go-mode
  :ensure t
  :hook (before-save . gofmt-before-save)
  :bind (:map go-mode-map
              ("M-." . godef-jump)
              ("<f6>" . gofmt)
              ("C-c 6" . gofmt))
  :config
  (setq gofmt-command "goimports"))

(use-package blacken
  :ensure t
  :config
  (setq blacken-line-length 88))

(setq ediff-window-setup-function 'ediff-setup-windows-plain)

(use-package google-translate
  :ensure t
  :config
  (require 'google-translate-default-ui)
  (global-set-key (kbd "C-c t") #'google-translate-at-point)
  (global-set-key (kbd "C-c T") #'google-translate-query-translate)
  (defun google-translate--search-tkk () "Search TKK." (list 430675 2721866130))
  (setq google-translate-backend-method 'curl))

(global-display-line-numbers-mode 1)

(setq auth-sources '("~/.authinfo")
      netstat-program "netstat")
(prefer-coding-system 'utf-8)

(when bd/linux
  (setenv "DBUS_SESSION_BUS_ADDRESS" "unix:path=/run/user/1000/bus"))

(use-package ansi-color
  :ensure t
  :hook (compilation-filter . ansi-color-compilation-filter))

(use-package sql
  :ensure t)

(add-to-list 'same-window-buffer-names "*SQL*")

(defun bd/sql-save-history-hook ()
  "Save SQL input history in a per-product file."
  (let ((lval 'sql-input-ring-file-name)
        (rval 'sql-product))
    (if (symbol-value rval)
        (let ((filename
               (concat "~/.emacs.d/sql/"
                       (symbol-name (symbol-value rval))
                       "-history.sql")))
          (set (make-local-variable lval) filename))
      (error "SQL history will not be saved because %s is nil"
             (symbol-name rval)))))

(add-hook 'sql-interactive-mode-hook #'bd/sql-save-history-hook)

(defun bd/sql-login-hook ()
  "Custom SQL login behavior for Oracle sessions."
  (when (eq sql-product 'oracle)
    (let ((proc (get-buffer-process (current-buffer))))
      (comint-send-string proc "SET COLSEP \"|\";\n")
      (comint-send-string proc "SET LINESIZE 16000;\n")
      (comint-send-string proc "SET PAGESIZE 9999;\n"))))

(add-hook 'sql-login-hook #'bd/sql-login-hook)

(setq compilation-scroll-output t)

(use-package pcmpl-args
  :ensure t)

(setq completion-in-region-function #'consult-completion-in-region)

(use-package yasnippet
  :ensure t
  :config
  (yas-global-mode 1)
  (yas-reload-all))

(add-hook 'prog-mode-hook #'yas-minor-mode)

(use-package kubernetes
  :ensure t
  :commands (kubernetes-overview)
  :config
  (setq kubernetes-poll-frequency 3600
        kubernetes-redraw-frequency 3600))

(fset 'k8s #'kubernetes-overview)

(use-package kubel
  :ensure t
  :after (vterm)
  :config
  (kubel-vterm-setup))

(use-package emms-setup
  :ensure nil
  :init
  (add-hook 'emms-player-started-hook #'emms-show)
  :config
  (setq emms-show-format "Playing: %s"
        emms-source-playlist-default-format 'm3u
        emms-source-file-default-directory "~/music/")
  (emms-all)
  (emms-default-players))

(put 'emms-browser-delete-files 'disabled nil)

(use-package recentf
  :hook (after-init . recentf-mode)
  :custom
  (recentf-max-saved-items 50))

(provide 'workflow)
