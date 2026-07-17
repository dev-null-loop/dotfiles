(setq bd/default-font "Monaco"
      bd/default-font-size 12
      bd/dired-listing-switches "-alh"
      bd/browser-command "open"
      bd/image-open-command "open"
      bd/pdf-open-command "open"
      bd/doc-open-command "open"
      bd/font-open-command "open")

(setq mac-command-modifier 'meta
      mac-option-modifier 'super
      mac-right-option-modifier 'super
      mac-pass-option-to-system nil)

(with-eval-after-load 'eshell
  (require 'eshell-z nil t))

(provide 'os-mac)
