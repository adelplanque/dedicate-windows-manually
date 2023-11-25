;;; dedicate-windows-manually.el --- Manually (un)dedicate windows

;; Copyright (C) 2013 Aaron Miller
;; <me@aaron-miller.me>

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2 of
;; the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be
;; useful, but WITHOUT ANY WARRANTY; without even the implied
;; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
;; PURPOSE.  See the GNU General Public License for more details.

;; You should have received a copy of the GNU General Public
;; License along with this program; if not, write to the Free
;; Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
;; MA 02111-1307 USA

;;; Commentary:

;; Introduction
;; ============

;; The functions here defined allow you to manually dedicate and
;; undedicate windows, that is, prevent `set-window-buffer' from
;; considering them when selecting a window in which to display a
;; given buffer.

;; Windows dedicated in this fashion will also be protected from
;; splitting by setting `window-size-fixed'.

;; Installation
;; ============

;; Place this file in your load path; then, place the following
;; command somewhere in your initialization file:

;; (require 'dedicate-windows-manually)

;; Now you can use:
;; * M-x dedicate-windows-dedicate to dedicate the selected window to
;;   its currently displayed buffer,
;; * M-x dedicate-windows-undedicate to release a dedication so
;;   applied,
;; * M-x dedicate-windows-toggle to switch between the states.
;; * M-x dedicate-windows-undedicate-all to release all dedication
;;   applied,

;; These functions will operate only on manually dedicated or
;; undedicated windows; that is,`dedicate-windows-dedicate' will not
;; dedicate a window which is already dedicated
;; (i.e. "(window-dedicated-p window) -> t", and
;; `dedicate-windows-undedicate' will not undedicate a window which
;; was not dedicated by way of `dedicate-windows-dedicate'.

;; If you find yourself frequently doing M-x dedicate-windows-toggle,
;; you might wish to place something like this in your init file:

;; (global-set-key (kbd "C-x 4 C-d") 'dedicate-windows-toggle)

;; Bugs:
;; * Changing the lighter string while you have windows dedicated is
;;   probably not a good idea.
;; * I should certainly find a better way to change the mode line.

;;; Code:

(require 'cl-macs)

(defgroup dedicate-windows nil
  "Options for `dedicate-windows-manually'."
  :group 'convenience
  :prefix "decidate-windows-")

(defcustom dedicate-windows-lighter-string " [D]"
  "String prepended to the mode line.
This string, propertized with `dedicate-windows-lighter-face', is
prepended to the mode line when the window is manually dedicated."
  :type 'string
  :group 'dedicated-window)

(defvar dedicate-windows-by-hand nil
  "List of windows known to have been manually dedicated.
Windows not in this list will not be undedicated by
`undedicate-window'.")

(defun dedicate-window-was-by-hand-p (window)
  (let ((result nil))
    (cl-loop for w in dedicate-windows-by-hand
             collect (if (eq w window) (setq result t)))
    result))

(defun dedicate-windows-dedicate (&optional window flag)
  "Dedicate a window to its buffer, and prevent it from being split.

Optional argument WINDOW, if non-nil, should specify a window.
Otherwise, or when called interactively, the currently selected
window is used.

Optional argument FLAG, if non-nil, will be passed verbatim to
`set-window-dedicated-p'."
  (interactive nil)
  (if (eq nil window) (setq window (selected-window)))
  (if (eq nil flag) (setq flag t))
  (if (window-dedicated-p window)
      (message "Window is already dedicated.")
    (progn
      (add-to-list 'dedicate-windows-by-hand window)
      (setq mode-line-format
            (append `(,dedicate-windows-lighter-string) mode-line-format))
      (setq window-size-fixed t)
      (set-window-dedicated-p window flag))))

(defun dedicate-windows-undedicate (&optional window)
  "Un-dedicate a window from its buffer.

Optional argument WINDOW, if non-nil, should specify a window listed in
`dedicated-windows-by-hand'.  Otherwise, or when called interactively,
the currently selected window is used.

If WINDOW is not in `dedicated-windows-by-hand', a complaint will
be issued and nothing will be done."
  (interactive nil)
  (if (eq nil window) (setq window (selected-window)))
  (if (not (window-dedicated-p window))
      (message "Window is not dedicated.")
    (if (not (dedicate-window-was-by-hand-p window))
        (message "Window is not dedicated by hand.")
      (progn
        (setq dedicate-windows-by-hand
              (remove window dedicate-windows-by-hand))
        (setq mode-line-format
              (remove dedicate-windows-lighter-string mode-line-format))
        (setq window-size-fixed nil)
        (set-window-dedicated-p window nil)))))

(defun dedicate-windows-undedicate-all ()
  "Un-dedicate all manually dedicated windows."
  (interactive)
  (while dedicate-windows-by-hand
    (dedicate-windows-undedicate (car dedicate-windows-by-hand))))

(defun dedicate-windows-toggle (&optional window)
  "Toggle a window's manual buffer dedication state.

Optional argument WINDOW, if non-nil, should specify a window.  Otherwise,
or when called interactively, the value of `selected-window' is used."
  (interactive nil)
  (if (eq nil window) (setq window (selected-window)))
  (if (window-dedicated-p window)
      (dedicate-windows-undedicate window)
    (dedicate-windows-dedicate window)))

(provide 'dedicate-windows-manually)

;;; dedicate-windows-manually.el ends here
