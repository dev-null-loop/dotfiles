;;; 9.9.1 Agent shell support functions

;;; 9.9.1.1 Helper functions

(defvar bd/home (expand-file-name "~"))
(defvar bd/codex-home (expand-file-name "~/.codex"))
(defvar bd/codex-acp-command
  (expand-file-name ".local/node_modules/.bin/codex-acp" bd/home))
(defvar bd/agent-recall-transcript-dir
  (expand-file-name "~/.agent-shell/transcripts"))

(use-package shell-maker
  :config
  (defun shell-maker-define-major-mode (config &optional mode-map)
    "Define the major mode for the shell using CONFIG.

Optionally use MODE-MAP.  When MODE-MAP is a live keymap object,
quote it before splicing it into the generated mode definition."
    (if mode-map
	(let ((mode-map-form (if (symbolp mode-map)
				 mode-map
			       `',mode-map)))
	  (eval `(define-derived-mode ,(shell-maker-major-mode config) comint-mode
		   ,(shell-maker-config-name config)
		   ,(format "Major mode for %s shell." (shell-maker-config-name config))
		   (use-local-map ,mode-map-form))))
      (let ((mode-map-symbol (intern (format "%s-shell-mode-map"
					     (downcase (shell-maker-config-name config))))))
	(when (boundp mode-map-symbol)
	  (makunbound mode-map-symbol))
	(eval `(defvar-keymap ,mode-map-symbol
		 :parent shell-maker-mode-map))
	(eval `(define-derived-mode ,(shell-maker-major-mode config) comint-mode
		 ,(shell-maker-config-name config)
		 ,(format "Major mode for %s shell." (shell-maker-config-name config))
		 (use-local-map ,mode-map-symbol)))))))

;;; 9.9.2 Agent shell and local AI tooling

(use-package agent-shell
  :ensure t
  :preface
  (defun bd/agent-shell-register-helm-handlers (commands)
    "Use plain minibuffer completion for agent-shell COMMANDS.
Helm can mis-handle propertized agent-shell candidates and try to
execute a `keymap' text property as a command."
    (when (boundp 'helm-completing-read-handlers-alist)
      (dolist (command commands)
	(add-to-list 'helm-completing-read-handlers-alist
		     (cons command #'completing-read-default)))))
  (defun bd/agent-shell-select-config-plain (&rest args)
    "Select an `agent-shell' config using plain string candidates.
ARGS accepts the same plist as `agent-shell-select-config'."
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
	   (selected-name (let ((completing-read-function #'completing-read-default))
			    (completing-read
			     (if default-name
				 (format-prompt
				  (string-remove-suffix ": " prompt)
				  default-name)
			       prompt)
			     (mapcar #'car choices) nil t nil nil default-name))))
      (cdr (assoc selected-name choices))))
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
    "Keep the selected agent-shell window pinned to the editable prompt.

This works around a recent scrolling regression where typing or
submitting input can leave point below the visible window even though the
user is still editing the live prompt."
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
  (defun bd/agent-shell-mode-setup ()
    "Apply local editing setup for `agent-shell-mode'."
    (agent-shell-completion-mode -1)
    (buffer-disable-undo)
    (bd/agent-shell-enable-scroll-fix))
  :init
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
  ;; Add agent installation configs here
  ((codex . "npm install -g @openai/codex"))
  :hook (agent-shell-mode . bd/agent-shell-mode-setup)
  :custom
  ;; Set this before the package loads so autoloaded entry points also
  ;; use plain string candidates for the agent picker.
  (agent-shell-show-config-icons nil)
  ;; Start a fresh ACP session by default so the configured Codex mode
  ;; is applied instead of inheriting an older resumed session.
  (agent-shell-session-strategy 'new)
  :config
  ;; The 2026-07-13 in-place Markdown renderer rewrites the live fragment on
  ;; every ACP chunk and can display streamed replies one token per paragraph.
  ;; Use the package's supported non-destructive renderer until that streaming
  ;; regression is fixed upstream.
  (setq agent-shell-markdown-render-function
	#'agent-shell--markdown-overlays-put)
  (bd/agent-shell-migrate-session-restore)
  (advice-add 'agent-shell-restart :before
	      (lambda (&rest _) (bd/agent-shell-migrate-session-restore)))
  (shell-maker-define-major-mode (agent-shell--make-shell-maker-config)
				 agent-shell-mode-map)
  (bd/agent-shell-register-helm-handlers
   (apropos-internal "^agent-shell" #'commandp))
  (advice-add 'agent-shell-select-config :override
	      #'bd/agent-shell-select-config-plain))

(use-package agent-shell-openai
  :after agent-shell
  :config
  ;; Keep Codex setup behind the OpenAI backend load so startup does not
  ;; depend on `agent-shell' internals being eagerly required.
  (setq agent-shell-mcp-servers nil
	agent-shell-preferred-agent-config
	(agent-shell-openai-make-codex-config)
	;; Do not force an immediate `session/set_mode` after startup.
	;; Current `codex-acp` already defaults to Agent mode, and letting the
	;; server choose avoids version-skew issues during new-session bootstrap.
	agent-shell-openai-default-session-mode-id nil
	agent-shell-openai-codex-acp-command
	(list bd/codex-acp-command
	      "-c" "features.enable_mcp_apps=true")
	agent-shell-openai-codex-environment
	(agent-shell-make-environment-variables
	 "HOME" bd/home
	 "CODEX_HOME" bd/codex-home
	 "CODEX_CI" ""
	 "CODEX_THREAD_ID" ""
	 "INITIAL_AGENT_MODE" "agent"
	 "CODEX_SANDBOX_NETWORK_DISABLED" "0"
	 :inherit-env t)
	agent-shell-openai-authentication
	(agent-shell-openai-make-authentication :login t)))

(use-package agent-recall
  :after agent-shell
  :custom
  (agent-recall-search-function 'grep)
  (agent-recall-canonical-transcript-dir bd/agent-recall-transcript-dir)
  (agent-recall-index-project-local-transcripts nil)
  :hook (agent-shell-mode . agent-recall-track-sessions)
  :config
  (global-agent-recall-transcript-mode 1)
  (message "agent-recall backend=%S" (agent-recall--effective-search-function)))

;;(setq agent-shell-prefer-session-resume nil)
;; helm-M-x-execute-command: Keyword argument :group-id not one of (:namespace-id :block-id :label-left :label-right :body)
;; agent-shell-ui-make-fragment-model: Keyword argument :group-id not one of (:namespace-id :block-id :label-left :label-right :body)
