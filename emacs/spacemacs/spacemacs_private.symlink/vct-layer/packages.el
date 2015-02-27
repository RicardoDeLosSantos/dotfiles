
;; This file is used to extend Spacemacs configuration.
(defvar vct-layer-packages
  '(
    org
    markdown-mode
   )
)
(defvar vct-layer-excluded-packages '()
)
(defun vct-layer/init-org ()
  (use-package org
    :init (progn
      (defun vct-org-visual-line ()
          (setq visual-line-fringe-indicators '(nil right-curly-arrow))
          (turn-on-visual-line-mode)
      )
      (add-hook 'org-mode-hook 'vct-org-visual-line)
      (add-hook 'org-mode-hook 'org-bullets-mode t)

      (defun vct-org-hooks ()
          (plist-put org-format-latex-options :scale 1.4)
      )
      (add-hook 'org-mode-hook 'vct-org-hooks)

      (defun vct-org-color-hooks ()
          (font-lock-add-keywords 'org-mode
            '(
               (
                 "\\(\\\\begin\\|\\\\end\\)\\(?:\{\\)\\(.*\\)\\(?:\}\\)"
                 (1 'font-lock-keyword-face)
                 (2 'font-lock-function-name-face)
               )
             )
          )
          (font-lock-add-keywords 'org-mode
            '(
               (
                 "\\(\\\\label\\)\\(?:\{\\)\\(.*\\)\\(?:\}\\)"
                 (1 'font-lock-keyword-face)
                 (2 'font-lock-constant-face)
               )
             )
           )
      )
      (add-hook 'org-mode-hook 'vct-org-color-hooks)

      (set-face-attribute 'italic nil
                          ;;:family "DejaVu Sans Mono"
                          :family "Inconsolata Italic"
                          :height 100
                          :weight 'normal
                          :width 'normal)
      ;(set-face-attribute 'variable-pitch nil :font "DejaVu Sans Mono-11" :weight 'bold)
      (dolist (face '(
                      org-block-begin-line
                      org-block-end-line
                      org-verbatim
                      org-block-background
                      org-level-1
                      org-level-2
                      org-level-3
                      org-level-4
                     )
              )
          (set-face-attribute face nil :inherit 'fixed-pitch)
      )
      (set-face-attribute 'fixed-pitch nil :font "Inconsolata-11")
    )
    :config (
      message "vct-layer loaded successfully!"
    )
  )
)
(defun vct-layer/init-markdown-mode ()
  (use-package markdown-mode
    :init (progn
    )
    :config (
      message "vct-layer loaded successfully!"
    )
  )
)
