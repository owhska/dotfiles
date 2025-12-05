;;; === CRITICAL PERFORMANCE CONFIGURATIONS ===
;; RADICAL optimizations that must come BEFORE everything
(setq gc-cons-threshold 400000000)  ; 400MB during loading
(setq read-process-output-max (* 16 1024 1024))  ; 16MB for I/O
(setq inhibit-startup-screen t)
(setq inhibit-startup-message t)
(setq inhibit-startup-echo-area-message t)
(setq initial-major-mode 'fundamental-mode)
(setq initial-scratch-message nil)
(setq message-log-max 1000)
(setq auto-save-default nil)
(setq create-lockfiles nil)

;; Radical UI performance
(setq idle-update-delay 2.0)
(setq redisplay-skip-fontification-on-input t)
(setq auto-window-vscroll nil)



(setq fast-but-imprecise-scrolling t)
(setq jit-lock-stealth-time 10)
(setq jit-lock-defer-time 1.0)
(setq jit-lock-stealth-verbose nil)

;; ULTRA radical minimal interface
(tool-bar-mode -1)
(menu-bar-mode -1) 
(scroll-bar-mode -1)
(setq visible-bell nil)
(setq ring-bell-function 'ignore)
(setq use-dialog-box nil)
(setq use-file-dialog nil)
(setq inhibit-compacting-font-caches t)

;;; === PACKAGE INSTALLATION (MINIMAL) ===
(require 'package)
(setq package-archives '(("melpa" . "https://melpa.org/packages/")
                         ("gnu" . "https://elpa.gnu.org/packages/")))

;;; === LSP MODE (OPTIMIZED) ===

;; Install and configure LSP mode
(defun my-load-lsp-mode ()
  "Load LSP mode with optimizations."
  (package-initialize)
  
  ;; Install required packages if necessary
  (unless (package-installed-p 'lsp-mode)
    (package-refresh-contents)
    (package-install 'lsp-mode))
  
  (unless (package-installed-p 'company)
    (package-install 'company))
  
  ;; Configure LSP BEFORE loading
  (setq lsp-keymap-prefix "C-c l")
  (setq lsp-restart 'auto-restart)
  (setq lsp-enable-symbol-highlighting nil)
  (setq lsp-enable-on-type-formatting nil)
  (setq lsp-auto-guess-root t)
  (setq lsp-signature-auto-activate nil)
  (setq lsp-signature-render-documentation nil)
  (setq lsp-ui-sideline-show-code-actions nil)
  (setq lsp-diagnostics-provider :none)
  (setq lsp-ui-doc-enable nil)
  (setq lsp-headerline-breadcrumb-enable nil)
  (setq lsp-auto-execute-action nil)
  (setq lsp-enable-code-action nil)
  (setq lsp-code-action-enable nil)
  
  ;; Load LSP mode
  (when (require 'lsp-mode nil t)
    ;; Configure hooks for specific languages
    (dolist (hook '((python-mode . lsp-deferred)
                    (js-mode . lsp-deferred)
                    (js-jsx-mode . lsp-deferred)
                    (typescript-mode . lsp-deferred)
                    (typescript-ts-mode . lsp-deferred)
                    (elixir-mode . lsp-deferred)
                    (web-mode . lsp-deferred)
                    (c-mode . lsp-deferred)
                    (c++-mode . lsp-deferred)
                    (java-mode . lsp-deferred)
                    (go-ts-mode . lsp-deferred)
                    (rust-mode . lsp-deferred)))
      (add-hook (car hook) (cdr hook)))
    
    ;; Configure company mode for completion
    (when (require 'company nil t)
      (setq company-idle-delay 0.1
            company-minimum-prefix-length 1
            company-selection-wrap-around t
            company-show-numbers t
            company-tooltip-limit 5
            company-tooltip-align-annotations nil
            company-tooltip-flip-when-above t
            company-tooltip-annotation nil
            company-format-margin-function nil
            company-frontends '(company-pseudo-tooltip-frontend))
      (global-company-mode 1))))

;; Load LSP after a short delay
(run-with-idle-timer 1 nil 'my-load-lsp-mode)

;;; === EVIL MODE (WITHOUT USE-PACKAGE) ===

;; Performance configurations BEFORE loading
(setq evil-want-integration nil)
(setq evil-want-C-u-scroll t)
(setq evil-want-C-i-jump nil)
(setq evil-respect-visual-line-mode nil)
(setq evil-search-module 'evil-search)
(setq evil-ex-complete-emacs-commands nil)
(setq evil-ex-interactive-search-history nil)

;; Load evil mode in an organized way
(defun my-load-evil-mode ()
  "Load Evil Mode correctly."
  (package-initialize)  ; Initialize packages here
  
  ;; Install Evil if necessary
  (unless (package-installed-p 'evil)
    (package-refresh-contents)
    (package-install 'evil))
  
  ;; Load and activate Evil
  (when (require 'evil nil t)
    (evil-mode 1)
    
    ;; Configure keybindings
    (define-key evil-normal-state-map (kbd "C-s") 'my-enhanced-isearch)
    (define-key evil-insert-state-map (kbd "C-s") 'my-enhanced-isearch)
    (define-key evil-visual-state-map (kbd "C-s") 'my-enhanced-isearch)
    
    ;; Add GC hooks only if Evil loaded
    (add-hook 'evil-insert-state-entry-hook 'my-evil-optimize-gc)
    (add-hook 'evil-insert-state-exit-hook 'my-evil-restore-gc)
    
    ))

;; Execute after 0.5 seconds
(run-with-idle-timer 0.5 nil 'my-load-evil-mode)

;;; === EVIL MODE SPECIFIC OPTIMIZATIONS ===

;; Optimized GC for Evil Mode operations
(defun my-evil-optimize-gc ()
  "Optimize GC for Evil Mode operations."
  (setq gc-cons-threshold 200000000))

(defun my-evil-restore-gc ()
  "Restore normal GC after Evil operations."
  (setq gc-cons-threshold 80000000))

;;; === ULTRA FAST FILE SEARCH SYSTEM ===

;; Global settings for case-insensitive search
(setq case-fold-search t)
(setq read-file-name-completion-ignore-case t)
(setq completion-ignore-case t)

;; Main file search system
(defun my-find-files ()
  "Case-insensitive file search with intelligent pattern matching.
Ex: 'Modulo' finds Modulo.java, ModuloMapper.java, ModuloService.java
    'test.js' finds test.js, unit-test.js, test-utils.js"
  (interactive)
  (let ((dir (read-directory-name "Directory: " default-directory))
        (input (read-string "Search pattern: " (my-get-initial-input))))
    (find-name-dired dir (my-process-search-pattern input))))

(defun my-get-initial-input ()
  "Get initial input based on context."
  (cond
   ;; If we're in a file buffer, suggest the base name
   ((buffer-file-name)
    (file-name-sans-extension (file-name-nondirectory (buffer-file-name))))
   ;; If there's an active selection, use the selected text
   ((use-region-p)
    (buffer-substring-no-properties (region-beginning) (region-end)))
   ;; Otherwise, empty string
   (t "")))

(defun my-process-search-pattern (input)
  "Process search pattern to make it more flexible."
  (cond
   ;; If it already has wildcards, use as is
   ((string-match-p "[*?]" input) input)
   
   ;; If it's a filename with extension (ex: Modulo.java)
   ((string-match-p "\\.[^.]*$" input)
    (let ((name (file-name-sans-extension input))
          (ext (file-name-extension input)))
      (if (string-empty-p name)
          (concat "*." ext)
        (concat "*" name "*." ext))))
   
   ;; Just text without extension - search in any part of the name
   (t (concat "*" input "*"))))

;; Fast search with find (even better performance)
(defun my-fast-find-files ()
  "Ultra-fast file search using native find."
  (interactive)
  (let ((dir (read-directory-name "Directory: " default-directory))
        (pattern (read-string "Pattern (ex: *Modulo*.java): " "*")))
    (find-file 
     (completing-read "Select file: "
                      (split-string 
                       (shell-command-to-string 
                        (format "find '%s' -type f -iname '%s' 2>/dev/null | head -100" 
                                dir pattern)) "\n" t)))))

;; Search in Git project (if available)
(defun my-find-in-git-repo ()
  "Search files in current Git repository."
  (interactive)
  (let ((git-root (locate-dominating-file default-directory ".git")))
    (if git-root
        (let ((default-directory git-root))
          (call-interactively 'my-find-files))
      (call-interactively 'my-find-files))))

;;; === NATIVE SEARCH/COMPLETION SYSTEM ===

;; Icomplete (native alternative to Vertico)
(icomplete-mode 1)
(setq completion-styles '(basic partial-completion emacs22))
(setq completion-category-overrides '((file (styles basic partial-completion))))

;; Settings for case-insensitive completion
(setq completion-ignore-case t)
(setq read-buffer-completion-ignore-case t)
(setq read-file-name-completion-ignore-case t)

;; Native incremental search
(setq search-highlight t)
(setq search-whitespace-regexp ".*?")
(setq isearch-lazy-count t)
(setq isearch-allow-scroll t)
(setq isearch-case-fold-search t)  ; Case-insensitive isearch

;;; === FAST SEARCH SYSTEM ===

;; Text search in files (similar to consult-ripgrep - C-c r)
(defun my-grep-in-current-dir ()
  "Search text in current directory (fast)."
  (interactive)
  (let ((pattern (read-string "Text to search: ")))
    (grep (format "grep -nH -r -i \"%s\" ." pattern))))  ; -i for case-insensitive

(defun my-grep-in-project ()
  "Search text in project files."
  (interactive)
  (let ((pattern (read-string "Text to search: "))
        (directory (read-directory-name "Directory: " default-directory)))
    (grep (format "grep -nH -r -i \"%s\" %s" pattern directory))))

;; Enhanced incremental search (similar to consult-line - C-s)
(defun my-enhanced-isearch ()
  "Start isearch with symbol at point. Use C-n/C-p to navigate."
  (interactive)
  (let ((symbol (thing-at-point 'symbol t)))
    (isearch-forward)
    (when symbol
      (isearch-yank-string symbol))))

;; Improved occur (powerful buffer search)
(defun my-occur-symbol ()
  "Search current symbol in buffer with occur."
  (interactive)
  (let ((symbol (thing-at-point 'symbol t)))
    (if symbol
        (occur symbol)
      (call-interactively 'occur))))

(defun my-occur-project ()
  "Search text in all open buffers."
  (interactive)
  (let ((pattern (read-string "Search in all buffers: ")))
    (multi-occur (buffer-list) pattern)))

;;; === PERSONAL CONFIGURATIONS (Minimal) ===
(defun display-warning (&rest _args) nil)
(setq warning-minimum-level :emergency)
(global-set-key [C-tab] 'other-window)
(global-set-key (kbd "C-c c") 'compile)
(global-set-key (kbd "C-c x") 'execute-extended-command)

;;; === CLIPBOARD INTEGRATION (Copy/Paste between Emacs and OS) ===

;; Configure clipboard integration
(setq select-enable-clipboard t)      ; Make killing and yanking use clipboard
(setq select-enable-primary t)        ; Also use primary selection (middle click)
(setq save-interprogram-paste-before-kill t) ; Save clipboard before killing
(setq mouse-drag-copy-region t)       ; Mouse selection copies to clipboard

;; Function to copy to system clipboard (C-c C-c)
(defun my-copy-to-clipboard ()
  "Copy region to system clipboard."
  (interactive)
  (if (use-region-p)
      (progn
        (kill-ring-save (region-beginning) (region-end))
        (message "Copied to clipboard!"))
    (message "No region selected!")))

;; Function to paste from system clipboard (C-c C-v)
(defun my-paste-from-clipboard ()
  "Paste from system clipboard."
  (interactive)
  (yank)
  (message "Pasted from clipboard!"))

;; Function to cut to system clipboard (C-c C-x)
(defun my-cut-to-clipboard ()
  "Cut region to system clipboard."
  (interactive)
  (if (use-region-p)
      (progn
        (kill-region (region-beginning) (region-end))
        (message "Cut to clipboard!"))
    (message "No region selected!")))

;; Configure Evil Mode for better clipboard integration
(defun my-configure-evil-clipboard ()
  "Configure Evil Mode for clipboard operations."
  (when (featurep 'evil)
    ;; In Evil normal mode: y copies to clipboard
    (define-key evil-normal-state-map "y" 'evil-yank)
    (define-key evil-visual-state-map "y" 'evil-yank)
    
    ;; In Evil normal mode: p pastes from clipboard
    (define-key evil-normal-state-map "p" 'evil-paste-after)
    (define-key evil-normal-state-map "P" 'evil-paste-before)
    
    ;; In insert mode: C-y pastes from clipboard
    (define-key evil-insert-state-map (kbd "C-y") 'yank)))

;; Alternative keybindings (more standard)
(global-set-key (kbd "C-c C-c") 'my-copy-to-clipboard)
(global-set-key (kbd "C-c C-v") 'my-paste-from-clipboard)
(global-set-key (kbd "C-c C-x") 'my-cut-to-clipboard)

;; Use C-c y and C-c p as simpler alternatives
(global-set-key (kbd "C-c y") 'my-copy-to-clipboard)
(global-set-key (kbd "C-c p") 'my-paste-from-clipboard)

;; Set up clipboard after Evil loads
(add-hook 'evil-mode-hook 'my-configure-evil-clipboard)

;; Workaround for terminal Emacs
(when (not (display-graphic-p))
  ;; For terminal Emacs, we need to use xclip/xsel
  (cond
   ((executable-find "xclip")
    (setq x-select-enable-clipboard t)
    (defun xclip-copy (start end)
      (interactive "r")
      (shell-command-on-region start end "xclip -selection clipboard"))
    (defun xclip-paste ()
      (interactive)
      (insert (shell-command-to-string "xclip -selection clipboard -o")))
    (global-set-key (kbd "C-c C-c") 'xclip-copy)
    (global-set-key (kbd "C-c C-v") 'xclip-paste))
   
   ((executable-find "pbcopy") ; macOS
    (setq x-select-enable-clipboard t)
    (defun pbcopy-copy (start end)
      (interactive "r")
      (shell-command-on-region start end "pbcopy"))
    (defun pbpaste-paste ()
      (interactive)
      (insert (shell-command-to-string "pbpaste")))
    (global-set-key (kbd "C-c C-c") 'pbcopy-copy)
    (global-set-key (kbd "C-c C-v") 'pbpaste-paste))))

;;; === IMPROVED YANK/POP FUNCTIONALITY ===

;; Make yank (paste) show what was yanked
(setq yank-excluded-properties t)  ; Don't copy text properties
(setq yank-pop-change-selection t) ; Change selection when yank-popping

;; Function to show yanked text in minibuffer
(defun my-yank-advice (orig-fun &rest args)
  "Show yanked text in minibuffer."
  (let ((result (apply orig-fun args)))
    (when (and kill-ring (not (string= (car kill-ring) "")))
      (let ((text (car kill-ring)))
        (message "Yanked: %s" 
                 (if (> (length text) 50)
                     (concat (substring text 0 47) "...")
                   text))))
    result))

;; Enable the advice
(advice-add 'yank :around 'my-yank-advice)
(advice-add 'evil-paste-after :around 'my-yank-advice)
(advice-add 'evil-paste-before :around 'my-yank-advice)

;; SEARCH SHORTCUTS CONFIGURATION
(global-set-key (kbd "C-s") 'my-enhanced-isearch)        ; Incremental search
(global-set-key (kbd "C-c f") 'my-find-files)            ; File search (case-insensitive)
(global-set-key (kbd "C-c F") 'my-fast-find-files)       ; Fast file search
(global-set-key (kbd "C-c g") 'my-find-in-git-repo)      ; Search in Git repo
(global-set-key (kbd "C-c r") 'my-grep-in-current-dir)   ; Text search in files

;; Tab settings
(setq tab-width 4)
(setq-default indent-tabs-mode nil)

;;; === RADICAL PERFORMANCE CONFIGURATIONS ===

;; AGGRESSIVE intelligent GC
(defun my-minibuffer-setup-hook ()
  (setq gc-cons-threshold 800000000))

(defun my-minibuffer-exit-hook ()
  (setq gc-cons-threshold 400000000))

(add-hook 'minibuffer-setup-hook #'my-minibuffer-setup-hook)
(add-hook 'minibuffer-exit-hook #'my-minibuffer-exit-hook)

;; ULTRA fast file system
(setq backup-directory-alist `(("." . "~/.emacs.d/backups")))
(setq auto-save-list-file-prefix nil)

;;; === EDITING ESSENTIALS ===

;; Electric pair - lightweight
(electric-pair-mode 1)

;; Native show-paren (lighter than git-gutter for parentheses)
(show-paren-mode 1)
(setq show-paren-delay 0)

;;; === DISABLE UNNECESSARY FEATURES FOR LSP ===

;; Disable elements that interfere with LSP
(setq eldoc-mode nil)
(global-eldoc-mode -1)
(tab-bar-mode -1)
(setq mode-line-misc-info nil)
(remove-hook 'emacs-lisp-mode-hook 'eldoc-mode)
(remove-hook 'lsp-mode-hook 'eldoc-mode)

;;; === NATIVE GIT INTEGRATION ===

(defun my-git-status-info ()
  "Return Git branch and status information."
  (when (and (buffer-file-name)
             (locate-dominating-file default-directory ".git"))
    (let* ((git-dir (locate-dominating-file default-directory ".git"))
           (branch (with-temp-buffer
                     (cd git-dir)
                     (when (zerop (call-process "git" nil t nil 
                                               "branch" "--show-current"))
                       (string-trim (buffer-string)))))
           (status (with-temp-buffer
                     (cd git-dir)
                     (call-process "git" nil t nil "status" "--porcelain")
                     (if (> (buffer-size) 0) "!" ""))))
      (when branch
        (format "  %s%s" branch status)))))

;; Native VC (Version Control) - much lighter
(setq vc-handled-backends '(Git))
(setq vc-follow-symlinks t)

;; Mode-line with native Git info
;; Mode-line minimalista mas funcional

(setq-default mode-line-format
  '("%e"
    " "
    (:propertize "%b" face mode-line-buffer-id)
    "  "
    (:eval (when-let ((git-info (my-git-status-info)))
             (propertize git-info 'face 'font-lock-type-face)))
    "   "

    (:propertize mode-name face font-lock-keyword-face)
    "   "
    "%l:%c"
    "   " 
    (:eval (when (buffer-modified-p)
	     (propertize "●" 'face 'error)))))

(force-mode-line-update t)

;;; === LANGUAGE MODES (REAL on-demand) ===

;; Native TypeScript (if available)
(when (fboundp 'typescript-ts-mode)
  (add-to-list 'auto-mode-alist '("\\.tsx?\\'" . typescript-ts-mode)))

;; Native Go  
(when (fboundp 'go-ts-mode)
  (add-to-list 'auto-mode-alist '("\\.go\\'" . go-ts-mode)))

;; Elixir - use fundamental mode if not available
(add-to-list 'auto-mode-alist '("\\.exs?\\'" . prog-mode))

;;; === APPEARANCE CONFIGURATIONS ===

(custom-set-faces
 ;; Base
 `(default ((t (:background "#121212" :foreground "#EAEAEA"))))
 `(cursor ((t (:background "#F59E0B"))))
 
 ;; Basic syntax
 `(font-lock-comment-face ((t (:foreground "#8A8A8D" :italic t))))
 `(font-lock-comment-delimiter-face ((t (:foreground "#737373" :italic t))))
 `(font-lock-string-face ((t (:foreground "#EAEAEA"))))
 `(font-lock-doc-face ((t (:foreground "#BEBEBE" :italic t))))
 `(font-lock-number-face ((t (:foreground "#FBBF24"))))
 `(font-lock-keyword-face ((t (:foreground "#059669" :bold t))))
 `(font-lock-function-name-face ((t (:foreground "#DC2626"))))
 `(font-lock-type-face ((t (:foreground "#FBBF24"))))
 `(font-lock-constant-face ((t (:foreground "#D97706"))))
 `(font-lock-builtin-face ((t (:foreground "#F59E0B"))))
 `(font-lock-variable-name-face ((t (:foreground "#EAEAEA"))))
 `(font-lock-preprocessor-face ((t (:foreground "#FBBF24" :bold t))))
 `(font-lock-warning-face ((t (:foreground "#DC2626" :background "#262626" :bold t))))
 
 ;; UI
 `(hl-line ((t (:background "#212121"))))
 `(region ((t (:background "#333333" :foreground "#FFFFFF"))))
 `(highlight ((t (:background "#262626"))))
 `(fringe ((t (:background "#121212" :foreground "#333333"))))
 `(vertical-border ((t (:foreground "#333333"))))
 
 ;; Mode line
 `(mode-line ((t (:background "#212121" :foreground "#EAEAEA" :box (:line-width 1 :color "#333333")))))
 `(mode-line-inactive ((t (:background "#0D0D0D" :foreground "#8A8A8D" :box (:line-width 1 :color "#262626")))))
 `(mode-line-highlight ((t (:background "#333333" :foreground "#EAEAEA"))))
 `(mode-line-emphasis ((t (:bold t :foreground "#DC2626"))))
 
 ;; Search
 `(isearch ((t (:background "#F59E0B" :foreground "#121212" :bold t))))
 `(lazy-highlight ((t (:background "#3B82F6" :foreground "#121212"))))
 `(match ((t (:background "#8D20B2" :foreground "#121212" :bold t))))
 
 ;; Minibuffer
 `(minibuffer-prompt ((t (:foreground "#3B82F6" :bold t))))
 `(completions-common-part ((t (:foreground "#10B981"))))
 `(completions-first-difference ((t (:foreground "#DC2626"))))
 
 ;; Diffs
 `(diff-added ((t (:background "#262626" :foreground "#10B981"))))
 `(diff-removed ((t (:background "#262626" :foreground "#DC2626"))))
 `(diff-changed ((t (:background "#262626" :foreground "#F59E0B"))))
 
 ;; Org
 `(org-level-1 ((t (:foreground "#DC2626" :bold t :height 1.2))))
 `(org-level-2 ((t (:foreground "#3B82F6" :bold t))))
 `(org-level-3 ((t (:foreground "#10B981" :bold t))))
 `(org-code ((t (:foreground "#B027DE" :background "#0D0D0D"))))
 `(org-link ((t (:foreground "#3B82F6" :underline t))))
 `(org-todo ((t (:foreground "#DC2626" :bold t))))
 `(org-done ((t (:foreground "#10B981" :bold t))))
 
 ;; Line numbers - CONFIGURAÇÃO CORRIGIDA
 `(line-number ((t (:inherit default :foreground "#333333" :background "#121212"))))
 `(line-number-current-line ((t (:inherit default :foreground "#BEBEBE" :background "#212121" :bold t))))
 
 ;; Parentheses
 `(show-paren-match ((t (:background "#3B82F6" :foreground "#121212" :bold t))))
 `(show-paren-mismatch ((t (:background "#DC2626" :foreground "#121212" :bold t))))
 
 ;; Widgets
 `(widget-button ((t (:foreground "#3B82F6" :bold t :underline t))))
 `(widget-field ((t (:background "#0D0D0D" :foreground "#EAEAEA"))))
 
 ;; Status
 `(error ((t (:foreground "#DC2626" :bold t))))
 `(warning ((t (:foreground "#F59E0B" :bold t))))
 `(success ((t (:foreground "#10B981" :bold t))))

 ;; Additional for better compatibility
 `(header-line ((t (:inherit mode-line))))
 `(tooltip ((t (:background "#212121" :foreground "#EAEAEA"))))
 `(shadow ((t (:foreground "#8A8A8D"))))
 `(secondary-selection ((t (:background "#262626"))))
 `(trailing-whitespace ((t (:background "#DC2626"))))
 `(escape-glyph ((t (:foreground "#F59E0B"))))
 `(homoglyph ((t (:foreground "#F59E0B"))))
 `(bold ((t (:bold t))))
 `(italic ((t (:italic t)))))

;; Fonts - DEFER
(run-with-idle-timer 5 nil
  (lambda ()
    (add-to-list 'default-frame-alist '(font . "Iosevka-14"))))

;;; === SCALABLE LINE NUMBERS - CONFIGURAÇÃO SIMPLIFICADA ===

;; Remove configurações problemáticas de largura fixa
(setq display-line-numbers-width nil)  ; Remove largura fixa
(setq display-line-numbers-grow-only nil)  ; Permite que diminua também

;; Configuração mínima e funcional para números de linha
(setq display-line-numbers-minor-type t)  ; Números relativos opcionais

;; Função simplificada para números de linha
(defun my-fix-line-numbers-scale ()
  "Ajusta números de linha quando texto é escalado - versão simplificada."
  (when display-line-numbers-mode
    (display-line-numbers-mode -1)
    (display-line-numbers-mode 1)))

;; Ajustar números quando o texto é escalado (opcional)
(add-hook 'text-scale-mode-hook 'my-fix-line-numbers-scale)

;;; === INTELLIGENT LINE NUMBERING ===
(add-hook 'prog-mode-hook 'display-line-numbers-mode)
(add-hook 'text-mode-hook 'display-line-numbers-mode)

;; Disable in unnecessary modes
(dolist (hook '(dired-mode-hook vterm-mode-hook shell-mode-hook 
              eshell-mode-hook compilation-mode-hook help-mode-hook 
              info-mode-hook))
  (add-hook hook (lambda () (display-line-numbers-mode -1))))

;;; === NATIVE MAGIT ALTERNATIVES ===

;; Basic Git commands via shell command
(defun my-git-status ()
  "Git status using native command."
  (interactive)
  (let ((default-directory (locate-dominating-file default-directory ".git")))
    (if default-directory
        (compile "git status")
      (message "Not a git repository"))))

(defun my-git-log ()
  "Git log using native command."
  (interactive)
  (let ((default-directory (locate-dominating-file default-directory ".git")))
    (if default-directory
        (compile "git log --name-status")
      (message "Not a git repository"))))

(global-set-key (kbd "C-x g") 'my-git-status)
(global-set-key (kbd "C-x l") 'my-git-log)

;;; === NAVIGATION CONFIGURATIONS FOR SEARCH RESULTS ===

;; Enhanced isearch navigation
(with-eval-after-load 'isearch
  ;; Navigate through isearch matches with up/down arrows
  (define-key isearch-mode-map (kbd "<down>") 'isearch-repeat-forward)
  (define-key isearch-mode-map (kbd "<up>") 'isearch-repeat-backward)
  (define-key isearch-mode-map (kbd "C-n") 'isearch-repeat-forward)
  (define-key isearch-mode-map (kbd "C-p") 'isearch-repeat-backward)
  
  ;; Tab to complete to next match
  (define-key isearch-mode-map (kbd "TAB") 'isearch-yank-word-or-char)
  (define-key isearch-mode-map (kbd "<tab>") 'isearch-yank-word-or-char))

;; Enhanced occur navigation
(with-eval-after-load 'occur
  ;; Navigate through occur matches with up/down arrows
  (define-key occur-mode-map (kbd "<down>") 'occur-next)
  (define-key occur-mode-map (kbd "<up>") 'occur-prev)
  (define-key occur-mode-map (kbd "C-n") 'occur-next)
  (define-key occur-mode-map (kbd "C-p") 'occur-prev)
  
  ;; TAB = next occurrence
  (define-key occur-mode-map (kbd "<tab>") 'occur-next)
  (define-key occur-mode-map (kbd "TAB") 'occur-next)
  
  ;; Shift+TAB = previous occurrence
  (define-key occur-mode-map (kbd "<backtab>") 'occur-prev)
  (define-key occur-mode-map (kbd "S-TAB") 'occur-prev)
  
  ;; Enter to go to occurrence
  (define-key occur-mode-map (kbd "RET") 'occur-mode-goto-occurrence)
  (define-key occur-mode-map (kbd "<return>") 'occur-mode-goto-occurrence))

;; Enhanced grep navigation (for grep buffers)
(defun my-setup-grep-navigation ()
  "Set up navigation keys for grep buffers."
  (when (eq major-mode 'grep-mode)
    (local-set-key (kbd "<down>") 'next-line)
    (local-set-key (kbd "<up>") 'previous-line)
    (local-set-key (kbd "TAB") 'compilation-next-error)
    (local-set-key (kbd "<tab>") 'compilation-next-error)
    (local-set-key (kbd "<backtab>") 'compilation-previous-error)
    (local-set-key (kbd "S-TAB") 'compilation-previous-error)
    (local-set-key (kbd "RET") 'compilation-goto-error)))

(add-hook 'grep-mode-hook 'my-setup-grep-navigation)

;; Enhanced compilation navigation
(defun my-setup-compilation-navigation ()
  "Set up navigation keys for compilation buffers."
  (when (eq major-mode 'compilation-mode)
    (local-set-key (kbd "<down>") 'next-line)
    (local-set-key (kbd "<up>") 'previous-line)
    (local-set-key (kbd "TAB") 'compilation-next-error)
    (local-set-key (kbd "<tab>") 'compilation-next-error)
    (local-set-key (kbd "<backtab>") 'compilation-previous-error)
    (local-set-key (kbd "S-TAB") 'compilation-previous-error)
    (local-set-key (kbd "RET") 'compilation-goto-error)))

(add-hook 'compilation-mode-hook 'my-setup-compilation-navigation)

;;; === ADDITIONAL CONFIGURATIONS (DEFERRED) ===

;; C mode
(setq-default c-basic-offset 4)
(add-hook 'c-mode-hook (lambda () (c-toggle-comment-style -1)))

;; Emacs Lisp
(add-hook 'emacs-lisp-mode-hook
          (lambda ()
            (local-set-key (kbd "C-c C-j") 'eval-print-last-sexp)))

;; Word wrap
(add-hook 'markdown-mode-hook (lambda () (toggle-word-wrap 1)))

;; File modes
(dolist (pair '(("Cask" . emacs-lisp-mode)
                ("\\.html\\'" . nxml-mode)
                ("\\.xsd\\'" . nxml-mode)
                ("\\.ant\\'" . nxml-mode)
                ("\\.ebi\\'" . lisp-mode)))
  (add-to-list 'auto-mode-alist pair))

;;; === FINAL CONFIGURATIONS ===

;; Automatic confirmations
(defun my-always-yes (&rest args) t)
(advice-add 'yes-or-no-p :override 'my-always-yes)
(advice-add 'y-or-n-p :override 'my-always-yes)

(setq confirm-nonexistent-file-or-buffer nil)
(setq confirm-kill-processes nil)
(setq confirm-kill-emacs nil)

;; Maximize - DEFER
(run-with-idle-timer 1 nil 'toggle-frame-maximized)

;; FINAL GC reset and re-enable auto-save
(add-hook 'emacs-startup-hook
  (lambda ()
    (setq gc-cons-threshold 80000000)  ; 80MB after startup
    (setq auto-save-default t)  ; Re-enable auto-save
    (message "Emacs loaded in %.2f seconds" 
             (float-time (time-subtract after-init-time before-init-time)))))

;;; === CUSTOM FILE CONFIGURATION ===
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))

(when (file-exists-p custom-file)
  (load custom-file))

(defun my-save-custom-file ()
  "Save customizations to correct file."
  (unless (file-exists-p custom-file)
    (write-region "" nil custom-file))
  (custom-save-all))

(add-hook 'after-init-hook 'my-save-custom-file)

;; MINIMAL final message
(message "Starting Emacs...")
