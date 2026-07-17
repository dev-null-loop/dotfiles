(require 'package)

(add-to-list 'package-archives '("melpa-edge" . "https://melpa.org/packages/") t)
(add-to-list 'package-archives '("melpa-stable" . "https://stable.melpa.org/packages/") t)

(package-initialize)

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(use-package exec-path-from-shell
  :ensure t
  :if (or bd/mac bd/linux)
  :config
  (exec-path-from-shell-initialize)
  (exec-path-from-shell-copy-envs
   (append
    '("TERM" "GOPRIVATE" "HELM_CHART_PATH" "DISPLAY"
      "SSH_TTY" "SSH_AUTH_SOCK" "SSH_AGENT_PID")
    (when bd/linux
      '("HYPRLAND_CMD" "XDG_DESKTOP_SESSION" "XDG_BACKEND"
        "WAYLAND_DISPLAY" "MOZ_ENABLE_WAYLAND"
        "HYPRLAND_INSTANCE_SIGNATURE"))))
  (bd/normalize-path)
  (bd/configure-shell-programs)
  :demand t)

(use-package ghostel
  :ensure t
  :commands (ghostel
             ghostel-project
             ghostel-other
             ghostel-next
             ghostel-previous
             ghostel-list-buffers)
  :custom
  (ghostel-shell bd/default-shell)
  (ghostel-shell-integration t)
  (ghostel-use-native-pty t)
  (ghostel-kill-buffer-on-exit t)
  :config
  (with-eval-after-load 'ghostel-eshell
    (setq ghostel-eshell-track-title nil))
  (add-hook 'eshell-load-hook #'ghostel-eshell-visual-command-mode))

(defun bd/helm-font-family ()
  "Return the font family Helm should use for highlighted headers."
  (or bd/default-font
      (face-attribute 'default :family nil t)))

(defun bd/helm-apply-fonts ()
  "Apply consistent Helm fonts across Linux and macOS."
  (let ((family (bd/helm-font-family)))
    (when (and family (stringp family) (not (string-empty-p family)))
      (face-remap-add-relative 'default :family family)
      (set-face-attribute 'helm-source-header nil :family family))))

(use-package helm
  :ensure t
  :bind (("C-x C-f" . helm-find-files)
         ("C-x C-b" . helm-buffers-list)
         ("M-x" . helm-M-x)
         ("M-y" . helm-show-kill-ring)
         ("M-s o" . helm-occur)
         ("M-s i" . helm-imenu)
         ("M-s I" . helm-imenu-in-all-buffers)
         ("M-s m" . helm-mini)
         ("M-s b" . helm-bookmarks)
         ("M-l" . helm-eshell-history)
         ("C-c h" . helm-command-prefix))
  :config
  (global-unset-key (kbd "C-x c"))
  (setq helm-candidate-separator "***"
        helm-candidate-number-limit 200
        helm-M-x-fuzzy-match t
        helm-ff-keep-cached-candidates nil
        helm-semantic-fuzzy-match t
        helm-imenu-fuzzy-match t
        helm-buffers-fuzzy-matching t
        helm-recentf-fuzzy-match t
        helm-split-window-in-side-p t
        helm-move-to-line-cycle-in-source t
        helm-ff-search-library-in-lsexp t
        helm-scroll-amount 8
        helm-ff-file-name-history-use-recentf t
        helm-echo-input-in-header-line t
        helm-display-header-line nil
        helm-show-completion-display-function
        #'helm-show-completion-default-display-function)
  (set-frame-parameter nil 'background-mode 'dark)
  (add-hook 'helm-major-mode-hook #'bd/helm-apply-fonts)
  (with-eval-after-load 'helm
    (define-key helm-map (kbd "<tab>") #'helm-execute-persistent-action)
    (define-key helm-map (kbd "C-i") #'helm-execute-persistent-action)
    (define-key helm-map (kbd "C-z") #'helm-select-action)
    (set-face-attribute 'helm-selection nil
                        :background "red"
                        :foreground "#ebdbb2"))
  (helm-autoresize-mode 1)
  (setq helm-autoresize-max-height 30
        helm-autoresize-min-height 30)
  (add-hook 'helm-after-initialize-hook #'helm-init-relative-display-line-numbers)
  (define-key global-map [remap find-file] #'helm-find-files)
  (define-key global-map [remap execute-extended-command] #'helm-M-x)
  (define-key global-map [remap switch-to-buffer] #'helm-mini))

(use-package helm-xref
  :ensure t)

(provide 'packages)
