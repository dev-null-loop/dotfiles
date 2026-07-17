;; Linux GUI sessions do not always inherit SSH_AUTH_SOCK.
(setenv "SSH_AUTH_SOCK"
        (or (getenv "SSH_AUTH_SOCK")
            (concat (or (getenv "XDG_RUNTIME_DIR") "/run/user/1000")
                    "/ssh-agent.socket")))

(setq bd/default-font "Monaco for Powerline"
      bd/default-font-size 13
      bd/dired-listing-switches "-lav -G --group-directories-first --time-style=long-iso"
      bd/browser-command (or (bd/find-executable "qutebrowser")
                             (bd/find-executable "xdg-open"))
      bd/image-open-command (or (bd/find-executable "geeqie")
                                (bd/find-executable "xdg-open"))
      bd/pdf-open-command (or (bd/find-executable "mupdf")
                              (bd/find-executable "xdg-open"))
      bd/doc-open-command (or (bd/find-executable "libreoffice")
                              (bd/find-executable "xdg-open"))
      bd/font-open-command (or (bd/find-executable "display")
                               (bd/find-executable "xdg-open")))

(when (and (executable-find "brightness_up")
           (executable-find "brightness_down"))
  (global-set-key (kbd "<XF86MonBrightnessUp>")
                  (lambda () (interactive) (shell-command "brightness_up")))
  (global-set-key (kbd "<XF86MonBrightnessDown>")
                  (lambda () (interactive) (shell-command "brightness_down"))))

(with-eval-after-load 'eshell
  (require 'eshell-z nil t)
  (add-to-list 'eshell-command-aliases-list
               '("spq" "runcon unconfined_u:unconfined_r:unconfined_t:s0 steampipe query --output csv $*")))

(provide 'os-linux)
