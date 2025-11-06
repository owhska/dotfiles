;;; Initialize package system
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

;; Bootstrap `use-package`
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(require 'use-package)
(setq use-package-always-ensure t)

;;Config particular
(defun display-warning (&rest _args) nil)
(setq warning-minimum-level :emergency)

;;Tab em todos modos de edicao    
;;(global-set-key (kbd "TAB") 'self-insert-command)
(setq tab-width 4)
(setq-default indent-tabs-mode nil)

;; === TRANSPARÊNCIA ===
(add-to-list 'default-frame-alist '(alpha . (92 . 87)))
(set-frame-parameter nil 'alpha '(92 . 87))

;;TESTES
;;(use-package font-lock
;;  :custom-face
;;  (font-lock-keyword-face ((t (:foreground unspecified :background unspecified))))
;;  (font-lock-operator-face ((t (:foreground unspecified))))
;;  (font-lock-type-face ((t (:foreground unspecified))))
;;  (font-lock-variable-name-face ((t (:foreground unspecified :background unspecified))))
;;  (font-lock-constant-face ((t (:foreground unspecified :background unspecified))))
;;  (font-lock-number-face ((t (:foreground unspecified))))
;;  (font-lock-doc-face ((t (:foreground unspecified :inherit 'font-lock-comment-face))))
;;  (font-lock-preprocessor-face ((t (:foreground unspecified))))
;;  (font-lock-builtin-face ((t (:foreground unspecified)))))

(use-package vertico
  :ensure t
  :init (vertico-mode))

(use-package consult
  :ensure t
  :bind (("C-s" . consult-line)
         ("C-c h" . consult-history)
         ("C-x 8" . consult-imenu)
	 ("C-c f" . consult-find)
	 ("C-c r" . consult-ripgrep))
  :init (consult-preview-at-point-mode))

(use-package orderless
  :ensure t
  :custom (completion-styles '(orderless)))

;;TRABALHO
(use-package typescript-mode
  :ensure t
  :mode "\\.ts\\'")

;;IDO-MODE
;;(ido-mode 1)
;;(ido-everywhere 1)
;;(setq ido-auto-merge-work-directories-length -1)

;; Set custom file
(setq custom-file "~/.emacs.custom.el")
(load custom-file 'noerror)

;; Add local load path
(add-to-list 'load-path "~/.emacs.local/")

;; Enable electric pair mode
(electric-pair-mode 1)

;;; Appearance
(defun rc/get-default-font ()
  (cond
   ((eq system-type 'gnu/linux) "Iosevka-20")))

(add-to-list 'default-frame-alist `(font . ,(rc/get-default-font)))

(global-display-line-numbers-mode 1)
(add-hook 'emacs-startup-hook #'toggle-frame-maximized)

;; VERTICO for enhanced minibuffer completion
(use-package vertico
  :init
  (vertico-mode)
  :config
  (setq vertico-cycle t))

;; MARGINALIA for documentation and context in vertico popups
(use-package marginalia
  :after vertico
  :init
  (marginalia-mode))


;; Evil mode
(use-package evil
  :ensure t
  :config
  (evil-mode 1))

;; Font settings
(set-face-attribute 'default nil :family "JetBrains Mono" :height 250)

;; UI settings
(tool-bar-mode 0)
(menu-bar-mode 0)
(scroll-bar-mode 0)
(column-number-mode 1)
(show-paren-mode 1)
(setq inhibit-startup-screen t)
(setq ring-bell-function 'ignore)

;; Theme
(use-package gruber-darker-theme
  :ensure t
  :config
  (load-theme 'gruber-darker t))

;; Optional Zenburn theme (uncomment if needed)
;; (use-package zenburn-theme
;;   :ensure t
;;   :config
;;   (load-theme 'zenburn t)
;;   (set-face-attribute 'line-number nil :inherit 'default))

;;; C mode
(setq-default c-basic-offset 4
              c-default-style '((java-mode . "java")
                                (awk-mode . "awk")
                                (other . "bsd")))

(add-hook 'c-mode-hook
          (lambda ()
            (interactive)
            (c-toggle-comment-style -1)))

;;; Elixir mode
(use-package elixir-mode
  :ensure t
  :hook
  (elixir-mode . (lambda ()
                   (subword-mode 1) ;; Better navigation for camelCase/snake_case
                   (rc/turn-on-eldoc-mode))) ;; Enable ElDoc for Elixir
  :config
  (setq elixir-basic-offset 2)) ;; Set indentation to 2 spaces, standard for Elixir

;;; Emacs Lisp
(add-hook 'emacs-lisp-mode-hook
          (lambda ()
            (local-set-key (kbd "C-c C-j") 'eval-print-last-sexp)))
(add-to-list 'auto-mode-alist '("Cask" . emacs-lisp-mode))

;;; Word wrap
(defun rc/enable-word-wrap ()
  (interactive)
  (toggle-word-wrap 1))

(add-hook 'markdown-mode-hook 'rc/enable-word-wrap)

;;; nXML mode
(add-to-list 'auto-mode-alist '("\\.html\\'" . nxml-mode))
(add-to-list 'auto-mode-alist '("\\.xsd\\'" . nxml-mode))
(add-to-list 'auto-mode-alist '("\\.ant\\'" . nxml-mode))

;;; TRAMP
(setq tramp-auto-save-directory "/tmp")

;;; ElDoc mode
(defun rc/turn-on-eldoc-mode ()
  (interactive)
  (eldoc-mode 1))

(add-hook 'emacs-lisp-mode-hook 'rc/turn-on-eldoc-mode)

;;; LaTeX mode
(add-hook 'tex-mode-hook
          (lambda ()
            (add-to-list 'tex-verbatim-environments "code")))
(setq font-latex-fontify-sectioning 'color)

;;; Ebisp
(add-to-list 'auto-mode-alist '("\\.ebi\\'" . lisp-mode))

;;; Astyle for formatting
(defun astyle-buffer (&optional justify)
  (interactive)
  (let ((saved-line-number (line-number-at-pos)))
    (shell-command-on-region
     (point-min)
     (point-max)
     "astyle --style=kr"
     nil
     t)
    (goto-line saved-line-number)))

(add-hook 'simpc-mode-hook
          (lambda ()
            (setq-local fill-paragraph-function 'astyle-buffer)))

;;; Compilation
(require 'compile)
(add-to-list 'compilation-error-regexp-alist
             '("\\([a-zA-Z0-9\\.]+\\)(\\([0-9]+\\)\\(,\\([0-9]+\\)\\)?) \\(Warning:\\)?"
               1 2 (4) (5)))

(message "✅ Configuração carregada com sucesso!")
