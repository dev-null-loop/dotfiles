(defvar bd/default-font nil)
(defvar bd/default-font-size 12)
(defvar bd/dired-listing-switches nil)
(defvar bd/browser-command nil)
(defvar bd/image-open-command nil)
(defvar bd/pdf-open-command nil)
(defvar bd/doc-open-command nil)
(defvar bd/font-open-command nil)

(defconst bd/home (expand-file-name "~"))
(defconst bd/gh-dir (expand-file-name "~/gh"))
(defconst bd/src-dir (expand-file-name "~/src"))
(defconst bd/ora-dir (expand-file-name "~/ora"))
(defconst bd/codex-home (expand-file-name "~/.codex"))
(defconst bd/default-shell
  (cond
   (bd/mac "/bin/zsh")
   (bd/linux "/bin/bash")
   (t (or (getenv "SHELL") "/bin/sh"))))

(defun bd/find-executable (&rest candidates)
  "Return the first executable or existing file from CANDIDATES."
  (catch 'found
    (dolist (candidate candidates)
      (let ((path (or (executable-find candidate)
                      (expand-file-name candidate))))
        (when (and path (file-exists-p path))
          (throw 'found path))))
    nil))

(defun bd/path-entries (path-value)
  "Split PATH-VALUE into a list of non-empty path entries."
  (when path-value
    (split-string path-value path-separator t)))

(defun bd/join-path (entries)
  "Join ENTRIES into a PATH string."
  (mapconcat #'identity entries path-separator))

(defun bd/uniq-path (entries)
  "Return ENTRIES with duplicates removed, preserving order."
  (let ((seen (make-hash-table :test #'equal))
        result)
    (dolist (entry entries (nreverse result))
      (unless (gethash entry seen)
        (puthash entry t seen)
        (push entry result)))))

(defun bd/normalize-path ()
  "Normalize PATH and `exec-path' for Emacs shells and subprocesses."
  (let* ((current (bd/path-entries (getenv "PATH")))
         (extras (delq nil
                       (mapcar
                        (lambda (dir)
                          (when (file-directory-p dir) dir))
                        (append
                         (list (expand-file-name "~/.local/bin")
                               (expand-file-name "~/bin"))
                         (when bd/mac
                           '("/opt/homebrew/bin"
                             "/opt/homebrew/sbin"
                             "/usr/local/bin"))
                         (when bd/linux
                           '("/usr/local/bin"))))))
         (normalized (bd/uniq-path (append extras current))))
    (setenv "PATH" (bd/join-path normalized))
    (setq exec-path (bd/uniq-path (append normalized exec-path)))))

(defun bd/configure-shell-programs ()
  "Configure the shell programs Emacs should use."
  (setq shell-file-name bd/default-shell
        explicit-shell-file-name bd/default-shell)
  (setenv "SHELL" bd/default-shell)
  (with-eval-after-load 'vterm
    (setq vterm-shell bd/default-shell)))

(defun bd/display-startup-time ()
  "Report startup time once Emacs is initialized."
  (message "Emacs loaded in %s with %d garbage collections."
           (format "%.2f seconds"
                   (float-time
                    (time-subtract after-init-time before-init-time)))
           gcs-done))

(bd/normalize-path)
(bd/configure-shell-programs)
(add-hook 'emacs-startup-hook #'bd/display-startup-time)

(savehist-mode t)
(auto-image-file-mode 0)
(set-default 'truncate-lines t)

(setq create-lockfiles nil
      large-file-warning-threshold 67108864
      calc-multiplication-has-precedence nil
      ange-ftp-make-backup-files nil
      auto-compression-mode 1
      auto-save-default nil
      auto-save-list-file-prefix nil
      auto-save-mode 0
      backup-by-copying-when-mismatch t
      bookmark-save-flag 1
      c-default-style "linux"
      c-hungry-delete-key t
      c-toggle-hungry-state t
      case-fold-search t
      column-number-mode t
      compilation-ask-about-save 0
      compilation-scroll-output nil
      compilation-window-height 9
      compile-command "make"
      default-major-mode 'text-mode
      dired-recursive-copies 'always
      dired-recursive-deletes 'always
      fill-column 178
      gnus-use-full-window nil
      grep-highlight-matches t
      igrep-find t
      igrep-options "-i --color=tty"
      indent-tabs-mode nil
      inhibit-startup-message t
      kill-whole-line t
      make-backup-files nil
      mouse-wheel-follow-mouse t
      mouse-wheel-progressive-speed nil
      mouse-wheel-scroll-amount '(2 ((shift) . 2))
      nxml-child-indent 4
      nxml-attribute-indent 4
      query-replace-highlight t
      require-final-newline t
      scroll-conservatively 50
      scroll-preserve-screen-position nil
      scroll-step 1
      search-highlight t
      show-paren-mode 1
      size-indication-mode t
      split-height-threshold nil
      split-width-threshold 160
      term-suppress-hard-newline t
      transient-mark-mode 1
      visible-bell nil
      window-min-height 8
      window-min-width 16
      x-select-enable-clipboard t
      savehist-additional-variables '(search-ring regexp-search-ring)
      savehist-file (expand-file-name "savehist" user-emacs-directory))

(setq-default mode-line-buffer-identification
              (list '((buffer-file-name "%f"
                                        (dired-directory
                                         dired-directory
                                         (revert-buffer-function
                                          " %b"
                                          ("%b - Dir:  " default-directory)))))))

(setq auto-mode-alist
      (append
       '(("\\.js$" . javascript-mode)
         ("\\.stumpwmrc$" . lisp-mode)
         ("\\.conkerorrc$" . javascript-mode)
         ("\\.sqp$" . sqlplus-mode)
         ("\\.gnus$" . emacs-lisp-mode)
         ("\\.war$" . archive-mode)
         ("\\.ps1$" . powershell-mode)
         ("\\.zip$" . archive-mode)
         ("\\.ear$" . archive-mode)
         ("\\.wkf$" . jython-mode)
         ("\\.dsl$" . groovy-mode)
         ("env-vars" . sh-mode)
         ("\\.pp$" . terraform-mode)
         ("\\.ppvars$" . terraform-mode)
         ("\\.hcl$" . terraform-mode)
         ("\\.spc$" . terraform-mode)
         ("\\.sar$" . archive-mode)
         ("\\.yml$" . yaml-mode)
         ("\\.yaml$" . yaml-mode)
         ("\\.tfvars$" . terraform-mode)
         (".gitlab-ci.yml" . gitlab-ci-mode))
       auto-mode-alist))

(autoload 'paren "paren" nil t)
(autoload 'dired-tar "dired-tar" nil t)
(put 'downcase-region 'disabled nil)
(put 'narrow-to-region 'disabled nil)
(put 'upcase-region 'disabled nil)
(put 'erase-buffer 'disabled nil)

(defalias 'sh 'shell)
(defalias 'perl-mode 'cperl-mode)
(defalias 'yes-or-no-p 'y-or-n-p)
(defalias 'qrr 'query-replace-regexp)

(global-set-key (kbd "C-x k") #'kill-current-buffer)

(defun bd/usr-erase ()
  "Delete the current Dired selection, then refresh the buffer."
  (interactive)
  (dired-do-delete)
  (revert-buffer))

(add-hook 'after-save-hook #'executable-make-buffer-file-executable-if-script-p)
(add-hook 'before-save-hook #'whitespace-cleanup)
(add-hook 'dired-mode-hook
          (lambda ()
            (local-unset-key "\M-!")
            (local-set-key [\C-!] #'shell-command)
            (local-set-key "&" #'dired-do-shell-command-in-background)
            (local-set-key "\C-d" #'bd/usr-erase)))

(provide 'core)
