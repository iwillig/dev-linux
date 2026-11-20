;;; 50-guile.el --- Fedora Guile REPL default -*- lexical-binding: t; -*-

;; Fedora installs Guile 3 as guile3.0 rather than guile.
(with-eval-after-load 'cmuscheme
  (setq scheme-program-name "guile3.0"))

;;; 50-guile.el ends here
