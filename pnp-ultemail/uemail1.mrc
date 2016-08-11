; -----------------------------------------------------
; Peace and Protection (by misspai)
; -----------------------------------------------------
; ADDON: E-Mail (1 of 2)
; -----------------------------------------------------
alias echeck {
  if ($1 == q) { ecancel q ! | set %_+emc.quiet $true }
  else { ecancel ! ! | unset %_+emc.quiet }
  window -c @EMail
  if (%email.pop3 == $null) _error POP3 server not defined- See E-Mail setup
  if (%email.user == $null) _error POP3 account name not defined- See E-Mail setup
  if (%_+emc.quiet) goto pw
  window -l @EMail $_winpos(14%,7%,8%,8%) @EMail %font.basic
  titlebar @EMail check
  aline @EMail $chr(160)
  aline @EMail Checking for new e-mail... (account %email.accnum $+ - %email.account $+ )
  aline @EMail $chr(160)
  :pw
  if (%email.pw == $null) _askr _ech2 E-Mail password?
  else _ech2 $_pwenc(%email.pw)
}
alias _ech2 {
  set %_emc.pw $1
  set %_emc.act c
  .enable #_echeck
  if ($_not(%_+emc.quiet)) aline @EMail Logging in to POP3 server...
  sockopen ULTE-CHECK %email.pop3 110
}
alias ecancel {
  window -c @EWrap | window -c @Progress
  _qlogc $2
  .disable #_echeck #_echecklist #_echeckheader #_echeckget #_echeckgett
  if (($1 == $null) && ($_isopen(@EMail))) .disable #_epopup1 #_epopup2
  unset %_emc.stage %_emc.act %_emc.num %_emc.max %_emc.curr %_emc.prev %_emc.hlog %_emc.plog %_emc.lhead %_+emc.quiet %_emc.glue
  if ($1 != q) .disable #_email-tb
}
alias _qlogc if ($sock(ULTE-*,0) > 0) { sockwrite ULTE-* $eends(QUIT) | if ($1) sockclose ULTE-* | else sockmark ULTE-* DIE }
on 1:sockwrite:ULTE-*:if ($sock($sockname).mark == DIE) sockclose $sockname
alias _echeader {
  if ($window(@EMail) != $null) clear @EMail
  else {
    window -c @EMail
    window -l @EMail $_winpos(14%,7%,8%,8%) @EMail %font.basic
  }
  titlebar @EMail check- headers
  aline @EMail E-Mail waiting-
  aline @EMail $chr(160)
  set %_emc.act h
  .enable #_echeck
  sockopen ULTE-CHECK %email.pop3 110
}
alias _ecsall set %.lp $line(@EMail,0) | :loop | sline -a @EMail %.lp | if ($_vd(.lp) > 0) goto loop
alias _ecdo {
  if (s isin $1) {
    sline -r @EMail 1 | sline -r @EMail 2
    sline -r @EMail $line(@EMail,0)
    sline -r @EMail $calc($line(@EMail,0) - 1)
    sline -r @EMail $calc($line(@EMail,0) - 2)
    if ($sline(@EMail,0) < 1) _error You must select one or more e-mails first!
  }
  titlebar @EMail check- performing operation
  set %_emc.act $1
  if (g isin $1) {
    window @EWrap $_winpos(14%,7%,8%,8%) %font.basic
    window -h @EWrap
  }
  .enable #_echeck
  sockopen ULTE-CHECK %email.pop3 110
}
on 1:close:@EMail:ecancel | unset %_emc.pw
alias _ecnew {
  set %.new 1
  :loop
  set %.win @EMail $+ %.new
  if ($window(%.win) != $null) { inc %.new | goto loop }
  inc %_emc.left
  if ((%_emc.left < 3) || (%_emc.left > 13)) set %_emc.left 3
  set %.left %_emc.left $+ %
  set %.right $calc(16 - %_emc.left) $+ %
  window -ln %.win $_winpos(14%,7%,%.left,%.right) @EMailR %font.basic
  set %_emc.hlog $_ppdir $+ e $+ %.new $+ tmp.txt
  if ($exists(%_emc.hlog)) .remove %_emc.hlog
  return %.win
}
#_echeck off
on 1:sockopen:ULTE-CHECK:{
  if ($sockerr > 0) { if (%_+emc.quiet) halt | _error Error connecting to mail server }
  sockwrite ULTE-CHECK USER $eends(%email.user)
  sockwrite ULTE-CHECK PASS $eends(%_emc.pw)
  set %_emc.stage -1
}
on 1:sockclose:ULTE-CHECK:ecancel | if (%_+emc.quiet) halt | _error Mail server disconnected unexpectedly
on 1:sockread:ULTE-CHECK:{
  :loop
  sockread %.sockdata
  if ($sockbr == 0) return
  if ($left(%.sockdata,3) == +OK) _echeckdo1 %.sockdata
  elseif ($left(%.sockdata,4) == -ERR) { ecancel | _error Error from mail server- %.sockdata }
  else _echeckdo2 %.sockdata
  goto loop
}
alias -l _echeckdo1 {
  if ($_vi(_emc.stage) == 0) halt
  if (%_emc.stage == 1) {
    if (%_emc.act == c) if ($_not(%_+emc.quiet)) aline @EMail User name accepted...
  }
  elseif (%_emc.stage == 2) {
    if (%_emc.act == c) {
      if ($_not(%_+emc.quiet)) aline @EMail Password accepted...
      sockwrite ULTE-CHECK $eends(STAT)
    }
    elseif (%_emc.act == h) sockwrite ULTE-CHECK $eends(LIST)
    elseif ($left(%_emc.act,1) == a) sockwrite ULTE-CHECK $eends(STAT)
    else {
      set %_emc.max $sline(@EMail,0) | set %_emc.num 1
      inc %_emc.stage
      goto doas
    }
  }
  elseif (%_emc.stage == 3) {
    if (%_emc.act == c) {
      if (%_+emc.quiet) { ecancel | _eac.fin 0 $2 $3 | halt }
      ecancel
      if ($2 == 0) aline @EMail No new e-mail detected.
      else {
        aline @EMail --> %col.att $+ $2 <-- e-mail messages waiting ( $+ %col.dark $+ $3 bytes)
        aline @EMail $chr(160)
        aline @EMail Right-click on this window for options, or press F4 to get message headers.
        window -b @EMail
        .enable #_epopup1
      }
    }
    elseif (%_emc.act == h) .enable #_echecklist
    else {
      if ($2 == 0) { ecancel | _error No e-mail to get/delete! }
      set %_emc.max $2 | set %_emc.num 1
      goto doas
    }
  }
  elseif ($left(%_emc.act,1) isin as) {
    :doas
    set %_emc.prev %_emc.curr
    set %_emc.plog %_emc.hlog
    .disable #_echeckgett
    if (%email.get.reverse) {
      if ($left(%_emc.act,1) == a) { set %_emc.curr $calc(%_emc.max - %_emc.num + 1) }
      else { set %_emc.curr $sline(@EMail,$calc(%_emc.max - %_emc.num + 1)).ln | dec %_emc.curr 2 }
    }
    else {
      if ($left(%_emc.act,1) == a) { set %_emc.curr %_emc.num }
      else { set %_emc.curr $sline(@EMail,%_emc.num).ln | dec %_emc.curr 2 }
    }
    if (gd isin %_emc.act) {
      if ($calc(%_emc.stage % 2) == 1) set %.todo g
      else set %.todo d
    }
    else set %.todo $right(%_emc.act,1)
    if (%.todo == g) { sockwrite ULTE-CHECK RETR $eends(%_emc.curr) | set %_emc.curr $_ecnew | .enable #_echeckget }
    else sockwrite ULTE-CHECK DELE $eends(%_emc.curr)
    if ((gd isin %_emc.act) && (%.todo == g)) halt
    if ($_vi(_emc.num) > %_emc.max) set %_emc.act q $+ %_emc.act
  }
  elseif (d isin %_emc.act) {
    if (a isin %_ema.act) window -c @EMail
    else {
      set %.num $sline(@EMail,0)
      :loop
      dline @EMail $sline(@EMail,%.num).ln
      if ($_vd(.num) > 0) goto loop
      if ($line(@Email,0) < 6) window -c @EMail
      if (g isin %_emc.act) {
        if (@EMail !isin $active) dispa E-Mail download completed.
        if ($_isopen(@EMail)) window -n @EMail
      }
    }
    ecancel !
  }
  else {
    set %_emc.prev %_emc.curr
    set %_emc.plog %_emc.hlog
    .disable #_echeckgett
    set %_emc.act %_emc.act $+ z
  }
}
#_echeck end
#_echeckgett off
alias -l _echeckdo2 {
  if ($1- == .) { if ($_not(%email.get.min)) window -ar %_emc.prev | if (z isin %_emc.act) { if (@EMail !isin $active) dispa E-Mail download completed. | window -n @EMail | ecancel ! } }
  elseif ($left($1,1) isin >-) aline $strip($remove(%col.dark,)) %_emc.prev $1-
  elseif ($left($1,1) == .) _domline %_emc.glue $_rchop(1,$1-)
  else _domline %_emc.glue $1-
}
alias _domline2 _domline $1-
alias _domline {
  if (($right($1-,1) == =) || (%_emc.glue != $null)) {
    unset %_emc.glue
    set %.todo $replace($replace($replace($replace($1-,=0D,),=0A,),=92,$chr(146)),=3D,=)
    set %.toks $_numtok(127,%.todo)
    if ($right($1-,1) == =) { dec %.toks | set %.glue $_lchop(1,$_rtok(1,127,%.todo)) }
    else unset %.glue
    set %.todo $_ltok(%.toks,127,%.todo)
    if (%.todo != $null) {
      set %.num0 1
      :loop0
      _domline2 $gettok(%.todo,%.num0,127)
      if ($_vi(.num0) <= %.toks) goto loop0
    }
    set %_emc.glue %.glue
    return
  }
  unset %_emc.glue
  if ($1 == $null) aline %_emc.prev $chr(160)
  elseif ($len($1-) <= 80) aline %_emc.prev $1-
  else {
    echo -h @EWrap $1-
    unset %.pre | set %.num $line(@EWrap,0)
    if (%.num == 1) { aline %_emc.prev $1- | dline @EWrap 1 }
    else {
      :loop
      aline %_emc.prev %.pre $+ $line(@EWrap,1)
      dline @EWrap 1 | if ($_vd(.num) > 0) { set %.pre $str($chr(160),2) | goto loop }
    }
  }
}
#_echeckgett end
#_echeckget off
alias -l _echeckdo2 {
  if ($1- == .) { if ($_not(%email.get.min)) window -ar %_emc.prev | if (z isin %_emc.act) { if (@EMail !isin $active) dispa E-Mail download completed. window -n @EMail | ecancel ! } }
  else {
    if ($1 == $null) { .enable #_echeckgett | aline %_emc.prev $chr(160) | unset %_emc.glue }
    else {
      if (: isin $1) { set %.head $1 | set %.body $2- }
      else { set %.head %_emc.lhead | set %.body $1- }
      write %_emc.plog $1-
      if ((MIME !isin %.head) && (Content- !isin %.head) && (X- !isin %.head) && ($findtok(Received:.Message-ID:.Sender:.Status:.Precedence:,%.head,46) == $null)) aline %col.base %_emc.prev  $+ %.head $+  %.body
      if (%.head == From:) { if (@ isin %.body) _dynpop.rot email 9 %.body | titlebar %_emc.prev $window(%_emc.prev).titlebar - From: %.body }
      elseif (%.head == Subject:) titlebar %_emc.prev - %.body $window(%_emc.prev).titlebar
      elseif ((%.head == Reply-to:) && (@ isin %.body)) _dynpop.rot email 9 %.body
      set %_emc.lhead %.head
    }
  }
}
#_echeckget end
#_echecklist off
alias -l _echeckdo2 {
  if ($1- == .) { .disable #_echecklist | .enable #_echeckheader | set %_emc.num 3 }
  elseif ($2 != $null) { if ($2 > 9999) aline @EMail $chr(160) • %col.dark $+ $1 • %col.att $+ ( $+ $round($calc($2 / 1024),1) $+ k) • | else aline @EMail $chr(160) • %col.dark $+ $1 • ( $+ $2 bytes) • | sockwrite ULTE-CHECK TOP $1 $eends(1) }
}
#_echecklist end
#_echeckheader off
alias -l _echeckdo2 {
  if ($2 != $null) {
    if (From? iswm $1) rline @EMail %_emc.num $line(@EMail,%_emc.num) From: %col.target $+ $2- •
    elseif (Subject? iswm $1) rline @EMail %_emc.num $line(@EMail,%_emc.num) %col.dark $+ $2- •
  }
  elseif ($1 == .) {
    inc %_emc.num
    if ($line(@EMail,%_emc.num) == $null) {
      aline @EMail $chr(160)
      aline @EMail Select one or more e-mails and right-click for options.
      aline @EMail Or, right-click for other options. Press F4 to get all messages. (leaving them on the server)
      window -b @EMail
      ecancel
      .enable #_epopup2
    }
  }
}
#_echeckheader end
#_epopup1 off
menu @EMail {
  Get headers (from/subject):_echeader
  -
  Get all, leave on server:_ecdo ag
  Get all, delete from server:_ecdo agd
  Delete all messages:_ecdo ad
  -
  Close + cancel:ecancel | window -c @EMail
}
#_epopup1 end
#_epopup2 off
menu @EMail {
  Get selected, leave on server:_ecdo sg
  Get selected, delete from server:_ecdo sgd
  Delete selected:_ecdo sd
  -
  Get all, leave on server:_ecsall | _ecdo sg
  Get all, delete from server:_ecsall | _ecdo sgd
  Delete all messages:_ecsall | _ecdo sd
  -
  Close all incoming email:_cloem
  -
  Close + cancel:ecancel | window -c @EMail
}
#_epopup2 end
menu @EMail {
  Close + cancel:ecancel | window -c @EMail
}
on 1:start:{
  set %.num 1 | :loop
  set %.log $_ppdir $+ e $+ %.num $+ tmp.txt
  if ($exists(%.log)) { .remove %.log | inc %.num | goto loop }
}
menu @EMailR {
  $_exec(set %.bks [ $_mailcfg(Books) ] ):{ }
  Reply
  .Quote none...:_er.reply $active r n
  .Quote all...:_er.reply $active r a
  .Quote selection...:_er.reply $active r s
  Forward
  .Entire e-mail...:_er.reply $active f a
  .Selected text...:_er.reply $active f s
  Misc
  .Add sender to address book
  ..Book 1. $_a2x($_mailcfg(Book1,Name)):_er.abook $active 1
  ..$_tf2any( [ $_if( [ %.bks ] > 1) ] ,Book2.,$null) $_a2x($_mailcfg(Book2,Name)):_er.abook $active 2
  ..$_tf2any( [ $_if( [ %.bks ] > 2) ] ,Book3.,$null) $_a2x($_mailcfg(Book3,Name)):_er.abook $active 3
  ..$_tf2any( [ $_if( [ %.bks ] > 3) ] ,Book4.,$null) $_a2x($_mailcfg(Book4,Name)):_er.abook $active 4
  ..$_tf2any( [ $_if( [ %.bks ] > 4) ] ,More....,$null):_ebsel _er.abook $active Book to add sender to?
  .Extract all e-mails in headers
  ..Book 1. $_a2x($_mailcfg(Book1,Name)):_er.abookx $active 1
  ..$_tf2any( [ $_if( [ %.bks ] > 1) ] ,Book2.,$null) $_a2x($_mailcfg(Book2,Name)):_er.abookx $active 2
  ..$_tf2any( [ $_if( [ %.bks ] > 2) ] ,Book3.,$null) $_a2x($_mailcfg(Book3,Name)):_er.abookx $active 3
  ..$_tf2any( [ $_if( [ %.bks ] > 3) ] ,Book4.,$null) $_a2x($_mailcfg(Book4,Name)):_er.abookx $active 4
  ..$_tf2any( [ $_if( [ %.bks ] > 4) ] ,More....,$null):_ebsel _er.abookx $active Book to extract e-mails to?
  .View headers...:set %.fn $_ppdir $+ e $+ $remove($active,@EMail) $+ tmp.txt | if ($_not($exists(%.fn))) _error Headers file for e-mail missing! | open @Info /esend E-Mail headers | loadbuf @Info %.fn
  .-
  .Save to file...:set %_arhelp _er.export $active . | _askr _arhelp Filename to save mail to?
  .Save to file and edit...:set %_arhelp _er.export $active ! | _askr _arhelp Filename to save mail to?
  -
  Copy
  .One line:clipboard $sline($active,1)
  .Open copy window...:_er.copywin $active
  -
  Close:window -c $active
}
alias _er.abook {
  set %.num 1 | set %.ini Book $+ $2
  :loop1 | if ($left($line($1,%.num),7) != From:) { inc %.num | goto loop1 }
  set %.from $gettok($gettok($line($1,%.num),2-,32),1,44)
  :loop2 | if ($_mailcfg(%.ini,%.num) != $null) { inc %.num | goto loop2 }
  if ((< !isin %.from) && ($chr(40) isin %.from)) set %.from $remove($gettok(%.from,2-,40),$chr(41)) < $+ $gettok(%.from,1,40) $+ >
  _writemailc %.ini %.num %.from
}
alias _er.abookx {
  :new
  set %.tmp ~x $+ $r(0,99999) $+ t.txt
  if ($exists(%.tmp)) goto new
  window -c @Importing
  window -n @Importing
  set %.num 1
  :scan
  if ($count($line($active,%.num),$chr(32)) > 0) { inc %.num | goto scan }
  set %.num 1- $+ %.num
  savebuf %.num $active %.tmp
  loadbuf @Importing %.tmp
  .remove %.tmp
  set %email.book Book $+ $2
  ebook
  _ab.import !
}
alias _er.copywin {
  window -c @Copy
  set %.max $sline($1,0)
  if ((%.max < 1) || (%.max > 12)) window -n @Copy $_winpos(14%,7%,7%,7%) @Close %font.basic
  elseif (%.max <= 4) window -n @Copy $_winpos(35%,35%,7%,7%) @Close %font.basic
  else window -n @Copy $_winpos(20%,20%,7%,7%) @Close %font.basic
  set %.num 1
  if (%.max < 1) {
    set %.max $line($1,0)
    :loop1
    echo @Copy $line($1,%.num)
    if ($_vi(.num) <= %.max) goto loop1
  }
  else {
    :loop2
    echo @Copy $sline($1,%.num)
    if ($_vi(.num) <= %.max) goto loop2
  }
  titlebar @Copy window
  window -ar @Copy
}
alias _er.export {
  savebuf $1 $3-
  _recfile2 $3-
  if ($2 == !) edit $3-
}
alias _er.reply {
  set %.num 1 | unset %.from %.subj %.date %.replyto
  :loop1
  set %.line $line($1,%.num)
  if (%.line == $chr(160)) goto next
  if ($left(%.line,7) == From:) set %.from $gettok(%.line,2-,32)
  if ($left(%.line,11) == Reply-to:) set %.replyto $gettok(%.line,2-,32)
  if ($left(%.line,7) == Date:) set %.date $gettok(%.line,2-,32)
  if ($left(%.line,10) == Subject:) set %.subj $gettok(%.line,2-,32)
  inc %.num | goto loop1
  :next
  if (%.subj != $null) {
    if (($2 == r) && ($left(%.subj,3) != re:)) set %.subj Re: %.subj
    if ($2 == f) set %.subj Forwarded: %.subj
  }
  elseif ($2 == f) set %.subj Forwarded e-mail
  if ($2 == f) esend $chr(160) %.subj
  elseif (%.replyto != $null) esend $_s2f(%.replyto) %.subj
  elseif (%.from != $null) esend $_s2f(%.from) %.subj
  else esend $chr(160) %.subj
  if (($3 == n) || (($3 == s) && ($sline($1,0) == 0))) return
  if (%.date != $null) set %.date (on %.date $+ )
  set %.col $strip($remove(%col.dark,))
  if ($2 == f) { unset %.pre | aline %.col $active %.from said %.date - }
  else { set %.pre > | aline %.col $active You said %.date - }
  if ($3 == a) {
    inc %.num
    set %.max $line($1,0)
    :loop2
    if ($line($1,%.max) == $chr(160)) { dec %.max | goto loop2 }
    if (%.num <= %.max) {
      :loop3
      aline %.col $active %.pre $line($1,%.num)
      if ($_vi(.num) <= %.max) goto loop3
    }
    aline -s $active $chr(160)
    sline -r $active $line($active,0)
    return
  }
  set %.num 1
  set %.max $sline($1,0)
  set %.next $sline($1,1).ln
  :loop4
  set %.ln $sline($1,%.num).ln
  if (%.ln != %.next) {
    if ($2 == f) aline %.col $active (... snipped ...)
    else aline $active $chr(160)
  }
  aline %.col $active %.pre $line($1,%.ln)
  set %.next $_i(%.ln)
  if ($_vi(.num) <= %.max) goto loop4
  aline -s $active $chr(160)
  sline -r $active $line($active,0)
}
alias esend {
  unset %.new
  :loop
  set %.win @Compose $+ %.new
  if ($window(%.win) != $null) { if (%.new == $null) inc %.new | inc %.new | goto loop }
  inc %_emc.left
  if ((%_emc.left < 3) || (%_emc.left > 13)) set %_emc.left 3
  set %.left %_emc.left $+ %
  set %.right $calc(16 - %_emc.left) $+ %
  window -le %.win $_winpos(14%,7%,%.left,%.right) @Compose %font.basic
  if (@ isin $1) { set %.send $_f2s($1) | set %.subj $2- }
  else { unset %.send | set %.subj $1- }
  aline %.win Type to write message. Don't press Enter except at the end of a paragraph.
  aline %.win If a line is selected, text will insert before the line. (to unselect right-click, unselect)
  aline %.win F4 to send message, right-click for options and editing.
  aline %.win $chr(160)
  if (%.send == $null) {
    set %.send (not given) %col.dark $+ (double-click to edit)
    titlebar %.win e-mail to (none) - %.subj
  }
  else titlebar %.win e-mail to $_s2f(%.send) - %.subj
  if (%.subj == $null) set %.subj (none) %col.dark $+ (double-click to edit)
  aline %col.base %.win To: %.send
  aline %col.base %.win Subject: %.subj
  aline %.win $chr(160)
  editbox %.win $chr(160)
  set %_ [ $+ [ %.win ] ] 8
}
on 1:input:@:{
  if ($left($active,8) != @Compose) return
  set %.todo $_f2s($1-)
  if ($left(%.todo,2) == //) { editbox $active $chr(160) | %.todo | halt }
  set %.iline $sline($active,1).ln
  if (%.iline < %_ [ $+ [ $active ] ] ) set %.iline $_i($line($active,0))
  if (%.todo == $null) iline -a $active %.iline $chr(160)
  elseif (%email.wrap < 1) iline -a $active %.iline %.todo
  else {
    :loop
    if ($len(%.todo) <= %email.wrap) iline -a $active %.iline %.todo
    else {
      set %.text $left(%.todo,$calc(2 + %email.wrap))
      if ($chr(32) !isin $right(%.todo,$calc(%email.wrap / 2))) set %.text $_lchop(4,%.text)
      else set %.text $_ltok($_j($_numtok(32,%.text)),32,%.text)
      iline $active %.iline %.text
      inc %.iline
      set %.todo $_rchop($len(%.text),%.todo)
      goto loop
    }
  }
  sline -r $active %.iline | window -b $active | editbox $active $chr(160) | halt
}
menu @Compose {
  dclick:/if ($1 == 5) _ce.editto $active | if ($1 == 6) _ce.editsubj $active | set %.max %_ [ $+ [ $active ] ] | if (($1 > 6) && ($1 < $_j(%.max))) _ce.editf $active $1 | if ($1 >= %.max) _ce.editl $active $1
  Send mail...:_edosend $active
  Import file
  .at end of mail...:_ce.import $active e
  .at selected position...:_ce.import $active s
  .replace mail...:_ce.import $active r
  Save
  .to file...:set %_arhelp _ce.export $active . | _askr _arhelp Filename to save mail to?
  .to file and edit...:set %_arhelp _ce.export $active ! | _askr _arhelp Filename to save mail to?
  -
  Mail to
  .Address book...:ebook $active
  .Recent
  ..%^email.1:_ce.to $active $gettok(%^email.1,2-,32)
  ..%^email.2:_ce.to $active $gettok(%^email.2,2-,32)
  ..%^email.3:_ce.to $active $gettok(%^email.3,2-,32)
  ..%^email.4:_ce.to $active $gettok(%^email.4,2-,32)
  ..%^email.5:_ce.to $active $gettok(%^email.5,2-,32)
  ..%^email.6:_ce.to $active $gettok(%^email.6,2-,32)
  ..%^email.7:_ce.to $active $gettok(%^email.7,2-,32)
  ..%^email.8:_ce.to $active $gettok(%^email.8,2-,32)
  ..%^email.9:_ce.to $active $gettok(%^email.9,2-,32)
  ..-
  ..%^email.clear:unset %^email.*
  .Other...:_ce.editto $active
  .-
  .Carbon copy
  ..Address book...:ebook $active CC
  ..Recent
  ...%^email.1:_ce.cc $active CC $gettok(%^email.1,2-,32)
  ...%^email.2:_ce.cc $active CC $gettok(%^email.2,2-,32)
  ...%^email.3:_ce.cc $active CC $gettok(%^email.3,2-,32)
  ...%^email.4:_ce.cc $active CC $gettok(%^email.4,2-,32)
  ...%^email.5:_ce.cc $active CC $gettok(%^email.5,2-,32)
  ...%^email.6:_ce.cc $active CC $gettok(%^email.6,2-,32)
  ...%^email.7:_ce.cc $active CC $gettok(%^email.7,2-,32)
  ...%^email.8:_ce.cc $active CC $gettok(%^email.8,2-,32)
  ...%^email.9:_ce.cc $active CC $gettok(%^email.9,2-,32)
  ...-
  ...%^email.clear:unset %^email.*
  ..Other...:_ce.cc $active CC
  .Blind CC
  ..Address book...:ebook $active BlindCC
  ..Recent
  ...%^email.1:_ce.cc $active BlindCC $gettok(%^email.1,2-,32)
  ...%^email.2:_ce.cc $active BlindCC $gettok(%^email.2,2-,32)
  ...%^email.3:_ce.cc $active BlindCC $gettok(%^email.3,2-,32)
  ...%^email.4:_ce.cc $active BlindCC $gettok(%^email.4,2-,32)
  ...%^email.5:_ce.cc $active BlindCC $gettok(%^email.5,2-,32)
  ...%^email.6:_ce.cc $active BlindCC $gettok(%^email.6,2-,32)
  ...%^email.7:_ce.cc $active BlindCC $gettok(%^email.7,2-,32)
  ...%^email.8:_ce.cc $active BlindCC $gettok(%^email.8,2-,32)
  ...%^email.9:_ce.cc $active BlindCC $gettok(%^email.9,2-,32)
  ...-
  ...%^email.clear:unset %^email.*
  ..Other...:_ce.cc $active BlindCC
  Subject...:_ce.editsubj $active
  Advanced
  .Reply-to...:_ce.field $active Reply-to
  .Organization...:_ce.field $active Organization
  .-
  .Other...:set %_arhelp _ce.field $active | _askr _arhelp Custom e-mail field to add?
  -
  Delete lines:_ce.del $active
  Delete all...:set %_arhelp _ce.clear $active | _askyn _arhelp Delete entire message?
  -
  Unselect all:sline $active $line($active,0) | sline -r $active $line($active,0)
  Close:window -c $active
}
alias _ce.cc {
  set %.pre %_ [ $+ [ $1 ] ] | dec %.pre 2
  set %.search  $+ $2
  :loop
  set %.tok $remove($gettok($line($1,%.pre),1,32),%.search)
  if ((%.tok == :) || ($remove(%.tok,:) isnum)) goto next
  if ($_vd(.pre) > 3) goto loop
  if ($3 == $null) _ce.field $1 $2 | else _ce.field2 $1 $2 $3-
  return
  :next
  if ($3 == $null) _ce.editf $1 %.pre
  else {
    set %.old $gettok($line($1,%.pre),2-,32)
    if ($len(%.old) > 400) {
      set %.numb $remove(%.tok,:)
      if (%.numb == $null) inc %.numb | inc %.numb
      _ce.field2 $1 $2 $+ %.numb $3-
    }
    else _ce.editf2 $1 %.pre $2 $+ $remove(%.tok,:) %.old $+ , $3-
  }
}
alias _ce.editto {
  set %.email $gettok($line($1,5),2-,32) | set %.chk (not given) %col.dark $+ (double-click to edit) | set %_arhelp _ce.to $1
  if (%.email == %.chk) _askr _arhelp Send e-mail to?
  _pentry _arhelp $+ $_s2p(%.email) Send e-mail to?
}
alias _ce.to if ($2 == $null) halt | rline %col.base $1 5 To: $2- | titlebar $1 e-mail to $_s2f($gettok($2-,1,60)) - $gettok($window($1).titlebar,5-,32) | halt
alias _ce.editsubj {
  set %.subj $gettok($line($1,6),2-,32) | set %.chk (none) %col.dark $+ (double-click to edit) | set %_arhelp _ce.subj $1
  if (%.subj == %.chk) _askr _arhelp Subject of e-mail?
  _pentry _arhelp $+ $_s2p(%.subj) Subject of e-mail?
}
alias _ce.subj if ($2 == $null) halt | rline %col.base $1 6 Subject: $2- | titlebar $1 e-mail to $gettok($window($1).titlebar,3,32) - $2- | halt
alias _ce.clear {
  set %.num %_ [ $+ [ $1 ] ]
  set %.max $line($1,0)
  set %.range %.num $+ - $+ %.max
  dline $1 %.range
}
alias _ce.del {
  set %.pre %_ [ $+ [ $1 ] ]
  :loop
  set %.num $sline($1,1).ln
  if (%.num >= %.pre) { dline $1 %.num | goto loop }
  if ((%.num > 6) && (%.num < $_j(%.pre))) { dline $1 %.num | dec %.pre | dec %_ [ $+ [ $1 ] ] | goto loop }
}
alias _ce.field {
  set %.field $remove($replace($2-,$chr(32),-),:)
  set %.pre %_ [ $+ [ $1 ] ]
  dec %.pre 2
  :loop
  set %.tok $strip($remove($gettok($line($1,%.pre),1,32),:))
  if (%.tok == %.field) _error %.field field already exists, double-click on it to edit it.
  if ($_vd(.pre) > 3) goto loop
  set %_arhelp _ce.field2 $1 %.field
  _askr _arhelp Data for " $+ %.field $+ " field?
}
alias _ce.field2 set %.line %_ [ $+ [ $1 ] ] | iline %col.base $1 $_j(%.line)  $+ $2: $3- | inc %_ [ $+ [ $1 ] ] | window -b $1
alias _ce.editf {
  set %.line $line($1,$2) | set %.field $remove($strip($gettok(%.line,1,32)),:) | set %.data $gettok(%.line,2-,32) | set %_arhelp _ce.editf2 $1 $2 %.field
  _pentry _arhelp $+ $_s2p(%.data) Data for " $+ %.field $+ " field?
}
alias _ce.editf2 rline %col.base $1 $2  $+ $3: $4- | window -b $1
alias _ce.editl {
  set %_arhelp _ce.editl2 $1 $2
  _pentry _arhelp $+ $_s2p($line($1,$2)) Replace line with?
}
alias _ce.editl2 rline $1-
alias _ce.export {
  set %.max %_ [ $+ [ $1 ] ]
  set %.num $line($1,0)
  savebuf $calc(%.num - %.max + 1) $1 $3-
  _recfile2 $3-
  if ($2 == !) edit $3-
}
alias _ce.import {
  _timer924off
  set %.file $dir="File to import?" $mircdir*.txt
  _timer924on
  if ((%.file == $null) || (* isin %.file)) halt
  if ($2 == r) _ce.clear $1
  if ($2 == s) {
    set %.where $sline($1,1).ln
    if (%.where < %_ [ $+ [ $1 ] ] ) loadbuf $1 %.file
    else {
      set %.num $line($1,0)
      set %.range %.where $+ - $+ %.num
      savebuf %.range $1 ppm-ceit.txt
      dline $1 %.range
      loadbuf $1 %.file
      loadbuf $1 ppm-ceit.txt
      .remove ppm-ceit.txt
    }
  }
  else loadbuf $1 %.file
}
alias f4 {
  if ((@EMail isin $active) && ($active != @EMail)) {
    if ($sline($active,0) > 1) _er.reply $active r s
    else _er.reply $active r a
  }
  elseif (($_isopen(@Progress)) && (%_ems.win == $null) && (%_ems.lastwin != $null)) { window -c @Progress | window -c %_ems.lastwin }
  elseif (@Compose isin $active) _edosend $active
  elseif ($_isopen(@EMail)) {
    if ($gettok($line(@EMail,7),1,32) == no) window -c @EMail
    elseif (headers isin $window(@EMail).titlebar) { _ecsall | _ecdo sg }
    elseif (performing isin $window(@EMail).titlebar) window -c @EMail
    else _echeader
  }
  else echeck
}
alias f3 {
  set %.loop $window(0)
  if (%.loop > 0) {
    if (@EMail isin $active) {
      :loop2
      if ($window(%.loop) != $active) { dec %.loop | goto loop2 }
      dec %.loop | if (%.loop < 1) set %.loop $window(0)
    }
    :loop
    if (@EMail isin $window(%.loop)) { window -ar $window(%.loop) | halt }
    if ($_vd(.loop) > 0) goto loop
  }
  cd
}
alias ecfg {
  set %-+eacs.halt $true
  if ($1 == $null) {
    window -c @Account
    window -l @Account $_winpos(14%,7%,18%,18%) @Account %font.basic
    titlebar @Account settings (account %email.accnum $+ )
    aline @Account Current e-mail account settings- (account %col.target $+ %email.accnum $+ )
    aline @Account %=
    _ecfg n | _ecfg po | _ecfg u | _ecfg p | _ecfg s | _ecfg e | _ecfg r | _ecfg f | _ecfg o | _ecfg si | _ecfg w | _ecfg fa | _ecfg au | _ecfg cr
    aline @Account %=
    aline @Account Double-click to edit a setting, right-click to clear a setting.
    halt
  }
  unset %.var %.left
  if ($left($1,2) == po) { set %.var pop3 | set %.is POP3 server }
  elseif ($left($1,2) == si) { set %.var sig | set %.is Signature file }
  elseif ($left($1,2) == cr) { set %.var cret | set %.is Send only line feeds without carraige returns? (enable only if needed) }
  elseif ($left($1,2) == fa) { set %.var fastsend | set %.is Fastsend (for carbon-copy) }
  elseif ($findtok(au.ch.ac,$left($1,2),46) != $null) { set %.var autocheck | set %.is Auto check }
  else {
    set %.left $left($1,1)
    if (%.left == n) { set %.var account | set %.is Account name }
    if (%.left == s) { set %.var smtp | set %.is SMTP server }
    if (%.left == u) { set %.var user | set %.is POP3 username }
    if (%.left == p) { set %.var pw | set %.is POP3 password }
    if (%.left isin ea) { set %.var email | set %.is E-Mail address }
    if (%.left == r) { set %.var replyto | set %.is Reply-to address }
    if (%.left == f) { set %.var ffrom | set %.is "From" field }
    if (%.left == o) { set %.var org | set %.is "Organization" field }
    if (%.left isin lw) { set %.var wrap | set %.is Linewrap width }
  }
  if (%.var == $null) _error Unknown e-mail setting " $+ $1"
  if (! isin $1) set %.pre rline @Account $gettok($1,2,33)
  else set %.pre dispa
  if ($2 == 0) set %email. [ $+ [ %.var ] ]
  elseif ($2 != $null) {
    if (%.left == p) set %email. [ $+ [ %.var ] ] $_pwenc($2-)
    elseif ($left($1,2) == si) set %email. [ $+ [ %.var ] ] $remove($2-,$mircdir)
    else set %email. [ $+ [ %.var ] ] $2-
  }
  if (%email. [ $+ [ %.var ] ] == $null) %.pre %.is set to none. (disabled)
  elseif (%.left == p) %.pre %.is set to - %col.dark $+ (encrypted)
  else %.pre %.is set to - %col.dark $+ %email. [ $+ [ %.var ] ]
  if (%.left == n) {
    set %email.pu [ $+ [ %email.accnum ] ] %email.accnum $+ . %email.account
    set %email.curr Current- %email.accnum $+ . %email.account
  }
}
alias _ecfg ecfg $1! $+ $_i($line(@Account,0))
alias _ecfgdc2 ecfg $gettok(!.!.n.po.u.p.s.e.r.f.o.si.w.fa.au.cr,$1,46) $+ ! $+ $1 $2-
alias _ecfgdc {
  if (($1 < 3) || ($1 > 16)) halt
  if ($1 == 12) {
    _timer924off
    set %.file $dir="Signature file?" [ [ $_mircdir ] $+ ] *.txt
    _timer924on
    if ((%.file == $null) || (* isin %.file)) halt
    _ecfgdc2 12 %.file
  }
  else {
    set %.q $gettok($line(@Account,$1),1-2,32)
    set %_arhelp _ecfgdc2 $1
    set %.old $strip($gettok($line(@Account,$1),6-,32))
    if (%.old == (disabled)) _askr _arhelp Setting for %.q $+ ?
    else _pentry _arhelp $+ $_s2p(%.old) New setting for %.q $+ ?
  }
}
menu @Account {
  dclick:/_ecfgdc $1
  Change setting...:_ecfgdc $sline(@Account,1).ln
  Disable setting:_ecfgdc2 $sline(@Account,1).ln 0
  -
  Close:window -c @Account
}
#_email-tb off
alias titlebar { if (@ !isin $1) titlebar $1- %_email-tb | else titlebar $1- }
#_email-tb end
alias _remmailc remini $_ppdir $+ email.ini $1 $2
