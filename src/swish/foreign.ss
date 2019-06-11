;;; Copyright 2019 Beckman Coulter, Inc.
;;;
;;; Permission is hereby granted, free of charge, to any person
;;; obtaining a copy of this software and associated documentation
;;; files (the "Software"), to deal in the Software without
;;; restriction, including without limitation the rights to use, copy,
;;; modify, merge, publish, distribute, sublicense, and/or sell copies
;;; of the Software, and to permit persons to whom the Software is
;;; furnished to do so, subject to the following conditions:
;;;
;;; The above copyright notice and this permission notice shall be
;;; included in all copies or substantial portions of the Software.
;;;
;;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;;; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
;;; HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
;;; WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
;;; DEALINGS IN THE SOFTWARE.

(library (swish foreign)
  (export
   provide-shared-object
   require-shared-object)
  (import
   (scheme)
   (swish app-io)
   (swish erlang)
   (swish io)
   (swish json))

  (define (so-path so-name . more)
    `(swish shared-object ,(string->symbol so-name) ,(machine-type)
       ,@more))

  (define (provide-shared-object so-name filename)
    (unless (string? so-name) (bad-arg 'provide-shared-object so-name))
    (unless (string? filename) (bad-arg 'provide-shared-object filename))
    (json:update! (app:config) (so-path so-name 'file) values filename))

  (define require-shared-object
    (case-lambda
     [(so-name)
      (require-shared-object so-name
        (lambda (filename key dict)
          (load-shared-object filename)))]
     [(so-name handler)
      (unless (string? so-name) (bad-arg 'require-shared-object so-name))
      (unless (procedure? handler) (bad-arg 'require-shared-object handler))
      (let* ([dict (json:ref (app:config) (so-path so-name) #f)]
             [file (and (hashtable? dict) (hashtable-ref dict 'file #f))])
        (unless (string? file)
          (raise `#(unknown-shared-object ,so-name)))
        (match (catch (handler (resolve file) so-name dict))
          [#(EXIT ,reason) (raise `#(cannot-load-shared-object ,so-name ,reason))]
          [,_ (void)]))]))

  (define (resolve path)
    (if (path-absolute? path)
        path
        (get-real-path (path-combine (path-parent (app:config-filename)) path))))

  )