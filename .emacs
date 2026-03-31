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

(add-to-list 'initial-frame-alist '(fullscreen . maximized)) ;; start the initial frame maximized
(add-to-list 'default-frame-alist '(fullscreen . maximized)) ;; start every frame maximized
(add-hook 'window-setup-hook 'toggle-frame-maximized t)

;; fonts: char and monospace: []il|mnopqg0O
;; 0123456789abcdefghijklmnopqrstuvwxyz [] () :;,. !@#$^&*
;; 0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ {} <> "'`  ~-_/|\?
(cond
 ((find-font (font-spec :name "Monaco for Powerline"))
  (set-face-font 'default "Monaco for Powerline-13")
  (set-frame-font "Monaco for Powerline-13")))
(set-foreground-color "#ebdbb2")
(set-background-color "#073642")
;; (add-to-list 'default-frame-alist '(font . "Monaco for Powerline-13"))
;; (set-face-font 'default "Monaco for Powerline-13")
;; (set-frame-font "Monaco for Powerline-13" nil t)
;; (set-frame-font "DejaVu Sans Mono for Powerline-13.8" nil t)
;;(set-face-font 'default "DejaVu Sans Mono-14")
;;(set-face-font 'default "Inconsolata for Powerline-16")
;;(set-face-font 'default "Consolas 7NF-14")
;;(set-face-font 'default "-microsoft-Consolas-normal-normal-normal-*-18-*-*-*-m-0-iso10646-1")

;; start faster by reducing the frequency of garbage collection and then use a hook to measure Emacs startup time.
;; The default is 800 kilobytes.  Measured in bytes.
(defun efs/display-startup-time ()
  (message "Emacs loaded in %s with %d garbage collections."
           (format "%.2f seconds"
                   (float-time
                    (time-subtract after-init-time before-init-time)))
           gcs-done))
(add-hook 'emacs-startup-hook #'efs/display-startup-time)
(setq read-process-output-max (* 1024 1024)) ;; ~1mb; [default 4k]
(setq gc-cons-threshold (* 2 8 1000 1024)) ;; ~16mb; default is: 800 000
;; Install 'use-package' if necessary
(require 'package)
(setq package-enable-at-startup nil)
(add-to-list 'package-archives;; MELPA package repository
                 '("melpa-edge" . "https://melpa.org/packages/") t)
(add-to-list 'package-archives
                 '("melpa-stable" . "https://stable.melpa.org/packages/") t)
(package-initialize)
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

;;; global settings
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(fringe-mode 1) ;; https://emacs.stackexchange.com/questions/5289/any-way-to-get-a-working-separator-line-between-fringe-line-numbers-and-the-buff
(display-time-mode 0)
(savehist-mode t)
(auto-image-file-mode 0)
(set-default 'truncate-lines t)
(setq create-lockfiles nil)
(autoload 'paren "paren" nil t)
(autoload 'dired-tar "dired-tar" nil t)
(put 'downcase-region 'disabled nil)
(put 'narrow-to-region 'disabled nil)
(put 'upcase-region 'disabled nil)
(put 'erase-buffer 'disabled nil)
(global-set-key (kbd "<XF86MonBrightnessUp>")  (lambda () (interactive) (shell-command "brightness_up")))
(global-set-key (kbd "<XF86MonBrightnessDown>")  (lambda () (interactive) (shell-command "brightness_down")))
;;; hooks
(add-hook 'after-save-hook
          'executable-make-buffer-file-executable-if-script-p)
(add-hook 'before-save-hook 'whitespace-cleanup)
(add-hook 'dired-mode-hook
          #'(lambda ()
                 (local-unset-key "\M-!")
                 (local-set-key [\C-!] 'shell-command)
                 (local-set-key "&" 'dired-do-shell-command-in-background)
                 (local-set-key "\C-d" 'usr_erase)))
(setq default-frame-alist
          (append
           '((cursor-color . "red")
         (default-truncate-lines . t)
         (foreground-color . "#ebdbb2")
         (background-color . "#073642");; HEX: #2C5967

         (scroll-margin . 1))
           default-frame-alist)
          savehist-additional-variables
          '(search-ring regexp-search-ring)
          savehist-file "~/.emacs.d/savehist")
(setq-default
 mode-line-buffer-identification
 (list '((buffer-file-name "%f"
                           (dired-directory
                                dired-directory
                                (revert-buffer-function " %b"
                                                        ("%b - Dir:  " default-directory)))))))


;; file associations
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
       auto-mode-alist)
      large-file-warning-threshold 67108864
      calc-multiplication-has-precedence nil
      ange-ftp-make-backup-files nil
      auto-compression-mode 1
      auto-save-default nil
      auto-save-list-file-prefix nil
      auto-save-mode 0
      backup-by-copying-when-mismatch t
      blink-cursor-mode -1
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
      ;; --sort=WORD change  default  'name'  sort to WORD: none (-U), size (-S), time (-t), version (-v), extension (-X), name, width
      ;; dired-listing-switches "-lav -G --group-directories-first"
      dired-listing-switches "-lav -G --group-directories-first --time-style=long-iso"
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
      mouse-wheel-follow-mouse 't
      mouse-wheel-progressive-speed nil
      mouse-wheel-scroll-amount '(2 ((shift) . 2))
      nxml-child-indent 4 nxml-attribute-indent 4
      query-replace-highlight t
      require-final-newline t
      scroll-conservatively 50
      scroll-preserve-screen-position nil
      scroll-step 1
      search-highlight t
      set-scroll-bar-mode nil
      show-paren-mode 1
      size-indication-mode t
      split-height-threshold nil
      split-width-threshold 160
      term-suppress-hard-newline t
      transient-mark-mode 1
      visible-bell nil ;; you really only need one of these OR setq ring-bell-function 'ignore
      window-min-height 8
      window-min-width 16
      x-select-enable-clipboard t)
;; Make the kill ring work with X selections.
;; (setq select-enable-clipboard t
;;       select-enable-primary t)
(defalias 'sh 'shell)
(defalias 'perl-mode 'cperl-mode)
(defalias 'yes-or-no-p 'y-or-n-p)
(defalias 'qrr 'query-replace-regexp)

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
