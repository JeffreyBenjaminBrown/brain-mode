;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; brain-env.el -- Constants, state, and buffer-local variables
;;
;; Part of the Brain-mode package for Emacs:
;;   https://github.com/joshsh/brain-mode
;;
;; Copyright (C) 2011-2016 Joshua Shinavier and collaborators
;;
;; You should have received a copy of the GNU General Public License
;; along with this software.  If not, see <http://www.gnu.org/licenses/>.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(defconst brain-const-max-height 7
  "The maximum allowed height of a view")

(defconst brain-const-readonly-mode "readonly"
  "A state in which view buffers are not editable")
(defconst brain-const-readwrite-mode "readwrite"
  "A state in which view buffers are editable")
(defconst brain-const-search-mode "search"
  "A state for immutable search results")

(defconst brain-const-color-by-sharability "sharability"
  "A color scheme based on atom weight and sharability")
(defconst brain-const-color-by-class-inference "inference"
  "A color scheme based on type inference")

(defconst brain-const-forward-style "forward"
  "A view style in which atom children are arranged below parents in a tree")
(defconst brain-const-backward-style "backward"
  "A view style in which atom parents are arranged below children in a tree")

(defconst brain-const-sharability-private 0.25
  "A sharability level for the most sensitive information")
(defconst brain-const-sharability-personal 0.5
  "A sharability level for personal information which may be shared in certain contexts")
(defconst brain-const-sharability-public 0.75
  "A sharability level for information which can be freely shared")
(defconst brain-const-sharability-universal 1.0
  "A sharability level for extra-personal information known to everyone")
(defconst brain-const-weight-none 0.0
  "A weight for atoms of no importance, used as a lower limit")
(defconst brain-const-weight-deemphasized 0.25
  "A weight for less important atoms")
(defconst brain-const-weight-default 0.5
  "A weight for typical atoms")
(defconst brain-const-weight-emphasized 0.75
  "A weight for atoms of special importance")
(defconst brain-const-weight-all 1.0
  "A weight for the most important atoms")

(defun brain-env-get-context (&optional context)
  "Retrieves Brain-mode's buffer-local context"
  (if context context brain-bufferlocal-context))

