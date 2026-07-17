(defconst bd/mac (eq system-type 'darwin))
(defconst bd/linux (eq system-type 'gnu/linux))

(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))

(setq custom-file (expand-file-name "custom.el" user-emacs-directory))

(require 'core)
(require 'packages)

(when bd/linux
  (require 'os-linux))

(when bd/mac
  (require 'os-mac))

(require 'ui)
(require 'bd-agent-shell)
(require 'workflow)

(load custom-file 'noerror)

(let ((local-file (expand-file-name "local.el" user-emacs-directory)))
  (when (file-exists-p local-file)
    (load local-file nil t)))
