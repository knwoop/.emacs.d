;;; early-init.el --- Early Init File -*- lexical-binding: t -*-

;;; Commentary:
;; Emacs 27+ loads this file before init.el.
;; Used for startup optimization.

;;; Code:

;; Increase GC threshold during startup
(setq gc-cons-threshold most-positive-fixnum)
(setq gc-cons-percentage 0.6)

;; Restore after startup
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 16 1024 1024)  ; 16MB
                  gc-cons-percentage 0.1)))

;; Prevent package.el from loading packages before init.el
(setq package-enable-at-startup nil)

;; Disable UI elements early (before frame creation)
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)

;; Disable mode-line flicker
(setq-default mode-line-format nil)

;; Faster startup by not resizing frame
(setq frame-inhibit-implied-resize t)

;; Disable bidirectional text rendering for performance
(setq-default bidi-display-reordering nil)
(setq-default bidi-paragraph-direction 'left-to-right)

;; Reduce rendering/line scan work
(setq auto-window-vscroll nil)

;; Native compilation settings (Emacs 28+)
(when (featurep 'native-compile)
  (setq native-comp-async-report-warnings-errors nil)
  (setq native-comp-deferred-compilation t))

(provide 'early-init)
;;; early-init.el ends here
