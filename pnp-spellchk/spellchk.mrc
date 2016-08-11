; -----------------------------------------------------
; Peace and Protection (by misspai)
; -----------------------------------------------------
; ADDON: Spell checker (by misspai)
; Loosely based on input21.mrc by CodeRx
; -----------------------------------------------------

menu MenuBar {
  -
  SpellCheck
  .Add word:_askr _word2 Misspelled word?
  .Remove word:%_arhelp = word -r | _askr _arhelp Word to remove from SpellCheck dictionary?
  .-
  .$_dynpop($iif($group(#ppSpellCheck) == On,$true,$false)) On:.enable #ppSpellCheck | dispa SpellCheck is enabled.
  .$_dynpop($iif($group(#ppSpellCheck) == Off,$true,$false)) Off:.disable #ppSpellCheck | dispa SpellCheck is disabled.
  .-
  .$_dynpop($iif(%spelltell == 2,$true,$false)) Tell me corrections made:%spelltell = 2 | dispa SpellCheck will tell you when a correction is made.
  .$_dynpop($iif(%spelltell == 1,$true,$false)) Make corrections silently:%spelltell = 1 | dispa SpellCheck will make corrections without warning you.
  .$_dynpop($iif(%spelltell == 0,$true,$false)) Full halt if any errors:%spelltell = 0 | dispa If SpellCheck finds an error, it will tell you and nothing will be sent to IRC.
}
alias _word2 %_arhelp = word $1 | _askr _arhelp Correctly spelled word?
on 1:START:{
  if (%spelltell !isin 012) %spelltell = 2
  if ($exists($scriptdirdict.ini) == $false) { disps SpellCheck dictionary file not found - Creating default dictionary file... | defdict }
}
alias schkunload unset %spelltell | .remove $scriptdirdict.ini

alias word {
  if (($2 == $null) || ($3)) { dispa Usage: /word misspelled-word correct-word | dispa Use /word -r misspelled-word to remove a word from the dictionary | halt }
  if ($1 == -r) {
    if ($null == [ $readini -n $scriptdirdict.ini $left($2,1) $2 ] ) { if ($show) dispa  $+ $2 not in dictionary. }
    else {
      remini $scriptdirdict.ini $left($2,1) $2
      if ($show) dispa  $+ $2 removed from SpellCheck dictionary.
    }
  }
  else {
    if ($1 === $2) _error Misspelled word and corrected word are the same! ( $+ $1 $+ )
    if (($show) && ($null != [ $readini -n $scriptdirdict.ini $left($1,1) $1 ] )) dispa SpellCheck was replacing $1 with $readini -n $scriptdirdict.ini $left($1,1) $1
    writeini $scriptdirdict.ini $left($1,1) $1 $2
    if ($show) dispa SpellCheck will now replace  $+ $1 with  $+ $2
  }
}

alias -l spellcheck {
  %.ret = $1-
  %.tok = $gettok($1-,0,32)
  :loop
  %.old = $gettok($1-,%.tok,32)
  %.pre =
  %.post =
  :pre | if ($left(%.old,1) !isletter) { if ($ifmatch !isnum) { if ($ifmatch) { %.pre = %.pre $+ $ifmatch | %.old = $mid(%.old,2,$len(%.old)) | goto pre } } }
  :post | if ($right(%.old,1) !isletter) { if ($ifmatch !isnum) { if ($ifmatch) { %.post = %.post $+ $ifmatch | %.old = $left(%.old,$calc($len(%.old) -1)) | goto post } } }
  if ($readini -n $scriptdirdict.ini $left(%.old,1) %.old) {
if ($ifmatch !== %.old) {
    %.new = %.pre $+ $ifmatch $+ %.post
    %.ret = $puttok(%.ret,%.new,%.tok,32)
    if (%spelltell != 1) dispa SpellCheck: %col.att $+ %.old $+  should be  $+ $readini -n $scriptdirdict.ini $left(%.old,1) %.old
}
  }
  if (%.tok > 1) { dec %.tok | goto loop }
  return %.ret
}

#ppSpellCheck on
on 1:INPUT:*:if ($halted) return | if (($left($1,1) != $readini -n $mircini text commandchar) && ($chr(32) !isin $target) && ($left($target,1) != @)) { if ($spellcheck($1-) !== $1-) { if (%spelltell == 0) dispa SpellCheck: %col.att $+ Output aborted! | else say %.ret | .enable #_inputhalt | halt } }
#ppSpellCheck end

alias defdict {
  .word youre you're
  .word hlep help
  .word soem some
  .word friedn friend
  .word freind friend
  .word thier their
  .word thsi this
  .word fwe few
  .word I"ll I'll
  .word wtih with
  .word wiht with
  .word adn and
  .word teh the
  .word hte the
  .word aslo also
  .word mirc mIRC
  .word P7P P&P
  .word defualt default
  .word neccessary necessary
  .word necesary necessary
  .word neccesary necessary
  .word wierd weird
}

alias schkhelp run $scriptdirspellchk.txt
