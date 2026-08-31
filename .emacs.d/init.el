(defconst bd/mac (eq system-type 'darwin))
(defconst bd/linux (eq system-type 'gnu/linux))

(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))

(defun bd/load-config-module (feature)
  "Load FEATURE from `user-emacs-directory'/lisp in source order."
  (let ((file (expand-file-name (format "lisp/%s.el" feature) user-emacs-directory)))
    (load file nil 'nomessage)))

(dolist (feature '(os-linux
		   os-mac
		   core
		   workflow
		   packages
		   agent-shell
		   custom-generated))
  (when (or (not (memq feature '(os-linux os-mac)))
	    (and (eq feature 'os-linux) bd/linux)
	    (and (eq feature 'os-mac) bd/mac))
    (bd/load-config-module feature)))
