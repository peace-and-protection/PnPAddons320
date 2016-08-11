; -----------------------------------------------------
; Peace and Protection (by misspai)
; -----------------------------------------------------
; ADDON: Dice roller/etc.
; -----------------------------------------------------
on 1:load:_resdvar
alias -l _resdvar {
  set %dice.action $true | set %dice.d.chans all | set %dice.c.chans all
  set %dice.d.mustknow $false | set %dice.c.mustknow $false
  set %dice.local.ch-input-dice $false | set %dice.local.pr-input-dice $false
  set %dice.local.ch-text-dice $false | set %dice.local.pr-text-dice $false
  set %dice.m.trigger !calc * | set %dice.c.trigger !calc
  _setdcsc 5   14 4
}
alias -l _locpre return  $+ $colour(info) $+ ***
on 1:start:unset %dice.subdice*
; $_dice(x,y) rolls XdY
alias -l _dice {
  if (($1 < 1) || ($2 < 1)) return 0
  set %.numd $1
  set %.total $r(1,$2)
  if ($1 > 20) set %dice.subdice %dice.col.sub $+ (too many to list)
  else set %dice.subdice %dice.col.sub $+ %.total $+ 
  :loop
  if (%.numd > 1) {
    dec %.numd
    if ($1 > 20) inc %.total $r(1,$2)
    else {
      set %.rolled $r(1,$2)
      inc %.total %.rolled
      set %dice.subdice %dice.col.sub $+ %.rolled $+  %dice.col.subsep $+ .. %dice.subdice
    }
    goto loop
  }
  set %dice.subdicer $1 $+ d $+ $2
  set %dice.subdicet %.total
  return %.total
}
; Just like $calc except replaces all #d# pairs first (returns $null if errors found)
; Also replaces #..# with a random number of that range
alias -l _dcalc {
  set %.dcurr 0+ $replace($lower($1-),x,*) $+ +0
  if ($remove($remove($remove($remove($remove($remove($remove($remove($remove($remove($remove(%.dcurr,d),+),-),^),/),*),.),%),$chr(40)),$chr(41)),$chr(32)) !isnum) return
  unset %.subdice2
  :loop
  set %.dpos $pos(%.dcurr,d)
  if (%.dpos > 0) {
    unset %.dleft %.dright
    :loopL
    dec %.dpos
    if ($mid(%.dcurr,%.dpos,1) == $chr(32)) goto loopL
    if ($mid(%.dcurr,%.dpos,1) isnum) { set %.dleft $mid(%.dcurr,%.dpos,1) $+ %.dleft | goto loopL }
    set %.dpos2 $pos(%.dcurr,d)
    if ($mid(%.dcurr,$calc(%.dpos2 + 1),1) == d) { inc %.dpos2 | set %.calcit $true }
    else unset %.calcit
    :loopR
    inc %.dpos2
    if ($mid(%.dcurr,%.dpos2,1) == $chr(32)) goto loopR
    if ($mid(%.dcurr,%.dpos2,1) isnum) { set %.dright %.dright $+ $mid(%.dcurr,%.dpos2,1) | goto loopR }
    if (%.dright == $null) return
    if (%.dleft == $null) set %.dleft 1
    if (%.dleft > 100) return %dice.col.total $+ (Error: Too many dice)
    if (%.dright > 30000) return %dice.col.total $+ (Error: Dice too large)
    set %.dleft $_dice(%.dleft,%.dright)
    if (%.calcit) {
      if (%.subdice2 == $null) set %.subdice2 %dice.subdice
      else set %.subdice2 %.subdice2 $+ , %dice.subdice
    }
    set %.dcurr $left(%.dcurr,%.dpos) $+ %.dleft $+ $mid(%.dcurr,%.dpos2,$len(%.dcurr))
    goto loop
  }
  :loop2
  set %.dpos $pos(%.dcurr,..)
  if (%.dpos > 0) {
    unset %.dleft %.dright
    :loopL2
    dec %.dpos
    if ($mid(%.dcurr,%.dpos,1) == $chr(32)) goto loopL2
    if ($mid(%.dcurr,%.dpos,1) isnum) { set %.dleft $mid(%.dcurr,%.dpos,1) $+ %.dleft | goto loopL2 }
    set %.dpos2 $calc($pos(%.dcurr,..) + 1)
    :loopR2
    inc %.dpos2
    if ($mid(%.dcurr,%.dpos2,1) == $chr(32)) goto loopR2
    if ($mid(%.dcurr,%.dpos2,1) isnum) { set %.dright %.dright $+ $mid(%.dcurr,%.dpos2,1) | goto loopR2 }
    if (%.dright == $null) return
    if (%.dleft == $null) return
    if ($calc(%.dright - %.dleft) > 30000) return %dice.col.total $+ (Error: Range too big)
    if (%.dleft > %.dright) set %.dleft $r(%.dright,%.dleft)
    else set %.dleft $r(%.dleft,%.dright)
    set %.dcurr $left(%.dcurr,%.dpos) $+ %.dleft $+ $mid(%.dcurr,%.dpos2,$len(%.dcurr))
    goto loop2
  }
  if (%.subdice2) return %.subdice2 %dice.col.sep $+ => %dice.col.total $+ $calc(%.dcurr) $+ 
  return %dice.col.total $+ $calc(%.dcurr) $+ 
}
; Scans a line of text and evaluates all equations in it. (returns a nicely formatted output)
; Equations are series of numbers/operations (spaces allowed) with at least two numbers seperated by at least one operation, or a 'd#' alone.
; Special cases where all operations are / or all are - or all are x are ignored (dates, ranges, 1/2, resolution/sizes, etc) d0 by itself ignored
; Special checks for (2, 2), 123.23.53.12, etc (since these types of things can occur in normal text easily)
; If § or ==/=>/=byitself is present ANYWHERE it skips evaluation (to prevent infinite loops if many users run scripts like this)
; Spurious d and x and . and - before and after are stripped (for cases like "2d6 damage" or "and 2d7 gems") (before, must have a space to be spurious)
; Legal chars- 0123456789.()
; Legal operations- dx+-*/%^ (and ..)
; first param is - for normal, + to skip checks (for use with stuff like forced calculation)
alias -l _masseval set %.test * = * | if ((§ isin $2-) || (== isin $2-) || (=> isin $2-) || (%.test iswm $2-)) return | return $_masseval2($1,$replace($2-,$chr(32),))
alias -l _masseval2 {
  if (¶ isin $2-) return
  unset %.ret
  set %.mask $replace($replace($replace($replace($replace($replace($replace($replace($replace($replace($2-,0,¶),1,¶),2,¶),3,¶),4,¶),5,¶),6,¶),7,¶),8,¶),9,¶)
  set %.count 1
  :looper
  set %.pos $pos(%.mask,¶,%.count)
  if (%.pos > 0) {
    if ($mid($2-,%.pos,1) isnum) {
      set %.str $mid($2-,%.pos,1)
      set %.pos2 %.pos
      :loopR
      inc %.pos2
      if ($mid($2-,%.pos2,1) isin 0123456789.()dx+-*/%^) { set %.str %.str $+ $mid($2-,%.pos2,1) | goto loopR }
      :loopL
      dec %.pos
      if ($mid($2-,%.pos,1) isin .()d+-) { set %.str $mid($2-,%.pos,1) $+ %.str | goto loopL }
      :loopS1
      set %.bad (x*d.-
      if ($right(%.str,1) isin %.bad) { set %.str $left(%.str,$calc($len(%.str)-1)) | goto loopS1 }
      :loopS2
      set %.bad )x*
      if ($left(%.str,1) isin %.bad) { set %.str $right(%.str,$calc($len(%.str)-1)) | goto loopS2 }
      set %.str $remtok(%.str,,127)
      if ($1 == -) {
        set %.str2 $remove(%.str,)
        if ($remove(%.str2,/) isnum) goto next
        if ($remove(%.str2,-) isnum) goto next
        if ($remove(%.str2,x) isnum) goto next
        if (($remove($remove($remove(%.str,$chr(40)),$chr(41)),.) isnum) && (.. !isin %.str)) goto next
      }
      if (($left(%.str,1) == d) && ($remove(%.str,d) isnum) && ($remove(%.str,d) != 0)) set %.str d $+ $remove(%.str,d)
      elseif ($1 == -) {
        set %.str2 $remove($remove(%.str,$chr(40)),$chr(41))
        if ($remove(%.str2,) isnum) goto next
        if ($left(%.str2,1) == .) set %.chk $mid(%.str2,2,1)
        elseif ($left(%.str2,1) isin -+) {
          if ($mid(%str2,2,1) == .) set %.chk $mid(%.str2,3,1)
          else set %.chk $mid(%.str2,2,1)
        }
        else set %.chk $left(%.str2,1)
        if ((%.chk !isnum) || ($right(%.str2,1) !isnum)) goto next
      }
      set %.str $replace(%.str,,$chr(32))
      set %.is $_dcalc($replace(%.str,x,*))
      if (%.is != $null) {
        if (%.ret == $null) set %.ret %dice.col.equ $+ %.str $+  %dice.col.sep $+ => %.is
        else set %.ret %.ret $+ %dice.col.semi $+ ; %dice.col.equ $+ %.str $+  %dice.col.sep $+ => %.is
      }
    }
    :next
    set %.count %.pos2
    goto looper
  }
  if (%.ret) return %dice.col.logo $+ [§] %.ret
  return
}
#ch-text-calc on
on 1:text:%dice.m.trigger:#:{
  if (($findtok(%dice.c.chans,$chan,44) == $null) && (%dice.c.chans != all)) return
  if ((%dice.c.mustknow) && ($nick !isnotify) && ($level($fulladdress) == $dlevel)) return
  set %.dice $_masseval(+,$2-)
  if (%.dice != $null) _demsg $chan %.dice
  else _demsg $chan %dice.col.logo $+ [§] Error processing request
}
#ch-text-calc end
#pr-text-calc on
on 1:text:%dice.m.trigger:?:{
  if ((%dice.c.mustknow) && ($nick !isnotify) && ($level($fulladdress) == $dlevel)) return
  set %.dice $_masseval(+,$2-)
  if (%.dice != $null) _demsg $nick %.dice
  else _demsg $nick %dice.col.logo $+ [§] Error processing request
}
on 1:chat:%dice.m.trigger:{
  if (($nick == %_qlogin.nick) || ($nick == $me)) return
  set %.dice $_masseval(+,$2-)
  if (%.dice != $null) _demsg =$nick %.dice
  else _demsg =$nick %dice.col.logo $+ [§] Error processing request
}
#pr-text-calc end
#ch-input-dice on
on 1:input:#:{
  if ($left($1,1) == !) return
  if (($findtok(%dice.c.chans,$chan,44) == $null) && (%dice.c.chans != all)) return
  if ($left($1,1) != /) {
    set %.dice $_masseval(-,$1-)
    if (%.dice != $null) {
      say $1-
      if (%dice.local.ch-input-dice) echo $colour(norm) -a $_locpre %.dice
      else _demsg $target %.dice
      .enable #_inputhalt | halt
    }
  }
  elseif (($left($1,4) == /me) && (%dice.action)) {
    set %.dice $_masseval(-,$2-)
    if (%.dice != $null) {
      me $2-
      if (%dice.local.ch-input-dice) echo $colour(norm) -a $_locpre %.dice
      else _demsg $target %.dice
      .enable #_inputhalt | halt
    }
  }
}
#ch-input-dice end
#pr-input-dice off
on 1:input:?:{
  if ($left($1,1) == !) return
  if ($left($1,1) != /) {
    set %.dice $_masseval(-,$1-)
    if (%.dice != $null) {
      say $1-
      if (%dice.local.pr-input-dice) echo $colour(norm) -a $_locpre %.dice
      else _demsg $target %.dice
      .enable #_inputhalt | halt
    }
  }
  elseif (($left($1,4) == /me) && (%dice.action)) {
    set %.dice $_masseval(-,$2-)
    if (%.dice != $null) {
      me $2-
      if (%dice.local.pr-input-dice) echo $colour(norm) -a $_locpre %.dice
      else _demsg $target %.dice
      .enable #_inputhalt | halt
    }
  }
}
#pr-input-dice end
#ch-text-dice on
on 1:text:*:#:{
  if ($left($1,1) == !) return
  if (($findtok(%dice.d.chans,$chan,44) == $null) && (%dice.d.chans != all)) return
  if ((%dice.d.mustknow) && ($nick !isnotify) && ($level($fulladdress) == $dlevel)) return
  set %.dice $_masseval(-,$1-)
  if (%.dice != $null) {
    if (%dice.local.ch-text-dice) echo $colour(norm) $chan $_locpre %.dice
    else _demsg $chan %.dice
  }
}
on 1:action:*:#:{
  if (($findtok(%dice.d.chans,$chan,44) == $null) && (%dice.d.chans != all)) return
  if ((%dice.d.mustknow) && ($nick !isnotify) && ($level($fulladdress) == $dlevel)) return
  if (%dice.action) {
    set %.dice $_masseval(-,$1-)
    if (%.dice != $null) {
      if (%dice.local.ch-text-dice) echo $colour(norm) $chan $_locpre %.dice
      else _demsg $chan %.dice
    }
  }
}
#ch-text-dice end
#pr-text-dice on
on 1:text:*:?:{
  if ($left($1,1) == !) return
  if ((%dice.d.mustknow) && ($nick !isnotify) && ($level($fulladdress) == $dlevel)) return
  set %.dice $_masseval(-,$1-)
  if (%.dice != $null) {
    if (%dice.local.ch-text-dice) echo $colour(norm) $nick $_locpre %.dice
    else _demsg $nick %.dice
  }
}
on 1:action:*:?:{
  if (%dice.action) {
    if ((%dice.d.mustknow) && ($nick !isnotify) && ($level($fulladdress) == $dlevel)) return
    set %.dice $_masseval(-,$1-)
    if (%.dice != $null) {
      if (%dice.local.ch-text-dice) echo $colour(norm) $nick $_locpre %.dice
      else _demsg $nick %.dice
    }
  }
}
on 1:chat:*:{
  if (($nick == %_qlogin.nick) || ($nick == $me)) return
  if ($left($1,1) == !) return
  if ($1 == ACTION) {
    if (%dice.action) {
      set %.dice $_masseval(-,$remove($2-,))
      if (%.dice != $null) {
        if (%dice.local.ch-text-dice) echo $colour(norm) =$nick $_locpre %.dice
        else _demsg =$nick %.dice
      }
    }
  }
  else {
    set %.dice $_masseval(-,$1-)
    if (%.dice != $null) {
      if (%dice.local.ch-text-dice) echo $colour(norm) =$nick $_locpre %.dice
      else _demsg =$nick %.dice
    }
  }
}
#pr-text-dice end
; Local calculation
alias calc {
  if ($1 == $null) { echo $colour(info) -a $_locpre %dice.col.logo $+ [§] Usage: /calc equation to calculate an equation or dice roll locally | halt }
  set %.dice $_masseval(+,$1-)
  if (%.dice != $null) echo $colour(norm) -a $_locpre %.dice
  else echo $colour(norm) -a $_locpre %dice.col.logo $+ [§] Error evaluating
}
; Said calculation
alias scalc {
  if ($1 == $null) { echo $colour(info) -a $_locpre %dice.col.logo $+ [§] Usage: /scalc equation to say a calculated equation or dice roll to the current window | halt }
  set %.dice $_masseval(+,$1-)
  if (%.dice != $null) say %.dice
  else echo $colour(norm) -a $_locpre %dice.col.logo $+ [§] Error evaluating
}
alias msgcalc {
  if ($2 == $null) return
  set %.dice $_masseval(+,$2-)
  if (%.dice != $null) msg $1 %.dice
  else echo $colour(norm) -a $_locpre %dice.col.logo $+ [§] Error evaluating
}
; Repeated calculation
alias recalc {
  if ($2 == $null) { echo $colour(info) -a $_locpre %dice.col.logo $+ [§] Usage: /recalc N equation to repeat equation N times (usually repeated dice rolls) | halt }
  set %.times $1
  :loop
  calc $2-
  if (%.times > 1) { dec %.times | goto loop }
}
alias rescalc {
  if ($2 == $null) { echo $colour(info) -a $_locpre %dice.col.logo $+ [§] Usage: /rescalc N equation to repeat (and say) equation N times (usually repeated dice rolls) | halt }
  set %.times $1
  :loop
  scalc $2-
  if (%.times > 1) { dec %.times | goto loop }
}
alias remsgcalc {
  if ($3 == $null) return
  set %.times $2
  :loop
  msgcalc $1 $3-
  if (%.times > 1) { dec %.times | goto loop }
}
; Recent dice breakup
alias subdice {
  if (%dice.subdice == $null) echo $colour(info) -a $_locpre %dice.col.logo $+ [§] No dice have been rolled
  else echo $colour(norm) -a $_locpre %dice.col.logo $+ [§]  $+ $colour(info) $+ Last dice roll was %dice.col.equ $+ %dice.subdicer $+  %dice.col.sep $+ => %dice.subdice %dice.col.sep $+ => %dice.col.total $+ %dice.subdicet $+ 
}
; quiet msg with special echo
alias -l _demsg {
  if ($left($1,1) == =) msg $1-
  else {
    .raw privmsg $1 : $+ $2-
    .timer -m 1 1 echo $colour(norm) $1 > $2-
  }
}
alias helpdice dicehelp
alias dicehelp edit $scriptdirdice.txt
alias dicecfg cfgdice
alias cfgdice {
  window -c @DiceConfig
  window -l -t $+ $int($calc(27 * %font.fixtab / 18)) @DiceConfig $_winpos(0%,0%,14%,14%) @DiceConfig %font.basic
  titlebar @DiceConfig - Right-click for help
  aline @DiceConfig Double click on an option to toggle or modify, right-click for help.
  aline @DiceConfig %=
  aline @DiceConfig Activate on equations/dice in channel text 	: $_tf2yn($group(#ch-text-dice))
  aline @DiceConfig Activate on equations/dice in private text 	: $_tf2yn($group(#pr-text-dice))
  aline @DiceConfig Display results locally only (their channel text)	: $_tf2yn(%dice.local.ch-text-dice)
  aline @DiceConfig Display results locally only (their private text)	: $_tf2yn(%dice.local.pr-text-dice)
  aline @DiceConfig Activate on actions as well as text 	: $_tf2yn(%dice.action)
  aline @DiceConfig Activate in which channels	: %dice.d.chans
  aline @DiceConfig Only activate for users on notify/userlist	: $_tf2yn(%dice.d.mustknow)
  aline @DiceConfig %=
  aline @DiceConfig Activate on equations/dice in your channel text 	: $_tf2yn($group(#ch-input-dice))
  aline @DiceConfig Activate on equations/dice in your private text 	: $_tf2yn($group(#pr-input-dice))
  aline @DiceConfig Display results locally only (your channel text)	: $_tf2yn(%dice.local.ch-input-dice)
  aline @DiceConfig Display results locally only (your private text)	: $_tf2yn(%dice.local.pr-input-dice)
  aline @DiceConfig %=
  aline @DiceConfig Activate on !calculation requests in channel text 	: $_tf2yn($group(#ch-text-calc))
  aline @DiceConfig Activate on !calculation requests in private text 	: $_tf2yn($group(#pr-text-calc))
  aline @DiceConfig Activate in which channels	: %dice.c.chans
  aline @DiceConfig Only activate for users on notify/userlist	: $_tf2yn(%dice.c.mustknow)
  aline @DiceConfig !Calculation request command/trigger	: %dice.c.trigger
  aline @DiceConfig %=
  aline @DiceConfig Add to menubar popups (P&P Tools menu) 	: $_tf2yn($group(#dice-menu-pop))
  aline @DiceConfig Add to channel popups 	: $_tf2yn($group(#dice-chan-pop))
  aline @DiceConfig Add to query/DCC chat popups 	: $_tf2yn($group(#dice-qch-pop))
  aline @DiceConfig %=
  aline @DiceConfig Double click on an example to change the current color scheme
  aline @DiceConfig Current - %dice.col.logo $+ [§] %dice.col.equ $+ 5dd6 %dice.col.sep $+ => %dice.col.sub $+ 2 %dice.col.subsep $+ .. %dice.col.sub $+ 5 %dice.col.subsep $+ .. %dice.col.sub $+ 6 %dice.col.subsep $+ .. %dice.col.sub $+ 5 %dice.col.subsep $+ .. %dice.col.sub $+ 3 %dice.col.sep $+ => %dice.col.total $+ 21
  aline @DiceConfig %=
  aline @DiceConfig [§] 55dd6 => 2 14.. 5 14.. 6 14.. 5 14.. 3 => 0421
  aline @DiceConfig [§] 35dd6 => 2 14.. 5 14.. 6 14.. 5 14.. 3 => 0421
  aline @DiceConfig [§] 95dd6 => 2 14.. 5 14.. 6 14.. 5 14.. 3 => 0421
  aline @DiceConfig [§] 5dd6 14=> 2 15.. 5 15.. 6 15.. 5 15.. 3 14=> 21
  aline @DiceConfig [§] 5dd6 15=> 2 14.. 5 14.. 6 14.. 5 14.. 3 15=> 21
  aline @DiceConfig [§] 125dd6 => 022 .. 025 .. 026 .. 025 .. 023 => 1221
  aline @DiceConfig [§] 115dd6 => 102 .. 105 .. 106 .. 105 .. 103 => 1121
  aline @DiceConfig [§] 105dd6 => 022 .. 025 .. 026 .. 025 .. 023 => 1021
  aline @DiceConfig %=
  aline @DiceConfig [§] 5dd6 => 2 .. 5 .. 6 .. 5 .. 3 => 21
  aline @DiceConfig [§] 5dd6 => 2 .. 5 .. 6 .. 5 .. 3 => 21
  aline @DiceConfig [§] 5dd6 => 2 .. 5 .. 6 .. 5 .. 3 => 21
  aline @DiceConfig [§] 5dd6 => 2 .. 5 .. 6 .. 5 .. 3 => 21
  aline @DiceConfig [§] 5dd6 => 2 .. 5 .. 6 .. 5 .. 3 => 21
  aline @DiceConfig [§] 5dd6 => 2 .. 5 .. 6 .. 5 .. 3 => 21
  aline @DiceConfig [§] 5dd6 => 2 .. 5 .. 6 .. 5 .. 3 => 21
  aline @DiceConfig [§] 5dd6 => 2 .. 5 .. 6 .. 5 .. 3 => 21
  aline @DiceConfig [§] 5dd6 => 2 .. 5 .. 6 .. 5 .. 3 => 21
  aline @DiceConfig [§] 5dd6 => 2 .. 5 .. 6 .. 5 .. 3 => 21
}
alias -l _tf2yn if (($1 == $true) || ($1 == on)) return YES | return NO
alias -l _togg if ($group($1) == on) .disable $1 | else .enable $1
alias -l _tog2 if (% [ $+ [ $1 ] ] == $true) set % [ $+ [ $1 ] ] $false | else set % [ $+ [ $1 ] ] $true
alias _tog3 {
  if ($5 == $null) { set %_arhelp _tog3 $1-5 | _pentry _arhelp $+ $_s2p(% [ $+ [ $2 ] ] ) Channels in which to activate on $3-4 $+ ? (Enter all for all channels) }
  set % [ $+ [ $2 ] ] $_s2c($5-)
  rline @DiceConfig $1 Activate in which channels	: % [ $+ [ $2 ] ]
}
alias _tog4 {
  if ($1 == $null) _pentry _tog4 $+ $_s2p(%dice.c.trigger) Trigger command for !calculation requests?
  set %dice.c.trigger $1
  set %dice.m.trigger $1 *
  rline @DiceConfig 20 !Calculation request command/trigger	: %dice.c.trigger
}
menu @DiceConfig {
  dclick {
    if ($1 == 3) { _togg #ch-text-dice | rline @DiceConfig 3 Activate on equations/dice in channel text 	: $_tf2yn($group(#ch-text-dice)) }
    elseif ($1 == 4) { _togg #pr-text-dice | rline @DiceConfig 4 Activate on equations/dice in private text 	: $_tf2yn($group(#pr-text-dice)) }
    elseif ($1 == 5) { _tog2 dice.local.ch-text-dice | rline @DiceConfig 5 Display results locally only (their channel text)	: $_tf2yn(%dice.local.ch-text-dice) }
    elseif ($1 == 6) { _tog2 dice.local.pr-text-dice | rline @DiceConfig 6 Display results locally only (their private text)	: $_tf2yn(%dice.local.pr-text-dice) }
    elseif ($1 == 7) { _tog2 dice.action | rline @DiceConfig 7 Activate on actions as well as text 	: $_tf2yn(%dice.action) }
    elseif ($1 == 8) _tog3 8 dice.d.chans inline equations/dice
    elseif ($1 == 9) { _tog2 dice.d.mustknow | rline @DiceConfig 9 Only activate for users on notify/userlist	: $_tf2yn(%dice.d.mustknow) }
    elseif ($1 == 11) { _togg #ch-input-dice | rline @DiceConfig 11 Activate on equations/dice in your channel text 	: $_tf2yn($group(#ch-input-dice)) }
    elseif ($1 == 12) { _togg #pr-input-dice | rline @DiceConfig 12 Activate on equations/dice in your private text 	: $_tf2yn($group(#pr-input-dice)) }
    elseif ($1 == 13) { _tog2 dice.local.ch-input-dice | rline @DiceConfig 13 Display results locally only (your channel text)	: $_tf2yn(%dice.local.ch-input-dice) }
    elseif ($1 == 14) { _tog2 dice.local.pr-input-dice | rline @DiceConfig 14 Display results locally only (your private text)	: $_tf2yn(%dice.local.pr-input-dice) }
    elseif ($1 == 16) { _togg #ch-text-calc | rline @DiceConfig 16 Activate on !calculation requests in channel text 	: $_tf2yn($group(#ch-text-calc)) }
    elseif ($1 == 17) { _togg #pr-text-calc | rline @DiceConfig 17 Activate on !calculation requests in private text 	: $_tf2yn($group(#pr-text-calc)) }
    elseif ($1 == 18) _tog3 18 dice.c.chans !calculation requests
    elseif ($1 == 19) { _tog2 dice.c.mustknow | rline @DiceConfig 19 Only activate for users on notify/userlist	: $_tf2yn(%dice.c.mustknow) }
    elseif ($1 == 20) _tog4
    elseif ($1 == 22) { _togg #dice-menu-pop | rline @DiceConfig 22 Add to menubar popups (P&P Tools menu) 	: $_tf2yn($group(#dice-menu-pop)) }
    elseif ($1 == 23) { _togg #dice-chan-pop | rline @DiceConfig 23 Add to channel popups 	: $_tf2yn($group(#dice-chan-pop)) }
    elseif ($1 == 24) { _togg #dice-qch-pop | rline @DiceConfig 24 Add to query/DCC chat popups 	: $_tf2yn($group(#dice-qch-pop)) }
    elseif ($1 == 29) _setdcsc 5   14 4
    elseif ($1 == 30) _setdcsc 3   14 4
    elseif ($1 == 31) _setdcsc 9   14 4
    elseif ($1 == 32) _setdcsc  14  15 
    elseif ($1 == 33) _setdcsc  15  14 
    elseif ($1 == 34) _setdcsc 12  2 - 12
    elseif ($1 == 35) _setdcsc 11  10 - 11
    elseif ($1 == 36) _setdcsc 10  2 - 10
    elseif ($1 == 38) _setdcsc    - 
    elseif ($1 == 39) _setdcsc    - 
    elseif ($1 == 40) _setdcsc  - - - 
    elseif ($1 == 41) _setdcsc - - - - 
    elseif ($1 == 42) _setdcsc  - - - 
    elseif ($1 == 43) _setdcsc - - - - 
    elseif ($1 == 44) _setdcsc - - - - 
    elseif ($1 == 45) _setdcsc  - - - 
    elseif ($1 == 46) _setdcsc  - - - 
    elseif ($1 == 47) _setdcsc - - - - -
  }
  Help:dicehelp
  -
  Close:window -c @DiceConfig
}
; _setdcsc Equation => SubDice ..; Total
alias -l _setdcsc {
  set %dice.col.logo | set %dice.col.equ $remove($1,-) | set %dice.col.total $remove($5,-) | set %dice.col.sep $remove($2,-) | set %dice.col.sub $remove($3,-) | set %dice.col.semi $remove($4,-) | set %dice.col.subsep $remove($4,-)
  if ($window(@DiceConfig) != $null) rline @DiceConfig 27 Current - %dice.col.logo $+ [§] %dice.col.equ $+ 5dd6 %dice.col.sep $+ => %dice.col.sub $+ 2 %dice.col.subsep $+ .. %dice.col.sub $+ 5 %dice.col.subsep $+ .. %dice.col.sub $+ 6 %dice.col.subsep $+ .. %dice.col.sub $+ 5 %dice.col.subsep $+ .. %dice.col.sub $+ 3 %dice.col.sep $+ => %dice.col.total $+ 21
}
alias _rcpart2 set %.temp.eq $1- | _askr _rcpart3 How many times should we roll/calculate?
alias _rscpart2 set %.temp.eq $2- | set %_arhelp _rscpart3 $1 | _askr _arhelp How many times should we roll/calculate?
alias _rcpart3 recalc $1 %.temp.eq
alias _rscpart3 remsgcalc $1-2 %.temp.eq
#dice-menu-pop on
menu menubar {
  -
  Dice
  .Calculate:_askr calc Equation to calculate or dice to roll? (ex: 5d6 + 3)
  .Calc + Say:set %_arhelp msgcalc $active | _askr _arhelp Equation to calculate or dice to roll? (ex: 5d6 + 3)
  .-
  .Repeat Calc:_askr _rcpart2 Dice (or equation) to roll (calculate) multiple times? (ex: 4dd6)
  .Repeat Calc + Say:set %_arhelp _rscpart2 $active | _askr _arhelp Dice (or equation) to roll (calculate) multiple times? (ex: 4dd6)
  .-
  .Last roll's subdice:subdice
  .-
  .Configure:dicecfg
  .-
  .Help:dicehelp
}
#dice-menu-pop end
#dice-chan-pop off
menu channel {
  -
  Dice
  .Calculate:_askr calc Equation to calculate or dice to roll? (ex: 5d6 + 3)
  .Calc + Say:set %_arhelp msgcalc $active | _askr _arhelp Equation to calculate or dice to roll? (ex: 5d6 + 3)
  .-
  .Repeat Calc:_askr _rcpart2 Dice (or equation) to roll (calculate) multiple times? (ex: 4dd6)
  .Repeat Calc + Say:set %_arhelp _rscpart2 $active | _askr _arhelp Dice (or equation) to roll (calculate) multiple times? (ex: 4dd6)
  .-
  .Last roll's subdice:subdice
  .-
  .Configure:dicecfg
  .-
  .Help:dicehelp
}
#dice-chan-pop end
#dice-qch-pop off
menu query {
  -
  Dice
  .Calculate:_askr calc Equation to calculate or dice to roll? (ex: 5d6 + 3)
  .Calc + Say:set %_arhelp msgcalc $active | _askr _arhelp Equation to calculate or dice to roll? (ex: 5d6 + 3)
  .-
  .Repeat Calc:_askr _rcpart2 Dice (or equation) to roll (calculate) multiple times? (ex: 4dd6)
  .Repeat Calc + Say:set %_arhelp _rscpart2 $active | _askr _arhelp Dice (or equation) to roll (calculate) multiple times? (ex: 4dd6)
  .-
  .Last roll's subdice:subdice
  .-
  .Configure:dicecfg
  .-
  .Help:dicehelp
}
#dice-qch-pop end
