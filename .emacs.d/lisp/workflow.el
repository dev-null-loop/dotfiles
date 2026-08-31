;;; 5. Keybindings

;;; 5.1 System keys

(global-set-key (kbd "<XF86MonBrightnessUp>") (lambda () (interactive) (shell-command "brightness_up")))
(global-set-key (kbd "<XF86MonBrightnessDown>")
		(lambda () (interactive) (shell-command "brightness_down")))

;;; 5.2 Window and buffer management

(global-set-key (kbd "C-w") #'backward-kill-word)
(global-set-key (kbd "C-x C-k") #'kill-region)
(global-set-key (kbd "M-0") #'delete-window)
(global-set-key (kbd "M-1") #'delete-other-windows)
(global-set-key (kbd "M-2") #'split-window-vertically)
(global-set-key (kbd "M-3") #'split-window-horizontally)
(global-set-key (kbd "C-x C-n") #'other-window)
(global-set-key (kbd "C-x r u") #'revert-buffer)
(global-set-key (kbd "C-x k") #'bd/kill-buffer-silently)
(global-set-key (kbd "C-x m") #'list-bookmarks)
(global-set-key (kbd "C-x C-b") #'bs-show)
(global-set-key (kbd "M-g") #'goto-line)
(global-set-key (kbd "C-z") nil)
(global-set-key (kbd "C-x C-c") #'save-buffers-kill-emacs)

;;; 5.3 Shells, terminals, and commands

(global-set-key (kbd "C-c +") #'bd/resize-window-vertically)
(global-set-key (kbd "C-c C-n") #'vterm-next-prompt)
(global-set-key (kbd "C-c C-p") #'vterm-previous-prompt)
(global-set-key (kbd "C-c C-t") #'vterm-copy-mode)
(global-set-key (kbd "C-x 7 2") #'bd/maximize-window-in-direction)
(global-set-key
 (kbd "C-x 7 3")
 (lambda ()
   (interactive)
   (bd/maximize-window-in-direction 'horizontal)))

;;; 5.4 Editing and search helpers

(global-set-key (kbd "C-M-i") #'bd/toggle-fold)

;;; 5.5 Browsing and translation

(global-set-key (kbd "C-c C-o") #'browse-url-at-point)

;;; 6. Hooks

;;; 6.1 Startup and lifecycle hooks

(add-hook 'window-setup-hook 'toggle-frame-maximized t)
(add-hook 'emacs-startup-hook #'bd/display-startup-time)
(add-hook 'after-save-hook 'executable-make-buffer-file-executable-if-script-p)
(add-hook 'before-save-hook 'whitespace-cleanup)

;;; 6.2 Dired hooks

(add-hook 'dired-mode-hook
	  #'(lambda ()
	      (local-unset-key "\M-!")
	      (local-set-key [\C-!] 'shell-command)
	      (local-set-key "&" 'dired-do-shell-command-in-background)
	      (local-set-key "\C-d" #'bd/dired-delete-and-revert)))

;;; 8. Advice and aliases

;;; 8.1 General aliases

(defalias 'sh 'shell)
(defalias 'perl-mode 'cperl-mode)
(defalias 'yes-or-no-p 'y-or-n-p)
(defalias 'qrr 'query-replace-regexp)

;;; 10. File associations and registries

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
(setq dired-guess-shell-alist-user bd/dired-guess-shell-alist-user)

;;; tramp
;; https://willschenk.com/howto/2020/tramp_tricks/
;; C-x C-f /remotehost:filename RET (or /method:user@remotehost:filename)
;; C-x C-f /ssh:root@ssb.willschenk.com:/etc/host
;; C-x C-f /sudo:localhost:/etc/hosts
;; C-x C-f /sudo::/path/to/file
;; C-x C-f /docker:redis_container:/

;; $ cd /sudo::
;; /sudo:root@detlef:/root $
;; ssh-add key.rsa
;; C-x d /user@host:~ and it's done


;;(setq same-window-buffer-names nil) ;; buseste *Completions* buffer
;;(setq same-window-buffer-names '("*Completions*"))
;;(setq special-display-frame-alist '(unsplittable . nil))
;;(setq display-buffer-alist '("*Async Shell Command*" "*info*" "*terminal*" "*shell*"))

;;; 7. Functions

;;; 7.2 Dired, archives, and shell-open helpers

(defun bd/dired-delete-and-revert ()
  "Delete and revert buffer. Bound to DEL"
  (interactive)
  (dired-do-delete)
  ;; daca am sters atunci, revert, else do nothing
  (revert-buffer))

(defun archive-extract-to-file (archive-name item-name command dir)
  "Extract ITEM-NAME from ARCHIVE-NAME using COMMAND. Save to DIR."
  (unwind-protect
	  ;; remove the leading / from the file name to force
	  ;; expand-file-name to interpret its path as relative to dir
	  (let* ((file-name (if (string-match "\\`/" item-name)
				(substring item-name 1)
			  item-name))
		 (output-file (expand-file-name file-name dir))
		 (output-dir (file-name-directory output-file)))
	;; create the output directory (and its parents) if it does
	;; not exist yet
	(unless (file-directory-p output-dir)
	  (make-directory output-dir t))
	;; execute COMMAND, redirecting output to output-file
	(apply #'call-process
		   (car command)
		   nil
		   `(:file ,output-file)
		   nil
		   (append (cdr command) (list archive-name item-name))))
	nil))

(defun archive-extract-to-file (archive-name item-name command dir keep-relpath)
  "Extract ITEM-NAME from ARCHIVE-NAME using COMMAND. Save to
DIR. If KEEP-RELPATH, extract with relative path otherwise don't."
  (unwind-protect
	  (let* ((file-name (if keep-relpath
				(if (string-match "\\`/" item-name)
				    (substring item-name 1)
				  item-name)
			      (file-name-nondirectory item-name)))
		 (output-file (expand-file-name file-name dir))
		 (output-dir (file-name-directory output-file)))
	(unless (file-directory-p output-dir)
	  (make-directory output-dir t))
	(apply #'call-process
		   (car command)
		   nil
		   `(:file ,output-file)
		   nil
		   (append (cdr command) (list archive-name item-name))))
	nil))

(defun archive-extract-marked-to-file (keep-relpath)
  "Extract marked archive items to OUTPUT-DIR. If KEEP-RELPATH is non-nil
   or prefix-arg (C-u) is set, keep relative paths of files in archive,
   otherwise don't."
  (interactive "P")
  (let ((output-dir (or (dired-dwim-target-directory) default-directory))
	(command (symbol-value (archive-name "extract")))
	(archive (buffer-file-name))
	(items (archive-get-marked ?* t)))
    (mapc
     (lambda (item)
       (archive-extract-to-file archive
				(aref item 0)
				command output-dir keep-relpath))
     items)))

(add-to-list 'display-buffer-alist '("*Async Shell Command*" display-buffer-no-window (nil)))

(defun xset ()
  (interactive)
  ;; Apply the XKB layout before xmodmap so custom mappings are not raced away.
  (start-process-shell-command
   "xkb-and-xmodmap" nil
   (format "/usr/bin/setxkbmap -layout ro -option ctrl:nocaps && /usr/bin/xmodmap %s"
	   (shell-quote-argument (expand-file-name "~/.Xmodmap"))))
  (start-process-shell-command
   "xset-tweaks" nil "/usr/bin/xset b off && /usr/bin/xset r rate 250 30"))

(defun bd/resize-window-vertically (key)
  "Interactively resize the selected window with `+' or `-'."
  (interactive "cHit +/- to enlarge/shrink")
  (cond
   ((eq key (string-to-char "+"))
	(enlarge-window 1)
	(call-interactively #'bd/resize-window-vertically))
   ((eq key (string-to-char "-"))
	(enlarge-window -1)
	(call-interactively #'bd/resize-window-vertically))
   (t (push key unread-command-events))))
(defalias 'v-resize #'bd/resize-window-vertically)

(defun bd/kill-buffer-silently ()
  "Kill the current bufzzfer without confirmation; unless it is not saved."
  (interactive)
  (kill-buffer nil))
(defalias 'usr-kill-buffer-silently #'bd/kill-buffer-silently)

(defun dired-get-size ()
  (interactive)
  (message "Size of all marked files: %s"
	   (car (split-string
		 (car (last (apply #'process-lines "/usr/bin/du" "-sch"
				   (dired-get-marked-files))))))))

(defun dired-do-shell-command-in-background ()
  (interactive)
  (let* ((file (dired-get-filename))
	 (ext (downcase (concat (file-name-extension file) "$")))
	 (ps (car (assoc-default ext dired-guess-shell-alist-user))))
    (if (stringp ps)
	(let ((process-environment
	       (if (string= ps "geeqie")
		   (cons "GQ_DISABLE_CLUTTER=y" process-environment)
		 process-environment)))
	  (start-process "dired-open" nil ps file))
      (message "no association"))))

;;; 7.3 Editing and buffer helpers

(defun uniquify-all-lines-region (start end)
  "Find duplicate lines in region START to END keeping first occurrence."
  (interactive "*r")
  (save-excursion
	(let ((end (copy-marker end)))
	  (while
	      (progn
		(goto-char start)
		(re-search-forward "^\\(.*\\)\n\\(\\(.*\n\\)*\\)\\1\n" end t))
	    (replace-match "\\1\n\\2")))))

(defun uniquify-all-lines-buffer ()
  "Delete duplicate lines in buffer and keep first occurrence."
  (interactive "*")
  (uniquify-all-lines-region (point-min) (point-max)))

(defun kill-other-buffers ()
  "Kill all other buffers."
  (interactive)
  (mapc 'kill-buffer
	(delq (current-buffer)
	      (remove 'buffer-file-name (buffer-list)))))

(defun bd/toggle-fold ()
  "Toggle fold all lines larger than indentation on current line."
  (interactive)
  (let ((col 1))
	(save-excursion
	  (back-to-indentation)
	  (setq col (+ 1 (current-column)))
	  (set-selective-display
	   (if selective-display nil (or col 1))))))
(defalias 'aj-toggle-fold #'bd/toggle-fold)

(defun bd/set-region-writable (begin end)
  "Removes the read-only text property from the marked region."
  (interactive "r")
  (let ((modified (buffer-modified-p))
	(inhibit-read-only t))
    (remove-text-properties begin end '(read-only t))
    (set-buffer-modified-p modified)))
(defalias 'set-region-writeable #'bd/set-region-writable)

(defun bd/maximize-window-in-direction (&optional horizontally)
  "Maximize window.
Default vertically, unless HORIZONTALLY is non-nil."
  (interactive)
  (unless (seq-every-p
	   (apply-partially #'window-at-side-p nil)
	   (if horizontally '(left right) '(top bottom)))
    (let* ((buf (window-buffer))
	   (top-size (window-size (frame-root-window) (not horizontally)))
	   (size (min (/ top-size 2) (window-size nil (not horizontally))))
	   (dir (if horizontally
		    (if (window-at-side-p nil 'top) 'above 'below)
		  (if (window-at-side-p nil 'right) 'right 'left))))
      (delete-window)
      (set-window-buffer
       (select-window (split-window (frame-root-window) (- size) dir))
       buf))))
(defalias 'maximize-window-in-direction #'bd/maximize-window-in-direction)

;;; 7.4 Shell completion helpers

(defconst pcmpl-git-commands
  '("add" "bisect" "branch" "checkout" "clone"
    "commit" "diff" "fetch" "grep"
    "init" "log" "merge" "mv" "pull" "push" "rebase"
    "reset" "rm" "show" "status" "tag")
  "List of `git' commands.")

(defun pcomplete/git ()
  "Completion for `git'."
  (pcomplete-here* pcmpl-git-commands))

(defconst pcmpl-terraform-commands
  '("init" "validate" "plan" "apply" "destroy"
    "console" "fmt" "force-unlock" "get" "graph" "import" "login" "logout" "metadata" "modules"
    "output" "show" "state" "taint" "test" "untaint" "version" "workspace")
  "List of `terraform' commands.")

(defun pcomplete/terraform ()
  "Completion for `terraform'."
  (pcomplete-here* pcmpl-terraform-commands))

(defun pcomplete/sudo ()
  "Completion rules for the `sudo' command."
  (let ((pcomplete-ignore-case t))
	(pcomplete-here (funcall pcomplete-command-completion-function))
	(while (pcomplete-here (pcomplete-entries)))))

(defcustom pcomplete-systemctl-commands
  '("disable" "enable" "status" "start" "restart" "stop" "reenable"
    "list-units" "list-unit-files")
  "Pcomplete candidates for `systemctl' main commands."
  :type '(repeat (string :tag "systemctl command"))
  :group 'pcomplete)

(defvar pcomplete-systemd-units
  (split-string
   (shell-command-to-string
	"(systemctl list-units --all --full --no-legend;systemctl list-unit-files --full --no-legend)|while read -r a b; do echo \" $a\";done;"))
  "Pcomplete candidates for all `systemd' units.")

(defvar pcomplete-systemd-user-units
  (split-string
   (shell-command-to-string
	"(systemctl list-units --user --all --full --no-legend;systemctl list-unit-files --user --full --no-legend)|while read -r a b;do echo \" $a\";done;"))
  "Pcomplete candidates for all `systemd' user units.")

(defun pcomplete/systemctl ()
  "Completion rules for the `systemctl' command."
  (pcomplete-here (append pcomplete-systemctl-commands '("--user")))
  (cond ((pcomplete-test "--user")
	 (pcomplete-here pcomplete-systemctl-commands)
	 (pcomplete-here pcomplete-systemd-user-units))
	(t (pcomplete-here pcomplete-systemd-units))))

(defvar pcomplete-man-user-commands
  (split-string
   (shell-command-to-string
	"apropos -s 1 .|while read -r a b; do echo \" $a\";done;"))
  "Pcomplete candidates for `man' command.")

(defun pcomplete/man ()
  "Completion rules for the `man' command."
  (pcomplete-here pcomplete-man-user-commands))

;;; 7.4.1 Eshell remote helpers

(defun eshell/remote-cd (&optional directory)
  (if (file-remote-p default-directory)
      (with-parsed-tramp-file-name default-directory nil
	(eshell/cd (tramp-make-tramp-file-name
		    (tramp-file-name-method v)
		    (tramp-file-name-user v)
		    'nil
		    (tramp-file-name-host v)
		    'nil
		    (or directory "")
		    (tramp-file-name-hop v))))
    (eshell/cd directory)))
(defalias 'eshell/rcd 'eshell/remote-cd)
(defalias 'eshell/lcd 'eshell/remote-cd)