(defun brain-env-set-context (context)
  "Sets Brain-mode's buffer-local context"
  (setq brain-bufferlocal-context context)
  (make-local-variable 'brain-bufferlocal-context))

(defun brain-env-clone-context (&optional context)
  "Creates a new buffer-local context by refreshing and copying another"
  (refresh-context context)
  (let (
    (context (copy-alist (brain-env-get-context context)))
    (sharability (brain-data-target-sharability)))
      (set-default-sharability (adjust-default-sharability sharability) context)
      context))

(defun brain-env-define-buffer-local-variables ()
  "Populates a first definition of buffer-local context with default values"
  (defvar brain-bufferlocal-context (default-context)))

(defun brain-env-numeric-value (json prop default)
  "Reads a numeric value from a map"
  (let ((v (assoc prop json)))
    (if v (string-to-number (cdr v)) default)))

(defun brain-env-parse-context (json context)
  "Sets variables of the buffer-local context according to a service response"
  (set-min-sharability (brain-env-numeric-value json 'minSharability (get-min-sharability context)))
  (set-max-sharability (brain-env-numeric-value json 'maxSharability (get-max-sharability context)))
  (set-default-sharability (brain-env-numeric-value json 'defaultSharability (get-default-sharability context)))
  (set-min-weight (brain-env-numeric-value json 'minWeight (get-min-weight context)))
  (set-max-weight (brain-env-numeric-value json 'maxWeight (get-max-weight)))
  (set-default-weight (brain-env-numeric-value json 'defaultWeight (get-default-weight)))
  (set-root-id (get-value 'root json))
  (set-height
    ;; Always leave a search view with height 1, rather than that of the last view.
    ;; The user experience is a little unpredictable otherwise.
    (if (equal (get-mode) brain-const-search-mode)
      1
      (brain-env-numeric-value json 'height (get-height context))))
  (let ((style (get-value 'style json)))
    (if style (set-style style)))
  (set-title (get-value 'title json))
  (set-atoms-by-id (make-hash-table :test 'equal)))

(defun brain-env-debug-message (msg)
  "Outputs a debugging message"
  (message "%s" (concat "Debug: " msg)))

(defun brain-env-info-message (msg)
  "Outputs an informational message"
  (message "%s" (concat "Info: " msg)))

(defun brain-env-error-message (msg)
  "Outputs an error message"
  (message "%s" (concat "Error: " msg)))

(defun brain-env-error-no-target ()
  "Informs the user that an atom was not found"
  (brain-env-error-message "there is no target associated with this line"))

(defun brain-env-using-inference ()
  "Determines whether the current buffer is an inference-enabled view"
  (equal (get-view-style) brain-const-color-by-class-inference))

(defun brain-env-succeed ()
  "Confirms an assertion"
  t)

(defun brain-env-fail (message)
  "Fails an assertion with the given message"
  (and (brain-env-error-message message) nil))

(defun brain-env-in-readonly-mode ()
  "Determines whether the current buffer is a read-only tree view"
  (equal (get-mode) brain-const-readonly-mode))

(defun brain-env-in-readwrite-mode ()
  "Determines whether the current buffer is an editable tree view"
  (equal (get-mode) brain-const-readwrite-mode))

(defun brain-env-in-search-mode ()
  "Determines whether the current buffer is a page of search results"
  (equal (get-mode) brain-const-search-mode))

(defun brain-env-set-readonly (&optional context)
  "Switches to a read-only tree view"
  (set-mode brain-const-readonly-mode context))

(defun brain-env-set-readwrite (&optional context)
  "Switches to an editable tree view"
  (set-mode brain-const-readwrite-mode context))

(defun brain-env-set-forward-style (&optional context)
  "Switches to the default, parent-to-child style of tree view"
  (set-style brain-const-forward-style context))

(defun brain-env-set-backward-style (&optional context)
  "Switches to the inverse (child-to-parent) style of tree view"
  (set-style brain-const-backward-style context))

(defun brain-env-in-view-mode ()
  "Determines whether the current buffer is an atom's tree view, as opposed to a page of search results, etc."
  (let ((mode (get-mode)))
    (if (or
        (equal mode brain-const-readonly-mode)
        (equal mode brain-const-readwrite-mode))
      t
    (brain-env-fail (concat "cannot create tree view in mode '" mode "'")) nil)))

(defun brain-env-in-setproperties-mode ()
  "Determines whether atom properties can be set in the current buffer"
  (if (or
       (equal (get-mode) brain-const-search-mode)
       (equal (get-mode) brain-const-readonly-mode)
       (equal (get-mode) brain-const-readwrite-mode))
      t
    (brain-env-fail "cannot set properties in current mode") nil))

(defun brain-env-is-readwrite-context (&optional context)
  "Asserts that the current Brain-mode buffer is in a read-only state"
  (let ((mode (get-mode context)))
    (and mode
      (equal mode brain-const-readwrite-mode))))

(defun brain-env-assert-readwrite-context ()
  "Asserts that the current Brain-mode buffer is in a writable state"
  (if (brain-env-is-readwrite-context)
    (brain-env-succeed)
    (brain-env-fail (concat "cannot update view in current mode: " (get-mode))) nil))

(defun brain-env-assert-height-in-bounds (height)
  "Asserts that a view height is positive and not greater than the maximum allowed height"
  (if (< height 1)
    (brain-env-fail (concat "height of " (number-to-string height) " is too low (must be >= 1)"))
    (if (> height brain-const-max-height)
      (brain-env-fail (concat "height of " (number-to-string height) " is too high (must be <= "
                                 (number-to-string brain-const-max-height) ")"))
      (brain-env-succeed))))

(defun brain-env-toggle-inference-viewstyle (&optional context)
  "Switches from the 'weight/sharability' view style to the 'type inference' style, or vice versa"
  (set-view-style
    (if (equal (get-view-style) brain-const-color-by-sharability)
      brain-const-color-by-class-inference
      brain-const-color-by-sharability) context))

(defun brain-env-format-date (time)
  "Formats the current date for use in a buffer of notes"
  (format-time-string const-date-format time))

(defun brain-env-format-time (time &optional with-seconds)
  "Formats the current time for use in a buffer of notes"
  (format-time-string
    (if with-seconds
        const-time-with-seconds-format
        const-time-format)
    time))

(defun get-action (&optional context) (get-bufferlocal context 'action))
(defun get-atoms-by-id (&optional context) (get-bufferlocal context 'atoms-by-id))
(defun get-default-sharability (&optional context) (get-bufferlocal context 'default-sharability))
(defun get-default-weight (&optional context) (get-bufferlocal context 'default-weight))
(defun get-file (&optional context) (get-bufferlocal context 'file))
(defun get-format (&optional context) (get-bufferlocal context 'format))
(defun get-height (&optional context) (get-bufferlocal context 'height))
(defun get-line (&optional context) (get-bufferlocal context 'line))
(defun get-max-sharability (&optional context) (get-bufferlocal context 'max-sharability))
(defun get-max-weight (&optional context) (get-bufferlocal context 'max-weight))
(defun get-min-sharability (&optional context) (get-bufferlocal context 'min-sharability))
(defun get-min-weight (&optional context) (get-bufferlocal context 'min-weight))
(defun get-minimize-verbatim-blocks (&optional context) (get-bufferlocal context 'minimize-verbatim-blocks))
(defun get-mode (&optional context) (get-bufferlocal context 'mode))
(defun get-query (&optional context) (get-bufferlocal context 'query))
(defun get-query-type (&optional context) (get-bufferlocal context 'query-type))
(defun get-root-id (&optional context) (get-bufferlocal context 'root-id))
(defun get-style (&optional context) (get-bufferlocal context 'style))
(defun get-title (&optional context) (get-bufferlocal context 'title))
(defun get-value-length-cutoff (&optional context) (get-bufferlocal context 'value-length-cutoff))
(defun get-view (&optional context) (get-bufferlocal context 'view))
(defun get-view-properties (&optional context) (get-bufferlocal context 'view-properties))
(defun get-view-style (&optional context) (get-bufferlocal context 'view-style))

(defun set-action (action &optional context) (set-bufferlocal context 'action action))
(defun set-atoms-by-id (atoms-by-id &optional context) (set-bufferlocal context 'atoms-by-id atoms-by-id))
(defun set-file (file &optional context) (set-bufferlocal context 'file file))
(defun set-format (format &optional context) (set-bufferlocal context 'format format))
(defun set-default-sharability (sharability &optional context) (set-bufferlocal context 'default-sharability sharability))
(defun set-default-weight (weight &optional context) (set-bufferlocal context 'default-weight weight))
(defun set-height (height &optional context) (set-bufferlocal context 'height height))
(defun set-line (line &optional context) (set-bufferlocal context 'line line))
(defun set-max-sharability (sharability &optional context) (set-bufferlocal context 'max-sharability sharability))
(defun set-max-weight (weight &optional context) (set-bufferlocal context 'max-weight weight))
(defun set-min-sharability (sharability &optional context) (set-bufferlocal context 'min-sharability sharability))
(defun set-min-weight (weight &optional context) (set-bufferlocal context 'min-weight weight))
(defun set-minimize-verbatim-blocks (flag &optional context) (set-bufferlocal context 'minimize-verbatim-blocks flag))
(defun set-mode (mode &optional context) (set-bufferlocal context 'mode mode))
(defun set-query (query &optional context) (set-bufferlocal context 'query query))
(defun set-query-type (type &optional context) (set-bufferlocal context 'query-type type))
(defun set-root-id (root-id &optional context) (set-bufferlocal context 'root-id root-id))
(defun set-style (style &optional context) (set-bufferlocal context 'style style))
(defun set-title (title &optional context) (set-bufferlocal context 'title title))
(defun set-value-length-cutoff (cutoff &optional context) (set-bufferlocal context 'value-length-cutoff cutoff))
(defun set-view (view &optional context) (set-bufferlocal context 'view view))
(defun set-view-properties (view-properties &optional context) (set-bufferlocal context 'view-properties view-properties))
(defun set-view-style (view-style &optional context) (set-bufferlocal context 'view-style view-style))

(defconst const-date-format "%Y-%m-%d")
(defconst const-time-format "%H:%M")
(defconst const-time-with-seconds-format "%H:%M:%S")

(defun get-bufferlocal (context key)
  (get-value key (brain-env-get-context context)))

(defun set-bufferlocal (context key value)
  (setcdr (assoc key (brain-env-get-context context)) value))

(defun default-context () (list
  (cons 'action 'nil)
  (cons 'atoms-by-id 'nil)
  (cons 'default-sharability brain-const-sharability-personal)
  (cons 'default-weight brain-const-weight-default)
  (cons 'file 'nil)
  (cons 'format 'nil)
  (cons 'height 2)
  (cons 'line 1)
  (cons 'max-sharability brain-const-sharability-universal)
  (cons 'max-weight brain-const-weight-all)
  (cons 'min-sharability brain-const-sharability-private)
  (cons 'min-weight brain-const-weight-none)
  (cons 'minimize-verbatim-blocks 'nil)
  (cons 'mode brain-const-readonly-mode)
  (cons 'query 'nil)
  (cons 'query-type 'nil)
  (cons 'root-id 'nil)
  (cons 'style brain-const-forward-style)
  (cons 'title 'nil)
  (cons 'value-length-cutoff 100)
  (cons 'view 'nil)
  (cons 'view-properties 'nil)
  (cons 'view-style brain-const-color-by-sharability)))

(defun refresh-context (&optional context)
  (set-line (line-number-at-pos) context))

;; change the default sharability in the new view after a user visits a link or target
;; The default will never be greater than 0.75 unless explicitly set by the user.
(defun adjust-default-sharability (sharability)
  (if sharability
      (if (<= sharability 0.75) sharability 0.75)
    0.5))

(defun get-value (key json)
  (cdr (assoc key json)))

(defun mode-for-visit ()
  (if (or (equal (get-mode) brain-const-readwrite-mode) (equal (get-mode) brain-const-readonly-mode))
      (get-mode)
    brain-const-readonly-mode))


(provide 'brain-env)
