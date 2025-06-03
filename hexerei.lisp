#|
 __                                  __ 
  .uef^"                                                                 @88>  
:d88E                     uL   ..                 .u    .                %8P   
`888E            .u     .@88b  @88R      .u     .d88B :@8c       .u       .    
 888E .z8k    ud8888.  '"Y888k/"*P    ud8888.  ="8888f8888r   ud8888.   .@88u  
 888E~?888L :888'8888.    Y888L     :888'8888.   4888>'88"  :888'8888. ''888E` 
 888E  888E d888 '88%"     8888     d888 '88%"   4888> '    d888 '88%"   888E  
 888E  888E 8888.+"        `888N    8888.+"      4888>      8888.+"      888E  
 888E  888E 8888L       .u./"888&   8888L       .d888L .+   8888L        888E  
 888E  888E '8888c. .+ d888" Y888*" '8888c. .+  ^"8888*"    '8888c. .+   888&  
m888N= 888>  "88888%   ` "Y   Y"     "88888%       "Y"       "88888%     R888" 
 `Y"   888     "YP'                    "YP'                    "YP'       ""   
      J88"                                                                     
      @%                                                                       
    :"                                                                         

|#

(defpackage :hexerei
  (:use :cl :alexandria :local-time)
  (:export :main))

(in-package :hexerei)

(defvar *raw* nil "Raw transaction data")
(defvar *pointer* 0 "Current position in raw data")

(defun print-help ()
  (format t "Usage: ords.lisp [OPTIONS] [TX_FILE|TX_ID]~%~%")
  (format t "Parse and output the ordinal inscription inside transaction~%~%")
  (format t "Positional Arguments:~%")
  (format t "  TX_FILE              input raw transaction file or transaction ID with txid~%~%")
  (format t "Options:~%")
  (format t "  -du, data-uri         print inscription as data-uri instead of writing to a file~%")
  (format t "  -o, output FILE       write inscription to specified output file~%")
  (format t "  -tx, txid             get transaction data from URL instead of a file~%")
  (format t "  -h, help              show this help message and exit~%")
  (uiop:quit 0))

(defun parse-command-line-arguments ()
  (let* ((args (uiop:command-line-arguments))
         (options '("-du" "data-uri" "-o" "output" "-tx" "txid" "-h" "help"))
         (valid-args (list))
         (tx-file nil)
         (i 0))
    (loop while (< i (length args))
          for arg = (nth i args)
          do (cond
               ((member arg '("-h" "help") :test #'string=)
                (print-help))
               ((member arg options :test #'string=)
                (push arg valid-args)
                (when (member arg '("-o" "output") :test #'string=)
                  (if (< (1+ i) (length args))
                      (progn
                        (push (nth (1+ i) args) valid-args)
                        (incf i 2))
                      (progn
                        (format t "Error: 'output' requires a file argument~%")
                        (print-help)
                        (uiop:quit 1))))
                (incf i))
               (t
                (if tx-file
                    (progn
                      (format t "Unknown or invalid argument: ~a~%" arg)
                      (print-help)
                      (uiop:quit 1))
                    (progn
                      (setf tx-file arg)
                      (push arg valid-args)
                      (incf i))))))
    (loop for arg in args
          unless (member arg valid-args :test #'string=)
          do (format t "Unknown or invalid argument: ~a~%" arg)
             (print-help)
             (uiop:quit 1))
    (list :tx-file tx-file
          :data-uri (or (member "-du" args :test #'string=)
                        (member "data-uri" args :test #'string=))
          :output (or (second (member "-o" args :test #'string=))
                      (second (member "output" args :test #'string=)))
          :txid (or (member "-tx" args :test #'string=)
                    (member "txid" args :test #'string=)))))

(defun hex-to-bytes (hex-string)
  (let* ((len (length hex-string))
         (result (make-array (/ len 2) :element-type '(unsigned-byte 8))))
    (loop for i from 0 below len by 2
          for j from 0
          do (setf (aref result j)
                   (parse-integer hex-string :start i :end (+ i 2) :radix 16)))
    result))

(defun read-raw-data (tx-file)
  (with-open-file (stream tx-file :direction :input)
    (let ((hex-string (read-line stream)))
      (hex-to-bytes hex-string))))

(defun fetch-raw-data-from-url (tx-id)
  (format t "Fetching txid: ~a~%" tx-id)
  (multiple-value-bind (body status headers)
      (drakma:http-request (format nil "https://mempool.space/api/tx/~a/hex" tx-id)
                           :want-stream nil)
    (format t "API response status: ~d~%" status)
    (format t "API response headers: ~a~%" headers)
    (unless (= status 200)
      (format *error-output* "Failed to fetch data: ~d - Response: ~a~%" status body)
      (uiop:quit 1))
    (hex-to-bytes body)))

(defun read-bytes (n)
  (prog1
      (subseq *raw* *pointer* (+ *pointer* n))
    (incf *pointer* n)))

(defun get-initial-position ()
  (let ((inscription-mark (hex-to-bytes "0063036f7264")))
    (let ((pos (search inscription-mark *raw*)))
      (unless pos
        (format *error-output* "No ordinal inscription found in transaction~%")
        (uiop:quit 1))
      (format t "Found inscription marker at position: ~d~%" pos)
      (format t "Bytes before marker: ~{#x~2,'0x~}~%"
              (coerce (subseq *raw* (max 0 (- pos 10)) pos) 'list))
      (format t "Bytes after marker: ~{#x~2,'0x~}~%"
              (coerce (subseq *raw* pos (min (length *raw*) (+ pos 22))) 'list))
      (+ pos (length inscription-mark)))))

(defun read-content-type ()
  (let ((byte (read-bytes 1)))
    (format t "First byte after marker: ~{#x~2,'0x~}~%" (coerce byte 'list))
    (unless (or (equalp byte #(81))
                (equalp byte #(1)))
      (let ((next-byte (read-bytes 1)))
        (format *error-output* "Invalid prefix at position ~d: got ~{#x~2,'0x~} ~{#x~2,'0x~}, expected 0x51 or 0x01~%"
                (- *pointer* 2) (coerce byte 'list) (coerce next-byte 'list))
        (uiop:quit 1)))
    (when (equalp byte #(1))
      (let ((next-byte (read-bytes 1)))
        (unless (equalp next-byte #(1))
          (format *error-output* "Invalid second byte at position ~d: got ~{#x~2,'0x~}, expected 0x01~%"
                  (- *pointer* 1) (coerce next-byte 'list))
          (uiop:quit 1))))
    (let* ((size (aref (read-bytes 1) 0))
           (content-type (read-bytes size)))
      (format t "Content type size: ~d~%" size)
      (flexi-streams:octets-to-string content-type :external-format :utf-8))))

(defun nreverse-bytes (bytes)
  (reduce #'(lambda (acc byte) (+ (ash acc 8) byte))
          (nreverse bytes) :initial-value 0))

(defun read-pushdata (opcode)
  (let ((int-opcode (aref opcode 0)))
    (cond
      ((<= 1 int-opcode #x4b)
       (let ((bytes (read-bytes int-opcode)))
         (loop for i below int-opcode
               collect (aref bytes i))))
      ((= int-opcode #x4c)
       (let ((size (aref (read-bytes 1) 0)))
         (let ((bytes (read-bytes size)))
           (loop for i below size
                 collect (aref bytes i)))))
      ((= int-opcode #x4d)
       (let ((size (nreverse-bytes (read-bytes 2))))
         (let ((bytes (read-bytes size)))
           (loop for i below size
                 collect (aref bytes i)))))
      ((= int-opcode #x4e)
       (let ((size (nreverse-bytes (read-bytes 4))))
         (let ((bytes (read-bytes size)))
           (loop for i below size
                 collect (aref bytes i)))))
      (t
       (format *error-output* "Invalid push opcode #x~x at position ~d~%"
               int-opcode *pointer*)
       (uiop:quit 1)))))

(defun write-data-uri (data content-type)
  (let ((base64-string (cl-base64:usb8-array-to-base64-string data)))
    (format t "data:~a;base64,~a~%" content-type base64-string)))

(defun get-file-extension (content-type)
  (alexandria:switch (content-type :test #'string=)
    ("image/png" "png")
    ("image/jpeg" "jpg")
    ("image/gif" "gif")
    ("image/webp" "webp")    
    ("application/pdf" "pdf")
    ("text/plain" "txt")
    ("text/plain;charset=utf-8" "txt")
    ("text/html;charset=utf-8" "html")
    (t "bin")))

(defun write-file (data content-type output)
  (let* ((base-filename (or output
                            (format-timestring nil (now)
                                               :format '(:year :month :day "-" :hour :min :sec))))
         (extension (get-file-extension content-type))
         (filename (format nil "~a.~a" base-filename extension)))
    (loop while (probe-file filename)
          for i from 1
          do (setf filename (format nil "~a_~d.~a" base-filename i extension)))
    (format t "Writing contents to file \"~a\"~%" filename)
    (with-open-file (f filename :direction :output
                                :if-exists :supersede
                                :element-type '(unsigned-byte 8))
      (write-sequence data f))))

(defun main ()
  (let ((args (parse-command-line-arguments)))
    (unless (getf args :tx-file)
      (format *error-output* "Error: Transaction file or ID must be provided.~%")
      (print-help)
      (uiop:quit 1))
    (setf *raw*
          (if (getf args :txid)
              (progn
                (unless (and (stringp (getf args :tx-file)) (> (length (getf args :tx-file)) 0))
                  (format *error-output* "Error: Invalid transaction ID: ~a~%" (getf args :tx-file))
                  (print-help)
                  (uiop:quit 1))
                (fetch-raw-data-from-url (getf args :tx-file)))
              (progn
                (unless (probe-file (getf args :tx-file))
                  (format *error-output* "Error: File does not exist: ~a~%" (getf args :tx-file))
                  (print-help)
                  (uiop:quit 1))
                (read-raw-data (getf args :tx-file)))))
    (setf *pointer* (get-initial-position))
    
    (let* ((content-type (read-content-type)))
      (format t "Content type: ~a~%" content-type)
      (assert (equalp (read-bytes 1) #(0)))
      
      (let ((data (make-array 0 :element-type '(unsigned-byte 8) :adjustable t :fill-pointer 0))
            (op-endif #(104)))
        (loop with opcode = (read-bytes 1)
              until (equalp opcode op-endif)
              do (dolist (byte (read-pushdata opcode))
                   (vector-push-extend byte data))
                 (setf opcode (read-bytes 1)))
        
        (format t "Total size: ~d bytes~%" (length data))
        (if (getf args :data-uri)
            (write-data-uri data content-type)
            (write-file data content-type (getf args :output))))
      (format t "~%Done~%")))
  (uiop:quit 0))
