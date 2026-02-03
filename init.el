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
  (setq user-full-name "knwoop"
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

  ;; Scrolling
  (setq scroll-margin 3
        scroll-conservatively 101
        scroll-preserve-screen-position t
        auto-window-vscroll nil)

  ;; Parentheses
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

  ;; Editing
  (electric-pair-mode 1)
  (delete-selection-mode 1)
  (save-place-mode 1)

  ;; Recent files
  (recentf-mode 1)
  (setq recentf-max-saved-items 200
        recentf-exclude '("/tmp/" "/ssh:" "/sudo:"))

  ;; History
  (savehist-mode 1)
  (setq history-length 1000
        savehist-save-minibuffer-history t)

  ;; Misc
  (setq custom-file (locate-user-emacs-file "custom.el"))
  (setq uniquify-buffer-name-style 'forward)

  ;; Tabs
  (setq tab-bar-show 1)
  (global-tab-line-mode 1)
  (setq tab-line-new-button-show nil
        tab-line-close-button-show nil)

  ;; Whitespace
  (setq-default show-trailing-whitespace nil)
  (add-hook 'before-save-hook #'delete-trailing-whitespace))

;; ============================================================================
;; Daemon / Server Settings
;; ============================================================================

(leaf *daemon-settings
  :config
  (defun my/setup-frame (frame)
    "Setup FRAME when created from daemon."
    (with-selected-frame frame
      (when (display-graphic-p frame)
        (set-face-attribute 'default nil
                            :family "HackGen Console NF"
                            :height 140)
        (set-fontset-font t 'japanese-jisx0208
                          (font-spec :family "HackGen Console NF")))))

  (if (daemonp)
      (add-hook 'after-make-frame-functions #'my/setup-frame)
    (my/setup-frame (selected-frame))))

;; ============================================================================
;; Clipboard (macOS)
;; ============================================================================

(leaf *clipboard
  :config
  (setq select-enable-clipboard t
        select-enable-primary t)

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
  (doom-modeline-icon . nil)
  (doom-modeline-major-mode-icon . nil)
  (doom-modeline-buffer-file-name-style . 'file-name)
  (doom-modeline-buffer-encoding . nil)
  (doom-modeline-vcs-max-length . 20))

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

(leaf vertico-directory
  :after vertico
  :ensure nil
  :require t
  :bind
  (vertico-map
   ("RET"   . vertico-directory-enter)
   ("DEL"   . vertico-directory-delete-char)
   ("M-DEL" . vertico-directory-delete-word))
  :hook (rfn-eshadow-update-overlay-hook . vertico-directory-tidy))

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
  :require t
  :setq
  (corfu-auto . t)
  (corfu-auto-delay . 0.1)
  (corfu-auto-prefix . 1)
  (corfu-cycle . t)
  (corfu-preselect . 'prompt)
  :config
  (global-corfu-mode 1)
  (defun corfu-enable-in-minibuffer ()
    "Enable Corfu in the minibuffer."
    (when (local-variable-p 'completion-at-point-functions)
      (setq-local corfu-auto nil)
      (corfu-mode 1)))
  (add-hook 'minibuffer-setup-hook #'corfu-enable-in-minibuffer))

(leaf corfu-terminal
  :ensure t
  :after corfu
  :config
  (unless (display-graphic-p)
    (corfu-terminal-mode 1)))

(leaf cape
  :ensure t
  :config
  (add-to-list 'completion-at-point-functions #'cape-dabbrev t)
  (add-to-list 'completion-at-point-functions #'cape-file t))

;; ============================================================================
;; LSP Mode
;; ============================================================================

(leaf lsp-mode
  :ensure t
  :commands (lsp lsp-deferred)
  :hook ((go-mode-hook         . lsp-deferred)
         (go-ts-mode-hook      . lsp-deferred)
         (typescript-ts-mode-hook . lsp-deferred)
         (tsx-ts-mode-hook     . lsp-deferred)
         (js-ts-mode-hook      . lsp-deferred)
         (js-mode-hook         . lsp-deferred)
         (python-mode-hook     . lsp-deferred)
         (python-ts-mode-hook  . lsp-deferred)
         (rust-mode-hook       . lsp-deferred)
         (rust-ts-mode-hook    . lsp-deferred)
         (lsp-mode-hook        . lsp-completion-mode)
         (lsp-mode-hook        . lsp-enable-which-key-integration))
  :init
  (setq read-process-output-max (* 1024 1024))
  :setq
  (lsp-keymap-prefix . "C-c l")
  (lsp-idle-delay . 0.5)
  (lsp-log-io . nil)
  (lsp-keep-workspace-alive . nil)
  (lsp-enable-file-watchers . nil)
  (lsp-enable-folding . nil)
  (lsp-enable-symbol-highlighting . t)
  (lsp-enable-text-document-color . nil)
  (lsp-enable-indentation . nil)
  (lsp-enable-on-type-formatting . nil)
  (lsp-completion-provider . :capf)
  (lsp-completion-show-detail . t)
  (lsp-completion-show-kind . t)
  (lsp-signature-auto-activate . nil)
  (lsp-signature-render-documentation . nil)
  (lsp-headerline-breadcrumb-enable . t)
  (lsp-headerline-breadcrumb-segments . '(project file symbols))
  (lsp-lens-enable . nil)
  (lsp-semantic-tokens-enable . t)
  (lsp-diagnostics-provider . :flymake)
  (lsp-modeline-code-actions-enable . nil)
  (lsp-modeline-diagnostics-enable . nil)
  (lsp-modeline-workspace-status-enable . nil)
  (lsp-eslint-auto-fix-on-save . t)
  (lsp-eslint-run . "onType")
  :config
  (defun my/lsp-mode-setup-completion ()
    (setf (alist-get 'styles (alist-get 'lsp-capf completion-category-defaults))
          '(orderless)))
  (add-hook 'lsp-completion-mode-hook #'my/lsp-mode-setup-completion))

(leaf lsp-ui
  :ensure t
  :hook (lsp-mode-hook . lsp-ui-mode)
  :setq
  (lsp-ui-sideline-enable . t)
  (lsp-ui-sideline-show-diagnostics . t)
  (lsp-ui-sideline-show-hover . nil)
  (lsp-ui-sideline-show-code-actions . t)
  (lsp-ui-sideline-delay . 0.2)
  (lsp-ui-peek-enable . t)
  (lsp-ui-peek-show-directory . t)
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
;; Tree-sitter (Emacs 29+)
;; ============================================================================

(leaf treesit-auto
  :ensure t
  :when (and (>= emacs-major-version 29)
             (fboundp 'treesit-available-p)
             (treesit-available-p))
  :init
  (setq treesit-auto-install 'prompt)
  :config
  (treesit-auto-add-to-auto-mode-alist 'all)
  :global-minor-mode global-treesit-auto-mode)

;; ============================================================================
;; Programming Languages
;; ============================================================================

;; ----------------------------------------------------------------------------
;; Go
;; ----------------------------------------------------------------------------

(leaf go-ts-mode
  :init
  (setq go-ts-mode-indent-offset 4)
  :hook
  (go-ts-mode-hook . (lambda ()
                       (setq tab-width 4
                             indent-tabs-mode t)))
  :config
  (add-hook 'before-save-hook
            (lambda ()
              (when (derived-mode-p 'go-ts-mode)
                (lsp-format-buffer)
                (lsp-organize-imports)))))

(leaf go-mode
  :ensure t
  :unless (and (fboundp 'treesit-available-p) (treesit-available-p))
  :mode "\\.go\\'"
  :hook
  (go-mode-hook . (lambda ()
                    (setq tab-width 4
                          indent-tabs-mode t)))
  :config
  (add-hook 'before-save-hook
            (lambda ()
              (when (derived-mode-p 'go-mode)
                (lsp-format-buffer)
                (lsp-organize-imports)))))

(leaf gotest
  :ensure t
  :commands (go-test-current-test
             go-test-current-file
             go-test-current-project
             go-test-current-benchmark
             go-test-current-coverage
             go-run)
  :init
  (defun my/go-test-keybindings ()
    "Set up keybindings for gotest."
    (local-set-key (kbd "C-c t t") #'go-test-current-test)
    (local-set-key (kbd "C-c t f") #'go-test-current-file)
    (local-set-key (kbd "C-c t p") #'go-test-current-project)
    (local-set-key (kbd "C-c t b") #'go-test-current-benchmark)
    (local-set-key (kbd "C-c t c") #'go-test-current-coverage)
    (local-set-key (kbd "C-c t x") #'go-run))
  :hook
  ((go-mode-hook go-ts-mode-hook) . my/go-test-keybindings)
  :setq
  (go-test-verbose . t)
  :config
  (define-key go-test-mode-map (kbd "q") #'quit-window))

(leaf go-tag
  :ensure t
  :bind
  (go-ts-mode-map
   ("C-c t a" . go-tag-add)
   ("C-c t r" . go-tag-remove)))

;; ----------------------------------------------------------------------------
;; TypeScript / JavaScript
;; ----------------------------------------------------------------------------

(leaf typescript-ts-mode
  :mode (("\\.ts\\'" . typescript-ts-mode)
         ("\\.mts\\'" . typescript-ts-mode)
         ("\\.cts\\'" . typescript-ts-mode))
  :init
  (setq typescript-ts-mode-indent-offset 2))

(leaf tsx-ts-mode
  :mode "\\.tsx\\'"
  :init
  (setq typescript-ts-mode-indent-offset 2))

(leaf js-ts-mode
  :mode (("\\.js\\'" . js-ts-mode)
         ("\\.mjs\\'" . js-ts-mode)
         ("\\.cjs\\'" . js-ts-mode)
         ("\\.jsx\\'" . js-ts-mode))
  :init
  (setq js-indent-level 2))

(leaf add-node-modules-path
  :ensure t
  :hook ((typescript-ts-mode-hook . add-node-modules-path)
         (tsx-ts-mode-hook . add-node-modules-path)
         (js-ts-mode-hook . add-node-modules-path)
         (js-mode-hook . add-node-modules-path)
         (json-ts-mode-hook . add-node-modules-path)
         (json-mode-hook . add-node-modules-path)))

;; ----------------------------------------------------------------------------
;; Rust
;; ----------------------------------------------------------------------------

(leaf rust-mode
  :ensure t
  :mode "\\.rs\\'"
  :setq
  (rust-format-on-save . t)
  :config
  (add-hook 'before-save-hook
            (lambda ()
              (when (and (derived-mode-p 'rust-mode)
                         (bound-and-true-p lsp-mode))
                (lsp-format-buffer)))))

(leaf cargo
  :ensure t
  :hook (rust-mode-hook . cargo-minor-mode))

(with-eval-after-load 'cargo
  (define-key cargo-minor-mode-map (kbd "C-c C-c C-b") #'cargo-process-build)
  (define-key cargo-minor-mode-map (kbd "C-c C-c C-r") #'cargo-process-run)
  (define-key cargo-minor-mode-map (kbd "C-c C-c C-t") #'cargo-process-test)
  (define-key cargo-minor-mode-map (kbd "C-c C-c C-c") #'cargo-process-check)
  (define-key cargo-minor-mode-map (kbd "C-c C-c C-l") #'cargo-process-clippy))

;; ----------------------------------------------------------------------------
;; Python
;; ----------------------------------------------------------------------------

(leaf python
  :mode (("\\.py\\'" . python-ts-mode))
  :init
  (setq python-indent-offset 4)
  :config
  (when (executable-find "ipython")
    (setq python-shell-interpreter "ipython"
          python-shell-interpreter-args "-i --simple-prompt")))

(leaf pyvenv
  :ensure t
  :hook (python-ts-mode-hook . pyvenv-tracking-mode)
  :config
  (defun my/auto-activate-venv ()
    "Automatically activate Python virtual environment."
    (let* ((root (or (locate-dominating-file default-directory ".venv")
                     (locate-dominating-file default-directory "venv")))
           (venv-path (when root
                        (cond
                         ((file-directory-p (expand-file-name ".venv" root))
                          (expand-file-name ".venv" root))
                         ((file-directory-p (expand-file-name "venv" root))
                          (expand-file-name "venv" root))))))
      (when venv-path
        (pyvenv-activate venv-path))))
  (add-hook 'python-ts-mode-hook #'my/auto-activate-venv))

;; ----------------------------------------------------------------------------
;; Other Languages
;; ----------------------------------------------------------------------------

(leaf yaml-mode
  :ensure t
  :mode "\\.ya?ml\\'")

(leaf json-mode
  :ensure t
  :mode "\\.json\\'"
  :init
  (setq js-indent-level 2))

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

(leaf protobuf-mode
  :ensure t
  :mode "\\.proto\\'"
  :hook
  (protobuf-mode-hook . lsp-deferred)
  (protobuf-mode-hook . (lambda ()
                          (setq-local c-basic-offset 2)
                          (setq-local tab-width 2)
                          (setq-local indent-tabs-mode nil)
                          (c-set-offset 'inclass 2))))

(leaf swift-mode
  :ensure t
  :mode "\\.swift\\'"
  :hook (swift-mode-hook . lsp-deferred)
  :setq
  (swift-mode:basic-offset . 4))

(leaf lsp-java
  :ensure t
  :hook (java-mode-hook . lsp-deferred)
  :setq
  (lsp-java-save-actions-organize-imports . t))

(leaf kotlin-mode
  :ensure t
  :mode "\\.kt\\'"
  :hook (kotlin-mode-hook . lsp-deferred)
  :setq
  (kotlin-tab-width . 4))

;; ----------------------------------------------------------------------------
;; Formatting (apheleia)
;; ----------------------------------------------------------------------------

(leaf apheleia
  :ensure t
  :hook (after-init-hook . apheleia-global-mode)
  :config
  ;; Prettier
  (setf (alist-get 'prettier apheleia-formatters)
        '("npx" "prettier" "--stdin-filepath" filepath))
  (setf (alist-get 'typescript-ts-mode apheleia-mode-alist) '(prettier))
  (setf (alist-get 'tsx-ts-mode apheleia-mode-alist) '(prettier))
  (setf (alist-get 'js-ts-mode apheleia-mode-alist) '(prettier))
  (setf (alist-get 'js-mode apheleia-mode-alist) '(prettier))
  (setf (alist-get 'json-ts-mode apheleia-mode-alist) '(prettier))
  (setf (alist-get 'json-mode apheleia-mode-alist) '(prettier))
  ;; Ruff
  (setf (alist-get 'ruff apheleia-formatters)
        '("ruff" "format" "--stdin-filename" filepath "-"))
  (setf (alist-get 'python-ts-mode apheleia-mode-alist) '(ruff))
  (setf (alist-get 'python-mode apheleia-mode-alist) '(ruff)))

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

(defun my/open-pr-for-current-line ()
  "Open the GitHub PR for the current line."
  (interactive)
  (let* ((line-number (line-number-at-pos))
         (file-name (buffer-file-name))
         (commit-hash
          (string-trim
           (shell-command-to-string
            (format "git blame -L %d,%d --porcelain %s | head -n 1 | cut -d ' ' -f 1"
                    line-number line-number file-name)))))
    (if (and commit-hash
             (not (string-empty-p commit-hash))
             (not (string-match-p "^0+$" commit-hash)))
        (shell-command (format "~/.config/scripts/bin/git-open-pr %s" commit-hash))
      (message "No commit found for this line (uncommitted changes?)"))))

(global-set-key (kbd "C-c g p") #'my/open-pr-for-current-line)

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
;; Syntax Check (flymake)
;; ============================================================================

(leaf flymake
  :hook (prog-mode-hook . flymake-mode)
  :bind
  (("M-g f"   . consult-flymake)
   ("C-c e n" . flymake-goto-next-error)
   ("C-c e p" . flymake-goto-prev-error))
  :config
  (set-face-attribute 'flymake-error nil
                      :foreground "red"
                      :weight 'bold
                      :underline '(:style wave :color "red"))
  (set-face-attribute 'flymake-warning nil
                      :foreground "yellow"
                      :weight 'bold
                      :underline '(:style wave :color "yellow"))
  (set-face-attribute 'flymake-note nil
                      :underline '(:style wave :color "green")))

;; ============================================================================
;; Compilation
;; ============================================================================

(leaf compile
  :bind
  (compilation-mode-map
   ("q" . quit-window)))

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

(leaf avy
  :ensure t
  :bind
  (("M-j"   . avy-goto-char-timer)
   ("M-g l" . avy-goto-line)))

(leaf expand-region
  :ensure t
  :commands er/expand-region er/contract-region
  :bind
  (("C--" . er/contract-region))
  :init
  (defun my/set-mark-or-expand-region ()
    "If mark is not active, set mark. Otherwise, expand region."
    (interactive)
    (if (eq last-command this-command)
        (er/expand-region 1)
      (set-mark-command nil)))
  (global-set-key (kbd "C-SPC") 'my/set-mark-or-expand-region)
  (global-set-key (kbd "C-@") 'my/set-mark-or-expand-region)
  :config
  (setq expand-region-contract-fast-key "-"
        expand-region-reset-fast-key "0"))

(leaf wgrep
  :ensure t
  :setq
  (wgrep-auto-save-buffer . t)
  (wgrep-change-readonly-file . t))

(leaf yasnippet
  :ensure t
  :hook (after-init-hook . yas-global-mode)
  :bind
  (yas-minor-mode-map
   ("C-c y e" . yas-expand)
   ("C-c y n" . yas-new-snippet)
   ("C-c y v" . yas-visit-snippet-file)
   ("C-c y i" . yas-insert-snippet))
  :blackout yas-minor-mode)

(leaf yasnippet-snippets
  :ensure t
  :after yasnippet)

;; ============================================================================
;; GitHub Copilot
;; ============================================================================

(leaf editorconfig
  :ensure t
  :hook (after-init-hook . editorconfig-mode)
  :blackout t)

(with-eval-after-load 'corfu
  (unless (fboundp 'corfu--popup-p)
    (defun corfu--popup-p ()
      "Return non-nil if corfu popup is visible."
      (and (boundp 'corfu--frame)
           corfu--frame
           (frame-visible-p corfu--frame)))))

(leaf copilot
  :ensure t
  :hook (prog-mode-hook . copilot-mode)
  :bind
  (copilot-completion-map
   ("<tab>"   . copilot-accept-completion)
   ("TAB"     . copilot-accept-completion)
   ("C-<tab>" . copilot-accept-completion-by-word)
   ("M-<tab>" . copilot-accept-completion-by-line)
   ("M-n"     . copilot-next-completion)
   ("M-p"     . copilot-previous-completion)
   ("C-g"     . copilot-clear-overlay))
  :setq
  (copilot-idle-delay . 0.1)
  (copilot-max-char . 1000000)
  (copilot-indent-offset-warning-disable . t)
  :config
  (add-to-list 'copilot-disable-predicates
               (lambda () (member major-mode '(shell-mode eshell-mode vterm-mode term-mode))))
  (add-to-list 'copilot-disable-predicates
               (lambda () (use-region-p)))
  (add-to-list 'copilot-disable-predicates
               (lambda () (and (fboundp 'corfu--popup-p) (corfu--popup-p))))
  (add-to-list 'copilot-major-mode-alist '("typescript-ts" . "typescript"))
  (add-to-list 'copilot-major-mode-alist '("tsx-ts" . "typescriptreact"))
  (add-to-list 'copilot-major-mode-alist '("js-ts" . "javascript"))
  (add-to-list 'copilot-major-mode-alist '("go-ts" . "go"))
  (add-to-list 'copilot-major-mode-alist '("python-ts" . "python"))
  (add-to-list 'copilot-major-mode-alist '("rust-ts" . "rust"))
  (add-to-list 'copilot-major-mode-alist '("json-ts" . "json"))
  (add-to-list 'copilot-major-mode-alist '("yaml-ts" . "yaml"))
  (add-to-list 'copilot-major-mode-alist '("swift" . "swift"))
  (add-to-list 'copilot-major-mode-alist '("java" . "java"))
  (add-to-list 'copilot-major-mode-alist '("kotlin" . "kotlin")))

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
  (windmove-default-keybindings)
  (global-set-key (kbd "M-o") 'other-window)
  (global-set-key (kbd "C-x k") 'kill-current-buffer)

  (defun my/copy-file-path ()
    "Copy the current buffer's file path relative to project root."
    (interactive)
    (if-let ((path (buffer-file-name)))
        (let* ((root (or (when (project-current)
                           (project-root (project-current)))
                         default-directory))
               (relative (file-relative-name path root)))
          (kill-new relative)
          (message "Copied: %s" relative))
      (message "Buffer is not visiting a file")))

  (defun my/copy-file-name ()
    "Copy the current buffer's file name to clipboard."
    (interactive)
    (if-let ((path (buffer-file-name)))
        (let ((name (file-name-nondirectory path)))
          (kill-new name)
          (message "Copied: %s" name))
      (message "Buffer is not visiting a file")))

  (defun my/copy-github-link ()
    "Copy GitHub link for current file and line to clipboard."
    (interactive)
    (if-let ((file-path (buffer-file-name)))
        (let* ((git-root (string-trim (shell-command-to-string "git rev-parse --show-toplevel")))
               (remote-url (string-trim (shell-command-to-string "git remote get-url origin")))
               (commit (string-trim (shell-command-to-string "git rev-parse HEAD")))
               (relative-path (file-relative-name file-path git-root))
               (line-num (line-number-at-pos))
               ;; リージョン選択時は範囲を含める
               (line-spec (if (use-region-p)
                              (format "L%d-L%d"
                                      (line-number-at-pos (region-beginning))
                                      (line-number-at-pos (region-end)))
                            (format "L%d" line-num)))
               ;; 各種リモートURL形式を https://github.com/user/repo に変換
               (github-url (cond
                            ((string-match "git@github\\.com:\\(.+\\)\\.git" remote-url)
                             (format "https://github.com/%s" (match-string 1 remote-url)))
                            ((string-match "ssh://git@github\\.com/\\(.+\\)\\.git" remote-url)
                             (format "https://github.com/%s" (match-string 1 remote-url)))
                            ((string-match "https://github\\.com/\\(.+\\)\\.git" remote-url)
                             (format "https://github.com/%s" (match-string 1 remote-url)))
                            ((string-match "https://github\\.com/\\(.+\\)" remote-url)
                             (format "https://github.com/%s" (match-string 1 remote-url)))
                            (t remote-url)))
               (full-url (format "%s/blob/%s/%s#%s" github-url commit relative-path line-spec)))
          (kill-new full-url)
          (message "Copied: %s" full-url))
      (message "Buffer is not visiting a file")))

  (global-set-key (kbd "C-c f p") 'my/copy-file-path)
  (global-set-key (kbd "C-c f n") 'my/copy-file-name)
  (global-set-key (kbd "C-c f g") 'my/copy-github-link)
  (global-set-key (kbd "C-c /") 'comment-or-uncomment-region)
  (global-set-key (kbd "C-c c t") 'copilot-mode)
  (global-set-key (kbd "C-c c c") 'copilot-complete)
  (global-set-key (kbd "C-c c d") 'copilot-diagnose))

;; ============================================================================
;; Quick Note
;; ============================================================================

;; Quick Note
(defvar my/note-directory "~/Library/Mobile Documents/com~apple~CloudDocs/Obsidian Vault/")

(defun my/note-categories ()
  "Get list of category directories."
  (when (file-directory-p my/note-directory)
    (seq-filter
     (lambda (f)
       (and (file-directory-p (expand-file-name f my/note-directory))
            (not (string-prefix-p "." f))))
     (directory-files my/note-directory nil "^[^.]"))))

(defun my/note-new ()
  "Create new note with timestamp in category."
  (interactive)
  (unless (file-exists-p my/note-directory)
    (make-directory my/note-directory t))
  (let* ((categories (my/note-categories))
         (category (completing-read "Category (or new): " categories nil nil))
         (category (if (string-empty-p category) "inbox" category))
         (title (read-string "Title: "))
         (title (if (string-empty-p title) "untitled" title))
         (slug (string-trim (replace-regexp-in-string "[^a-zA-Z0-9]+" "-" (downcase title)) "-"))
         (dir (expand-file-name category my/note-directory))
         (filename (format "%s/%s-%s.md"
                           dir
                           (format-time-string "%Y%m%d")
                           slug)))
    (make-directory dir t)
    (find-file filename)
    (insert (format "# %s\n\nCreated: %s\n\n" title (format-time-string "%Y-%m-%d %H:%M")))))

(defun my/note-find ()
  "Find note or directory with consult."
  (interactive)
  (consult-find my/note-directory))

(defun my/note-search ()
  "Search note content."
  (interactive)
  (consult-ripgrep my/note-directory))

(defun my/note-search-category ()
  "Search notes in specific category."
  (interactive)
  (let* ((categories (my/note-categories))
         (category (completing-read "Category: " categories nil t))
         (dir (expand-file-name category my/note-directory)))
    (consult-ripgrep dir)))

(global-set-key (kbd "C-c n n") #'my/note-new)
(global-set-key (kbd "C-c n f") #'my/note-find)
(global-set-key (kbd "C-c n s") #'my/note-search)
(global-set-key (kbd "C-c n c") #'my/note-search-category)

;; ============================================================================
;; Local Configuration
;; ============================================================================

(let ((local-config (locate-user-emacs-file "local.el")))
  (when (file-exists-p local-config)
    (load local-config)))

(provide 'init)
;;; init.el ends here
