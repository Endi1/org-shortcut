;;; org-shortcut.el --- Bindings for shortcut.com in org-mode  -*- lexical-binding:t -*-

;; Copyright (C) 2024

;; Author: Endi Sukaj <endisukaj@gmail.com>
;; URL: https://github.com/endi1/org-shortcut
;; Package-Requires: ((plz "0.9.1") (emacs "28.1"))
;; Keywords: comm
;; Version: 0.0.1
;; SPDX-License-Identifier: GPL-3.0
;;; Commentary:
;; This package provides a minor mode that adds shortcut.com bindings to org-mode

;;; Code:

(require 'json)
(require 'plz)

(defcustom org-shortcut-api-key nil
  "The shortcut API key."
  :type '(string)
  :group 'org-shortcut-mode)


;;;###autoload
(define-minor-mode org-shortcut-mode
  "A simple minor mode that adds shortcut.com bindings for =org-mode=.
With no argument, toggles the mode.
A positive prefix argument enables the mode.
A negative prefix argument disables it."
  :init-value nil
  :lighter " Org Shortcut Mode"
  :global nil)

(defun org-shortcut-get-story (n)
  "Fetch story from shortcut with ID N and insert it as an =org-mode= entry."
  (interactive "nStory id: ")
  (let* (
         (url (when n (format "https://api.app.shortcut.com/api/v3/stories/%s" n)))
         (capture-buffer (current-buffer))) ; Ensures the current buffer is captured
    (if n
        (progn
          (message "Fetching story with ID: %s from URL: %s " n url)
          (plz 'get url
            :headers (list (cons "Shortcut-Token" org-shortcut-api-key))
            :as #'json-read
            :then (lambda (alist)
                    (with-current-buffer capture-buffer
                      (let* ((story-name (alist-get 'name alist))
                             (story-description (alist-get 'description alist))
                             (story-link (alist-get 'app_url alist)))
                        (org-shortcut-org-insert-entry
                         story-name
                         story-link
                         story-description
                         n)))))))))

(defun org-shortcut-org-insert-entry (&optional title story_link description story_id)
  "Insert new org entry from a shortcut story.
Arguments: TITLE STORY_LINK DESCRIPTION STORY_ID."
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


(provide 'org-shortcut)
;;; org-shortcut.el ends here
