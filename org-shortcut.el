;;; org-shortcut.el --- shortcut.com bindings for org-mode  -*- lexical-binding:t -*-
;; Copyright (C) 2024 Endi Sukaj.
;; Author: Endi Sukaj <endisukaj@gmail.com>
;; Package-Requires: ((plz "0.9.1"))
;; Keywords: org-mode
;; Version: 0.0.1
;;; Commentary:
;; This package provides a minor mode that adds shortcut.com bindings to org-mode

;;; Code:

(defcustom shortcut-api-key nil
  "The shortcut API key."
  :type '(string)
  :group 'org-shortcut-mode)


;;;###autoload
(defvar org-shortcut-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c o s g") 'get-story)
    map))

;;;###autoload
(define-minor-mode org-shortcut-mode
  "A simple minor mode that adds shortcut.com bindings for =org-mode=.
With no argument, toggles the mode.
A positive prefix argument enables the mode.
A negative prefix argument disables it."
  :init-value nil
  :lighter " Org Shortcut Mode"
  :keymap org-shortcut-mode-map
  :global nil)

(defun get-story (n)
  "Fetch story from shortcut with ID N and insert it as an =org-mode= entry."
  (interactive "nStory id: ")
  (let* (
         (url (when n (format "https://api.app.shortcut.com/api/v3/stories/%s" n)))
         (capture-buffer (current-buffer))) ; Ensures the current buffer is captured
    (if n
        (progn
          (message "Fetching story with ID: %s from URL: %s with api-key %s" n url shortcut-api-key)
          (plz 'get url
            :headers (list (cons "Shortcut-Token" shortcut-api-key))
            :as #'json-read
            :then (lambda (alist)
                    (message (format "response is %s" alist))
                    (with-current-buffer capture-buffer
                      (let* ((story-name (alist-get 'name alist))
                             (story-description (alist-get 'description alist))
                             (story-link (alist-get 'app_url alist)))
                        (my/org-insert-entry
                         story-name
                         story-link
                         story-description
                         n))
                      )
                    )
            )
          )
      )
    )
  )

(defun my/org-insert-entry (&optional title story_link description story_id)
  (save-excursion
    (goto-char (point-max))  ; Move to end of buffer
    (unless (bolp) (newline))  ; Ensure we're at the start of a line
    
    ;; Insert headline
    (insert (format "** TODO %s\n" (or title "New Entry")))
    
    ;; Insert optional description
    (when description
      (insert description "\n"))

    (when story_link
      (insert story_link "\n"))
    
    ;; Insert properties if provided
    (when story_id
      (insert ":PROPERTIES:\n")
      (insert (format ":STORY_ID: %d\n" story_id))
      (insert ":END:\n"))))


(provide 'org-shortcut-mode)
;;; org-shortcut.el ends here
