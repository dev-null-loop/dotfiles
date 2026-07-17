(defun bd/agent-shell-register-helm-handlers (commands)
  "Use plain minibuffer completion for agent-shell COMMANDS."
  (when (boundp 'helm-completing-read-handlers-alist)
    (dolist (command commands)
      (add-to-list 'helm-completing-read-handlers-alist
                   (cons command #'completing-read-default)))))

(defun bd/agent-shell-select-config-plain (&rest args)
  "Select an `agent-shell' config using plain string candidates."
  (let* ((prompt (or (plist-get args :prompt) "Select agent: "))
         (preferred (and (fboundp 'agent-shell--resolve-preferred-config)
                         (agent-shell--resolve-preferred-config)))
         (configs (if preferred
                      (cons preferred (remove preferred agent-shell-agent-configs))
                    agent-shell-agent-configs))
         (choices (mapcar (lambda (config)
                            (cons (substring-no-properties
                                   (or (map-elt config :mode-line-name)
                                       (map-elt config :buffer-name)
                                       "Unknown Agent"))
                                  config))
                          configs))
         (default-name (when preferred (caar choices)))
         (selected-name
          (let ((completing-read-function #'completing-read-default))
            (completing-read
             (if default-name
                 (format-prompt
                  (string-remove-suffix ": " prompt)
                  default-name)
               prompt)
             (mapcar #'car choices) nil t nil nil default-name))))
    (cdr (assoc selected-name choices))))

(with-eval-after-load 'shell-maker
  (defun shell-maker-define-major-mode (config &optional mode-map)
    "Define the major mode for the shell using CONFIG.

Optionally use MODE-MAP. When MODE-MAP is a live keymap object,
quote it before splicing it into the generated mode definition."
    (if mode-map
        (let ((mode-map-form (if (symbolp mode-map) mode-map `',mode-map)))
          (eval `(define-derived-mode ,(shell-maker-major-mode config) comint-mode
                   ,(shell-maker-config-name config)
                   ,(format "Major mode for %s shell." (shell-maker-config-name config))
                   (use-local-map ,mode-map-form))))
      (let ((mode-map-symbol (intern (format "%s-shell-mode-map"
                                             (downcase (shell-maker-config-name config))))))
        (when (boundp mode-map-symbol)
          (makunbound mode-map-symbol))
        (eval `(defvar-keymap ,mode-map-symbol :parent shell-maker-mode-map))
        (eval `(define-derived-mode ,(shell-maker-major-mode config) comint-mode
                 ,(shell-maker-config-name config)
                 ,(format "Major mode for %s shell." (shell-maker-config-name config))
                 (use-local-map ,mode-map-symbol)))))))

(use-package agent-shell
  :ensure t
  :init
  (setq agent-shell-show-config-icons nil)
  (setq agent-shell-session-strategy 'new)
  (bd/agent-shell-register-helm-handlers
   '(agent-shell
     agent-shell-mode
     agent-shell-new-shell
     agent-shell-new-temp-shell
     agent-shell-new-downloads-shell
     agent-shell-resume-session
     agent-shell-send-dwim
     agent-shell-send-region
     agent-shell-send-file
     agent-shell-send-other-file
     agent-shell-send-screenshot
     agent-shell-send-clipboard-image))
  :ensure-system-package
  ((codex . "npm install -g @openai/codex"))
  :hook ((agent-shell-mode . (lambda () (agent-shell-completion-mode -1)))
         (agent-shell-mode . buffer-disable-undo))
  :config
  (setq agent-shell-markdown-render-function
        #'agent-shell--markdown-overlays-put)
  (defun bd/agent-shell-migrate-session-restore ()
    "Translate retired agent-shell restore settings to the new variable."
    (let ((legacy-restore
           (and (boundp 'agent-shell-session-restore-strategy)
                agent-shell-session-restore-strategy)))
      (when legacy-restore
        (setq agent-shell-session-restore-verbosity
              (pcase legacy-restore
                ((or 'minimal 'title-only 'quiet) 'minimal)
                ('last 'last)
                ('first-last 'first-last)
                ('full 'full)
                (_ 'minimal))))
      (when (boundp 'agent-shell-session-restore-strategy)
        (setq agent-shell-session-restore-strategy nil))))
  (defun bd/agent-shell-keep-input-visible ()
    "Keep the selected agent-shell window pinned to the editable prompt."
    (when (and (derived-mode-p 'agent-shell-mode)
               (eq (current-buffer) (window-buffer (selected-window))))
      (let ((prompt-end (ignore-errors (shell-maker--prompt-end-position))))
        (when (and prompt-end
                   (>= (point) prompt-end)
                   (not (pos-visible-in-window-p (point) (selected-window) t)))
          (recenter -1)))))
  (defun bd/agent-shell-enable-scroll-fix ()
    "Enable local post-command scrolling repair for `agent-shell-mode'."
    (add-hook 'post-command-hook #'bd/agent-shell-keep-input-visible nil t))
  (bd/agent-shell-migrate-session-restore)
  (advice-add 'agent-shell-restart :before
              (lambda (&rest _) (bd/agent-shell-migrate-session-restore)))
  (shell-maker-define-major-mode (agent-shell--make-shell-maker-config)
                                 agent-shell-mode-map)
  (bd/agent-shell-register-helm-handlers
   (apropos-internal "^agent-shell" #'commandp))
  (add-hook 'agent-shell-mode-hook #'bd/agent-shell-enable-scroll-fix)
  (advice-add 'agent-shell-select-config :override
              #'bd/agent-shell-select-config-plain))

(with-eval-after-load 'agent-shell-openai
  (let ((codex-acp (bd/find-executable
                    "codex-acp"
                    "~/.local/node_modules/.bin/codex-acp"
                    "~/node_modules/.bin/codex-acp")))
    (setq agent-shell-mcp-servers nil)
    (setq agent-shell-preferred-agent-config
          (agent-shell-openai-make-codex-config))
    (setq agent-shell-openai-default-session-mode-id "agent")
    (when codex-acp
      (setq agent-shell-openai-codex-acp-command
            (list codex-acp "-c" "features.enable_mcp_apps=true")))
    (setq agent-shell-openai-codex-environment
          (agent-shell-make-environment-variables
           "HOME" bd/home
           "CODEX_HOME" bd/codex-home
           "CODEX_CI" ""
           "CODEX_THREAD_ID" ""
           "CODEX_SANDBOX_NETWORK_DISABLED" "0"
           :inherit-env t))
    (setq agent-shell-openai-authentication
          (agent-shell-openai-make-authentication :login t))))

(when (locate-library "agent-recall")
  (require 'agent-recall nil t))

(with-eval-after-load 'agent-recall
  (setq agent-recall-search-paths
        (delq nil (list bd/gh-dir bd/src-dir bd/ora-dir bd/home)))
  (global-agent-recall-transcript-mode 1)
  (setq agent-recall-search-function 'grep)
  (add-hook 'agent-shell-mode-hook #'agent-recall-track-sessions))

(provide 'bd-agent-shell)
