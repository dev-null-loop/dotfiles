(defun bd/apply-default-font ()
  "Apply the configured default font if it is available."
  (when (and bd/default-font
             (find-font (font-spec :name bd/default-font)))
    (let ((font-spec (format "%s-%d" bd/default-font bd/default-font-size)))
      (set-face-font 'default font-spec)
      (set-frame-font font-spec nil t))))

(defun bd/maximize-frame (&optional frame)
  "Maximize FRAME in a way that works across Linux and macOS."
  (let ((target (or frame (selected-frame))))
    (when (frame-live-p target)
      (set-frame-parameter target 'fullscreen 'maximized)
      (when (display-graphic-p target)
        (modify-frame-parameters target '((fullscreen . maximized)))))))

(add-hook 'window-setup-hook #'bd/maximize-frame)
(add-hook 'after-make-frame-functions #'bd/maximize-frame)

(bd/apply-default-font)

(set-foreground-color "#ebdbb2")
(set-background-color "#073642")

(when (fboundp 'fringe-mode)
  (fringe-mode 1))
(display-time-mode 0)

(setq default-frame-alist
      (append
       '((cursor-color . "red")
         (default-truncate-lines . t)
         (foreground-color . "#ebdbb2")
         (background-color . "#073642")
         (scroll-margin . 1))
       default-frame-alist))

(when bd/dired-listing-switches
  (setq dired-listing-switches bd/dired-listing-switches))

(when bd/browser-command
  (setq browse-url-browser-function 'browse-url-generic
        browse-url-generic-program bd/browser-command))

(setq dired-guess-shell-alist-user
      `(("ADF$" ,bd/image-open-command)
        ("CR2$" ,bd/image-open-command)
        ("doc$" ,bd/doc-open-command)
        ("docx$" ,bd/doc-open-command)
        ("jpeg$" ,bd/image-open-command)
        ("jpg$" ,bd/image-open-command)
        ("odp$" ,bd/doc-open-command)
        ("ods$" ,bd/doc-open-command)
        ("odt$" ,bd/doc-open-command)
        ("otf$" ,bd/font-open-command)
        ("pdf$" ,bd/pdf-open-command)
        ("png$" ,bd/image-open-command)
        ("pps$" ,bd/doc-open-command)
        ("ppt$" ,bd/doc-open-command)
        ("pptm$" ,bd/doc-open-command)
        ("pptx$" ,bd/doc-open-command)
        ("rtf$" ,bd/doc-open-command)
        ("svg$" ,bd/image-open-command)
        ("ttf$" ,bd/font-open-command)
        ("webp$" ,bd/image-open-command)
        ("xls$" ,bd/doc-open-command)
        ("xlsx$" ,bd/doc-open-command)))

(provide 'ui)
