(defpackage :lem-vi-mode/tests/operator
  (:use :cl
        :lem
        :rove
        :lem-vi-mode/tests/utils)
  (:import-from :lem-fake-interface
                :with-fake-interface)
  (:import-from :named-readtables
                :in-readtable))
(in-package :lem-vi-mode/tests/operator)

(in-readtable :interpol-syntax)

(deftest vi-delete
  (with-fake-interface ()
    (with-vi-buffer (#?"a[b]c\ndef\nghi\njkl\n")
      (cmd "dd")
      (ok (buf= #?"d[e]f\nghi\njkl\n"))
      (cmd "dd")
      (ok (buf= #?"g[h]i\njkl\n"))
      (cmd "p")
      (ok (buf= #?"ghi\n[d]ef\njkl\n"))
      (cmd "2dd")
      (ok (buf= #?"ghi\n[]")))
    (with-vi-buffer (#?"[a]bc\ndef\nghi\njkl\n")
      (cmd "1000dd")
      (ok (buf= "[]")))
    (testing "with vi-forward-word-begin"
      (with-vi-buffer (#?"[a]bc\n  def\n")
        (cmd "dw")
        (ok (buf= #?"[\n]  def\n"))
        (cmd "dw")
        (ok (buf= #?"  [d]ef\n")))
      (with-vi-buffer (#?"abc\n[ ] def\n")
        (cmd "dw")
        (ok (buf= #?"abc\n[d]ef\n"))))
    (testing "daw"
      (with-vi-buffer ("foo b[a]r baz")
        (cmd "daw")
        (ok (buf= "foo [b]az")))
      (with-vi-buffer ("foo bar b[a]z")
        (cmd "daw")
        (ok (buf= "foo ba[r]")))
      (with-vi-buffer ("foo[ ] bar   baz")
        (cmd "daw")
        (ok (buf= "foo[ ]  baz")))
      (with-vi-buffer ("foo b[a]r baz")
        (cmd "2daw")
        (ok (buf= "fo[o]")))
      (with-vi-buffer ("foo b[a]r baz")
        (cmd "d2aw")
        (ok (buf= "fo[o]")))
      (with-vi-buffer ("foo b[a]r baz")
        (cmd "3daw")
        (ok (buf= "foo b[a]r baz")))
      (with-vi-buffer ("f[o]o$bar")
        (cmd "daw")
        (ok (buf= "[$]bar"))
        (cmd "daw")
        (ok (buf= "[b]ar")))
      (with-vi-buffer (#?"[]\n foo bar\n")
        (cmd "daw")
        (ok (buf= #?"[ ]bar\n"))))
    (testing "diw"
      (with-vi-buffer ("foo b[a]r baz")
        (cmd "diw")
        (ok (buf= "foo [ ]baz"))
        (cmd "diw")
        (ok (buf= "foo[b]az")))
      (with-vi-buffer ("foo b[a]r baz")
        (cmd "2diw")
        (ok (buf= "foo [b]az"))
        (cmd "2diw")
        (ok (buf= "foo [b]az")))
      (with-vi-buffer ("f[o]o$bar")
        (cmd "diw")
        (ok (buf= "[$]bar"))
        (cmd "diw")
        (ok (buf= "[b]ar")))
      (with-vi-buffer (#?"[]\n foo bar\n")
        (cmd "diw")
        (ok (buf= #?"[]\n foo bar\n"))))))

(deftest vi-join-line
  (with-fake-interface ()
    (lem:window-set-size (lem:current-window) 5 24)
    (with-vi-buffer (#?"[a]bcdefgh\nijklmn\n")
      (cmd "J")
      (ok (buf= #?"abcdefgh[ ]ijklmn\n")))))

(deftest vi-repeat
  (with-fake-interface ()
    (with-vi-buffer (#?"[1]:abc\n2:def\n3:ghi\n4:jkl\n5:mno\n6:opq\n7:rst\n8:uvw")
      (cmd "dd")
      (ok (buf= #?"[2]:def\n3:ghi\n4:jkl\n5:mno\n6:opq\n7:rst\n8:uvw"))
      (cmd ".")
      (ok (buf= #?"[3]:ghi\n4:jkl\n5:mno\n6:opq\n7:rst\n8:uvw"))
      (cmd "2.")
      (ok (buf= #?"[5]:mno\n6:opq\n7:rst\n8:uvw")))
    (with-vi-buffer (#?"[1]:abc\n2:def\n3:ghi\n4:jkl\n5:mno\n6:opq\n7:rst\n8:uvw")
      (cmd "2d2d")
      (ok (buf= #?"[5]:mno\n6:opq\n7:rst\n8:uvw"))
      (cmd "2.")
      (ok (buf= #?"[7]:rst\n8:uvw")))
    (with-vi-buffer (#?"[f]oo\nbar\nbaz\n")
      (cmd "A-fighters<Esc>")
      (ok (buf= #?"foo-fighter[s]\nbar\nbaz\n"))
      (cmd "j^.")
      (ok (buf= #?"foo-fighters\nbar-fighter[s]\nbaz\n")))))
