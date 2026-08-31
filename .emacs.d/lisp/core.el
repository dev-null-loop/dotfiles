;;; 1. Core

(defvar bd/default-font "Monaco for Powerline")
(defvar bd/default-font-size 13)
(defvar bd/dired-listing-switches "-lav -G --group-directories-first --time-style=long-iso")
(defvar bd/browser-command "qutebrowser")
(defvar bd/dired-guess-shell-alist-user nil)

;; Ensure Emacs can talk to the same SSH agent as the shell.
;; Some GUI Emacs sessions don't inherit SSH_AUTH_SOCK, which breaks
;; `ssh` and Git over SSH inside Emacs. We fix it by:
;; 1. If SSH_AUTH_SOCK is already set, leave it alone.
;; 2. Otherwise, assume ssh-agent is running with its socket in
;;    $XDG_RUNTIME_DIR/ssh-agent.socket (the common setup on Wayland/systemd).
(setenv "SSH_AUTH_SOCK"
	(or (getenv "SSH_AUTH_SOCK")
	    (concat (or (getenv "XDG_RUNTIME_DIR") "/run/user/1000")
		    "/ssh-agent.socket")))

;;; 7. Functions

;;; 7.1 Startup helper

;; Start faster by reducing the frequency of garbage collection and then use a
;; hook to measure Emacs startup time.
(defun bd/display-startup-time ()
  (message "Emacs loaded in %s with %d garbage collections."
	   (format "%.2f seconds"
		   (float-time
		    (time-subtract after-init-time before-init-time)))
	   gcs-done))

(defun bd/with-safe-default-directory (fn &rest args)
  "Call FN with an existing `default-directory'."
  (let ((default-directory
	 (cond
	  ((and (stringp default-directory)
		(file-directory-p default-directory))
	   default-directory)
	  ((and buffer-file-name
		(file-directory-p (file-name-directory buffer-file-name)))
	   (file-name-directory buffer-file-name))
	  (t (expand-file-name "~")))))
    (apply fn args)))

;;; 2. Packaging

