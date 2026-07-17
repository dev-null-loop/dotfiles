(setq bd/default-font "Monaco"
      bd/default-font-size 12
      bd/dired-listing-switches "-alh"
      bd/browser-command "open"
      bd/image-open-command "open"
      bd/pdf-open-command "open"
      bd/doc-open-command "open"
      bd/font-open-command "open")

(with-eval-after-load 'eshell
  (require 'eshell-z nil t))

(provide 'os-mac)
