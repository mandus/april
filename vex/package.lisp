;;; -*- Mode:Lisp; Syntax:ANSI-Common-Lisp; Coding:utf-8; Package:Vex -*-
;;;; package.lisp

(defpackage #:vex
  (:export #:local-idiom #:vex-program #:ambivalent #:monadic #:dyadic #:reverse-op #:boolean-op
           #:reverse-boolean-op #:args #:of-overloaded? #:composer #:set-composer-elements
           #:set-composer-patterns #:get-system-meta #:set-system-meta #:specify-vex-idiom
           #:extend-vex-idiom #:of-lexicon #:of-lexicons #:idiom-symbols #:ws-assign-fun #:ws-assign-val)
  (:use #:cl #:alexandria #:maxpc #:cl-ppcre #:symbol-munger #:prove))

