; -----------------------------------------------------
; Peace and Protection (by misspai)
; -----------------------------------------------------
; ADDON: E-Mail (2 of 2)
; -----------------------------------------------------
alias eends if (%email.cret) return $1- $+ $lf | return $1- $+ $cr $+ $lf
alias _mailcfg if ($2 == $null) set %.read $readini -n $_ppdir $+ email.ini settings $_iniprep($1) | else set %.read $readini -n $_ppdir $+ email.ini $1 $_iniprep($2-) | return $_readprep(%.read)
alias _writemailc if ($3 == $null) _remmailc $1- | else writeini $_ppdir $+ email.ini $1 $2 $3-
alias _edosend {
  _timer924on
  _escancel !
  unset %_ems.lastwin
  if (%email.smtp == $null) _error SMTP server not defined- See E-Mail setup
  if (%email.email == $null) _error E-Mail address not defined- See E-Mail setup
  if ($line($1,$line($1,0)) != $chr(160)) aline $1 $chr(160)
  set %_ems.win $1
  set %_ems.to $gettok($line($1,5),2-,32)
  if (< isin %_ems.to) set %.tutu $remove($gettok(%_ems.to,2,60),>)
  elseif ($chr(40) isin %_ems.to) set %.tutu $gettok(%_ems.to,1,40)
  else set %.tutu %_ems.to
  if (@ !isin %.tutu) { unset %_ems.win %_ems.to | _error You must give a legitimate e-mail address to send to! }
  _dynpop.rot email 9 %_ems.to
  set %_ems.hideto $true
  set %_ems.targets $_numtok(44,%_ems.to)
  set %.pre %_ [ $+ [ $1 ] ] | dec %.pre 2
  set %.targ 2
  :loop
  set %.tok $strip($remove($remove($gettok($line($1,%.pre),1,32),CC),Blind))
  if ((%.tok == :) || ($remove(%.tok,:) isnum)) {
    if (blind !isin $gettok($line($1,%.pre),1,32)) set %_ems.hideto $false
    set %_ems.to [ $+ [ %.targ ] ] $gettok($line($1,%.pre),2-,32)
    inc %_ems.targets $_numtok(44,$gettok($line($1,%.pre),2-,32))
    inc %.targ
  }
  if ($_vd(.pre) > 3) goto loop
  if (%_ems.targets < 2) set %_ems.hideto $false
  sline $1 1
  _progress.1 Sending e-mail...
  set %.ini $_mircdir $+ mirc.ini
  set %_ems.oldident $readini %.ini ident userid
  set %_ems.oldactive $readini %.ini ident active
  .identd on $gettok(%email.email,1,64)
  set %_ems.todo $line(%_ems.win,0)
  set %_ems.progr $calc(%_ems.todo + %_ems.targets + 3)
  set %.lof $lines(%email.sig)
  if (%.lof > 0) inc %_ems.progr %.lof
  set %_ems.progc 0 | set %_ems.progt 2
  .enable #_esend
  _esprog Resolving DNS of SMTP server...
  _esprog Logging in to SMTP server...
  sockopen ULTE-SEND %email.smtp 25
}
alias _escancel {
  window -c @Progress
  .disable #_esenddns #_esend
  unset %_ems.stage %_ems.win %_ems.to* %_ems.lastwin %_ems.prog? %_ems.targets %_ems.hideto
  _qlogc $1
  if (%_ems.oldident != $null) {
    .identd on %_ems.oldident
    if (%_ems.oldactive != yes) .identd off
    unset %_ems.oldident %_ems.oldactive
  }
}
#_esend off
on 1:sockopen:ULTE-SEND:{
  if ($sockerr > 0) _error Error connecting to mail server
  else _esprog Handshaking with server...
}
on 1:sockclose:ULTE-SEND:_escancel | _error Mail server disconnected unexpectedly
on 1:sockread:ULTE-SEND:{
  :loop
  sockread %.sockdata
  if ($sockbr == 0) return
  _esenddo1 %.sockdata
  goto loop
}
alias -l _esenddo1 {
  if ($1 == 220) { sockwrite ULTE-SEND HELO $eends($gettok(%email.email,2,64)) | set %_ems.stage 1 }
  elseif (25? iswm $1) {
    if (%_ems.stage == 1) sockwrite ULTE-SEND MAIL FROM:< $+ %email.email $+ $eends(>)
    elseif (%_ems.stage == 2) {
      :next
      _esprog Sending receipients list...
      set %.gorg $gettok(%_ems.to,1,44)
      set %_ems.to $gettok(%_ems.to,2-,44)
      if (< isin %.gorg) set %.gorg $remove($gettok(%.gorg,2,60),>)
      set %.gorg $gettok(%.gorg,1,32)
      if (@ isin %.gorg) sockwrite ULTE-SEND RCPT TO:< $+ %.gorg $+ $eends(>)
      if (%_ems.to == $null) {
        set %_ems.to %_ems.to [ $+ [ %_ems.progt ] ]
        set %_ems.to [ $+ [ %_ems.progt ] ]
        inc %_ems.progt
      }
      if (%_ems.to != $null) {
        if (%email.fastsend isin onyesenabled$true) goto next
        halt
      }
    }
    elseif (%_ems.stage == 3) sockwrite ULTE-SEND $eends(DATA)
    elseif (%_ems.stage == 0) sockwrite ULTE-SEND $eends(QUIT)
    inc %_ems.stage
  }
  elseif ($left($1,1) isin 45) { _escancel | _error Error from server when sending mail- $2- }
  elseif ($1 == 354) {
    _esprog Sending mail header...
    if (%email.ffrom == $null) sockwrite ULTE-SEND From: $eends(%email.email)
    else sockwrite ULTE-SEND From: %email.ffrom < $+ %email.email $+ $eends(>)
    set %.+did.from: $true
    if (%_ems.hideto) set %.+did.to: $true
    set %.num 5
    :loop1
    set %.line $line(%_ems.win,%.num)
    _esprog2
    if (%.line != $chr(160)) {
      set %.field $strip($gettok(%.line,1,32))
      set %.data $gettok(%.line,2-,32)
      if ((%.+did. [ $+ [ %.field ] ] != $true) && ( !isin %.data)) {
        set %.+did. [ $+ [ %.field ] ] $true
        if (BlindCC !isin %.field) sockwrite -t ULTE-SEND %.field $eends(%.data)
      }
      inc %.num
      goto loop1
    }
    inc %.num
    if ((%.+did.reply-to: != $true) && (%email.replyto != $null) && (%email.replyto != %email.email)) sockwrite ULTE-SEND Reply-to: $eends(%email.replyto)
    if ((%.+did.organization: != $true) && (%email.org != $null)) sockwrite ULTE-SEND Organization: $eends(%email.org)
    set %.line X-Mailer: P&P %pp.ver for mirc $version $+ $lf
    :loop2
    _esprog2
    set %.next $_f2s($line(%_ems.win,%.num))
    if (%.next == $null) {
      set %.line %.line $+ $lf
      if ($_vi(.num) < %_ems.todo) goto loop2
      sockwrite -t ULTE-SEND $eends(%.line)
      goto nexts
    }
    sockwrite -t ULTE-SEND $eends(%.line)
    set %.line %.next
    if ($left(%.line,1) == .) set %.line . $+ %.line
    inc %.num
    goto loop2
    :nexts
    if (%email.sig != $null) {
      set %.max $lines(%email.sig)
      if (%.max > 0) {
        set %.num 1
        :loop
        _esprog Sending signature...
        set %.line $read -nl [ $+ [ %.num ] ] %email.sig
        if ($left(%.line,1) == .) sockwrite ULTE-SEND . $+ $eends(%.line)
        elseif (%.line != $null) sockwrite -t ULTE-SEND $eends(%.line)
        if ($_vi(.num) <= %.max) goto loop
      }
    }
    _esprog Logging off...
    sockwrite ULTE-SEND $eends(.)
    set %_ems.stage 0
  }
  elseif ($1 == 221) {
    _progress.2 100 Mail sent! (press F4 to close this and e-mail window)
    .disable #_esend
    set %_ems.lastwin %_ems.win
    unset %_ems.stage %_ems.win %_ems.to* %_ems.prog? %_ems.targets
    if (%_ems.oldident != $null) {
      .identd on %_ems.oldident
      if (%_ems.oldactive != yes) .identd off
      unset %_ems.oldident %_ems.oldactive
    }
    sockclose ULTE-SEND
    halt
  }
}
alias _esprog inc %_ems.progc | set %.perc $int($calc(%_ems.progc * 100 / %_ems.progr)) | _progress.2 %.perc $1-
alias _esprog2 inc %_ems.progc | if ($_vi(.emsp) < 5) return | unset %.emsp | set %.perc $int($calc(%_ems.progc * 100 / %_ems.progr)) | _progress.2 %.perc Sending message...
#_esend end
alias ebook {
  window -c @Address
  window -l @Address $_winpos(21%,14%,21%,21%) @Address %font.basic
  set %.num 1
  :loop
  set %.addr $_mailcfg(%email.book,%.num)
  if (%.addr != $null) { aline @Address %.addr | inc %.num | goto loop }
  aline @Address %=
  aline @Address Add new entry...
  if ($1 == $null) { aline @Address (double-click to modify an entry) | unset %_addr.pop }
  else { aline @Address (double-click to select an entry) | set %_addr.pop Select entry }
  unset %_addr.pop2
  if ($2 != $null) set %_addr.pop2 Select all entries
  aline @Address (right-click to delete an entry)
  aline @Address %=
  aline @Address Current book- %col.target $+ $remove(%email.book,Book) $+  - %col.dark $+ $_mailcfg(%email.book,Name) $+  (double-click for books)
  titlebar @Address book - $_mailcfg(%email.book,Name) ( $+ $remove(%email.book,Book) $+ )
  aline @Address Create new book...
  set %_addr.target $1
  set %_addr.max %.num
  set %_addr.cc $2
}
menu @Address {
  dclick:/if ($1 < %_addr.max) { if (%_addr.target == $null) _ab.mod $1 | else _ab.sel $1 } | %.tmp = 1 + %_addr.max | if ($1 == %.tmp) _ab.add | inc %.tmp 4 | if ($1 == %.tmp) _ebsel _ab.book sel Select a book | inc %.tmp | if ($1 == %.tmp) _abs.new
  %_addr.pop:{
    :loop
    set %.num $sline(@Address,1).ln
    if ((%.num < 1) || (%.num >= %_addr.max)) halt
    _ab.sel %.num
    sline -r @Address $sline(@Address,1).ln
    goto loop
  }
  %_addr.pop2:{
    set %.num 1
    :loop
    if (%.num >= %_addr.max) halt
    _ab.sel %.num
    inc %.num | goto loop
  }
  -
  Delete entry
  .Yes I'm sure:_ab.del
  Modify entry...:set %.num $sline(@Address,1).ln | if ((%.num > 0) && (%.num < %_addr.max)) _ab.mod %.num
  New entry...:_ab.add
  -
  Change book...:_ebsel _ab.book sel Select a book
  New book...:_abs.new
  Copy to another book...:_ebsel _ab.copy sel Book to copy to?
  -
  Copy to clipboard:clipboard $sline(@Address,1)
  Import file...:_timer924off | set %.file $dir="File to grab e-mail addresses from?" [ [ $_mircdir ] $+ ] *.txt | _timer924on | if ((* isin %.file) || (%.file == $null)) halt | _ab.import %.file
  Reduce to bare e-mails...:_askyn _ab.bare Remove all names for addresses, leaving only e-mail addresses?
  -
  Close:window -c @Address
}
alias eaddr ebook $1-
alias _ebsel {
  window -c @AddressBook
  window -l @AddressBook $_winpos(21%,14%,22%,20%) @AddressBook %font.basic
  titlebar @AddressBook selection - $3-
  set %.num $_mailcfg(Books)
  :loop
  set %.ini Book $+ %.num
  set %.addr $_mailcfg(%.ini,Name)
  iline @AddressBook 1 Book %col.target $+ %.num $+  - %col.dark $+ %.addr
  if ($_vd(.num) > 0) goto loop
  aline @AddressBook %=
  aline @AddressBook Create new book...
  aline @AddressBook (double-click to select a book)
  aline @AddressBook (right-click to delete or rename a book)
  set %_abselcmd $1 $2
}
menu @AddressBook {
  dclick:/set %.tmp $_mailcfg(Books) | if ($1 <= %.tmp) _abs.sel $1 | if ($1 == $calc(%.tmp + 2)) _abs.new
  Select book:set %.ln $sline(@AddressBook,1).ln | if ((%.ln <= $_mailcfg(Books)) && (%.ln > 0)) _abs.sel %.ln
  -
  Delete book
  .Yes I'm sure:set %.ln $sline(@AddressBook,1).ln | if ((%.ln <= $_mailcfg(Books)) && (%.ln > 0)) _abs.del %.ln
  Rename book...:set %.ln $sline(@AddressBook,1).ln | if ((%.ln <= $_mailcfg(Books)) && (%.ln > 0)) _abs.ren %.ln
  New book...:_abs.new
  -
  Close:window -c @AddressBook
}
alias _abs.sel window -c @AddressBook | %_abselcmd $1
alias _abs.del {
  if ($_mailcfg(Books) <= 1) _error You must have at least one address book.
  set %.tmp Book $+ $1 | _remmailc %.tmp
  if ($1 < $_mailcfg(Books)) {
    set %.tmp2 Book $+ $_mailcfg(Books) | _writemailc %.tmp Name $_mailcfg(%.tmp2,Name)
    set %.num 1
    :loop
    set %.addr $_mailcfg(%.tmp2,%.num)
    if (%.addr != $null) {
      _writemailc %.tmp %.num %.addr
      inc %.num | goto loop
    }
    _remmailc %.tmp2
  }
  else { set %.tmp2 %.tmp | set %.tmp Book1 }
  _writemailc Settings Books $_j($_mailcfg(Books))
  if ((%email.book == %.tmp) || (%email.book == %.tmp2)) {
    set %email.book %.tmp
    if ($_isopen(@Address)) window -c @Address
  }
  if ($_isopen(@AddressBook)) _ebsel %_abselcmd $gettok($window(@AddressBook).titlebar,3-,32)
}
alias _abs.ren set %.tmp Book $+ $1 | set %_arhelp _abs.ren2 $1 | _pentry _arhelp $+ $_s2p($_mailcfg(%.tmp,Name)) New name for address book $1?
alias _abs.ren2 {
  set %.tmp Book $+ $1 | _writemailc %.tmp Name $2-
  if ((%email.book == %.tmp) && ($_isopen(@Address))) {
    rline @Address $calc(%_addr.max + 5) Current book- %col.target $+ $1 - %col.dark $+ $2- (double-click for books)
    titlebar @Address book - $2- ( $+ $1)
  }
  if ($_isopen(@AddressBook)) rline @AddressBook $1 Book %col.target $+ $1 - %col.dark $+ $2-
}
alias _abs.new _askr _abs.new2 Name for new address book?
alias _abs.new2 {
  set %.tmp $_mailcfg(Books) | inc %.tmp | _writemailc Settings Books %.tmp
  set %.tmp2 Book $+ %.tmp | _writemailc %.tmp2 Name $1-
  if ($_isopen(@AddressBook)) iline @AddressBook %.tmp Book %col.target $+ %.tmp $+  - %col.dark $+ $1-
  elseif ($_isopen(@Address)) _ab.book sel %.tmp
}
alias _ab.book set %email.book Book $+ $2 | window -c @Address | ebook %_addr.target %_addr.cc
alias _ab.copy {
  set %.tmp Book $+ $2
  set %.max 1
  :loop1
  if ($_mailcfg(%.tmp,%.max) != $null) { inc %.max | goto loop1 }
  set %.num 1
  :loop2
  if ($sline(@Address,%.num).ln >= %_addr.max) return
  set %.addr $sline(@Address,%.num)
  if (%.addr != $null) { _writemailc %.tmp %.max %.addr | inc %.max | inc %.num | goto loop2 }
}
alias _ab.add _askr _ab.add2 E-Mail address of new entry?
alias _ab.add2 set %_arhelp _ab.add3 $1 | _pentry _arhelp Name or nickname for new entry?2
alias _ab.add3 {
  if ($2 == $null) set %.new $1
  else set %.new $2- < $+ $1>
  set %.scan 1
  if (%_addr.max > 1) {
    :scan
    set %.olda $remove($_rtok(1,60,$line(@Address,%.scan)),>)
    if (%.olda == %.new) return $true
    if ($_vi(.scan) < %_addr.max) goto scan
  }
  iline @Address %_addr.max %.new
  _writemailc %email.book %_addr.max %.new
  inc %_addr.max
  return $false
}
alias _ab.import {
  if ($1 != !) { window -c @Importing | window -n @Importing | loadbuf @Importing $1- }
  set %.max $line(@Importing,0)
  set %.cur 1 | set %.found 0 | unset %.dupe
  _progress.1 Scanning file and importing e-mail addresses...
  :loop1
  set %.line $line(@Importing,%.cur)
  if ($_vd(.pupd) < 0) {
    set %.pupd 5
    set %.perc $int($calc(%.cur * 100 / %.max))
    _progress.2 %.perc %.perc $+ % complete... ( $+ %.found found)
  }
  if (@ isin %.line) {
    :loop2
    set %.pos $pos(%.line,@)
    set %.from %.pos
    :loop3
    dec %.from
    set %.bit $mid(%.line,%.from,1)
    if ((%.bit isletter) || (%.bit isnum) || (%.bit isin .-_)) goto loop3
    inc %.from
    :loop4
    inc %.pos
    set %.bit $mid(%.line,%.pos,1)
    if ((%.bit isletter) || (%.bit isnum) || (%.bit isin .-_)) goto loop4
    %.len = %.pos - %.from
    set %.email $mid(%.line,%.from,%.len)
    if (($gettok(%.email,1,64) != $null) && (. isin $gettok(%.email,2,64))) { inc %.found | _ab.add3 %.email | if ($result) inc %.dupe }
    set %.line $_rchop($_j(%.pos),%.line)
    if (@ isin %.line) goto loop2
  }
  if ($_vi(.cur) <= %.max) goto loop1
  if (%.dupe == $null) _progress.2 100 Import complete! %.found $_plural2(address,addresses,%.found) imported.
  else _progress.2 100 Import complete! %.found found, %.dupe $_plural(duplicate,%.dupe) $+ , $calc(%.found - %.dupe) imported.
  window -c @Importing
}
alias _ab.bare {
  set %.num $_j(%_addr.max)
  if (%.num > 0) {
    :loop1
    set %.line $line(@Address,%.num)
    if (< isin %.line) rline @Address %.num $remove($gettok(%.line,2-,60),>)
    if ($_vd(.num) > 0) goto loop1
    set %.name $_mailcfg(%email.book,Name)
    _remmailc %email.book
    _writemailc %email.book Name %.name
    set %.num 1
    :loop2
    _writemailc %email.book %.num $line(@Address,%.num)
    if ($_vi(.num) < %_addr.max) goto loop2
  }
}
alias _ab.del {
  :loop1
  set %.num $sline(@Address,1).ln
  if ((%.num > 0) && (%.num < %_addr.max)) { dline @Address %.num | dec %_addr.max | goto loop1 }
  set %.name $_mailcfg(%email.book,Name)
  _remmailc %email.book
  _writemailc %email.book Name %.name
  if (%_addr.max > 1) {
    set %.num 1
    :loop2
    _writemailc %email.book %.num $line(@Address,%.num)
    if ($_vi(.num) < %_addr.max) goto loop2
  }
}
alias _ab.mod {
  set %.cur $line(@Address,$1)
  if (< isin %.cur) { set %.who $gettok(%.cur,1,60) | set %.email $remove($gettok(%.cur,2,60),>) }
  else { unset %.who | set %.email %.cur }
  set %_arhelp _ab.mod2 $1
  _pentry _arhelp $+  $+ $_s2p(%.email) New e-mail address for entry?
}
alias _ab.mod2 {
  set %_arhelp _ab.mod3 $1 $2
  if (%.who == $null) _pentry _arhelp Name or nickname for entry?2
  else _pentry _arhelp $+  $+ $_s2p(%.who) New name or nickname for entry?
}
alias _ab.mod3 {
  if ($3 == $null) set %.new $2
  else set %.new $3- < $+ $2>
  rline @Address $1 %.new
  _writemailc %email.book $1 %.new
}
alias _ab.sel {
  set %.addr $line(@Address,$1)
  if ($_not($_isopen(%_addr.target))) halt
  if (cc isin %_addr.cc) _ce.cc %_addr.target %_addr.cc %.addr
  else {
    window -c @Address
    rline %col.base %_addr.target 5 To: %.addr
    titlebar %_addr.target e-mail to $_s2f($gettok(%.addr,1,60)) - $gettok($window(%_addr.target).titlebar,5-,32)
    halt
  }
}
alias eacc {
  set %-+eacs.halt $true
  _esaveacc %email.accnum
  if ($1 == $null) { disp Current e-mail account - %col.target $+ %email.accnum $+  - %email.account | halt }
  if (v isin $1) {
    open @Info /eacc E-Mail account info
    dispr @Info E-Mail accounts-
    set %.num 1
    :loop
    set %.cfg EMail $+ %.num
    if (%.num == %email.accnum) set %.cur - %col.dark $+ (current)
    else unset %.cur
    dispr @Info $chr(160) • %col.target $+ $chr(35) $+ %.num $+  - $_mailcfg(%.cfg,name) - $_mailcfg(%.cfg,user) / $_mailcfg(%.cfg,addr) / $_mailcfg(%.cfg,who) %.cur
    if ($_vi(.num) <= %email.acclast) goto loop
    halt
  }
  if (n isin $1) {
    set %email.accnum $_vi(email.acclast)
    set %email.curr Current- %email.accnum $+ . %email.account
    _esaveacc %email.accnum
    disp New e-mail account created ( $+ %col.target $+ $chr(35) $+ %email.accnum $+ ) Please give it a unique name and settings.
    goto cfg
  }
  if (%email.acclast <= 1) if ((d isin $1) || (r isin $1)) _error You need more than one account defined before you can delete accounts.
  if (d isin $1) set %.todel %email.accnum
  elseif (r isin $1) {
    if (($2 < 1) || ($2 > %email.acclast) || ($2 !isnum)) _error You must give a valid account number to remove.
    set %.todel $2
  }
  else {
    if (($1 < 1) || ($1 > %email.acclast) || ($1 !isnum)) _error You must give a valid account number to switch to.
    _eloadacc $1
    goto cfgp
  }
  if (%.todel != %email.accnum) _eloadacc %.todel
  disp E-Mail account %col.att $+ deleted - %col.target $+ %email.accnum $+  - %email.account
  if (%.todel == %email.acclast) {
    set %.cfg EMail $+ %.todel
    _remmailc %.cfg
    _eloadacc 1
  }
  else {
    _eloadacc %email.acclast
    _remmailc %.cfg
    _esaveacc %.todel
    set %email.accnum %.todel
  }
  set %email.curr Current- %email.accnum $+ . %email.account
  set %email.pu [ $+ [ %email.acclast ] ]
  dec %email.acclast
  :cfgp
  disp E-Mail account loaded - %col.target $+ %email.accnum $+  - %email.account
  :cfg
  if (($_isopen(@Account) == $true) || (n isin $1)) ecfg
}
alias _esaveacc {
  set %.cfg EMail $+ $1
  set %email.pu [ $+ [ $1 ] ] $1. %email.account
  _writemailc %.cfg name %email.account
  _writemailc %.cfg smtp %email.smtp
  _writemailc %.cfg pop3 %email.pop3
  _writemailc %.cfg user %email.user
  _writemailc %.cfg pw %email.pw
  _writemailc %.cfg addr %email.email
  _writemailc %.cfg reply %email.replyto
  _writemailc %.cfg who %email.ffrom
  _writemailc %.cfg org %email.org
  _writemailc %.cfg sig %email.sig
  _writemailc %.cfg cret %email.cret
  _writemailc %.cfg wrap %email.wrap
  _writemailc %.cfg ccsend %email.fastsend
  _writemailc %.cfg auto %email.autocheck
}
alias _eloadacc {
  set %.cfg EMail $+ $1
  set %email.accnum $1
  set %email.account $_mailcfg(%.cfg,name)
  set %email.curr Current- %email.accnum $+ . %email.account
  set %email.smtp $_mailcfg(%.cfg,smtp)
  set %email.pop3 $_mailcfg(%.cfg,pop3)
  set %email.user $_mailcfg(%.cfg,user)
  set %email.pw $_mailcfg(%.cfg,pw)
  set %email.email $_mailcfg(%.cfg,addr)
  set %email.replyto $_mailcfg(%.cfg,reply)
  set %email.ffrom $_mailcfg(%.cfg,who)
  set %email.org $_mailcfg(%.cfg,org)
  set %email.sig $_mailcfg(%.cfg,sig)
  set %email.cret $_mailcfg(%.cfg,cret)
  set %email.wrap $_mailcfg(%.cfg,wrap)
  set %email.fastsend $_mailcfg(%.cfg,ccsend)
  set %email.autocheck $_mailcfg(%.cfg,auto)
}
alias email {
  if ($left($1,2) isin cfcose) ecfg $2-
  elseif ($left($1,2) == ac) eacc $2-
  elseif ($left($1,1) isin snme) esend $2-
  elseif ($left($1,1) isin ab) ebook
  else echeck
}
menu menubar {
  -
  E-Mail
  .Check...:echeck
  .Compose new...:esend
  .Address book...:ebook
  .-
  .Account
  ..%email.curr:eacc %email.accnum
  ..-
  ..%email.pu1:eacc 1
  ..%email.pu2:eacc 2
  ..%email.pu3:eacc 3
  ..%email.pu4:eacc 4
  ..%email.pu5:eacc 5
  ..%email.pu6:eacc 6
  ..%email.pu7:eacc 7
  ..%email.pu8:eacc 8
  ..%email.pu9:eacc 9
  ..-
  ..New account...:eacc n
  ..Delete current
  ...Yes I'm sure:eacc d
  ..Rename current...:set %_arhelp ecfg n | _askr _arhelp New name for account %email.accnum $+ ?
  .Configure...:ecfg
  .Auto check
  ..When
  ...$_dynpop($_if( [ %email.auto.when ] == off)) Disable:set %email.auto.when off | disp E-Mail auto check disabled.
  ...$_dynpop($_if( [ %email.auto.when ] == away)) Only when away:set %email.auto.when away | disp E-Mail auto check will only occur when you are away.
  ...$_dynpop($_if( [ %email.auto.when ] == here)) Only when here:set %email.auto.when here | disp E-Mail auto check will only occur when you are not away.
  ...$_dynpop($_if( [ %email.auto.when ] == on)) Anytime:set %email.auto.when on | disp E-Mail auto check enabled. (will occur whether you are away or not)
  ..Frequency
  ...Currently every %email.auto.freq minutes:disp E-Mail auto check occurs every %email.auto.freq minutes.
  ...-
  ...Every 5 minutes:_acsfreq 5
  ...Every 10 minutes:_acsfreq 10
  ...Every 15 minutes:_acsfreq 15
  ...Every 20 minutes:_acsfreq 20
  ...Every X minutes...:_askr _acsfreq Number of minutes between e-mail checks?
  ..Only if idle
  ...Currently must idle %email.auto.idle %email.auto.idlet:disp E-Mail auto check only occurs if you are idle %email.auto.idle %email.auto.idlet or more.
  ...-
  ...Idle 0 seconds:_acsidle 0 s
  ...Idle 15 seconds:_acsidle 15 s
  ...Idle 30 seconds:_acsidle 30 s
  ...Idle 60 seconds:_acsidle 60 s
  ...Idle 5 minutes:_acsidle 5
  ...Idle 10 minutes:_acsidle 10
  ...Idle X minutes...:_askr _acsidle Number of minutes you must idle before e-mail check will occur?
  ..Account
  ...$_dynpop($_if( [ %email.auto.acc ] == curr)) Current only:set %email.auto.acc curr | disp E-Mail auto check will only check the currently loaded account. (assuming auto check is on for that account)
  ...$_dynpop($_if( [ %email.auto.acc ] == all)) All accounts:set %email.auto.acc all | disp E-Mail auto check will check all accounts that have auto check enabled.
  ...$_dynpop($_if( [ %email.auto.acc ] == cycle)) Current, then load next:set %email.auto.acc cycle | disp E-Mail auto check will check the currently loaded account, then load the next account (in order) that has auto check enabled.
  ..If found
  ...$_dynpop($_if( [ %email.auto.do ] == tb)) Show in titlebar:set %email.auto.do tb | disp If e-mail is detected, a count of new messages will be shown in the mIRC titlebar.
  ...$_dynpop($_if( [ %email.auto.do ] == note)) Display note:set %email.auto.do note | disp If e-mail is detected, a note will be displayed in the active window.
  ...$_dynpop($_if( [ %email.auto.do ] == win)) Popup window:set %email.auto.do win | disp If e-mail is detected, the e-mail window will be displayed.
  ...$_dynpop($_if( [ %email.auto.do ] == get)) Get headers:set %email.auto.do get | disp If e-mail is detected, the e-mail window will be displayed and the e-mail headers will be downloaded.
  ..-
  ..Defaults (on):set %email.auto.when on | set %email.auto.freq 10 | set %email.auto.idle 0 | set %email.auto.acc curr | set %email.auto.do tb | disp Automatic e-mail checks enabled with default behavior.
  .-
  .Get mail
  ..$_dynpop(%email.get.reverse) in reverse order:dispa Mail will be downloaded in "reverse" order, so the OLDEST message will be displayed on top. | set %email.get.reverse $true
  ..$_dynpop($_not(%email.get.reverse)) in normal order:dispa Mail will be downloaded in "normal" order, so the NEWEST message will be displayed on top. | set %email.get.reverse $false
  ..-
  ..$_dynpop($_not(%email.get.min)) normal window:dispa Mail windows will open normally, as they are downloaded | set %email.get.min $false
  ..$_dynpop(%email.get.min) minimized:dispa Mail windows will be minimized as you receive them, for you to restore manually yourself | set %email.get.min $true
  .-
  .Help:help ! e-mail system
}
alias _acsfreq set %email.auto.freq $1 | disp E-Mail auto check will occur every %email.auto.freq minutes. | _acstimer
alias _acsidle set %email.auto.idle $1 | if ($2 == s) set %email.auto.idlet seconds | else set %email.auto.idlet minutes | disp E-Mail auto check will only occur if you are idle %email.auto.idle %email.auto.idlet or more.
on 1:start:_acstimer
alias _acstimer if (%email.auto.freq > 0) .timer915 -o 1 $calc(%email.auto.freq * 60) _acsdo
alias _acstimerq if (%email.auto.freq > 0) .timer915 -o 1 $calc(%email.auto.freq * 20) _acsdo
alias _acsdo {
  if (%email.auto.when == off) { _acstimer | return }
  if ((%email.auto.when == away) && (%_away.why == $null)) { _acstimer | return }
  if ((%email.auto.when == here) && (%_away.why != $null)) { _acstimer | return }
  set %.idle $idle
  if (%email.auto.idlet != seconds) set %.idle $calc(%.idle / 60)
  if (%.idle < %email.auto.idle) { _acstimerq | return }
  set %.wins $window(0)
  if (%.wins > 0) {
    if (($_isopen(@Progress)) || ($_isopen(@Error)) || ($_isopen(@Quick))) { _acstimerq | return }
    :loopw
    set %.winw $window(%.wins)
    if (EMail isin %.winw) { _acstimer | return }
    if ($_vd(.wins) > 0) goto loopw
  }
  unset %-+eacs.halt
  if (%email.auto.acc == curr) {
    if (%email.autocheck !isin onyesenabled$true) { _acstimer | return }
    echeck q
  }
  else {
    if (%email.autocheck !isin onyesenabled$true) {
      set %.load $_acsfind(%email.accnum)
      if (%.load == $null) { _acstimer | return }
      _eloadacc %.load
    }
    set %-eacs.start %email.accnum
    echeck q
  }
  _acstimer
}
alias _acsfind {
  set %.next $_i($1)
  :loop
  if (%.next > %email.acclast) set %.next 1
  if (%.next == %email.accnum) set %.isac %email.autocheck
  else { set %.nini EMail $+ %.next | set %.isac $_mailcfg(%.nini,auto) }
  if (%.isac isin onyesenabled$true) return %.next
  if (%.next == $1) return $null
  inc %.next
  goto loop
}
alias _eac.fin {
  if ($2 > 0) {
    if (%email.auto.do == tb) { .enable #_email-tb | set %_email-tb - E-Mail: $2 on %email.account }
    elseif (%email.auto.do == note) dispa New e-mail detected- %col.target $+ $2 messages. ( $+ $3 bytes) (account %email.accnum $+ - %email.account $+ )
    elseif (%email.auto.do == win) {
      window -c @EMail
      window -l @EMail $_winpos(14%,7%,8%,8%) @EMail %font.basic
      titlebar @EMail check
      aline @EMail $chr(160)
      aline @EMail New e-mail detected- (account %email.accnum $+ - %email.account $+ )
      aline @EMail $chr(160)
      aline @EMail --> %col.att $+ $2 <-- e-mail messages waiting ( $+ %col.dark $+ $3 bytes)
      aline @EMail $chr(160)
      aline @EMail Right-click on this window for options, press F4 to get message headers.
      window -b @EMail
      .enable #_epopup1
    }
    else _echeader
  }
  else {
    .disable #_email-tb
    if (%email.auto.acc != curr) {
      if (%-+eacs.halt) { unset %-+eacs.halt %-eacs.start | return }
      return
      set %.load $_acsfind(%email.accnum)
      if ((%.load == $null) || (%.load == %email.accnum)) return
      _eloadacc %.load
      if (%email.auto.acc == all) {
        if (%-eacs.start != %email.accnum) { echeck q | return }
      }
      unset %-eacs.start
    }
  }
}
on 1:load:{
  set %.ini $_ppdir $+ email.ini
  if ($exists(%.ini)) {
    set %email.get.reverse $_mailcfg(Settings,Get)
    set %email.auto.when $_mailcfg(Settings,When)
    set %email.auto.freq $_mailcfg(Settings,Freq)
    set %email.auto.idle $_mailcfg(Settings,Idle)
    set %email.auto.idlet $_mailcfg(Settings,IT)
    set %email.auto.acc $_mailcfg(Settings,Acc)
    set %email.auto.do $_mailcfg(Settings,Do)
    set %email.acclast $_mailcfg(Settings,A)
    set %email.book Book1
    set %.nuku %email.acclast
    :loop
    _eloadacc %.nuku
    _esaveacc %.nuku
    if ($_vd(.nuku) > 0) goto loop
  }
  else {
    set %email.get.reverse $true
    set %email.auto.when off
    set %email.auto.freq 15
    set %email.auto.idle 5
    set %email.auto.idlet minutes
    set %email.auto.acc curr
    set %email.auto.do note
    set %email.acclast 1
    set %email.account Default
    set %email.accnum 1
    set %email.email $email
    set %email.wrap 78
    set %email.curr Current- 1. Default
    set %email.pu1 1. Default
    set %email.book Book1
    set %email.fastsend on
    set %email.autocheck on
    unset %email.smtp %email.pop3 %email.user %email.sig %email.ffrom %email.org %email.replyto %email.pw %email.cret
    _esaveacc 1 | _writemailc Settings Books 1
    _writemailc Book1 Name Default Book
    _writemailc Book1 1 misspai <michiru@earthlink.net>
  }
}
alias _emunload {
  .timer915 off
  window -c @EMail | window -c @Address | window -c @Account
  _esaveacc %email.accnum
  _writemailc Settings Get %email.get.reverse
  _writemailc Settings When %email.auto.when
  _writemailc Settings Freq %email.auto.freq
  _writemailc Settings Idle %email.auto.idle
  _writemailc Settings IT %email.auto.idlet
  _writemailc Settings Acc %email.auto.acc
  _writemailc Settings Do %email.auto.do
  _writemailc Settings A %email.acclast
}
alias _cloem set %.loop $window(0) | :loop | if (@EMail?* iswm $window(%.loop)) window -c $window(%.loop) | if ($_vd(.loop) > 0) goto loop
