(defcustom journal-directory "~/journal" 
  "Directory for storing journal text files.")
(defcustom journal-encrypt-to nil
  "List of keys to encrypt journal entries to")

(defvar journal-saver nil)
(defvar journal-start-time nil)
(defvar journal-start-wc nil)

(defun journal-auto-save ()
  (when (and journal-start-time (buffer-modified-p))
    (save-buffer)
    (let ((wc (word-count)))
      (message "%d wpm, %d words" 
               (if (> wc journal-start-wc)
                   (/ (* 60 (- wc journal-start-wc)) 
                      (- (float-time) journal-start-time))
                 0)
               wc))))

(defun word-count (&optional start end)
  "Counts words in region or whole buffer."
  (let ((n 0)
        (start (or start (point-min)))
        (end (or end (point-max))))
    (save-excursion
      (goto-char start)
      (while (< (point) end) (when (forward-word 1) (setq n (1+ n)))))
    n))

(defun journal ()
  "Open today's journal entry file."
  (interactive)
  (find-file (concat journal-directory
                     (format-time-string 
                      (if journal-encrypt-to "/journal-%Y-%m-%d.txt.gpg"
                        "/journal-%Y-%m-%d.txt"))))
  (paragraph-indent-text-mode)
  (auto-fill-mode 1)
  (make-local-variable 'journal-start-time)
  (setq-local epa-file-encrypt-to journal-encrypt-to)
  (journal-stop)
  (setq journal-start-time (float-time))
  (setq journal-start-wc (word-count))
  (setq journal-saver (run-with-idle-timer 3 1 #'journal-auto-save)))

(defun journal-stop ()
  "Stop auto-saving journal file."
  (interactive)
  (when journal-saver
    (cancel-timer journal-saver)
    (journal-auto-save)
    (setq journal-saver nil)
    (setq journal-start-time nil)
    (setq journal-start-wc nil)))

(provide 'journal)

