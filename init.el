;;; init.el --- My Minimal Emacs Config -*- lexical-binding: t -*-

;;; Commentary:
;; Centaur Emacs inspired minimal configuration.
;; Uses leaf.el for package management.
;; Designed for emacs --daemon usage.

;;; Code:

;; ============================================================================
;; Leaf.el Bootstrap
;; ============================================================================

(eval-and-compile
  (customize-set-variable
   'package-archives '(("melpa"  . "https://melpa.org/packages/")
                       ("gnu"    . "https://elpa.gnu.org/packages/")
                       ("nongnu" . "https://elpa.nongnu.org/nongnu/")))
  (package-initialize)

  (unless (package-installed-p 'leaf)
    (package-refresh-contents)
    (package-install 'leaf))

  (leaf leaf-keywords
    :ensure t
    :init
    (leaf blackout :ensure t)
    :config
    (leaf-keywords-init)))

;; ============================================================================
;; Basic Settings
;; ============================================================================

(leaf *basic-settings
  :config
  ;; User info
  (setq user-full-name "Kenta"
        user-mail-address "")

  ;; UTF-8
  (prefer-coding-system 'utf-8)
  (set-default-coding-systems 'utf-8)
  (set-terminal-coding-system 'utf-8)
  (set-keyboard-coding-system 'utf-8)

  ;; Basic behaviors
  (setq inhibit-startup-message t
        inhibit-startup-echo-area-message t
        initial-scratch-message nil
        ring-bell-function 'ignore
        use-short-answers t
        confirm-kill-emacs 'y-or-n-p)

  ;; Better scrolling
  (setq scroll-margin 3
        scroll-conservatively 101
        scroll-preserve-screen-position t
        auto-window-vscroll nil)

  ;; Line numbers (disabled for minimal UI)
  ;; (setq-default display-line-numbers-width 4)
  ;; (add-hook 'prog-mode-hook #'display-line-numbers-mode)

  ;; Highlight current line (disabled for minimal UI)
  ;; (global-hl-line-mode 1)

  ;; Show matching parentheses
  (show-paren-mode 1)
  (setq show-paren-delay 0)

  ;; Auto revert
  (global-auto-revert-mode 1)
  (setq auto-revert-interval 1
        auto-revert-check-vc-info t
        global-auto-revert-non-file-buffers t)

  ;; Backup & autosave
  (setq make-backup-files nil
        auto-save-default nil
        create-lockfiles nil)

  ;; Indentation
  (setq-default indent-tabs-mode nil
                tab-width 4)

  ;; Disable electric indent (causes issues in Go)
  (electric-indent-mode -1)

  ;; Electric pair
  (electric-pair-mode 1)

  ;; Delete selection
  (delete-selection-mode 1)

  ;; Save cursor position
  (save-place-mode 1)

  ;; Recent files
  (recentf-mode 1)
  (setq recentf-max-saved-items 200
        recentf-exclude '("/tmp/" "/ssh:" "/sudo:"))

  ;; Save history
  (savehist-mode 1)
  (setq history-length 1000
        savehist-save-minibuffer-history t)

  ;; Disable customize saving to init.el
  (setq custom-file (locate-user-emacs-file "custom.el"))

  ;; Unique buffer names
  (setq uniquify-buffer-name-style 'forward)

  ;; Tabs (Emacs 27+)
  (setq tab-bar-show 1)

  ;; Tab-line (buffer tabs like screenshot)
  (global-tab-line-mode 1)
  (setq tab-line-new-button-show nil      ; 新規タブボタン非表示
        tab-line-close-button-show nil)   ; 閉じるボタン非表示

  ;; Whitespace
  (setq-default show-trailing-whitespace nil)
  (add-hook 'before-save-hook #'delete-trailing-whitespace))

;; ============================================================================
;; Daemon / Server Settings
;; ============================================================================

(leaf *daemon-settings
  :config
  ;; Frame setup for daemon mode
  (defun my/setup-frame (frame)
    "Setup FRAME when created from daemon."
    (with-selected-frame frame
      (when (display-graphic-p frame)
        ;; Font settings (adjust to your preference)
        (set-face-attribute 'default nil
                            :family "HackGen Console NF"
                            :height 140)
        ;; Japanese font
        (set-fontset-font t 'japanese-jisx0208
                          (font-spec :family "HackGen Console NF")))))

  (if (daemonp)
      (add-hook 'after-make-frame-functions #'my/setup-frame)
    (my/setup-frame (selected-frame))))

;; ============================================================================
;; Clipboard (macOS + tmux + terminal)
;; ============================================================================

(leaf *clipboard
  :config
  ;; GUI: use default clipboard integration
  (setq select-enable-clipboard t
        select-enable-primary t)

  ;; macOS Terminal/tmux: use pbcopy/pbpaste directly
  (when (eq system-type 'darwin)
    (defun my/copy-to-osx (text &optional push)
      "Copy TEXT to macOS clipboard via pbcopy."
      (let ((process-connection-type nil))
        (let ((proc (start-process "pbcopy" nil "pbcopy")))
          (process-send-string proc text)
          (process-send-eof proc))))

    (defun my/paste-from-osx ()
      "Paste from macOS clipboard via pbpaste."
      (shell-command-to-string "pbpaste"))

    ;; Only use pbcopy/pbpaste in terminal (not GUI)
    (unless (display-graphic-p)
      (setq interprogram-cut-function #'my/copy-to-osx
            interprogram-paste-function #'my/paste-from-osx))))

;; ============================================================================
;; UI / Theme
;; ============================================================================

(leaf doom-themes
  :ensure t
  :config
  (load-theme 'doom-molokai t)
  (doom-themes-visual-bell-config)
  (doom-themes-org-config))

(leaf doom-modeline
  :ensure t
  :hook (after-init-hook . doom-modeline-mode)
  :setq
  (doom-modeline-height . 25)
  (doom-modeline-bar-width . 3)
  (doom-modeline-icon . nil)              ; アイコン無効
  (doom-modeline-major-mode-icon . nil)   ; メジャーモードアイコン無効
  (doom-modeline-buffer-file-name-style . 'file-name)  ; ファイル名のみ
  (doom-modeline-buffer-encoding . nil)   ; エンコーディング非表示
  (doom-modeline-vcs-max-length . 20))

;; Icons (disabled for minimal UI)
;; Uncomment if you want icons:
;; (leaf nerd-icons :ensure t)
;; (leaf nerd-icons-dired :ensure t :hook (dired-mode-hook . nerd-icons-dired-mode))

;; ============================================================================
;; Completion (Vertico + Corfu)
;; ============================================================================

(leaf vertico
  :ensure t
  :hook (after-init-hook . vertico-mode)
  :setq
  (vertico-count . 15)
  (vertico-cycle . t)
  (vertico-resize . nil))

(leaf orderless
  :ensure t
  :setq
  (completion-styles . '(orderless basic))
  (completion-category-defaults . nil)
  (completion-category-overrides . '((file (styles partial-completion)))))

(leaf marginalia
  :ensure t
  :hook (after-init-hook . marginalia-mode))

(leaf consult
  :ensure t
  :bind
  (("C-s"     . consult-line)
   ("C-x b"   . consult-buffer)
   ("C-x C-r" . consult-recent-file)
   ("M-g g"   . consult-goto-line)
   ("M-g M-g" . consult-goto-line)
   ("M-s r"   . consult-ripgrep)
   ("M-s f"   . consult-find)
   ("M-y"     . consult-yank-pop))
  :setq
  (consult-async-min-input . 2))

(leaf embark
  :ensure t
  :bind
  (("C-."   . embark-act)
   ("C-;"   . embark-dwim)
   ("C-h B" . embark-bindings)))

(leaf embark-consult
  :ensure t
  :after embark consult
  :require t
  :hook (embark-collect-mode-hook . consult-preview-at-point-mode))

(leaf corfu
  :ensure t
  :hook ((after-init-hook . global-corfu-mode)
         (after-init-hook . corfu-popupinfo-mode))
  :setq
  (corfu-auto . t)
  (corfu-auto-delay . 0.2)
  (corfu-auto-prefix . 2)
  (corfu-cycle . t)
  (corfu-preselect . 'prompt)
  (corfu-popupinfo-delay . '(0.5 . 0.2)))

(leaf cape
  :ensure t
  :config
  (add-to-list 'completion-at-point-functions #'cape-dabbrev)
  (add-to-list 'completion-at-point-functions #'cape-file)
  (add-to-list 'completion-at-point-functions #'cape-keyword))

;; ============================================================================
;; LSP Mode
;; ============================================================================

(leaf lsp-mode
  :ensure t
  :commands (lsp lsp-deferred)
  :hook ((go-mode-hook         . lsp-deferred)
         (go-ts-mode-hook      . lsp-deferred)
         (typescript-mode-hook . lsp-deferred)
         (typescript-ts-mode-hook . lsp-deferred)
         (js-mode-hook         . lsp-deferred)
         (python-mode-hook     . lsp-deferred)
         (python-ts-mode-hook  . lsp-deferred)
         (rust-mode-hook       . lsp-deferred)
         (rust-ts-mode-hook    . lsp-deferred)
         (lsp-mode-hook        . lsp-enable-which-key-integration))
  :init
  ;; @see https://emacs-lsp.github.io/lsp-mode/page/performance
  (setq read-process-output-max (* 1024 1024))  ; 1MB
  :setq
  (lsp-keymap-prefix . "C-c l")
  ;; Performance (Centaur Emacs style)
  (lsp-idle-delay . 0.5)
  (lsp-log-io . nil)
  (lsp-keep-workspace-alive . nil)
  (lsp-enable-file-watchers . nil)           ; Disable for large projects/monorepo
  (lsp-enable-folding . nil)
  (lsp-enable-symbol-highlighting . nil)
  (lsp-enable-text-document-color . nil)
  (lsp-enable-indentation . nil)             ; Use emacs indentation
  (lsp-enable-on-type-formatting . nil)
  ;; Completion
  (lsp-completion-provider . :none)          ; Use corfu
  (lsp-completion-show-detail . t)
  (lsp-completion-show-kind . t)
  ;; Signature
  (lsp-signature-auto-activate . nil)
  (lsp-signature-render-documentation . nil)
  ;; Headerline
  (lsp-headerline-breadcrumb-enable . t)
  (lsp-headerline-breadcrumb-segments . '(project file symbols))
  ;; Lens
  (lsp-lens-enable . nil)                    ; Can be slow in large files
  ;; Semantic tokens
  (lsp-semantic-tokens-enable . t)
  ;; Modeline
  (lsp-modeline-code-actions-enable . nil)
  (lsp-modeline-diagnostics-enable . nil)
  (lsp-modeline-workspace-status-enable . nil)
  :config
  ;; Register completion function for orderless
  (defun my/lsp-mode-setup-completion ()
    (setf (alist-get 'styles (alist-get 'lsp-capf completion-category-defaults))
          '(orderless)))
  (add-hook 'lsp-completion-mode-hook #'my/lsp-mode-setup-completion))

(leaf lsp-ui
  :ensure t
  :hook (lsp-mode-hook . lsp-ui-mode)
  :setq
  ;; Sideline
  (lsp-ui-sideline-enable . t)
  (lsp-ui-sideline-show-diagnostics . t)
  (lsp-ui-sideline-show-hover . nil)
  (lsp-ui-sideline-show-code-actions . t)
  (lsp-ui-sideline-delay . 0.2)
  ;; Peek
  (lsp-ui-peek-enable . t)
  (lsp-ui-peek-show-directory . t)
  ;; Doc - disable by default (can be slow)
  (lsp-ui-doc-enable . nil)
  (lsp-ui-doc-delay . 0.5)
  (lsp-ui-doc-position . 'at-point)
  (lsp-ui-doc-show-with-cursor . nil)
  (lsp-ui-doc-show-with-mouse . nil)
  :bind
  (lsp-ui-mode-map
   ("M-." . lsp-ui-peek-find-definitions)
   ("M-?" . lsp-ui-peek-find-references)
   ("C-c l d" . lsp-ui-doc-glance)))

;; ============================================================================
;; Programming Languages
;; ============================================================================

;; go-ts-mode (Emacs 29+ built-in, tree-sitter based)
(leaf go-ts-mode
  :hook
  (go-ts-mode-hook . (lambda ()
                       (setq tab-width 4
                             indent-tabs-mode t)
                       ;; Disable electric-indent (causes double indent)
                       (electric-indent-local-mode -1)))
  :config
  ;; Format and organize imports on save
  (add-hook 'before-save-hook
            (lambda ()
              (when (derived-mode-p 'go-ts-mode)
                (lsp-format-buffer)
                (lsp-organize-imports)))))

;; go-mode (fallback for older Emacs or when tree-sitter unavailable)
(leaf go-mode
  :ensure t
  :unless (and (fboundp 'treesit-available-p) (treesit-available-p))
  :mode "\\.go\\'"
  :hook
  (go-mode-hook . (lambda ()
                    (setq tab-width 4
                          indent-tabs-mode t)
                    (electric-indent-local-mode -1)))
  :config
  (add-hook 'before-save-hook
            (lambda ()
              (when (derived-mode-p 'go-mode)
                (lsp-format-buffer)
                (lsp-organize-imports)))))

(leaf yaml-mode
  :ensure t
  :mode "\\.ya?ml\\'")

(leaf json-mode
  :ensure t
  :mode "\\.json\\'")

(leaf markdown-mode
  :ensure t
  :mode (("README\\.md\\'" . gfm-mode)
         ("\\.md\\'"       . markdown-mode)
         ("\\.markdown\\'" . markdown-mode))
  :setq
  (markdown-command . "pandoc"))

(leaf dockerfile-mode
  :ensure t
  :mode "Dockerfile\\'")

(leaf terraform-mode
  :ensure t
  :mode "\\.tf\\'")

;; Tree-sitter (Emacs 29+)
(leaf treesit-auto
  :ensure t
  :when (and (>= emacs-major-version 29)
             (fboundp 'treesit-available-p)
             (treesit-available-p))
  :init
  (setq treesit-auto-install 'prompt)
  :global-minor-mode global-treesit-auto-mode)

;; ============================================================================
;; Version Control
;; ============================================================================

(leaf magit
  :ensure t
  :bind
  (("C-x g"   . magit-status)
   ("C-x M-g" . magit-dispatch))
  :setq
  (magit-display-buffer-function . #'magit-display-buffer-same-window-except-diff-v1))

(leaf git-gutter
  :ensure t
  :hook (prog-mode-hook . git-gutter-mode)
  :setq
  (git-gutter:update-interval . 0.5)
  :blackout t)

;; ============================================================================
;; Project Management
;; ============================================================================

(leaf project
  :bind
  (("C-x p f" . project-find-file)
   ("C-x p p" . project-switch-project)
   ("C-x p g" . project-find-regexp)
   ("C-x p d" . project-dired)))

;; ============================================================================
;; Syntax Check
;; ============================================================================

(leaf flycheck
  :ensure t
  :hook (prog-mode-hook . flycheck-mode)
  :setq
  (flycheck-emacs-lisp-load-path . 'inherit)
  (flycheck-display-errors-delay . 0.3)
  :blackout t)

;; ============================================================================
;; Editing Enhancement
;; ============================================================================

(leaf which-key
  :ensure t
  :hook (after-init-hook . which-key-mode)
  :setq
  (which-key-idle-delay . 0.5)
  (which-key-idle-secondary-delay . 0.1)
  :blackout t)

(leaf rainbow-delimiters
  :ensure t
  :hook (prog-mode-hook . rainbow-delimiters-mode))

(leaf undo-fu
  :ensure t
  :bind
  (("C-/" . undo-fu-only-undo)
   ("C-?" . undo-fu-only-redo)))

(leaf mwim
  :ensure t
  :bind
  (("C-a" . mwim-beginning-of-code-or-line)
   ("C-e" . mwim-end-of-code-or-line)))

(leaf expand-region
  :ensure t
  :commands er/expand-region er/contract-region
  :bind
  (("C--" . er/contract-region))
  :init
  ;; Smart C-SPC: first press sets mark, subsequent presses expand region
  (defun my/set-mark-or-expand-region ()
    "If mark is not active, set mark. Otherwise, expand region."
    (interactive)
    (if (eq last-command this-command)
        (er/expand-region 1)
      (set-mark-command nil)))
  (global-set-key (kbd "C-SPC") 'my/set-mark-or-expand-region)
  (global-set-key (kbd "C-@") 'my/set-mark-or-expand-region)  ; Terminal
  :config
  (setq expand-region-contract-fast-key "-"
        expand-region-reset-fast-key "0"))

(leaf wgrep
  :ensure t
  :setq
  (wgrep-auto-save-buffer . t)
  (wgrep-change-readonly-file . t))

;; ============================================================================
;; Terminal / Shell
;; ============================================================================

(leaf vterm
  :ensure t
  :commands vterm
  :setq
  (vterm-max-scrollback . 10000)
  (vterm-buffer-name-string . "vterm: %s"))

;; ============================================================================
;; Key Bindings
;; ============================================================================

(leaf *keybindings
  :config
  ;; Window navigation
  (windmove-default-keybindings)

  ;; Easier window switching
  (global-set-key (kbd "M-o") 'other-window)

  ;; Buffer operations
  (global-set-key (kbd "C-x k") 'kill-this-buffer)

  ;; Comment toggle
  (global-set-key (kbd "C-c /") 'comment-or-uncomment-region))

;; ============================================================================
;; Local Configuration (if exists)
;; ============================================================================

(let ((local-config (locate-user-emacs-file "local.el")))
  (when (file-exists-p local-config)
    (load local-config)))

(provide 'init)
;;; init.el ends here
