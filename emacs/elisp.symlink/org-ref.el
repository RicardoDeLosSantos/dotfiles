
;;; org-ref.el --- setup bibliography, cite, ref and label org-mode links.

;; Copyright(C) 2014 John Kitchin

;; Author: John Kitchin <jkitchin@andrew.cmu.edu>
;; This file is not currently part of GNU Emacs.

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2, or (at
;; your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program ; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:
;;
;; Lisp code to setup bibliography cite, ref and label org-mode links.
;; also sets up reftex for org-mode. The links are clickable and do
;; things that are useful. You should really read org-ref.org for details.
;;
;; Package-Requires: ((dash "2.6.0"))

(require 'reftex-cite)
(require 'dash)

(defgroup org-ref nil
  "customization group for org-ref")

(defcustom org-ref-bibliography-notes
  nil
  "filename to where you will put all your notes about an entry in
  the default bibliography."
  :type 'file
  :group 'org-ref)

(defcustom org-ref-default-bibliography
  nil
  "list of bibtex files to search for. You should use full-paths for each file."
  :type '(repeat :tag "List of bibtex files" file)
  :group 'org-ref)

(defcustom org-ref-pdf-directory
  nil
  "directory where pdfs are stored by key. put a trailing / in"
  :type 'directory
  :group 'org-ref)

(defcustom org-ref-default-citation-link
  "cite"
  "The default type of citation link to use"
  :type 'string
  :group 'org-ref)

(defcustom org-ref-insert-cite-key
  "C-c ]"
  "Keyboard shortcut to insert a citation."
  :type 'string
  :group 'org-ref)

(defcustom org-ref-bibliography-entry-format
  "%a, %t, <i>%j</i>, <b>%v(%n)</b>, %p (%y). <a href=\"%U\">link</a>. <a href=\"http://dx.doi.org/%D\">doi</a>."
  "string to format an entry. Just the reference, no numbering at the beginning, etc..."
  :type 'string
  :group 'org-ref)

(defcustom org-ref-cite-types
  '("cite" "nocite" ;; the default latex cite commands
    ;; natbib cite commands, http://ctan.unixbrain.com/macros/latex/contrib/natbib/natnotes.pdf
    "citet" "citet*" "citep" "citep*"
    "citealt" "citealt*" "citealp" "citealp*"
    "citenum" "citetext"
    "citeauthor" "citeauthor*"
    "citeyear" "citeyear*"
    "Citet" "Citep" "Citealt" "Citealp" "Citeauthor"
    ;; biblatex commands
    ;; http://ctan.mirrorcatalogs.com/macros/latex/contrib/biblatex/doc/biblatex.pdf
    "Cite"
    "parencite" "Parencite"
    "footcite" "footcitetext"
    "textcite" "Textcite"
    "smartcite" "Smartcite"
    "cite*" "parencite*" "supercite"
    "autocite" "Autocite" "autocite*" "Autocite*"
    "Citeauthor*"
    "citetitle" "citetitle*"
    "citedate" "citedate*"
    "citeurl"
    "fullcite" "footfullcite"
    ;; "volcite" "Volcite" cannot support the syntax
    "notecite" "Notecite"
    "pnotecite" "Pnotecite"
    "fnotecite"
    ;; multicites. Very limited support for these.
    "cites" "Cites" "parencites" "Parencites"
    "footcites" "footcitetexts"
    "smartcites" "Smartcites" "textcites" "Textcites"
    "supercites" "autocites" "Autocites"
    )
  "List of citation types known in org-ref"
  :type '(repeat :tag "List of citation types" string)
  :group 'org-ref)

(defcustom org-ref-clean-bibtex-entry-hook nil
  "Hook that is run in org-ref-clean-bibtex-entry. The functions should take no arguments, and operate on the bibtex entry at point."
  :group 'org-ref
  :type 'hook)

(defvar org-ref-bibliography-files
  nil
  "variable to hold bibliography files to be searched")

(defun org-mode-reftex-setup ()
    (load-library "reftex")
    (and (buffer-file-name)
         (file-exists-p (buffer-file-name))
	 (global-auto-revert-mode t)
         (reftex-parse-all))
    (make-local-variable 'reftex-cite-format)
    (setq reftex-cite-format 'org)
    (define-key org-mode-map (kbd org-ref-insert-cite-key) 'org-ref-insert-cite-link)
  (setq reftex-label-alist '(("equation" ?e "eq:" "eqref:%s" t  ("equation" "eq.")))))

(add-hook 'org-mode-hook 'org-mode-reftex-setup)

(eval-after-load 'reftex-vars
  '(progn
      (add-to-list 'reftex-cite-format-builtin
                   '(org "Org-mode citation"
                         ((?\C-m . "cite:%l")     ; default
			  (?d . ",%l")            ; for appending
			  (?a . "autocite:%l")
			  (?t . "citet:%l")
			  (?T . "citet*:%l")
			  (?p . "citep:%l")
			  (?P . "citep*:%l")
			  (?h . "citeauthor:%l")
			  (?H . "citeauthor*:%l")
			  (?y . "citeyear:%l")
			  (?x . "citetext:%l")
			  (?n . "nocite:%l")
			  )))))

(defun org-ref-strip-string (string)
  "strip leading and trailing whitespace from the string"
  (replace-regexp-in-string
   (concat search-whitespace-regexp "$" ) ""
   (replace-regexp-in-string
    (concat "^" search-whitespace-regexp ) "" string)))

(defun org-ref-split-and-strip-string (string)
  "split key-string and strip keys. Assumes the key-string is comma delimited"
  (mapcar 'org-ref-strip-string (split-string string ",")))

(defun org-ref-reftex-get-bib-field (field entry &optional format)
  "similar to reftex-get-bib-field, but removes enclosing braces and quotes"
  (let ((result))
    (setq result (reftex-get-bib-field field entry format))
    (when (and (not (string= result "")) (string= "{" (substring result 0 1)))
      (setq result (substring result 1 -1)))
    (when (and (not (string= result "")) (string= "\"" (substring result 0 1)))
      (setq result (substring result 1 -1)))    
      result))

(defun org-ref-reftex-format-citation (entry format)
  "return a formatted string for the bibtex entry (from bibtex-parse-entry) according
to the format argument. The format is a string with these percent escapes.

In the format, the following percent escapes will be expanded.

%l   The BibTeX label of the citation.
%a   List of author names, see also `reftex-cite-punctuation'.
%2a  Like %a, but abbreviate more than 2 authors like Jones et al.
%A   First author name only.
%e   Works like %a, but on list of editor names. (%2e and %E work a well)

It is also possible to access all other BibTeX database fields:
%b booktitle     %c chapter        %d edition    %h howpublished
%i institution   %j journal        %k key        %m month
%n number        %o organization   %p pages      %P first page
%r address       %s school         %u publisher  %t title
%v volume        %y year
%B booktitle, abbreviated          %T title, abbreviated
%U url
%D doi

Usually, only %l is needed.  The other stuff is mainly for the echo area
display, and for (setq reftex-comment-citations t).

%< as a special operator kills punctuation and space around it after the
string has been formatted.

A pair of square brackets indicates an optional argument, and RefTeX
will prompt for the values of these arguments.

Beware that all this only works with BibTeX database files.  When
citations are made from the \bibitems in an explicit thebibliography
environment, only %l is available."
  ;; Format a citation from the info in the BibTeX ENTRY

  (unless (stringp format) (setq format "\\cite{%l}"))

  (if (and reftex-comment-citations
           (string-match "%l" reftex-cite-comment-format))
      (error "reftex-cite-comment-format contains invalid %%l"))

  (while (string-match
          "\\(\\`\\|[^%]\\)\\(\\(%\\([0-9]*\\)\\([a-zA-Z]\\)\\)[.,;: ]*\\)"
          format)
    (let ((n (string-to-number (match-string 4 format)))
          (l (string-to-char (match-string 5 format)))
          rpl b e)
      (save-match-data
        (setq rpl
              (cond
               ((= l ?l) (concat
                          (org-ref-reftex-get-bib-field "&key" entry)
                          (if reftex-comment-citations
                              reftex-cite-comment-format
                            "")))
               ((= l ?a) (reftex-format-names
                          (reftex-get-bib-names "author" entry)
                          (or n 2)))
               ((= l ?A) (car (reftex-get-bib-names "author" entry)))
               ((= l ?b) (org-ref-reftex-get-bib-field "booktitle" entry "in: %s"))
               ((= l ?B) (reftex-abbreviate-title
                          (org-ref-reftex-get-bib-field "booktitle" entry "in: %s")))
               ((= l ?c) (org-ref-reftex-get-bib-field "chapter" entry))
               ((= l ?d) (org-ref-reftex-get-bib-field "edition" entry))
               ((= l ?D) (org-ref-reftex-get-bib-field "doi" entry))
               ((= l ?e) (reftex-format-names
                          (reftex-get-bib-names "editor" entry)
                          (or n 2)))
               ((= l ?E) (car (reftex-get-bib-names "editor" entry)))
               ((= l ?h) (org-ref-reftex-get-bib-field "howpublished" entry))
               ((= l ?i) (org-ref-reftex-get-bib-field "institution" entry))
               ((= l ?j) (org-ref-reftex-get-bib-field "journal" entry))
               ((= l ?k) (org-ref-reftex-get-bib-field "key" entry))
               ((= l ?m) (org-ref-reftex-get-bib-field "month" entry))
               ((= l ?n) (org-ref-reftex-get-bib-field "number" entry))
               ((= l ?o) (org-ref-reftex-get-bib-field "organization" entry))
               ((= l ?p) (org-ref-reftex-get-bib-field "pages" entry))
               ((= l ?P) (car (split-string
                               (org-ref-reftex-get-bib-field "pages" entry)
                               "[- .]+")))
               ((= l ?s) (org-ref-reftex-get-bib-field "school" entry))
               ((= l ?u) (org-ref-reftex-get-bib-field "publisher" entry))
               ((= l ?U) (org-ref-reftex-get-bib-field "url" entry))
               ((= l ?r) (org-ref-reftex-get-bib-field "address" entry))
	       ;; strip enclosing brackets from title if they are there
               ((= l ?t) (org-ref-reftex-get-bib-field "title" entry))
               ((= l ?T) (reftex-abbreviate-title
                          (org-ref-reftex-get-bib-field "title" entry)))
               ((= l ?v) (org-ref-reftex-get-bib-field "volume" entry))
               ((= l ?y) (org-ref-reftex-get-bib-field "year" entry)))))

      (if (string= rpl "")
          (setq b (match-beginning 2) e (match-end 2))
        (setq b (match-beginning 3) e (match-end 3)))
      (setq format (concat (substring format 0 b) rpl (substring format e)))))
  (while (string-match "%%" format)
    (setq format (replace-match "%" t t format)))
  (while (string-match "[ ,.;:]*%<" format)
    (setq format (replace-match "" t t format)))
  ;; also replace carriage returns, tabs, and multiple whitespaces
  (setq format (replace-regexp-in-string "\n\\|\t\\|\s+" " " format))
  format)

(defun org-ref-get-bibtex-entry-citation (key)
  "returns a string for the bibliography entry corresponding to key, and formatted according to `org-ref-bibliography-entry-format'"

  (let ((org-ref-bibliography-files (org-ref-find-bibliography))
	(file) (entry))

    (setq file (catch 'result
		 (loop for file in org-ref-bibliography-files do
		       (if (org-ref-key-in-file-p key (file-truename file)) 
			   (throw 'result file)
			 (message "%s not found in %s" key (file-truename file))))))

    (with-temp-buffer
      (insert-file-contents file)
      (bibtex-search-entry key nil 0)
      (setq entry  (org-ref-reftex-format-citation (bibtex-parse-entry) org-ref-bibliography-entry-format)))
    entry))

(defun org-ref-get-bibtex-keys ()
  "return a list of unique keys in the buffer."
  (let ((keys '()))
    (org-element-map (org-element-parse-buffer) 'link
      (lambda (link)       
	(let ((plist (nth 1 link)))			     
	  (when (-contains? org-ref-cite-types (plist-get plist ':type))
	    (dolist 
		(key 
		 (org-ref-split-and-strip-string (plist-get plist ':path)))
	      (when (not (-contains? keys key))
		(setq keys (append keys (list key)))))))))
    ;; Sort keys alphabetically
    (setq keys (cl-sort keys 'string-lessp :key 'downcase))
    keys))

(defun org-ref-get-bibtex-entry-html (key)
  "returns an html string for the bibliography entry corresponding to key"

  (format "<li><a id=\"%s\">[%s] %s</a></li>" key key (org-ref-get-bibtex-entry-citation key)))

(defun org-ref-get-html-bibliography ()
  "Create an html bibliography when there are keys"
  (let ((keys (org-ref-get-bibtex-keys)))
    (when keys
      (concat "<h1>Bibliography</h1>
<ul>"
	      (mapconcat (lambda (x) (org-ref-get-bibtex-entry-html x)) keys "\n")
	      "\n</ul>"))))

(org-add-link-type "bibliography"
		   ;; this code is run on clicking. The bibliography
		   ;; may contain multiple files. this code finds the
		   ;; one you clicked on and opens it.
		   (lambda (link-string)	
		       ;; get link-string boundaries
		       ;; we have to go to the beginning of the line, and then search forward
		       
		     (let* ((bibfile)
			    ;; object is the link you clicked on
			    (object (org-element-context))
 
			    (link-string-beginning) 
			    (link-string-end))

		     (save-excursion
		       (goto-char (org-element-property :begin object))
		       (search-forward link-string nil nil 1)
		       (setq link-string-beginning (match-beginning 0))
		       (setq link-string-end (match-end 0)))

		       ;; We set the reftex-default-bibliography
		       ;; here. it should be a local variable only in
		       ;; the current buffer. We need this for using
		       ;; reftex to do citations.
		       (set (make-local-variable 'reftex-default-bibliography) 
			    (split-string (org-element-property :path object) ","))

		       ;; now if we have comma separated bibliographies
		       ;; we find the one clicked on. we want to
		       ;; search forward to next comma from point
		       (save-excursion
			 (if (search-forward "," link-string-end 1 1)
			     (setq key-end (- (match-end 0) 1)) ; we found a match
			   (setq key-end (point)))) ; no comma found so take the point
		       ;; and backward to previous comma from point
		       (save-excursion
			 (if (search-backward "," link-string-beginning 1 1)
			     (setq key-beginning (+ (match-beginning 0) 1)) ; we found a match
			   (setq key-beginning (point)))) ; no match found
		       ;; save the key we clicked on.
		       (setq bibfile (org-ref-strip-string (buffer-substring key-beginning key-end)))
		       (find-file bibfile))) ; open file on click

		     ;; formatting code
		   (lambda (keyword desc format)
		     (cond
		      ((eq format 'html) (org-ref-get-html-bibliography))
		      ((eq format 'latex)
			 ;; write out the latex bibliography command
		       (format "\\bibliography{%s}" (replace-regexp-in-string  "\\.bib" "" keyword))))))

(org-add-link-type "printbibliography"
		   (lambda (arg) (message "Nothing implemented for clicking here."))
		   (lambda (keyword desc format)
		     (cond
                      ((eq format 'html) (org-ref-get-html-bibliography))
		      ((eq format 'latex)
		       ;; write out the latex bibliography command
		       (format "\\printbibliography" keyword)))))

(org-add-link-type "bibliographystyle"
		   (lambda (arg) (message "Nothing implemented for clicking here."))
		   (lambda (keyword desc format)
		     (cond
		      ((eq format 'latex)
		       ;; write out the latex bibliography command
		       (format "\\bibliographystyle{%s}" keyword)))))

(defun org-bibliography-complete-link (&optional arg)
 (format "bibliography:%s" (read-file-name "enter file: " nil nil t)))

(defun org-ref-insert-bibliography-link ()
  "insert a bibliography with completion"
  (interactive)
  (insert (org-bibliography-complete-link)))

(org-add-link-type "addbibresource"
		   ;; this code is run on clicking. The addbibresource
		   ;; may contain multiple files. this code finds the
		   ;; one you clicked on and opens it.
		   (lambda (link-string)	
		       ;; get link-string boundaries
		       ;; we have to go to the beginning of the line, and then search forward
		       
		     (let* ((bibfile)
			    ;; object is the link you clicked on
			    (object (org-element-context))
 
			    (link-string-beginning) 
			    (link-string-end))

		     (save-excursion
		       (goto-char (org-element-property :begin object))
		       (search-forward link-string nil nil 1)
		       (setq link-string-beginning (match-beginning 0))
		       (setq link-string-end (match-end 0)))

		       ;; We set the reftex-default-addbibresource
		       ;; here. it should be a local variable only in
		       ;; the current buffer. We need this for using
		       ;; reftex to do citations.
		       (set (make-local-variable 'reftex-default-addbibresource) 
			    (split-string (org-element-property :path object) ","))

		       ;; now if we have comma separated bibliographies
		       ;; we find the one clicked on. we want to
		       ;; search forward to next comma from point
		       (save-excursion
			 (if (search-forward "," link-string-end 1 1)
			     (setq key-end (- (match-end 0) 1)) ; we found a match
			   (setq key-end (point)))) ; no comma found so take the point
		       ;; and backward to previous comma from point
		       (save-excursion
			 (if (search-backward "," link-string-beginning 1 1)
			     (setq key-beginning (+ (match-beginning 0) 1)) ; we found a match
			   (setq key-beginning (point)))) ; no match found
		       ;; save the key we clicked on.
		       (setq bibfile (org-ref-strip-string (buffer-substring key-beginning key-end)))
		       (find-file bibfile))) ; open file on click

		     ;; formatting code
		   (lambda (keyword desc format)
		     (cond
		      ((eq format 'html) (format "")); no output for html
		      ((eq format 'latex)
			 ;; write out the latex addbibresource command
		       (format "\\addbibresource{%s}" (replace-regexp-in-string  "\\.bib" "" keyword))))))

(defun org-ref-list-of-figures (&optional arg)
  "Generate buffer with list of figures in them"
  (interactive)
  (let* ((c-b (buffer-name))
	 (counter 0)
	 (list-of-figures 
	  (org-element-map (org-element-parse-buffer) 'link
	    (lambda (link) 
	      "create a link for to the figure"
	      (when 
		  (and (string= (org-element-property :type link) "file")
		       (string-match-p  
			"[^.]*\\.\\(png\\|jpg\\|eps\\|pdf\\)$"
			(org-element-property :path link)))                   
		(incf counter)
		
		(let* ((start (org-element-property :begin link))
		       (parent (car (cdr (org-element-property :parent link))))
		       (caption (caaar (plist-get parent :caption)))
		       (name (plist-get parent :name)))
		  (if caption 
		      (format 
		       "[[elisp:(progn (switch-to-buffer \"%s\")(goto-char %s))][figure %s: %s]] %s\n" 
		       c-b start counter (or name "") caption)
		    (format 
		     "[[elisp:(progn (switch-to-buffer \"%s\")(goto-char %s))][figure %s: %s]]\n" 
		     c-b start counter (or name "")))))))))
    (switch-to-buffer "*List of Figures*")
    (org-mode)
    (erase-buffer)
    (insert (mapconcat 'identity list-of-figures ""))
    (setq buffer-read-only t)
    (use-local-map (copy-keymap org-mode-map))
    (local-set-key "q" #'(lambda () (interactive) (kill-buffer)))))

(org-add-link-type 
 "list-of-figures"
 'org-ref-list-of-figures ; on click
 (lambda (keyword desc format)
   (cond
    ((eq format 'latex)
     (format "\\listoffigures")))))

(defun org-ref-list-of-tables (&optional arg)
  "Generate a buffer with a list of tables"
  (interactive)
  (let* ((c-b (buffer-name))
	 (counter 0)
	 (list-of-tables 
	  (org-element-map (org-element-parse-buffer 'element) 'table
	    (lambda (table) 
	      "create a link for to the table"
	      (incf counter)
	      (let ((start (org-element-property :begin table))
		    (name  (org-element-property :name table))
		    (caption (caaar (org-element-property :caption table))))
		(if caption 
		    (format 
		     "[[elisp:(progn (switch-to-buffer \"%s\")(goto-char %s))][table %s: %s]] %s\n" 
		     c-b start counter (or name "") caption)
		  (format 
		   "[[elisp:(progn (switch-to-buffer \"%s\")(goto-char %s))][table %s: %s]]\n" 
		   c-b start counter (or name ""))))))))
    (switch-to-buffer "*List of Tables*")
    (org-mode)
    (erase-buffer)
    (insert (mapconcat 'identity list-of-tables ""))
    (setq buffer-read-only t)
    (use-local-map (copy-keymap org-mode-map))
    (local-set-key "q" #'(lambda () (interactive) (kill-buffer)))))

(org-add-link-type 
 "list-of-tables"
 'org-ref-list-of-tables
 (lambda (keyword desc format)
   (cond
    ((eq format 'latex)
     (format "\\listoftables")))))

(org-add-link-type
 "label"
 (lambda (label)
   "on clicking count the number of label tags used in the buffer. A number greater than one means multiple labels!"
   (message (format "%s occurences"
		    (+ (count-matches (format "label:%s\\b" label) (point-min) (point-max) t)
		       (count-matches (format "\\label{%s}\\b" label) (point-min) (point-max) t)
                       ;; this is the org-format #+label:
		       (count-matches (format "#\\+label:%s\\b" label) (point-min) (point-max) t)))))
 (lambda (keyword desc format)
   (cond
    ((eq format 'html) (format "(<label>%s</label>)" path))
    ((eq format 'latex)
     (format "\\label{%s}" keyword)))))

(defun org-label-store-link ()
  "store a link to a label. The output will be a ref to that label"
  ;; First we have to make sure we are on a label link. 
  (let* ((object (org-element-context)))
    (when (and (equal (org-element-type object) 'link) 
               (equal (org-element-property :type object) "label"))
      (org-store-link-props
       :type "ref"
       :link (concat "ref:" (org-element-property :path object))))

    ;; Store link on table
    (when (equal (org-element-type object) 'table)
      (org-store-link-props
       :type "ref"
       :link (concat "ref:" (org-element-property :name object))))

;; it turns out this does not work. you can already store a link to a heading with a CUSTOM_ID
    ;; store link on heading with custom_id
;    (when (and (equal (org-element-type object) 'headline)
;	       (org-entry-get (point) "CUSTOM_ID"))
;      (org-store-link-props
;       :type "ref"
;       :link (concat "ref:" (org-entry-get (point) "CUSTOM_ID"))))

    ;; and to #+label: lines
    (when (and (equal (org-element-type object) 'paragraph)
	       (org-element-property :name object))
      (org-store-link-props
       :type "ref"
       :link (concat "ref:" (org-element-property :name object))))
))

(add-hook 'org-store-link-functions 'org-label-store-link)

(org-add-link-type
 "ref"
 (lambda (label)
   "on clicking goto the label. Navigate back with C-c &"
   (org-mark-ring-push)
   ;; next search from beginning of the buffer

   (unless
       (or
	;; our label links
	(progn 
	  (goto-char (point-min))
	  (re-search-forward (format "label:%s\\b" label) nil t))

	;; a latex label
	(progn
	  (goto-char (point-min))
	  (re-search-forward (format "\\label{%s}" label) nil t))

	;; #+label: name  org-definition
	(progn
	  (goto-char (point-min))
	  (re-search-forward (format "^#\\+label:\\s-*\\(%s\\)\\b" label) nil t))
	
	;; org tblname
	(progn
	  (goto-char (point-min))
	  (re-search-forward (format "^#\\+tblname:\\s-*\\(%s\\)\\b" label) nil t))

;; Commented out because these ref links do not actually translate correctly in LaTeX.
;; you need [[#label]] links.
	;; CUSTOM_ID
;	(progn
;	  (goto-char (point-min))
;	  (re-search-forward (format ":CUSTOM_ID:\s-*\\(%s\\)" label) nil t))
	)
     ;; we did not find anything, so go back to where we came
     (org-mark-ring-goto)
     (error "%s not found" label))
   (message "go back with (org-mark-ring-goto) `C-c &`"))
 ;formatting
 (lambda (keyword desc format)
   (cond
    ((eq format 'html) (format "(<ref>%s</ref>)" path))
    ((eq format 'latex)
     (format "\\ref{%s}" keyword)))))

(defun org-ref-get-custom-ids ()
 "return a list of custom_id properties in the buffer"
 (let ((results '()) custom_id)
   (org-map-entries 
    (lambda () 
      (let ((custom_id (org-entry-get (point) "CUSTOM_ID")))
	(when (not (null custom_id))
	  (setq results (append results (list custom_id)))))))
results))

(defun org-ref-get-latex-labels ()
(save-excursion
    (goto-char (point-min))
    (let ((matches '()))
      (while (re-search-forward "\\\\label{\\([a-zA-z0-9:-]*\\)}" (point-max) t)
	(add-to-list 'matches (match-string-no-properties 1) t))
matches)))

(defun org-ref-get-tblnames ()
  (org-element-map (org-element-parse-buffer 'element) 'table
    (lambda (table) 
      (org-element-property :name table))))

(defun org-ref-get-labels ()
  "returns a list of labels in the buffer that you can make a ref link to. this is used to auto-complete ref links."
  (save-excursion
    (goto-char (point-min))
    (let ((matches '()))
      (while (re-search-forward "label:\\([a-zA-z0-9:-]*\\)" (point-max) t)
	(add-to-list 'matches (match-string-no-properties 1) t))
      (append matches (org-ref-get-latex-labels) (org-ref-get-tblnames) (org-ref-get-custom-ids)))))

(defun org-ref-complete-link (&optional arg)
  "Completion function for ref links"
  (let ((label))
    (setq label (completing-read "label: " (org-ref-get-labels)))
    (format "ref:%s" label)))

(defun org-ref-insert-ref-link ()
 (interactive)
 (insert (org-ref-complete-link)))

(org-add-link-type
 "pageref"
 (lambda (label)
   "on clicking goto the label. Navigate back with C-c &"
   (org-mark-ring-push)
   ;; next search from beginning of the buffer

   (unless
       (or
	;; our label links
	(progn 
	  (goto-char (point-min))
	  (re-search-forward (format "label:%s\\b" label) nil t))

	;; a latex label
	(progn
	  (goto-char (point-min))
	  (re-search-forward (format "\\label{%s}" label) nil t))

	;; #+label: name  org-definition
	(progn
	  (goto-char (point-min))
	  (re-search-forward (format "^#\\+label:\\s-*\\(%s\\)\\b" label) nil t))
	
	;; org tblname
	(progn
	  (goto-char (point-min))
	  (re-search-forward (format "^#\\+tblname:\\s-*\\(%s\\)\\b" label) nil t))

;; Commented out because these ref links do not actually translate correctly in LaTeX.
;; you need [[#label]] links.
	;; CUSTOM_ID
;	(progn
;	  (goto-char (point-min))
;	  (re-search-forward (format ":CUSTOM_ID:\s-*\\(%s\\)" label) nil t))
	)
     ;; we did not find anything, so go back to where we came
     (org-mark-ring-goto)
     (error "%s not found" label))
   (message "go back with (org-mark-ring-goto) `C-c &`"))
 ;formatting
 (lambda (keyword desc format)
   (cond
    ((eq format 'html) (format "(<pageref>%s</pageref>)" path))
    ((eq format 'latex)
     (format "\\pageref{%s}" keyword)))))

(defun org-pageref-complete-link (&optional arg)
  "Completion function for ref links"
  (let ((label))
    (setq label (completing-read "label: " (org-ref-get-labels)))
    (format "ref:%s" label)))

(defun org-pageref-insert-ref-link ()
 (interactive)
 (insert (org-pageref-complete-link)))

(org-add-link-type
 "nameref"
 (lambda (label)
   "on clicking goto the label. Navigate back with C-c &"
   (org-mark-ring-push)
   ;; next search from beginning of the buffer

   (unless
       (or
	;; a latex label
	(progn
	  (goto-char (point-min))
	  (re-search-forward (format "\\label{%s}" label) nil t))
	)
     ;; we did not find anything, so go back to where we came
     (org-mark-ring-goto)
     (error "%s not found" label))
   (message "go back with (org-mark-ring-goto) `C-c &`"))
 ;formatting
 (lambda (keyword desc format)
   (cond
    ((eq format 'html) (format "(<nameref>%s</nameref>)" path))
    ((eq format 'latex)
     (format "\\nameref{%s}" keyword)))))

(org-add-link-type
 "eqref"
 (lambda (label)
   "on clicking goto the label. Navigate back with C-c &"
   (org-mark-ring-push)
   ;; next search from beginning of the buffer
   (goto-char (point-min))
   (unless
       (or
	;; search forward for the first match
	;; our label links
	(re-search-forward (format "label:%s" label) nil t)
	;; a latex label
	(re-search-forward (format "\\label{%s}" label) nil t)
	;; #+label: name  org-definition
	(re-search-forward (format "^#\\+label:\\s-*\\(%s\\)\\b" label) nil t))
     (org-mark-ring-goto)
     (error "%s not found" label))
   (message "go back with (org-mark-ring-goto) `C-c &`"))
 ;formatting
 (lambda (keyword desc format)
   (cond
    ((eq format 'html) (format "(<eqref>%s</eqref>)" path))
    ((eq format 'latex)
     (format "\\eqref{%s}" keyword)))))

(defun org-ref-get-bibtex-key-under-cursor ()
  "returns key under the bibtex cursor. We search forward from
point to get a comma, or the end of the link, and then backwards
to get a comma, or the beginning of the link. that delimits the
keyword we clicked on. We also strip the text properties."
  (interactive)
  (let* ((object (org-element-context))	 
	 (link-string (org-element-property :path object)))    
    
    ;; we need the link path start and end
    (save-excursion
      (goto-char (org-element-property :begin object))
      (search-forward link-string nil nil 1)
      (setq link-string-beginning (match-beginning 0))
      (setq link-string-end (match-end 0)))

    ;; The key is the text between commas, or the link boundaries
    (save-excursion
      (if (search-forward "," link-string-end t 1)
	  (setq key-end (- (match-end 0) 1)) ; we found a match
	(setq key-end link-string-end))) ; no comma found so take the end
    ;; and backward to previous comma from point which defines the start character
    (save-excursion
      (if (search-backward "," link-string-beginning 1 1)
	  (setq key-beginning (+ (match-beginning 0) 1)) ; we found a match
	(setq key-beginning link-string-beginning))) ; no match found
    ;; save the key we clicked on.
    (setq bibtex-key (org-ref-strip-string (buffer-substring key-beginning key-end)))
    (set-text-properties 0 (length bibtex-key) nil bibtex-key)
    bibtex-key
    ))

(defun org-ref-find-bibliography ()
  "find the bibliography in the buffer.
This function sets and returns cite-bibliography-files, which is a list of files
either from bibliography:f1.bib,f2.bib
\bibliography{f1,f2}
internal bibliographies

falling back to what the user has set in org-ref-default-bibliography
"
  (interactive)
  (catch 'result
    (save-excursion
      (goto-char (point-min))
      ;;  look for a bibliography link
      (when (re-search-forward "\\<bibliography:\\([^\]\|\n]+\\)" nil t)
	(setq org-ref-bibliography-files
	      (mapcar 'org-ref-strip-string (split-string (match-string 1) ",")))
	(throw 'result org-ref-bibliography-files))

      
      ;; we did not find a bibliography link. now look for \bibliography
      (goto-char (point-min))
      (when (re-search-forward "\\\\bibliography{\\([^}]+\\)}" nil t)
	;; split, and add .bib to each file
	(setq org-ref-bibliography-files
	      (mapcar (lambda (x) (concat x ".bib"))
		      (mapcar 'org-ref-strip-string 
			      (split-string (match-string 1) ","))))
	(throw 'result org-ref-bibliography-files))

      ;; no bibliography found. maybe we need a biblatex addbibresource
      (goto-char (point-min))
      ;;  look for a bibliography link
      (when (re-search-forward "addbibresource:\\([^\]\|\n]+\\)" nil t)
	(setq org-ref-bibliography-files
	      (mapcar 'org-ref-strip-string (split-string (match-string 1) ",")))
	(throw 'result org-ref-bibliography-files))
	  
      ;; we did not find anything. use defaults
      (setq org-ref-bibliography-files org-ref-default-bibliography)))

    ;; set reftex-default-bibliography so we can search
    (set (make-local-variable 'reftex-default-bibliography) org-ref-bibliography-files)
    org-ref-bibliography-files)

(defun org-ref-key-in-file-p (key filename)
  "determine if the key is in the file"
  (interactive "skey: \nsFile: ")

  (with-temp-buffer
    (insert-file-contents filename)
    (prog1
        (bibtex-search-entry key nil 0))))

(defun org-ref-get-bibtex-key-and-file (&optional key)
  "returns the bibtex key and file that it is in. If no key is provided, get one under point"
 (interactive)
 (let ((org-ref-bibliography-files (org-ref-find-bibliography))
       (file))
   (unless key
     (setq key (org-ref-get-bibtex-key-under-cursor)))
   (setq file     (catch 'result
		    (loop for file in org-ref-bibliography-files do
			  (if (org-ref-key-in-file-p key (file-truename file)) 
			      (throw 'result file)))))
   (cons key file)))

(defun org-ref-get-menu-options ()
  "returns a dynamically determined string of options for the citation under point.

we check to see if there is pdf, and if the key actually exists in the bibliography"
  (interactive)
  (let* ((results (org-ref-get-bibtex-key-and-file))
	 (key (car results))
         (pdf-file (format (concat org-ref-pdf-directory "%s.pdf") key))
         (bibfile (cdr results))
	 m1 m2 m3 m4 m5 menu-string)
    (setq m1 (if bibfile		 
		 "(o)pen"
	       "(No key found)"))

    (setq m3 (if (file-exists-p pdf-file)
		 "(p)df"
		     "(No pdf found)"))

    (setq m4 (if (not
                  (and bibfile
                       (string= (catch 'url
                                  (progn

                                    (with-temp-buffer
                                      (insert-file-contents bibfile)
                                      (bibtex-search-entry key)
                                      (when (not
                                             (string= (setq url (bibtex-autokey-get-field "url")) ""))
                                        (throw 'url url))

                                      (when (not
                                             (string= (setq url (bibtex-autokey-get-field "doi")) ""))
                                        (throw 'url url))))) "")))
               "(u)rl" "(no url found)"))
    (setq m5 "(n)otes")
    (setq m2 (if bibfile
		 (progn
                   (setq citation (progn
                                    (with-temp-buffer
                                      (insert-file-contents bibfile)
                                      (bibtex-search-entry key)
                                      (org-ref-bib-citation))))
                   citation)
	       "no key found"))

    (setq menu-string (mapconcat 'identity (list m2 "\n" m1 m3 m4 m5 "(q)uit") "  "))
    menu-string))

(defun org-ref-open-pdf-at-point ()
  "open the pdf for bibtex key under point if it exists"
  (interactive)
  (let* ((results (org-ref-get-bibtex-key-and-file))
	 (key (car results))
         (pdf-file (format (concat org-ref-pdf-directory "%s.pdf") key)))
    (if (file-exists-p pdf-file)
	(org-open-file pdf-file)
(message "no pdf found for %s" key))))


(defun org-ref-open-url-at-point ()
  "open the url for bibtex key under point."
  (interactive)
  (let* ((results (org-ref-get-bibtex-key-and-file))
	 (key (car results))
	 (bibfile (cdr results)))
    (save-excursion
      (with-temp-buffer
        (insert-file-contents bibfile)
        (bibtex-search-entry key)
        ;; I like this better than bibtex-url which does not always find
        ;; the urls
        (catch 'done
          (let ((url (bibtex-autokey-get-field "url")))
            (when  url
              (browse-url url)
              (throw 'done nil)))

          (let ((doi (bibtex-autokey-get-field "doi")))
            (when doi
              (if (string-match "^http" doi)
                  (browse-url doi)
                (browse-url (format "http://dx.doi.org/%s" doi)))
              (throw 'done nil))))))))

(defun org-ref-open-notes-at-point ()
  "open the notes for bibtex key under point."
  (interactive)
  (let* ((results (org-ref-get-bibtex-key-and-file))
	 (key (car results))
	 (bibfile (cdr results)))
    (save-excursion
      (with-temp-buffer
        (insert-file-contents bibfile)
        (bibtex-search-entry key)
        (org-ref-open-bibtex-notes)))))

(defun org-ref-citation-at-point ()
  "give message of current citation at point"
  (interactive)
  (let* ((cb (current-buffer))
	(results (org-ref-get-bibtex-key-and-file))
	(key (car results))
	(bibfile (cdr results)))	
    (message "%s" (progn
		    (with-temp-buffer
                      (insert-file-contents bibfile)
                      (bibtex-search-entry key)
                      (org-ref-bib-citation))))))

(defun org-ref-open-citation-at-point ()
  "open bibtex file to key at point"
  (interactive)
  (let* ((cb (current-buffer))
	(results (org-ref-get-bibtex-key-and-file))
	(key (car results))
	(bibfile (cdr results)))
    (find-file bibfile)
    (bibtex-search-entry key)))

(defun org-ref-cite-onclick-minibuffer-menu (&optional link-string)
  "use a minibuffer to select options for the citation under point.

you select your option with a single key press."
  (interactive)
  (let* ((choice (read-char (org-ref-get-menu-options)))
	 (results (org-ref-get-bibtex-key-and-file))
	 (key (car results))
	 (cb (current-buffer))
         (pdf-file (format (concat org-ref-pdf-directory "%s.pdf") key))
         (bibfile (cdr results)))

    (cond
     ;; open
     ((= choice ?o)
      (find-file bibfile)
       (bibtex-search-entry key))

     ;; cite
     ((= choice ?c)
      (org-ref-citation-at-point))
      

     ;; quit
     ((or 
      (= choice ?q) ; q
      (= choice ?\ )) ; space
      ;; this clears the minibuffer
      (message ""))

     ;; pdf
     ((= choice ?p)
      (org-ref-open-pdf-at-point))

     ;; notes
     ((= choice ?n)
      (org-ref-open-notes-at-point))

     ;; url
     ((= choice ?u)
      (org-ref-open-url-at-point))

     ;; anything else we just quit.
     (t (message "")))))
    

(org-add-link-type
 "autocite"
 'org-ref-cite-onclick-minibuffer-menu
 ;; formatting
 (lambda (keyword desc format)
   (cond
    ((eq format 'html) (format "(<autocite>%s</autocite>)" path))
    ((eq format 'latex)
     (concat "\\autocite{"
	     (mapconcat (lambda (key) key) (org-ref-split-and-strip-string keyword) ",")
	     "}")))))


(org-add-link-type
 "citealp"
 'org-ref-cite-onclick-minibuffer-menu
 ;; formatting
 (lambda (keyword desc format)
   (cond
    ((eq format 'html) (format "(<citealp>%s</citealp>)" path))
    ((eq format 'latex)
     (concat "\\citealp{"
	     (mapconcat (lambda (key) key) (org-ref-split-and-strip-string keyword) ",")
	     "}")))))

(org-add-link-type
 "citet"
 'org-ref-cite-onclick-minibuffer-menu
 ;; formatting
 (lambda (keyword desc format)
   (cond
((eq format 'html) (format "(<cite>%s</cite>)" path))
    ((eq format 'latex)
  (concat "\\citet{" (mapconcat (lambda (key) key) (org-ref-split-and-strip-string keyword) ",") "}")))))

(org-add-link-type
 "citet*"
 'org-ref-cite-onclick-minibuffer-menu
 ;; formatting
 (lambda (keyword desc format)
   (cond
((eq format 'html) (format "(<cite>%s</cite>)" path))
    ((eq format 'latex)
  (concat "\\citet*{" (mapconcat (lambda (key) key) (org-ref-split-and-strip-string keyword) ",") "}")))))

;; TODO these links do not support options [see][]
(org-add-link-type
 "citep"
 'org-ref-cite-onclick-minibuffer-menu
 ;; formatting
 (lambda (keyword desc format)
   (cond
((eq format 'html) (format "(<cite>%s</cite>)" path))
    ((eq format 'latex)
  (concat "\\citep{" (mapconcat (lambda (key) key) (org-ref-split-and-strip-string keyword) ",") "}")))))

(org-add-link-type
 "citep*"
 'org-ref-cite-onclick-minibuffer-menu
 ;; formatting
 (lambda (keyword desc format)
   (cond
((eq format 'html) (format "(<cite>%s</cite>)" path))
    ((eq format 'latex)
  (concat "\\citep*{" (mapconcat (lambda (key) key) (org-ref-split-and-strip-string keyword) ",") "}")))))

(org-add-link-type
 "citeauthor"
 'org-ref-cite-onclick-minibuffer-menu
 ;; formatting
 (lambda (keyword desc format)
   (cond
((eq format 'html) (format "(<cite>%s</cite>)" path))
    ((eq format 'latex)
  (concat "\\citeauthor{" (mapconcat (lambda (key) key) (org-ref-split-and-strip-string keyword) ",") "}")))))

(org-add-link-type
 "citeauthor*"
 'org-ref-cite-onclick-minibuffer-menu
 ;; formatting
 (lambda (keyword desc format)
   (cond
((eq format 'html) (format "(<cite>%s</cite>)" path))
    ((eq format 'latex)
  (concat "\\citeauthor*{" (mapconcat (lambda (key) key) (org-ref-split-and-strip-string keyword) ",") "}")))))

(org-add-link-type
 "citeyear"
 'org-ref-cite-onclick-minibuffer-menu
 ;; formatting
 (lambda (keyword desc format)
   (cond
((eq format 'html) (format "(<cite>%s</cite>)" path))
    ((eq format 'latex)
  (concat "\\citeyear{" (mapconcat (lambda (key) key) (org-ref-split-and-strip-string keyword) ",") "}")))))

(org-add-link-type
 "nocite"
 'org-ref-cite-onclick-minibuffer-menu
 ;; formatting
 (lambda (keyword desc format)
   (cond
((eq format 'html) (format "(<cite>%s</cite>)" path))
    ((eq format 'latex)
  (concat "\\nocite{" (mapconcat (lambda (key) key) (org-ref-split-and-strip-string keyword) ",") "}")))))

(org-add-link-type
 "citetext"
 nil ;; clicking does not make sense
 ;; formatting
 (lambda (keyword desc format)
   (cond
((eq format 'html) (format "(<cite>%s</cite>)" path))
    ((eq format 'latex)
  (concat "\\citetext{" path "}")))))

(defmacro org-ref-make-completion-function (type)
  `(defun ,(intern (format "org-%s-complete-link" type)) (&optional arg)
     (interactive)
     (format "%s:%s" 
	     ,type
	     (completing-read 
	      "bibtex key: " 
	      (let ((bibtex-files (org-ref-find-bibliography)))
		(bibtex-global-key-alist))))))

(defmacro org-ref-make-format-function (type)
  `(defun ,(intern (format "org-ref-format-%s" type)) (keyword desc format)
     (cond
      ((eq format 'html) 
       (mapconcat 
	(lambda (key) 
	  (format "<a href=\"#%s\">%s</a>" key key))
	(org-ref-split-and-strip-string keyword) ","))

      ((eq format 'latex)
       (if (string= (substring type -1) "s")
	   ;; biblatex format for multicite commands, which all end in s. These are formated as \cites{key1}{key2}...
	   (concat "\\" ,type (mapconcat (lambda (key) (format "{%s}"  key))
					 (org-ref-split-and-strip-string keyword) ""))
	 ;; bibtex format
       (concat "\\" ,type (when desc (org-ref-format-citation-description desc)) "{"
	       (mapconcat (lambda (key) key) (org-ref-split-and-strip-string keyword) ",")
	       "}"))))))

(defun org-ref-format-citation-description (desc)
  "return formatted citation description. if the cite link has a description, it is optional text for the citation command. You can specify pre and post text by separating these with ::."
  (interactive)
  (cond
   ((string-match "::" desc)
    (format "[%s][%s]" (car (setq results (split-string desc "::"))) (cadr results)))
   (t (format "[%s]" desc))))

(defun org-ref-define-citation-link (type &optional key)
  "add a citation link for org-ref. With optional key, set the reftex binding. For example:
(org-ref-define-citation-link \"citez\" ?z) will create a new citez link, with reftex key of z, 
and the completion function."
  (interactive "sCitation Type: \ncKey: ")

  ;; create the formatting function
  (eval `(org-ref-make-format-function ,type))

  (eval-expression 
   `(org-add-link-type 
     ,type
     'org-ref-cite-onclick-minibuffer-menu
     (quote ,(intern (format "org-ref-format-%s" type)))))

  ;; create the completion function
  (eval `(org-ref-make-completion-function ,type))
  
  ;; store new type so it works with adding citations, which checks
  ;; for existence in this list
  (add-to-list 'org-ref-cite-types type)

  ;; and finally if a key is specified, we modify the reftex menu
  (when key
    (setf (nth 2 (assoc 'org reftex-cite-format-builtin))
	  (append (nth 2 (assoc 'org reftex-cite-format-builtin)) 
		  `((,key  . ,(concat type ":%l")))))))

;; create all the link types and their completion functions
(mapcar 'org-ref-define-citation-link org-ref-cite-types)

(defun org-ref-insert-cite-link (alternative-cite)
  "Insert a default citation link using reftex. If you are on a link, it
appends to the end of the link, otherwise, a new link is
inserted. Use a prefix arg to get a menu of citation types."
  (interactive "P")
  (org-ref-find-bibliography)
  (let* ((object (org-element-context))
	 (link-string-beginning (org-element-property :begin object))
	 (link-string-end (org-element-property :end object))
	 (path (org-element-property :path object)))  

    (if (not alternative-cite)
	
	(cond
	 ;; case where we are in a link
	 ((and (equal (org-element-type object) 'link) 
	       (-contains? org-ref-cite-types (org-element-property :type object)))
	  (goto-char link-string-end)
	  ;; sometimes there are spaces at the end of the link
	  ;; this code moves point pack until no spaces are there
	  (while (looking-back " ") (backward-char))  
	  (insert (concat "," (mapconcat 'identity (reftex-citation t ?a) ","))))

	 ;; We are next to a link, and we want to append
	 ((save-excursion 
	    (backward-char)
	    (and (equal (org-element-type (org-element-context)) 'link) 
		 (-contains? org-ref-cite-types (org-element-property :type (org-element-context)))))
	  (while (looking-back " ") (backward-char))  
	  (insert (concat "," (mapconcat 'identity (reftex-citation t ?a) ","))))

	 ;; insert fresh link
	 (t 
	  (insert 
	   (concat org-ref-default-citation-link 
		   ":" 
		   (mapconcat 'identity (reftex-citation t) ",")))))

      ;; you pressed a C-u so we run this code
      (reftex-citation)))
  )

(defun org-ref-insert-cite-with-completion (type)
  "Insert a cite link with completion"
  (interactive (list (ido-completing-read "Type: " org-ref-cite-types)))
  (insert (funcall (intern (format "org-%s-complete-link" type)))))

(defun org-ref-store-bibtex-entry-link ()
  "Save a citation link to the current bibtex entry. Saves in the default link type."
  (interactive)
  (let ((link (concat org-ref-default-citation-link 
		 ":"   
		 (save-excursion
		   (bibtex-beginning-of-entry)
		   (reftex-get-bib-field "=key=" (bibtex-parse-entry))))))
    (message "saved %s" link)
    (push (list link) org-stored-links)
    (car org-stored-links)))

(defun org-ref-get-bibtex-keys ()
  "return a list of unique keys in the buffer"
  (interactive)
  (let ((keys '()))
    (org-element-map (org-element-parse-buffer) 'link
      (lambda (link)       
	(let ((plist (nth 1 link)))			     
	  (when (-contains? org-ref-cite-types (plist-get plist ':type))
	    (dolist 
		(key 
		 (org-ref-split-and-strip-string (plist-get plist ':path)))
	      (when (not (-contains? keys key))
		(setq keys (append keys (list key)))))))))
    keys))

(defun org-ref-get-bibtex-entry-html (key)
 (let ((org-ref-bibliography-files (org-ref-find-bibliography))
       (file) (entry))

   (setq file (catch 'result
		(loop for file in org-ref-bibliography-files do
		      (if (org-ref-key-in-file-p key (file-truename file)) 
			  (throw 'result file)))))
   (if file (with-temp-buffer
              (insert-file-contents file)
              (prog1
                  (bibtex-search-entry key nil 0)
                (setq entry  (org-ref-bib-html-citation)))
              (format "<li><a id=\"%s\">[%s] %s</a></li>" key key entry)))))

(defun org-ref-get-html-bibliography ()
  "Create an html bibliography when there are keys"
  (let ((keys (org-ref-get-bibtex-keys)))
    (when keys
      (concat "<h1>Bibliography</h1>
<ul>"
	      (mapconcat (lambda (x) (org-ref-get-bibtex-entry-html x)) keys "\n")
	      "\n</ul>"))))

(defun org-ref-bib-citation ()
  "from a bibtex entry, create and return a simple citation string."

  (bibtex-beginning-of-entry)
  (let* ((cb (current-buffer))
	 (bibtex-expand-strings t)
	 (entry (loop for (key . value) in (bibtex-parse-entry t)
		      collect (cons (downcase key) value)))
	 (title (replace-regexp-in-string "\n\\|\t\\|\s+" " " (reftex-get-bib-field "title" entry)))
	 (year  (reftex-get-bib-field "year" entry))
	 (author (replace-regexp-in-string "\n\\|\t\\|\s+" " " (reftex-get-bib-field "author" entry)))
	 (key (reftex-get-bib-field "=key=" entry))
	 (journal (reftex-get-bib-field "journal" entry))
	 (volume (reftex-get-bib-field "volume" entry))
	 (pages (reftex-get-bib-field "pages" entry))
	 (doi (reftex-get-bib-field "doi" entry))
	 (url (reftex-get-bib-field "url" entry))
	 )
    ;;authors, "title", Journal, vol(iss):pages (year).
    (format "%s, \"%s\", %s, %s:%s (%s)"
	    author title journal  volume pages year)))

(defun org-ref-bib-html-citation ()
  "from a bibtex entry, create and return a simple citation with html links."

  (bibtex-beginning-of-entry)
  (let* ((cb (current-buffer))
	 (bibtex-expand-strings t)
	 (entry (loop for (key . value) in (bibtex-parse-entry t)
		      collect (cons (downcase key) value)))
	 (title (replace-regexp-in-string "\n\\|\t\\|\s+" " " (reftex-get-bib-field "title" entry)))
	 (year  (reftex-get-bib-field "year" entry))
	 (author (replace-regexp-in-string "\n\\|\t\\|\s+" " " (reftex-get-bib-field "author" entry)))
	 (key (reftex-get-bib-field "=key=" entry))
	 (journal (reftex-get-bib-field "journal" entry))
	 (volume (reftex-get-bib-field "volume" entry))
	 (pages (reftex-get-bib-field "pages" entry))
	 (doi (reftex-get-bib-field "doi" entry))
	 (url (reftex-get-bib-field "url" entry))
	 )
    ;;authors, "title", Journal, vol(iss):pages (year).
    (concat (format "%s, \"%s\", %s, %s:%s (%s)."
		    author title journal  volume pages year)
	    (when url (format " <a href=\"%s\">link</a>" url))
	    (when doi (format " <a href=\"http://dx.doi.org/%s\">doi</a>" doi)))
    ))

(defun org-ref-open-bibtex-pdf ()
  "open pdf for a bibtex entry, if it exists. assumes point is in
the entry of interest in the bibfile. but does not check that."
  (interactive)
  (save-excursion
    (bibtex-beginning-of-entry)
    (let* ((bibtex-expand-strings t)
           (entry (bibtex-parse-entry t))
           (key (reftex-get-bib-field "=key=" entry))
           (pdf (format (concat org-ref-pdf-directory "%s.pdf") key)))
      (message "%s" pdf)
      (if (file-exists-p pdf)
          (org-open-link-from-string (format "[[file:%s]]" pdf))
        (ding)))))

(defun org-ref-open-bibtex-notes ()
  "from a bibtex entry, open the notes if they exist, and create a heading if they do not.

I never did figure out how to use reftex to make this happen
non-interactively. the reftex-format-citation function did not
work perfectly; there were carriage returns in the strings, and
it did not put the key where it needed to be. so, below I replace
the carriage returns and extra spaces with a single space and
construct the heading by hand."
  (interactive)

  (bibtex-beginning-of-entry)
  (let* ((cb (current-buffer))
	 (bibtex-expand-strings t)
	 (entry (loop for (key . value) in (bibtex-parse-entry t)
		      collect (cons (downcase key) value)))
	 (title (replace-regexp-in-string "\n\\|\t\\|\s+" " " (reftex-get-bib-field "title" entry)))
	 (year  (reftex-get-bib-field "year" entry))
	 (author (replace-regexp-in-string "\n\\|\t\\|\s+" " " (reftex-get-bib-field "author" entry)))
	 (key (reftex-get-bib-field "=key=" entry))
	 (journal (reftex-get-bib-field "journal" entry))
	 (volume (reftex-get-bib-field "volume" entry))
	 (pages (reftex-get-bib-field "pages" entry))
	 (doi (reftex-get-bib-field "doi" entry))
	 (url (reftex-get-bib-field "url" entry))
	 )

    ;; save key to clipboard to make saving pdf later easier by pasting.
    (with-temp-buffer
      (insert key)
      (kill-ring-save (point-min) (point-max)))
    
    ;; now look for entry in the notes file
    (if  org-ref-bibliography-notes
	(find-file org-ref-bibliography-notes)
      (error "org-ref-bib-bibliography-notes is not set to anything"))
    
    (goto-char (point-min))
    ;; put new entry in notes if we don't find it.
    (unless (re-search-forward (format ":Custom_ID: %s$" key) nil 'end)
      (insert (format "\n** TODO %s - %s" year title))
      (insert (format"
 :PROPERTIES:
  :Custom_ID: %s
  :AUTHOR: %s
  :JOURNAL: %s
  :YEAR: %s
  :VOLUME: %s
  :PAGES: %s
  :DOI: %s
  :URL: %s
 :END:
[[cite:%s]] [[file:%s/%s.pdf][pdf]]\n\n"
key author journal year volume pages doi url key org-ref-pdf-directory key))
(save-buffer))))

(defun org-ref-open-in-browser ()
  "Open the bibtex entry at point in a browser using the url field or doi field"
(interactive)
(save-excursion
  (bibtex-beginning-of-entry)
  (catch 'done
    (let ((url (bibtex-autokey-get-field "url")))
      (when  url
        (browse-url url)
        (throw 'done nil)))

    (let ((doi (bibtex-autokey-get-field "doi")))
      (when doi
        (if (string-match "^http" doi)
            (browse-url doi)
          (browse-url (format "http://dx.doi.org/%s" doi)))
        (throw 'done nil)))
    (message "No url or doi found"))))

(defun org-ref-upload-bibtex-entry-to-citeulike ()
  "with point in  a bibtex entry get bibtex string and submit to citeulike.

Relies on the python script /upload_bibtex_citeulike.py being in the user directory."
  (interactive)
  (message "uploading to citeulike")
  (save-restriction
    (bibtex-narrow-to-entry)
    (let ((startpos (point-min))
          (endpos (point-max))
          (bibtex-string (buffer-string))
          (script (concat "python " starter-kit-dir "/upload_bibtex_citeulike.py&")))
      (with-temp-buffer (insert bibtex-string)
                        (shell-command-on-region (point-min) (point-max) script t nil nil t)))))

(defun org-ref-build-full-bibliography ()
  "build pdf of all bibtex entries, and open it."
  (interactive)
  (let* ((bibfile (file-name-nondirectory (buffer-file-name)))
	(bib-base (file-name-sans-extension bibfile))
	(texfile (concat bib-base ".tex"))
	(pdffile (concat bib-base ".pdf")))
    (find-file texfile)
    (erase-buffer)
    (insert (format "\\documentclass[12pt]{article}
\\usepackage[version=3]{mhchem}
\\usepackage{url}
\\usepackage[numbers]{natbib}
\\usepackage[colorlinks=true, linkcolor=blue, urlcolor=blue, pdfstartview=FitH]{hyperref}
\\usepackage{doi}
\\begin{document}
\\nocite{*}
\\bibliographystyle{unsrtnat}
\\bibliography{%s}
\\end{document}" bib-base))
    (save-buffer)
    (shell-command (concat "pdflatex " bib-base))
    (shell-command (concat "bibtex " bib-base))
    (shell-command (concat "pdflatex " bib-base))
    (shell-command (concat "pdflatex " bib-base))
    (kill-buffer texfile)
    (org-open-file pdffile)
    )) 

(defun org-ref-extract-bibtex-entries ()
  "extract the bibtex entries referred to by cite links in the current buffer into a src block at the bottom of the current buffer.

If no bibliography is in the buffer the `reftex-default-bibliography' is used."
  (interactive)
  (let* ((temporary-file-directory (file-name-directory (buffer-file-name)))
         (tempname (make-temp-file "extract-bib"))
         (contents (buffer-string))
         (cb (current-buffer))
	 basename texfile bibfile results)
    
    ;; open tempfile and insert org-buffer contents
    (find-file tempname)
    (insert contents)
    (setq basename (file-name-sans-extension 
		    (file-name-nondirectory buffer-file-name))
	  texfile (concat tempname ".tex")
	  bibfile (concat tempname ".bib"))
    
    ;; see if we have a bibliography, and insert the default one if not.
    (save-excursion
      (goto-char (point-min))
      (unless (re-search-forward "^bibliography:" (point-max) 'end)
	(insert (format "\nbibliography:%s" 
			(mapconcat 'identity reftex-default-bibliography ",")))))
    (save-buffer)

    ;; get a latex file and extract the references
    (org-latex-export-to-latex)
    (find-file texfile)
    (reftex-parse-all)
    (reftex-create-bibtex-file bibfile)
    (save-buffer)
    ;; save results of the references
    (setq results (buffer-string))

    ;; kill buffers. these are named by basename, not full path
    (kill-buffer (concat basename ".bib"))
    (kill-buffer (concat basename ".tex"))
    (kill-buffer basename)

    (delete-file bibfile)
    (delete-file texfile)
    (delete-file tempname)

    ;; Now back to the original org buffer and insert the results
    (switch-to-buffer cb)
    (when (not (string= "" results))
      (save-excursion
        (goto-char (point-max))
        (insert "\n\n")
	(org-insert-heading)
	(insert (format " Bibtex entries

#+BEGIN_SRC text :tangle %s
%s
#+END_SRC" (concat (file-name-sans-extension (file-name-nondirectory (buffer-file-name))) ".bib") results))))))

(require 'cl)

(defun index (substring list)
  "return the index of string in a list of strings"
  (let ((i 0)
	(found nil))
    (dolist (arg list i)
      (if (string-match substring arg)
	  (progn 
	    (setq found t)
	    (return i)))
      (setq i (+ i 1)))
    ;; return counter if found, otherwise return nil
    (if found i nil)))


(defun org-ref-find-bad-citations ()
  "Create a list of citation keys in an org-file that do not have a bibtex entry in the known bibtex files.

Makes a new buffer with clickable links."
  (interactive)
  ;; generate the list of bibtex-keys and cited keys
  (let* ((bibtex-files (org-ref-find-bibliography))
         (bibtex-file-path (mapconcat (lambda (x) (file-name-directory (file-truename x))) bibtex-files ":"))
	 (bibtex-keys (mapcar (lambda (x) (car x)) (bibtex-global-key-alist)))
	 (bad-citations '()))

    (org-element-map (org-element-parse-buffer) 'link
      (lambda (link)       
	(let ((plist (nth 1 link)))			     
	  (when (equal (plist-get plist ':type) "cite")
	    (dolist (key (org-ref-split-and-strip-string (plist-get plist ':path)) )
	      (when (not (index key bibtex-keys))
		(setq bad-citations (append bad-citations
					    `(,(format "%s [[elisp:(progn (switch-to-buffer-other-frame \"%s\")(goto-char %s))][not found here]]\n"
						       key (buffer-name)(plist-get plist ':begin)))))
		))))))

    (if bad-citations
      (progn
	(switch-to-buffer-other-window "*Missing citations*")
	(org-mode)
	(erase-buffer)
	(insert "* List of bad cite links\n")
	(insert (mapconcat 'identity bad-citations ""))
					;(setq buffer-read-only t)
	(use-local-map (copy-keymap org-mode-map))
	(local-set-key "q" #'(lambda () (interactive) (kill-buffer))))
      (message "No bad cite links found"))))

(defun org-ref-find-non-ascii-characters ()
  "finds non-ascii characters in the buffer. Useful for cleaning up bibtex files"
  (interactive)
  (occur "[^[:ascii:]]"))

(defun org-ref-sort-bibtex-entry ()
  "sort fields of entry in standard order and downcase them"
  (interactive)
  (bibtex-beginning-of-entry)
  (let* ((master '("author" "title" "journal" "volume" "number" "pages" "year" "doi" "url"))
	 (entry (bibtex-parse-entry))
	 (entry-fields)
	 (other-fields)
	 (type (cdr (assoc "=type=" entry)))
	 (key (cdr (assoc "=key=" entry))))

    ;; these are the fields we want to order that are in this entry
    (setq entry-fields (mapcar (lambda (x) (car x)) entry))
    ;; we do not want to reenter these fields
    (setq entry-fields (remove "=key=" entry-fields))
    (setq entry-fields (remove "=type=" entry-fields))

    ;;these are the other fields in the entry
    (setq other-fields (remove-if-not (lambda(x) (not (member x master))) entry-fields))

    (cond
     ;; right now we only resort articles
     ((string= (downcase type) "article") 
      (bibtex-kill-entry)
      (insert
       (concat "@article{" key ",\n" 
	       (mapconcat  
		(lambda (field) 
		  (when (member field entry-fields)
		    (format "%s = %s," (downcase field) (cdr (assoc field entry))))) master "\n")
	       (mapconcat 
		(lambda (field) 
		  (format "%s = %s," (downcase field) (cdr (assoc field entry)))) other-fields "\n")
	       "\n}\n\n"))
      (bibtex-find-entry key)
      (bibtex-fill-entry)
      (bibtex-clean-entry)
       ))))

(defun org-ref-clean-bibtex-entry(&optional keep-key)
  "clean and replace the key in a bibtex function. When keep-key is t, do not replace it. You can use a prefix to specify the key should be kept"
  (interactive "P")
  (bibtex-beginning-of-entry) 
(end-of-line)
  ;; some entries do not have a key or comma in first line. We check and add it, if needed.
  (unless (string-match ",$" (thing-at-point 'line))
    (end-of-line)
    (insert ","))

  ;; check for empty pages, and put eid or article id in its place
  (let ((entry (bibtex-parse-entry))
	(pages (bibtex-autokey-get-field "pages"))
	(year (bibtex-autokey-get-field "year"))
        (doi  (bibtex-autokey-get-field "doi"))
        ;; The Journal of Chemical Physics uses eid
	(eid (bibtex-autokey-get-field "eid")))

    ;; replace http://dx.doi.org/ in doi. some journals put that in,
    ;; but we only want the doi.
    (when (string-match "^http://dx.doi.org/" doi)
      (bibtex-beginning-of-entry)
      (goto-char (car (cdr (bibtex-search-forward-field "doi" t))))
      (bibtex-kill-field)
      (bibtex-make-field "doi")
      (backward-char)
      (insert (replace-regexp-in-string "^http://dx.doi.org/" "" doi)))

    ;; asap articles often set year to 0, which messes up key
    ;; generation. fix that.
    (when (string= "0" year)  
      (bibtex-beginning-of-entry)
      (goto-char (car (cdr (bibtex-search-forward-field "year" t))))
      (bibtex-kill-field)
      (bibtex-make-field "year")
      (backward-char)
      (insert (read-string "Enter year: ")))

    ;; fix pages if they are empty if there is an eid to put there.
    (when (string= "-" pages)
      (when eid	  
	(bibtex-beginning-of-entry)
	;; this seems like a clunky way to set the pages field.But I
	;; cannot find a better way.
	(goto-char (car (cdr (bibtex-search-forward-field "pages" t))))
	(bibtex-kill-field)
	(bibtex-make-field "pages")
	(backward-char)
	(insert eid)))

    ;; replace naked & with \&
    (save-restriction
      (bibtex-narrow-to-entry)
      (bibtex-beginning-of-entry)
      (message "checking &")
      (replace-regexp " & " " \\\\& ")
      (widen))

    ;; generate a key, and if it duplicates an existing key, edit it.
    (unless keep-key
      (let ((key (bibtex-generate-autokey)))

	;; first we delete the existing key
	(bibtex-beginning-of-entry)
	(re-search-forward bibtex-entry-maybe-empty-head)
	(if (match-beginning bibtex-key-in-head)
	    (delete-region (match-beginning bibtex-key-in-head)
			   (match-end bibtex-key-in-head)))
	;; check if the key is in the buffer
	(when (save-excursion
		(bibtex-search-entry key))
	  (save-excursion
	    (bibtex-search-entry key)
	    (bibtex-copy-entry-as-kill)
	    (switch-to-buffer-other-window "*duplicate entry*")
	    (bibtex-yank))
	  (setq key (bibtex-read-key "Duplicate Key found, edit: " key)))

	(insert key)
	(kill-new key))) ;; save key for pasting	    

    ;; run hooks. each of these operates on the entry with no arguments.
    ;; this did not work like  i thought, it gives a symbolp error.
    ;; (run-hooks org-ref-clean-bibtex-entry-hook)
    (mapcar (lambda (x)
	      (save-restriction
		(save-excursion
		  (funcall x))))
	    org-ref-clean-bibtex-entry-hook)
    
    ;; sort fields within entry
    (org-ref-sort-bibtex-entry)
    ;; check for non-ascii characters
    (occur "[^[:ascii:]]")
    ))

(defun org-ref-get-citation-year (key)
  "get the year of an entry with key. Returns year as a string."
  (interactive)
  (let* ((results (org-ref-get-bibtex-key-and-file key))
	 (bibfile (cdr results)))
    (with-temp-buffer
      (insert-file-contents bibfile)
      (bibtex-search-entry key nil 0)
      (prog1 (reftex-get-bib-field "year" (bibtex-parse-entry t))
        ))))

(defun org-ref-sort-citation-link ()
 "replace link at point with sorted link by year"
 (interactive)
 (let* ((object (org-element-context))	 
        (type (org-element-property :type object))
	(begin (org-element-property :begin object))
	(end (org-element-property :end object))
	(link-string (org-element-property :path object))
	keys years data)
  (setq keys (org-ref-split-and-strip-string link-string))
  (setq years (mapcar 'org-ref-get-citation-year keys)) 
  (setq data (mapcar* (lambda (a b) `(,a . ,b)) years keys))
  (setq data (cl-sort data (lambda (x y) (< (string-to-int (car x)) (string-to-int (car y))))))
  ;; now get the keys separated by commas
  (setq keys (mapconcat (lambda (x) (cdr x)) data ","))
  ;; and replace the link with the sorted keys
  (cl--set-buffer-substring begin end (concat type ":" keys))))

(defun org-ref-swap-keys (i j keys)
 "swap the keys in a list with index i and j"
 (let ((tempi (nth i keys)))
   (setf (nth i keys) (nth j keys))
   (setf (nth j keys) tempi))
  keys)

(defun org-ref-swap-citation-link (direction)
 "move citation at point in direction +1 is to the right, -1 to the left"
 (interactive)
 (let* ((object (org-element-context))	 
        (type (org-element-property :type object))
	(begin (org-element-property :begin object))
	(end (org-element-property :end object))
	(link-string (org-element-property :path object))
	key keys i)
   ;;   We only want this to work on citation links
   (when (-contains? org-ref-cite-types type)
        (setq key (org-ref-get-bibtex-key-under-cursor))
	(setq keys (org-ref-split-and-strip-string link-string))
        (setq i (index key keys))  ;; defined in org-ref
	(if (> direction 0) ;; shift right
	    (org-ref-swap-keys i (+ i 1) keys)
	  (org-ref-swap-keys i (- i 1) keys))	
	(setq keys (mapconcat 'identity keys ","))
	;; and replace the link with the sorted keys
	(cl--set-buffer-substring begin end (concat type ":" keys))
	;; now go forward to key so we can move with the key
	(re-search-forward key) 
	(goto-char (match-beginning 0)))))

;; add hooks to make it work
(add-hook 'org-shiftright-hook (lambda () (org-ref-swap-citation-link 1)))
(add-hook 'org-shiftleft-hook (lambda () (org-ref-swap-citation-link -1)))

(defalias 'oro 'org-ref-open-citation-at-point)
(defalias 'orc 'org-ref-citation-at-point)
(defalias 'orp 'org-ref-open-pdf-at-point)
(defalias 'oru 'org-ref-open-url-at-point)
(defalias 'orn 'org-ref-open-notes-at-point)

(defalias 'orib 'org-ref-insert-bibliography-link)
(defalias 'oric 'org-ref-insert-cite-link)
(defalias 'orir 'org-ref-insert-ref-link)
(defalias 'orsl 'org-ref-store-bibtex-entry-link)

(defalias 'orcb 'org-ref-clean-bibtex-entry)

(provide 'org-ref)