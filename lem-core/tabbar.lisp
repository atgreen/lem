(defpackage :lem.tabbar
  (:use :cl :lem))
(in-package :lem.tabbar)

(defclass tabbar-window (header-window)
  ((buffer
    :initarg :buffer
    :accessor tabbar-buffer)
   (prev-buffer-list
    :initform '()
    :accessor tabbar-prev-buffer-list)
   (prev-current-buffer
    :initform nil
    :accessor tabbar-prev-current-buffer)
   (prev-display-width
    :initform 0
    :accessor tabbar-prev-display-width)))

(defvar *use-tabbar* nil)
(defvar *tabbar* nil)

(defun tabbar-init ()
  (let ((buffer (make-buffer " *tabbar*" :enable-undo-p nil)))
    (setf (variable-value 'truncate-lines :buffer buffer) nil)
    (setf *tabbar* (make-instance 'tabbar-window :buffer buffer))))

(defun tabbar-require-update ()
  (block exit
    (unless (eq (current-buffer) (tabbar-prev-current-buffer *tabbar*))
      (return-from exit t))
    (unless (eq (buffer-list) (tabbar-prev-buffer-list *tabbar*))
      (return-from exit t))
    (unless (= (display-width) (tabbar-prev-display-width *tabbar*))
      (return-from exit t))
    nil))

(defmethod window-redraw ((window tabbar-window) force)
  (declare (ignore force))
  (when (tabbar-require-update)
    (let* ((buffer (tabbar-buffer *tabbar*))
           (p (buffer-point buffer)))
      (erase-buffer buffer)
      (dolist (buffer (buffer-list))
        (insert-string p
                       (let ((name (buffer-name buffer)))
                         (if (< 20 (length name))
                             (format nil "[~A...]" (subseq name 0 17))
                             (format nil "[~A]" name)))
                       :attribute (if (eq buffer (current-buffer))
                                      'tabbar-active-tab-attribute
                                      'tabbar-attribute)))
      (let ((n (- (display-width) (point-column p))))
        (when (> n 0)
          (insert-string p (make-string n :initial-element #\space)
                         :attribute 'tabbar-attribute)))))
  (setf (tabbar-prev-buffer-list *tabbar*) (buffer-list))
  (setf (tabbar-prev-current-buffer *tabbar*) (current-buffer))
  (setf (tabbar-prev-display-width *tabbar*) (display-width))
  (call-next-method))

(defun tabbar-clear-cache ()
  (setf (tabbar-buffer *tabbar*) nil)
  (setf (tabbar-prev-buffer-list *tabbar*) '())
  (setf (tabbar-prev-current-buffer *tabbar*) nil)
  (setf (tabbar-prev-display-width *tabbar*) 0))
  
(defun tabbar-off ()
  (when *use-tabbar*
    (setf *use-tabbar* nil)
    (tabbar-clear-cache)
    (delete-window *tabbar*)
    (setf *tabbar* nil)))
  
(defun tabbar-on ()
  (unless *use-tabbar*
    (setf *use-tabbar* t)
    (tabbar-init)))

(defun enable-tabbar-p ()
  *use-tabbar*)

(define-command toggle-tabbar () ()
  (if (enable-tabbar-p)
      (tabbar-off)
      (tabbar-on)))

(define-key *global-keymap* (list (code-char 550)) 'tabbar-next) ; control + pagedown
(define-key *global-keymap* (list (code-char 555)) 'tabbar-prev) ; control + pageup

(define-command tabbar-next (n) ("p")
  (dotimes (_ n)
    (let ((buffer (get-next-buffer (current-buffer))))
      (switch-to-buffer (or buffer (first (buffer-list))) nil))))

(define-command tabbar-prev (n) ("p")
  (dotimes (_ n)
    (let ((buffer (get-previous-buffer (current-buffer))))
      (switch-to-buffer (or buffer (car (last (buffer-list)))) nil))))