;; https://emacs.stackexchange.com/questions/34277/best-practice-for-emacs-helm-setup-after-use-package-verse
;; Install 'use-package' if necessary.
(require 'package)
(setq package-enable-at-startup nil)
(add-to-list 'package-archives
	     '("melpa-edge" . "https://melpa.org/packages/") t)
(add-to-list 'package-archives
	     '("melpa-stable" . "https://stable.melpa.org/packages/") t)
(package-initialize)
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(load "~/tools/project-root.el")

;;; 3. UI / frames / theme

(add-to-list 'initial-frame-alist '(fullscreen . maximized))
(add-to-list 'default-frame-alist '(fullscreen . maximized))

;; Fonts: char and monospace: []il|mnopqg0O
;; 0123456789abcdefghijklmnopqrstuvwxyz [] () :;,. !@#$^&*
;; 0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ {} <> "'`  ~-_/|\?
(defun bd/disable-all-themes (&rest _)
  "Disable all active themes."
  (mapc #'disable-theme custom-enabled-themes))
(let ((font-spec (format "%s-%s" bd/default-font bd/default-font-size)))
  (when (find-font (font-spec :name bd/default-font))
    (set-face-font 'default font-spec)
    (set-frame-font font-spec)))
(set-face-attribute 'default nil
		    :foreground "#ebdbb2"
		    :background "#073642")
(bd/disable-all-themes)
(advice-add 'load-theme :before #'bd/disable-all-themes)
;; (set-face-attribute 'default nil :height 130)
;; (set-face-font 'default "Monaco for Powerline-13")
;; (set-face-font 'default "DejaVu Sans Mono-14")
;; (set-face-font 'default "Inconsolata for Powerline-16")
;; (set-face-font 'default "Consolas 7NF-14")
;; (set-face-font 'default "-microsoft-Consolas-normal-normal-normal-*-18-*-*-*-m-0-iso10646-1")

(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(fringe-mode 1) ;; https://emacs.stackexchange.com/questions/5289/any-way-to-get-a-working-separator-line-between-fringe-line-numbers-and-the-buff
(display-time-mode 0)
(savehist-mode t)
(auto-image-file-mode 0)
(global-auto-revert-mode 1)
(global-font-lock-mode 1)
(ido-mode 0)
(global-display-line-numbers-mode 1)
(setq-default truncate-lines t)

;;; 4. Variables / customization

;;; 4.1 Frame defaults

(setq default-frame-alist
      (append
       '((cursor-color . "red")
	 (default-truncate-lines . t)
	 (scroll-margin . 1))
       default-frame-alist))

;;; 4.2 Core editor behavior

(setq read-process-output-max (* 1024 1024) ;; ~1mb; [default 4k]
      gc-cons-threshold (* 2 8 1000 1024) ;; ~16mb; default is: 800 000
      create-lockfiles nil
      large-file-warning-threshold 50000000
      calc-multiplication-has-precedence nil
      ange-ftp-make-backup-files nil
      auto-compression-mode 1
      auto-save-default nil
      auto-save-list-file-prefix nil
      auto-save-mode 0
      auth-sources '("~/.authinfo")
      backup-by-copying-when-mismatch t
      blink-cursor-mode -1
      bookmark-save-flag 1
      c-default-style "linux"
      c-hungry-delete-key t
      c-toggle-hungry-state t
      case-fold-search t
      column-number-mode t
      completion-styles '(flex)
      compilation-ask-about-save 0
      compilation-scroll-output t
      compilation-window-height 9
      compile-command "make"
      default-major-mode 'text-mode
      dired-listing-switches bd/dired-listing-switches
      dired-recursive-copies 'always
      dired-recursive-deletes 'always
      ediff-window-setup-function 'ediff-setup-windows-plain
      fill-column 178
      gnus-use-full-window nil
      grep-highlight-matches t
      igrep-find t
      igrep-options "-i --color=tty"
      indent-tabs-mode nil
      inhibit-startup-message t
      kill-whole-line t
      make-backup-files nil
      mouse-wheel-follow-mouse 't
      mouse-wheel-progressive-speed nil
      mouse-wheel-scroll-amount '(2 ((shift) . 2))
      netstat-program "netstat"
      nxml-child-indent 4
      nxml-attribute-indent 4
      process-adaptive-read-buffering nil
      query-replace-highlight t
      require-final-newline t
      scroll-conservatively 50
      scroll-preserve-screen-position nil
      scroll-step 1
      search-highlight t
      set-scroll-bar-mode nil
      show-paren-mode 1
      size-indication-mode t
      split-height-threshold 80
      split-width-threshold 160
      term-suppress-hard-newline t
      transient-mark-mode 1
      trash-directory "~/.Trash"
      tramp-default-method "ssh"
      visible-bell nil
      window-min-height 0
      window-min-width 16
      x-select-enable-clipboard t)
(setq-default
 mode-line-buffer-identification
 (list '((buffer-file-name "%f"
			   (dired-directory
			    dired-directory
			    (revert-buffer-function " %b"
						    ("%b - Dir:  " default-directory)))))))

;;; 4.3 Runtime / browser / environment

(setq browse-url-browser-function #'browse-url-default-browser
      browse-url-generic-program bd/browser-command
      browse-url-handlers '(("picnob.com" . browse-url-firefox)
			    ("pixnoy.com" . browse-url-firefox)
			    ("." . browse-url-generic))
      savehist-additional-variables '(search-ring regexp-search-ring)
      savehist-file "~/.emacs.d/savehist"
      treesit-language-source-alist
      '((bash "https://github.com/tree-sitter/tree-sitter-bash")
	(cmake "https://github.com/uyha/tree-sitter-cmake")
	(css "https://github.com/tree-sitter/tree-sitter-css")
	(elisp "https://github.com/Wilfred/tree-sitter-elisp")
	(go "https://github.com/tree-sitter/tree-sitter-go")
	(html "https://github.com/tree-sitter/tree-sitter-html")
	(javascript "https://github.com/tree-sitter/tree-sitter-javascript" "master" "src")
	(json "https://github.com/tree-sitter/tree-sitter-json")
	(make "https://github.com/alemuller/tree-sitter-make")
	(markdown "https://github.com/ikatyang/tree-sitter-markdown")
	(python "https://github.com/tree-sitter/tree-sitter-python")
	(toml "https://github.com/tree-sitter/tree-sitter-toml")
	(tsx "https://github.com/tree-sitter/tree-sitter-typescript" "master" "tsx/src")
	(typescript "https://github.com/tree-sitter/tree-sitter-typescript" "master" "typescript/src")
	(yaml "https://github.com/ikatyang/tree-sitter-yaml")))
(advice-add 'browse-url-default-browser :around #'bd/with-safe-default-directory)
(advice-add 'browse-url-generic :around #'bd/with-safe-default-directory)
(prefer-coding-system 'utf-8)
(setenv "DBUS_SESSION_BUS_ADDRESS"
	"unix:path=/run/user/1000/bus")

;;; 4.4 Editing defaults and safety

(autoload 'paren "paren" nil t)
(autoload 'dired-tar "dired-tar" nil t)
(put 'downcase-region 'disabled nil)
(put 'narrow-to-region 'disabled nil)
(put 'upcase-region 'disabled nil)
(put 'erase-buffer 'disabled nil)

;; Make the kill ring work with X selections.
;; (setq select-enable-clipboard t
;;       select-enable-primary t)
