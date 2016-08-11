; -----------------------------------------------------
; Peace and Protection (by misspai)
; -----------------------------------------------------
; ADDON: Whiteboard (part 2)
; -----------------------------------------------------
; Stuff from part 1 (to keep -l switch)
; -----------------------------------------------------
alias -l noact return   
alias -l yesact return >
alias -l tell echo $colour(info) -s *** $1- | write wbevent.log $1-
alias -l event set %ppwb.event $1- | updwbtitle | write wbevent.log $1-
alias -l wbreset .timerwbtoolcheck off | sockclose PPWB* | unset %ppwb.* | .disable #ppwbdns | window -c @WBoard | window -c @WBoardPeople
alias -l wbkill set %ppwb.side local | titlebar @WBoard [local] $1- | sockclose PPWB* | .disable #ppwbdns | window -c @WBoardPeople | write wbevent.log ERROR- $1- | _error $1-
alias -l updwbtitle {
  if (%ppwb.side == client) titlebar @WBoard : %ppwb.me on %ppwb.server $+ [[ $+ %ppwb.port $+ ]] Users: $gettok(%ppwb.users,0,32) - %ppwb.event
  elseif (%ppwb.side == server) titlebar @WBoard : %ppwb.me on [[ $+ %ppwb.port $+ ]] Users: $calc($sock(PPWB-*,0) + 1) - %ppwb.event
  elseif (%ppwb.side == chan) titlebar @WBoard [[ $+ %ppwb.server $+ ]] - %ppwb.event
}
alias -l clearwb { clear @WBoard | drawrect -rf @WBoard 16777215 1 0 0 $window(@WBoard).dw $window(@WBoard).dh }
alias -l wbdesk if (%ppwbs.dtop) return d | return
; -----------------------------------------------------
; Starting the whiteboard
; -----------------------------------------------------
alias wbforce set %.force $true | wb $1-
alias wb {
  wbreset
  if ($exists(wbevent.log)) .remove wbevent.log
  if (($1 == 0) || ($1 == local)) {
    tell Starting up whiteboard locally... (no connections will be sent or accepted)
    set %ppwb.side local
    goto local
  }
  if ($me == $null) _error You do not have a nickname, whiteboard could not be started
  set %ppwb.me $me
  set %ppwb.side server
  set %ppwb.server $me
  if ($_ischan($1)) {
    if ($len($1) == 1) set %.chan #
    else set %.chan $1
    if ($me !ison %.chan) _error You must be on the channel to run a whiteboard in it
    if (([whiteboard] !isin $chan(%.chan).topic) && ($chan(%.chan).limit != 5050)) _error Channel topic must contain "[whiteboard]" or channel limit must be 5050 for whiteboard use to be allowed
    set %ppwb.server %.chan
    set %ppwb.side chan
  }
  elseif ($1 isnum) set %ppwb.port $1
  elseif ($1 == $null) set %ppwb.port 5050
  else {
    set %ppwb.side client
    if ($longip($1) == $null) {
      if (. isin $1) set %.addr $1
      else set %.addr $_nickglob($1)
      tell Looking up address of %.addr for whiteboard connection...
      set %ppwb.lookup %.addr
      .dns %.addr
      .enable #ppwbdns
      halt
    }
    set %ppwb.server $1
    if ($2 isnum) set %ppwb.port $2
    else set %ppwb.port 5050
    set %ppwb.users %ppwb.me
  }
  if (%.force != $true) if (%ppwb.side == server) if ($portfree(%ppwb.port) != $true) _error Port %ppwb.port is not available, whiteboard could not be started
  unset %.force
  :local
  window -pl10 $+ $wbdesk @WBoard 10 10 780 460 @WBoard Arial 15
  set %ppwb.colors 0 8323072 37632 252 127 10223772 32764 64764 64512 9671424 16579584 16515072 16515324 8355711 13816530 16777215
  aline -l @WBoard $yesact Freehand
  aline -l @WBoard $noact Lines
  aline -l @WBoard $noact Line series
  aline -l @WBoard $noact Rectangles
  aline -l @WBoard $noact Boxes
  aline -l @WBoard $noact Ellipses
  aline -l @WBoard $noact Doughnuts
  aline -l @WBoard $noact Text
  aline -l @WBoard $noact Fill
  aline -l @WBoard *Chat/Users*
  aline -l @WBoard ————————————
  aline -l @WBoard Inverse: Off
  aline -l @WBoard Width: 3
  aline -l @WBoard (thicker +)
  aline -l @WBoard (thinner –)
  aline -l @WBoard ————————————
  aline -l @WBoard $noact (custom)
  aline -lc1 @WBoard $noact Black
  aline -lc2 @WBoard $yesact Blue
  aline -lc3 @WBoard $noact Green
  aline -lc4 @WBoard $noact Red
  aline -lc5 @WBoard $noact Brown
  aline -lc6 @WBoard $noact Purple
  aline -lc7 @WBoard $noact Orange
  aline -lc8 @WBoard $noact Yellow
  aline -lc9 @WBoard $noact Lime
  aline -lc10 @WBoard $noact Aqua
  aline -lc11 @WBoard $noact Lt. Aqua
  aline -lc12 @WBoard $noact Lt. Blue
  aline -lc13 @WBoard $noact Pink
  aline -lc14 @WBoard $noact Grey
  aline -lc15 @WBoard $noact Lt. Grey
  aline -l @WBoard $noact (white)
  set %ppwb.color 2
  set %ppwb.colorrgb 8323072
  set %ppwb.width 3
  set %ppwb.mode 2
  set %ppwb.inverse $false
  clearwb
  .timerwbtoolcheck -mo 0 150 wbtoolcheck
  if (%ppwb.side == server) {
    event Waiting for connections...
    set %ppwb.nextsock 1
    socklisten PPWBLISTEN %ppwb.port
    if ($ip == $null) tell Whiteboard is now open and waiting for connections on port %ppwb.port $+ ...
    else tell Whiteboard is now open and waiting for connections on port %ppwb.port $+ ... (IP- $ip $+ )
    if (%ppwbs.autochat) wbaux n
  }
  elseif (%ppwb.side == local) titlebar @WBoard [local]
  elseif (%ppwb.side == chan) {
    titlebar @WBoard [[ $+ %ppwb.server $+ ]]
    describe $chan ** has activated whiteboard **
  }
  else {
    event Attempting to connect to whiteboard...
    tell Whiteboard is attempting to connect to $1 on port %ppwb.port $+ ...
    sockopen PPWBCONNECT $1 %ppwb.port
  }
}
; -----------------------------------------------------
; Command receive
; -----------------------------------------------------
alias -l wbcolget if ($1 isletter) return $gettok(%ppwb.colors,$calc($asc($1) - 64),32) | return $1
alias -l wbfind1 return %ppwbs.pics $+ $1-
alias -l wbfind2 return $mircdir $+ $1-
alias -l wbfind3 return $getdir(*.bmp) $+ $1-
alias -l wbfind {
  if ($exists($wbfind1($1-))) return $wbfind1($1-)
  elseif ($exists($wbfind2($1-))) return $wbfind2($1-)
  elseif ($exists($wbfind3($1-))) return $wbfind3($1-)
}
alias -l wbget {
  if (%ppwb.old.cmd) { %ppwb.old.cmd -ir @WBoard %ppwb.old.line | unset %ppwb.old.cmd %ppwb.old.line }
  if (($1 == L) && ($7 != $null)) drawline -r @WBoard $wbcolget($2) $3-
  elseif ($1 == I) drawline -ir @WBoard $wbcolget($2) $3-
  elseif ($1 == R) drawrect $2 $+ r @WBoard $wbcolget($3) $4-
  elseif ($1 == F) drawfill -rs @WBoard $wbcolget($2) $3-
  elseif ($1 == T) drawtext -r @WBoard $wbcolget($2) $3-
  elseif ($1 == O) drawtext -ro @WBoard $wbcolget($2) $3-
  elseif ($1 == C) {
    drawrect -rf @WBoard $wbcolget($2) 1 0 0 $window(@WBoard).dw $window(@WBoard).dh
    event Whiteboard cleared by $3
  }
  elseif ($1 == P) {
    set %.found $wbfind($5-)
    if (%.found == $null) event File not found! (Picture " $+ $5- $+ " tried to load by $2 $+ )
    else {
      drawpic @WBoard $3 $4 %.found
      event Picture " $+ $5- $+ " loaded by $2
    }
  }
  elseif ($1 == M) {
    if ($window(@WBoardPeople) == $null) wbaux
    echo -i2 @WBoardPeople < $+ $2 $+ > $3-
    write wbevent.log < $+ $2 $+ > $3-
  }
  elseif ($1 == A) {
    if ($window(@WBoardPeople) == $null) wbaux
    echo $colour(act) -i2 @WBoardPeople * $2-
    write wbevent.log * $2-
  }
  else halt
}
; -----------------------------------------------------
; Channel transmission
; -----------------------------------------------------
ctcp 1:PPWB:#:{
  if ($chan == %ppwb.server) { set %.+ctcpprochalt $true | wbget $2- | halt }
  if (%ppwb. [ $+ [ $chan ] ] == $null) disprs $chan %col.target $+ $nick $+  is using whiteboard CTCPs on $chan (further use from user not shown)
  set -u300 %ppwb. [ $+ [ $chan ] ] $true | set %.+ctcpprochalt $true | halt
}
; -----------------------------------------------------
; Server-side sockets
; -----------------------------------------------------
on 1:socklisten:PPWBLISTEN:{
  if ($sockerr > 0) halt
  if ((%ppwb.limit != $null) && ($calc($sock(PPWB-*,0) + $sock(PPWBV*,0)) >= %ppwb.limit)) {
    event Incoming connection refused due to user limit
    sockaccept PPWBB [ $+ [ %ppwb.nextsock ] ]
    sockwrite -n PPWBB [ $+ [ %ppwb.nextsock ] ] BAN User limit has been reached
  }
  else {
    set %ppwb.newsock PPWBV [ $+ [ %ppwb.nextsock ] ]
    sockaccept %ppwb.newsock
    set %ppwb.newip $sock(%ppwb.newsock).ip
    if (($findtok(%ppwb.banned,%ppwb.newip,32) != $null) || ($findtok(%ppwb.banned,$gettok(%ppwb.newip,1-3,46),32) != $null)) {
      event Incoming connection refused; IP is banned ( $+ %ppwb.newip $+ )
      sockwrite -n %ppwb.newsock BAN Your IP is banned from the whiteboard
      sockrename %ppwb.newsock PPWBB [ $+ [ %ppwb.nextsock ] ]
    }
    else {
      event Incoming connection attempt...
      sockwrite -n %ppwb.newsock PPWB S %ppwb.me
    }
  }
  inc %ppwb.nextsock
}
on 1:sockwrite:PPWBB*:.timer -o 1 1 sockclose $sockname
on 1:sockclose:PPWBV*:event Connection attempt was cancelled or lost
on 1:sockread:PPWBV*:{
  sockread %ppwb.data
  if (($gettok(%ppwb.data,1,32) != PPWB) || ($gettok(%ppwb.data,2,32) != C) || ($gettok(%ppwb.data,3,32) == $null) || ($gettok(%ppwb.data,4,32) != $null)) {
    event Invalid connection attempt (dropped)
    sockclose $sockname
    halt
  }
  if ($gettok(%ppwb.data,3,32) == %ppwb.me) {
    event Incoming connection refused; Nickname is same as yours
    sockwrite -n $sockname BAN This nickname is already connected
    sockrename $sockname PPWBB [ $+ [ %ppwb.nextsock ] ]
    inc %ppwb.nextsock
    halt
  }
  sockmark $sockname $gettok(%ppwb.data,3,32)
  set %.loop $sock(PPWB-*,0)
  set %.who %ppwb.me
  if (%.loop > 0) {
    :loop
    if ($gettok(%ppwb.data,3,32) == $sock(PPWB-*,%.loop).mark) {
      event Incoming connection refused; Nickname is already connected
      sockwrite -n $sockname BAN This nickname is already connected
      sockrename $sockname PPWBB [ $+ [ %ppwb.nextsock ] ]
      inc %ppwb.nextsock
      halt
    }
    set %.who %.who $sock(PPWB-*,%.loop).mark
    if ($_vd(.loop) > 0) goto loop
  }
  sockwrite -n $sockname HI %.who
  if (%ppwb.force) sockwrite -n $sockname SIZE %ppwb.force
  if ($sock(PPWB-*,0) > 0) sockwrite -n PPWB-* HI $gettok(%ppwb.data,3,32)
  sockrename $sockname PPWB- $+ $mid($sockname,6,$len($sockname))
  event Connection accepted from $gettok(%ppwb.data,3,32)
  if ((%ppwbs.joinpart) && ($window(@WBoardPeople) != $null)) echo $colour(join) -i2 @WBoardPeople *** $gettok(%ppwb.data,3,32) has joined the whiteboard
  wbadduser $gettok(%ppwb.data,3,32)
}
on 1:sockclose:PPWB-*:{
  set %.loop $sock(PPWB-*,0)
  :loop
  if ($sock(PPWB-*,%.loop) != $sockname) sockwrite -n $sock(PPWB-*,%.loop) BYE $sock($sockname).mark connection lost
  if ($_vd(.loop) > 0) goto loop
  .timer -mo 1 1 event Connection to $sock($sockname).mark lost
  if ((%ppwbs.joinpart) && ($window(@WBoardPeople) != $null)) echo $colour(part) -i2 @WBoardPeople *** $sock($sockname).mark has exited the whiteboard (connection lost)
  wbremuser $sock($sockname).mark
}
on 1:sockread:PPWB-*:{
  sockread %ppwb.data
  if ($gettok(%ppwb.data,1,32) == BYE) {
    set %.who $sock($sockname).mark
    wbremuser $sock($sockname).mark
    if ((%ppwbs.joinpart) && ($window(@WBoardPeople) != $null)) echo $colour(part) -i2 @WBoardPeople *** $sock($sockname).mark has exited the whiteboard (disconnected normally)
    sockclose $sockname
    event %.who disconnected normally
    if ($sock(PPWB-*,0) > 0) sockwrite -n PPWB-* BYE %.who quit normally
  }
  if ($gettok(%ppwb.data,1,32) isin AM) {
    set %.newdata $gettok(%ppwb.data,1,32) $sock($sockname).mark $gettok(%ppwb.data,2-,32)
    wbget %.newdata
    set %.loop $sock(PPWB-*,0)
    :loop
    if ($sock(PPWB-*,%.loop) != $sockname) sockwrite -n $sock(PPWB-*,%.loop) %.newdata
    if ($_vd(.loop) > 0) goto loop
  }
  else {
    wbget %ppwb.data
    set %.loop $sock(PPWB-*,0)
    :loop
    if ($sock(PPWB-*,%.loop) != $sockname) sockwrite -n $sock(PPWB-*,%.loop) %ppwb.data
    if ($_vd(.loop) > 0) goto loop
  }
}
; -----------------------------------------------------
; Client-side sockets
; -----------------------------------------------------
on 1:sockopen:PPWBCONNECT:{
  if ($sockerr > 0) wbkill Could not connect to whiteboard server (error code $sockerr $+ )
  sockwrite -n PPWBCONNECT PPWB C %ppwb.me
  event Connection made, logging in...
}
on 1:sockclose:PPWBCONNECT:wbkill Connection attempt was closed by server or due to timeout
on 1:sockread:PPWBCONNECT:{
  sockread %ppwb.data
  if ($gettok(%ppwb.data,1,32) == BAN) { sockclose PPWBCONNECT | wbkill Whiteboard server refused connection ( $+ $gettok(%ppwb.data,2-,32) $+ ) }
  if (($gettok(%ppwb.data,1,32) != PPWB) || ($gettok(%ppwb.data,2,32) != S) || ($gettok(%ppwb.data,3,32) == $null) || ($gettok(%ppwb.data,4,32) != $null)) wbkill Invalid data received from whiteboard server; connection dropped
  set %ppwb.server $gettok(%ppwb.data,3,32)
  sockrename PPWBCONNECT PPWBWAITHI
  event Logged in, waiting for userlist...
}
on 1:sockclose:PPWBWAITHI:wbkill Connection attempt was closed by server or due to timeout
on 1:sockread:PPWBWAITHI:{
  sockread %ppwb.data
  if ($gettok(%ppwb.data,1,32) == BAN) { sockclose PPWBWAITHI | wbkill Whiteboard server refused connection ( $+ $gettok(%ppwb.data,2-,32) $+ ) }
  if (($gettok(%ppwb.data,1,32) != HI) || ($gettok(%ppwb.data,2,32) == $null)) wbkill Invalid data received from whiteboard server; connection dropped
  set %ppwb.users $gettok(%ppwb.data,2-,32) %ppwb.me
  sockrename PPWBWAITHI PPWBDATA
  event Connected to whiteboard
  if ($window(@WBoardPeople) != $null) wbaux
  elseif (%ppwbs.autochat) wbaux n
  if ((%ppwbs.joinpart) && ($window(@WBoardPeople) != $null)) echo $colour(join) -i2 @WBoardPeople *** You have connected to the whiteboard
}
on 1:sockclose:PPWBDATA:wbkill Connection to server was lost
on 1:sockread:PPWBDATA:{
  sockread %ppwb.data
  if ($gettok(%ppwb.data,1,32) == HI) {
    set %ppwb.users %ppwb.users $gettok(%ppwb.data,2,32)
    event User $gettok(%ppwb.data,2,32) connected to whiteboard
    if ((%ppwbs.joinpart) && ($window(@WBoardPeople) != $null)) echo $colour(join) -i2 @WBoardPeople *** $gettok(%ppwb.data,2,32) has joined the whiteboard
    wbadduser $gettok(%ppwb.data,2,32)
  }
  elseif ($gettok(%ppwb.data,1,32) == BYE) {
    set %ppwb.users $remtok(%ppwb.users,$gettok(%ppwb.data,2,32),32)
    event User $gettok(%ppwb.data,2,32) disconnected ( $+ $gettok(%ppwb.data,3-,32) $+ )
    if ((%ppwbs.joinpart) && ($window(@WBoardPeople) != $null)) echo $colour(part) -i2 @WBoardPeople *** $gettok(%ppwb.data,2,32) has exited the whiteboard ( $+ $gettok(%ppwb.data,3-,32) $+ )
    wbremuser $gettok(%ppwb.data,2,32)
  }
  elseif ($gettok(%ppwb.data,1,32) == QUIT) wbkill Server closed whiteboard; connection lost
  elseif ($gettok(%ppwb.data,1,32) == SIZE) window @WBoard $gettok(%ppwb.data,2-,32)
  elseif ($gettok(%ppwb.data,1,32) == KICK) wbkill You were kicked from the whiteboard ( $+ $gettok(%ppwb.data,2-,32) $+ )
  else wbget %ppwb.data
}
; -----------------------------------------------------
; Userlist (incl. kick/ban/add/rem)
; and chat window
; -----------------------------------------------------
alias wbaux {
  if (%ppwb.side == local) {
    window -c @WBoardPeople
    _error No userlist or chat window- WhiteBoard is local only
  }
  if (%ppwb.side == chan) {
    window -c @WBoardPeople
    _error No userlist or chat window when WhiteBoard is run in a channel
  }
  if (%ppwb.side == server) {
    if ($window(@WBoardPeople) == $null) window -el15 $+ $1 $+ $wbdesk @WBoardPeople @WBoardPeople
    else clear -l @WBoardPeople
    aline -l %ppwbs.colorserv @WBoardPeople %ppwb.me (server)
    set %.loop $sock(PPWB-*,0)
    if (%.loop > 0) {
      :loop
      aline -l @WBoardPeople $sock(PPWB-*,%.loop).mark
      if ($_vd(.loop) > 0) goto loop
    }
  }
  else {
    if ($window(@WBoardPeople) == $null) window -el15 $+ $1 $+ $wbdesk @WBoardPeople @WBoardPeople
    else clear -l @WBoardPeople
    set %.loop $gettok(%ppwb.users,0,32)
    :loop
    if ($gettok(%ppwb.users,%.loop,32) == %ppwb.server) aline -l %ppwbs.colorserv @WBoardPeople $gettok(%ppwb.users,%.loop,32) (server)
    elseif ($gettok(%ppwb.users,%.loop,32) == %ppwb.me) aline -l %ppwbs.coloryou @WBoardPeople $gettok(%ppwb.users,%.loop,32)
    else aline -l @WBoardPeople $gettok(%ppwb.users,%.loop,32)
    if ($_vd(.loop) > 0) goto loop
  }
  titlebar @WBoardPeople (users- $line(@WBoardPeople,0,1) $+ )
}
alias -l wbusline if ($sline(@WBoardPeople,0) < 1) halt | return $gettok($sline(@WBoardPeople,1),1,32)
alias -l wbfindsock {
  set %.loop $sock(PPWB-*,0)
  :loop
  if ($sock(PPWB-*,%.loop).mark == $1) { set %ppwb.foundip $sock(PPWB-*,%.loop).ip | return $sock(PPWB-*,%.loop) }
  if ($_vd(.loop) > 0) goto loop
  _error Internal error- Socket for $1 could not be located!
}
alias -l wbremuser {
  if ($window(@WBoardPeople) == $null) return
  set %.loop 2
  :loop
  if ($line(@WBoardPeople,%.loop,1) == $1) dline -l @WBoardPeople %.loop
  else inc %.loop
  if ($line(@WBoardPeople,%.loop,1) != $null) goto loop
  titlebar @WBoardPeople (users- $line(@WBoardPeople,0,1) $+ )
}
alias -l wbadduser {
  if ($window(@WBoardPeople) == $null) return
  aline -l @WBoardPeople $1
  titlebar @WBoardPeople (users- $line(@WBoardPeople,0,1) $+ )
}
alias -l wbdokick {
  if ($sline(@WBoardPeople,1).ln == 1) _error You cannot kick yourself from the whiteboard
  set %ppwb.kickwhy $$?="Reason to kick $wbusline from whiteboard?"
  sockrename $wbfindsock($wbusline) PPWBB [ $+ [ %ppwb.nextsock ] ]
  sockwrite -n PPWBB [ $+ [ %ppwb.nextsock ] ] KICK %ppwb.kickwhy
  inc %ppwb.nextsock
  if ($sock(PPWB-*,0) > 0) sockwrite -n PPWB-* BYE $wbusline kicked: %ppwb.kickwhy
  event User $wbusline kicked ( $+ %ppwb.kickwhy $+ )
  if ((%ppwbs.joinpart) && ($window(@WBoardPeople) != $null)) echo $colour(part) -i2 @WBoardPeople *** $wbusline has exited the whiteboard (kicked: %ppwb.kickwhy $+ )
  wbremuser $wbusline
}
alias -l popmus if (%ppwb.side == server) return Control | return
menu @WBoardPeople {
  $popmus
  .Kick:wbdokick
  .Kick and ban current IP:wbdokick | event Banned %ppwb.foundip | set %ppwb.banned %ppwb.banned %ppwb.foundip
  .Kick and ban IP range:wbdokick | event Banned $gettok(%ppwb.foundip,1-3,46) $+ .* | set %ppwb.banned %ppwb.banned $gettok(%ppwb.foundip,1-3,46)
  -
  Via IRC
  .Whois:whois $wbusline
  .Ping:ping $wbusline
  .-
  .Query:q $wbusline
  .DCC Chat:c $wbusline
  .DCC Send:s $wbusline
  -
  View log:run notepad wbevent.log
  -
  Copy:clipboard $wbusline
  Close:window -c @WBoardPeople
}
on 1:input:@WBoardPeople:{
  if ($1 == /me) {
    echo $colour(act) -i2 @WBoardPeople * %ppwb.me $2-
    if (%ppwb.side == server) { if ($sock(PPWB-*,0) > 0) sockwrite -n PPWB-* A %ppwb.me $2- }
    elseif (%ppwb.side == client) { if ($sock(PPWBDATA,0) > 0) sockwrite -n PPWBDATA A $2- }
    write wbevent.log * %ppwb.me $2-
    halt
  }
  elseif ($1 == /say) {
    echo -i2 @WBoardPeople < $+ %ppwb.me $+ > $2-
    if (%ppwb.side == server) { if ($sock(PPWB-*,0) > 0) sockwrite -n PPWB-* M %ppwb.me $2- }
    elseif (%ppwb.side == client) { if ($sock(PPWBDATA,0) > 0) sockwrite -n PPWBDATA M $2- }
    write wbevent.log < $+ %ppwb.me $+ > $2-
    halt
  }
  elseif ($left($1,1) != /) {
    echo -i2 @WBoardPeople < $+ %ppwb.me $+ > $1-
    if (%ppwb.side == server) { if ($sock(PPWB-*,0) > 0) sockwrite -n PPWB-* M %ppwb.me $1- }
    elseif (%ppwb.side == client) { if ($sock(PPWBDATA,0) > 0) sockwrite -n PPWBDATA M $1- }
    write wbevent.log < $+ %ppwb.me $+ > $1-
    halt
  }
}
; -----------------------------------------------------
; Resolving DNS
; -----------------------------------------------------
#ppwbdns off
on 1:dns:{
  if (%ppwb.lookup == $null) { .disable #ppwbdns | return }
  if (($nick == %ppwb.lookup) || ($naddress == %ppwb.lookup)) {
    if ($iaddress == $null) wbkill Address of %ppwb.lookup could not be found; Whiteboard connection failed
    else wb $iaddress %ppwb.port
    unset %ppwb.lookup
    .disable #ppwbdns
  }
}
#ppwbdns end
; -----------------------------------------------------
; Help
; -----------------------------------------------------
alias wbhelp {
  window -c @WB
  window -l $+ $wbdesk @WB $_winpos(15%,8%,8%,8%) @Close %font.basic
  titlebar @WB - Help on using the Whiteboard
  loadbuf @WB $scriptdirppwb.dat
}
