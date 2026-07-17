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

(provide 'packages)
