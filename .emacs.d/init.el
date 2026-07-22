(defconst bd/mac (eq system-type 'darwin))
(defconst bd/linux (eq system-type 'gnu/linux))

(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))

(setq custom-file (expand-file-name "custom.el" user-emacs-directory))

(defun bd/load-config-module (feature)
  "Load FEATURE from `user-emacs-directory'/lisp, even during reloads."
  (let ((file (expand-file-name (format "lisp/%s.el" feature) user-emacs-directory)))
    (if (file-exists-p file)
        (load file nil 'nomessage)
      (require feature))))

(bd/load-config-module 'core)
(bd/load-config-module 'packages)

(when bd/linux
  (bd/load-config-module 'os-linux))

(when bd/mac
  (bd/load-config-module 'os-mac))

(bd/load-config-module 'ui)
(bd/load-config-module 'bd-agent-shell)
(bd/load-config-module 'workflow)

(load custom-file 'noerror)

(let ((local-file (expand-file-name "local.el" user-emacs-directory)))
  (when (file-exists-p local-file)
    (load local-file nil t)))
