;;; ide-mode.el - A very basic implementation of ide on emacs.

(require 'delsel)
(require 'eshell)
(require 'subr-x)

(defun find-from-dict(list option &optional elem)
  "Allows to use list of list as a dictionary."
  (if (equal elem nil)
      (nth 1 (nth (cl-position option list :test (lambda (a b) (member a b))) list))
    (nth elem (nth (cl-position option list :test (lambda (a b) (member a b))) list))
    )
  )
(defun insert-into-string(string identifier repl)
  "replace an identifier in a string"
  (string-join(split-string string identifier) repl)
  )
;; (require 'flycheck)
;; (require 'company)
;; (defvar ide-mode-hook '(yas-minor-mode company-mode flycheck-mode))
(defvar ide-mode-hook '())
(defun ide/ide-mode-init()
  )
(defvar ide-right-perc 30)
(defvar ide-shell-perc 20)
(defvar ide-input-perc 50)
(setq ide-mode-command-map (make-sparse-keymap))
(defun ide/ide-mode-open()
  "Something"
  (interactive)
  (defvar ide-mode nil)
  (defvar ide/extension nil)
  (defvar ide/file-name nil)
  (defvar ide/command nil)
  (defvar ide/temp nil)
  (defvar ide-code-buffer nil)
  (defvar ide-output-buffer nil)
  (defvar ide-input-buffer nil)
  (defvar ide-shell-buffer nil)
  (setq ide-code-buffer (get-buffer-window))
  (split-window-below (/ (* (- 100 ide-shell-perc) (window-height)) 100))
  (other-window 1)
  (eshell)
  (ide-slave-mode t)
  (set-window-dedicated-p (get-buffer-window) t)
  (setq ide-shell-buffer (get-buffer-window))
  (other-window 1)
  (split-window-right (/ (* (- 100 ide-right-perc) (window-width)) 100))
  (other-window 1)
  (switch-to-buffer "*Output*")
  (ide-slave-mode t)
  (set-window-dedicated-p (get-buffer-window) t)
  (setq ide-output-buffer (get-buffer-window))
  (split-window-vertically (/ (* (- 100 ide-input-perc) (window-height)) 100))
  (other-window 1)
  (switch-to-buffer "*Input*")
  (ide-slave-mode t)
  (set-window-dedicated-p (get-buffer-window) t)
  (setq ide-input-buffer (get-buffer-window))
  (other-window 2)
  (setq ide-mode t)
  (run-hooks 'ide-mode-hook)
  (setq split-window-preferred-function nil)
  )


(defun ide/ide-mode-compile()
  "Something"
  (interactive)
  (setq ide/extension (nth 1 (split-string (buffer-name) "\\.")))
  (setq ide/file-name (nth 0 (split-string (buffer-name) "\\.")))
  
  (setq ide/command (find-from-dict ide/ide-mode-compile-recipes ide/extension))
  (setq ide/command (string-join (split-string (string-join (split-string ide/command "%bf") (buffer-name)) "%bo") ide/file-name))
  (compile ide/command)
  )
(defun ide/ide-mode-execute()
  (interactive)
  (setq ide/command (find-from-dict ide/ide-mode-execute-recipes ide/extension))
  (setq ide/command (string-join (split-string (string-join (split-string ide/command "%bf") (buffer-name)) "%bo") ide/file-name))
  
  (defvar ide/file-name (nth 0 (split-string (buffer-name) "\\.")))
  (with-current-buffer (get-buffer "*Output*")
    (erase-buffer)
    )
  (with-current-buffer (get-buffer "*Input*")
    (shell-command-on-region (point-min) (point-max) ide/command)
    )
  (with-current-buffer (get-buffer "*Shell Command Output*")
    (kill-region (point-min) (point-max))
    (kill-buffer "*Shell Command Output*")
    )
  (with-current-buffer (get-buffer "*Output*")
    (yank)
    )
  )  

(defun ide/ide-mode-close() 
  "Something"
  (interactive)
  (kill-buffer "*eshell*")
  (kill-buffer "*Output*")
  ;(kill-buffer "*Input*")
  (makunbound 'ide-code-buffer)
  (makunbound 'ide-shell-buffer)
  (makunbound 'ide-output-buffer)
  (makunbound 'ide-input-buffer)
  (makunbound 'ide/extension)
  (makunbound 'ide/extension)
  (defvar ide/file-name nil)
  (defvar ide/command nil)
  (defvar ide/temp nil)
  (defvar ide-code-buffer nil)
  (defvar ide-output-buffer nil)
  (defvar ide-input-buffer nil)
  (defvar ide-shell-buffer nil)

  (setq ide-mode nil)
  (run-hooks 'ide-mode-hooks)
  (setq split-window-preferred-function 'split-window-sensibly)
  )
(defun ide/goto-shell()
  "Something"
  (interactive)
  (select-window ide-shell-buffer)
  )

(defun ide/goto-output()
  "Something"
  (interactive)
  (select-window ide-output-buffer)
  )
(defun ide/goto-input()
  "Something"
  (interactive)
  (select-window ide-input-buffer)
  )
(defun ide/goto-code()
  "Something"
  (interactive)
  (select-window ide-code-buffer)
  )
(defun ide/send-to-output(string)
  "Call `kill-append' with STRING, if it is indeed a string."
  (if (stringp string)
      (kill-append string nil))
  (with-current-buffer (get-buffer "*Output*")
    (mark-whole-buffer)
    (delete-active-region)
    (yank)
    )
  )
(defun ide/syntax-check()
  "After Save Check"
  (interactive)
  (let (( output (shell-command-to-string (insert-into-string (find-from-dict ide/geterrors (file-name-extension (buffer-name))) "%bf" (buffer-name))))
	(line (split-string (shell-command-to-string (concat "echo -e \"" output "\" | awk '{print $2}'")) "\n")) 
	(char (shell-command-to-string (concat "echo -e \"" output "\" | awk '{print $3}'"))))
    (mapcar 'set-fringemark-at-point line))
  )
(add-to-list 'eshell-virtual-targets  '("/dev/ide" (lambda(mode) (with-current-buffer (get-buffer "*Output*") (mark-whole-buffer) (delete-active-region)) (kill-new " ") 'ide/send-to-output) t))

(define-minor-mode ide-mode
  ""
  :lighter " ID"
  :keymap (make-sparse-keymap)
  (if ide-mode
      (ide/ide-mode-open)
    (ide/ide-mode-close)))

(define-minor-mode ide-slave-mode
  ""
  :lighter " ID"
  :keymap (make-sparse-keymap))
(provide 'ide-mode)
;;; ide-mode.el ends here
