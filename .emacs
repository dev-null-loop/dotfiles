(let ((init-file (expand-file-name "init.el" user-emacs-directory)))
  (if (file-exists-p init-file)
      (load init-file nil 'nomessage)
    (error "Missing init.el at %s" init-file)))
