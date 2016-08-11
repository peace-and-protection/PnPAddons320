; -----------------------------------------------------
; Peace and Protection (by misspai)
; -----------------------------------------------------
; ADDON: IRCrypt (P&P version)
; -----------------------------------------------------
; Key management
; -----------------------------------------------------
alias key {
  if ($2 == $null) { dispa Usage: /key nick/#channel key | halt }
  if ($len($2) < 3) _error Error- Key must be at least three characters long.
  if ($len($2) > 200) _error Error- Key must be shorter than 200 characters long.
  set %crypt.key. [ $+ [ $1 ] ] $2
  set %crypt.keys $addtok(%crypt.keys,$1,32)
  dispa Key for %col.target $+ $1 $+  set to %col.info1 $+ $2
}
alias viewkey {
  if ($1 == $null) {
    open @Info /key IRCrypt keys
    set %.num $_numtok(32,%crypt.keys)
    if (%.num < 1) dispr @Info No IRCrypt keys have been defined.
    else {
      dispr @Info The following IRCrypt keys have been defined-
      :loop
      dispr @Info • Key for %col.target $+ $gettok(%crypt.keys,%.num,32) $+  is %col.info1 $+ %crypt.key. [ $+ [ $gettok(%crypt.keys,%.num,32) ] ]
      if ($_vd(.num) > 0) goto loop
    }
  }
  else {
    set %.key %crypt.key. [ $+ [ $1 ] ]
    if (%.key == $null) dispa No key for %col.target $+ $1 $+  has been set
    else dispa Key for %col.target $+ $1 $+  is %col.info1 $+ %.key
  }
}
alias delkey {
  if ($1 == $null) { dispa Usage: /delkey nick/#channel | halt }
  set %.key %crypt.key. [ $+ [ $1 ] ]
  if (%.key == $null) dispa No key for %col.target $+ $1 $+  has been set
  else {
    set %crypt.key. [ $+ [ $1 ] ]
    set %crypt.keys $remtok(%crypt.keys,$1,32)
    dispa Key for %col.target $+ $1 $+  has been cleared
  }
}
alias clearkeys _askyn _ckok Really clear ALL IRCrypt keys?
alias _ckok unset %crypt.key.* %crypt.keys | disp All IRCrypt keys cleared.
; -----------------------------------------------------
; Encoding
; -----------------------------------------------------
alias enc {
  if ($1 == $null) { dispa Usage: /enc text | halt }
  if ($len($1-) > 250) { _error Please type a shorter message, the encryption routine is limited to 250 characters for speed considerations | halt }
  if (($chr(32) isin $active) || ($left($active,1) == @)) _error Use /enc in a channel, query, or chat, please
  if ($left($active,1) == =) set %.key %crypt.key. [ $+ [ $remove($active,=) ] ]
  else set %.key %crypt.key. [ $+ [ $active ] ]
  if (%.key == $null) _error No key has been defined for this window! Use /key to define a key. (and make sure the target knows it.)
  set %.len $len(%.key)
  set %.len1 $int($calc(%.len / 3))
  set %.len2 %.len1
  set %.len3 %.len1
  if ($calc(%.len % 3) > 0) inc %.len1
  if ($calc(%.len % 3) > 1) inc %.len2
  _enc2 %.len1 %.len2 %.len3 $mid(%.key,1,%.len1) $mid(%.key,$calc(%.len1 + 1),%.len2) $mid(%.key,$calc(%.len2 + %.len1 + 1),%.len3) $_s2p($1-)
}
alias -l _enc2 {
  bset &cur 1 1
  bset &cur 2 1
  bset &cur 3 1
  bset &cur 4 1
  unset %.out
  :loop
  bset &cur 5 $calc($asc($mid($7-,$bvar(&cur,4),1)) + $asc($mid($4,$bvar(&cur,1),1)) + $bvar(&cur,4))
  bset &cur 1 $calc($bvar(&cur,1) + 1)
  if ($bvar(&cur,1) > $1) bset &cur 1 1
  if ($calc($bvar(&cur,4) % 2) == 0) {
    bset &cur 5 $calc($bvar(&cur,5) + $asc($mid($5,$bvar(&cur,2),1)))
    bset &cur 2 $calc($bvar(&cur,2) + 1)
    if ($bvar(&cur,2) > $2) bset &cur 2 1
  }
  if ($calc($bvar(&cur,4) % 3) == 0) {
    bset &cur 5 $calc($bvar(&cur,5) + $asc($mid($6,$bvar(&cur,3),1)))
    bset &cur 3 $calc($bvar(&cur,3) + 1)
    if ($bvar(&cur,3) > $3) bset &cur 3 1
  }
  if ($bvar(&cur,5) > 33) set %.out %.out $+ $chr($bvar(&cur,5))
  else set %.out %.out $+ ! $+ $chr($calc($bvar(&cur,5) + 64))
  bset &cur 4 $calc($bvar(&cur,4) + 1)
  if ($bvar(&cur,4) <= $len($7-)) goto loop
  if ((%crypt.ctcpout) && ($chan($active) != $active) && (= !isin $active)) _qcr $active /¢/ %.out
  elseif ((%crypt.hideout) && (= !isin $active)) _privmsg $active /¢/ %.out
  else msg $active /¢/ %.out
  echo -ai2 ‹: $+ $me $+ :› $_p2s($7-)
}
alias encrypt enc $1-
; -----------------------------------------------------
; "Automatic" encoding
; -----------------------------------------------------
on 1:input:*:{
  if ($left($1,1) != %crypt.prefix) return
  if (($chr(32) isin $active) || ($left($active,1) == @)) return
  if (($len($1) == 1) && ($2 == $null)) return
  .enable #_inputhalt
  enc $mid($1,2,$len($1)) $2- | halt
}
; -----------------------------------------------------
; Decoding
; -----------------------------------------------------
alias decrypt {
  if ($2 == $null) { dispa Usage: /decrypt source text | halt }
  set %.key %crypt.key. [ $+ [ $1 ] ]
  if (%.key == $null) {
    if ($3 == !) return
    else _error No key has been defined for  $+ $1 $+ ! Use /key to define a key. (and make sure its the same one as the sender.)
  }
  set %.len $len(%.key)
  set %.len1 $int($calc(%.len / 3))
  set %.len2 %.len1
  set %.len3 %.len1
  if ($calc(%.len % 3) > 0) inc %.len1
  if ($calc(%.len % 3) > 1) inc %.len2
  _decr2 %.len1 %.len2 %.len3 $mid(%.key,1,%.len1) $mid(%.key,$calc(%.len1 + 1),%.len2) $mid(%.key,$calc(%.len2 + %.len1 + 1),%.len3) $2-3
  return $result
}
alias -l _decr2 {
  bset &cur 1 1
  bset &cur 2 1
  bset &cur 3 1
  bset &cur 4 1
  unset %.out
  set %.pos 1
  :loop
  if ($mid($7,%.pos,1) == !) { inc %.pos | bset &cur 5 $calc($asc($mid($7,%.pos,1)) - 64 - $asc($mid($4,$bvar(&cur,1),1)) - $bvar(&cur,4)) }
  else bset &cur 5 $calc($asc($mid($7,%.pos,1)) - $asc($mid($4,$bvar(&cur,1),1)) - $bvar(&cur,4))
  bset &cur 1 $calc($bvar(&cur,1) + 1)
  if ($bvar(&cur,1) > $1) bset &cur 1 1
  if ($calc($bvar(&cur,4) % 2) == 0) {
    bset &cur 5 $calc($bvar(&cur,5) - $asc($mid($5,$bvar(&cur,2),1)))
    bset &cur 2 $calc($bvar(&cur,2) + 1)
    if ($bvar(&cur,2) > $2) bset &cur 2 1
  }
  if ($calc($bvar(&cur,4) % 3) == 0) {
    bset &cur 5 $calc($bvar(&cur,5) - $asc($mid($6,$bvar(&cur,3),1)))
    bset &cur 3 $calc($bvar(&cur,3) + 1)
    if ($bvar(&cur,3) > $3) bset &cur 3 1
  }
  set %.out %.out $+ $chr($bvar(&cur,5))
  bset &cur 4 $calc($bvar(&cur,4) + 1)
  inc %.pos
  if (%.pos <= $len($7)) goto loop
  if ($8 == !) return $_p2s(%.out)
  disp Decrypted- $_p2s(%.out)
}
on 1:ctcpreply:/¢/*:{
  set %.+disphalt $true
  if (%crypt.hold) return
  if (($2 == $null) || ($3 != $null)) set %.echo %col.att $+ Erroneous encryption ( $+ $1- $+ )
  else {
    _icfldc
    if ($chan != $null) {
      set %.echo $decrypt($chan,$2,!)
      if (%.echo == $null) set %.echo $decrypt($nick,$2,!)
      if (%.echo == $null) { if (%crypt.warned) return | set -u20 %crypt.warned $true | set %.echo %col.att $+ No known decryption key for channel $chan or user $nick $+  ( $+ $1- $+ ) }
      else set %.echo ‹: $+ $nick $+ :› %.echo
      echo -i2 $chan %.echo
    }
    else {
      set %.echo $decrypt($nick,$2,!)
      if (%.echo == $null) { if (%crypt.warned) return | set -u20 %crypt.warned $true | set %.echo %col.att $+ No known decryption key for user $nick $+  ( $+ $1- $+ ) }
      else set %.echo ‹: $+ $nick $+ :› %.echo
      if ($query($nick) != $nick) q $nick
      echo -i2 $nick %.echo
    }
  }
  halt
}
on 1:text:/¢/ *:?:{
  if ((%crypt.hold) || ($2 == $null) || ($3 != $null)) return
  else {
    _icfldc
    set %.echo $decrypt($chan,$2,!)
    if (%.echo == $null) set %.echo $decrypt($nick,$2,!)
    if (%.echo == $null) { if (%crypt.warned) return | set -u20 %crypt.warned $true | set %.echo %col.att $+ No known decryption key for channel $chan or user $nick }
    else set %.echo ‹: $+ $nick $+ :› %.echo
    echo -i2 $nick %.echo
  }
}
on 1:text:/¢/ *:#:{
  if ((%crypt.hold) || ($2 == $null) || ($3 != $null)) return
  else {
    _icfldc
    set %.echo $decrypt($chan,$2,!)
    if (%.echo == $null) { if (%crypt.warned) return | set -u20 %crypt.warned $true | set %.echo %col.att $+ No known decryption key for channel $chan }
    else set %.echo ‹: $+ $nick $+ :› %.echo
    echo -i2 $chan %.echo
  }
}
on 1:chat:/¢/ *:{
  if ((%crypt.hold) || ($2 == $null) || ($3 != $null)) return
  else {
    _icfldc
    set %.echo $decrypt($nick,$2,!)
    if (%.echo == $null) { if (%crypt.warned) return | set -u20 %crypt.warned $true | set %.echo %col.att $+ No known decryption key for user $nick }
    else set %.echo ‹: $+ $nick $+ :› %.echo
    echo -i2 =$nick %.echo
  }
}
; -----------------------------------------------------
; Flood check
; -----------------------------------------------------
alias -l _icfldc {
  if (%crypt.fcheck) {
    _timersinc 15 crypt.flood
    if (%crypt.flood > 8) {
      set -u30 %crypt.hold $true
      disps %col.att $+ Ignoring (not decrypting) IRCrypt encryption for 30 seconds due to flood. (8 or more encryptions in 15 seconds)
    }
  }
}
on 1:connect:unset %crypt.flood %crypt.hold %crypt.warned
; -----------------------------------------------------
; Key distribution
; -----------------------------------------------------
ctcp 1:CRYPTKEY:{
  if (($2 != ASK) || ($3 == $null) || ($4 != $null)) halt
  if (($_not($_ischan($3))) && ($3 != $nick)) halt
  unset %.give
  if (%crypt.giveall) set %.give $true
  elseif ($ulevel > %crypt.givelevel) set %.give $true
  elseif (((%crypt.givenotify) || (%crypt.gnmatch)) && ($nick isnotify)) {
    if ((%-+notifymatch. [ $+ [ $nick ] ] == $true) || (%crypt.givenotify)) set %.give $true
  }
  set %.key %crypt.key. [ $+ [ $3 ] ]
  disp Encryption key request from %col.target $+ $nick $+  for %col.target $+ $3 $+  key
  if (%.key == $null) disp Request ignored- you have not defined this key yet.
  elseif (%.give != $true) { set %_crypt.give $nick $1 GIVE $3 %.key | disp Encryption key request not automatically filled- Type /givekey to send the user the key. }
  else { _qcr $nick $1 GIVE $3 %.key | disp Encryption key request automatically filled. }
  set %.+disphalt $true | halt
}
alias givekey {
  if ($1 != $null) { sendkey $1- | return }
  if (%_crypt.give != $null) {
    disp Encryption key request filled.
    _qcr %_crypt.give
  }
  unset %_crypt.give
}
on 1:ctcpreply:CRYPTKEY GIVE & &:{
  if (($_not($_ischan($3))) && ($3 != $me)) halt
  unset %.give
  if (%_crypt.req. [ $+ [ $nick ] ] == $3) { set %_crypt.req. [ $+ [ $nick ] ] | set %.give $true }
  elseif (%_crypt.req. [ $+ [ $comchan($nick,1) ] ] == $3) set %.give $true
  elseif (%crypt.acceptall) set %.give $true
  elseif ($ulevel > %crypt.acceptlevel) set %.give $true
  elseif (((%crypt.acceptnotify) || (%crypt.anmatch)) && ($nick isnotify)) {
    if ((%-+notifymatch. [ $+ [ $nick ] ] == $true) || (%crypt.acceptnotify)) set %.give $true
  }
  disp Encryption key offer from %col.target $+ $nick $+  for %col.target $+ $3 $+  ( $+ $4 $+ )
  set %.+disphalt $true
  if (%.give != $true) {
    if ($_ischan($3)) disp Encryption key offer not automatically accepted- Type /takekey to accept the offered channel key.
    else disp Encryption key offer not automatically accepted- Type /takekey to accept the user's private key.
    if ($3 == $me) set %_crypt.take $nick $4
    else set %_crypt.take $3 $4
    halt
  }
  disp Encryption key stored in database.
  if ($3 == $me) set %crypt.key. [ $+ [ $nick ] ] $4
  else set %crypt.key. [ $+ [ $3 ] ] $4
  halt
}
alias takekey {
  if (%_crypt.take != $null) {
    disp Encryption key stored in database.
    set %crypt.key. [ $+ [ $gettok(%_crypt.take,1,32) ] ] $gettok(%_crypt.take,2,32)
  }
  unset %_crypt.take
}
alias askkey {
  if ($1 == $null) { dispa Usage: /askkey nickname [channel] | halt }
  if ($2 == $null) {
    ctcp $1 CRYPTKEY ASK $me
    set %_crypt.req. [ $+ [ $1 ] ] $me
  }
  else {
    ctcp $1 CRYPTKEY ASK $2
    set %_crypt.req. [ $+ [ $1 ] ] $2
  }
}
alias sendkey {
  if ($1 == $null) { dispa Usage: /sendkey nickname/chan [channel] | halt }
  if ($2 == $null) set %.targ $1
  else set %.targ $2
  set %.key %crypt.key. [ $+ [ %.targ ] ]
  if (%.key == $null) _error No matching key has been defined! Use /key to define a key.
  ctcpreply $1 CRYPTKEY GIVE %.targ %.key
}
; -----------------------------------------------------
; Help
; -----------------------------------------------------
alias ircrypt crypt
alias crypt {
  window -c @Crypt
  window -l @Crypt $_winpos(15%,8%,8%,8%) @Close %font.basic
  titlebar @Crypt - Help on using IRCrypt (P&P version)
  aline %col.base @Crypt How IRCrypt works-
  aline @Crypt $chr(160) The encryption is key-based. The keys can be any length of 3 characters or more, and contain any
  aline @Crypt $chr(160) character except spaces. Longer keys are generally more secure, and the entire key is used in encrypting
  aline @Crypt $chr(160) messages, unless the key is longer than the message. IRCrypt uses a relatively complex, hard-to-break
  aline @Crypt $chr(160) scheme, with an infinite variety of keys. This is unlike other mIRC encryption scripts which have easy to
  aline @Crypt $chr(160) crack schemes based on a limited number of keys. (rarely more than 256 possibilities.)
  aline @Crypt $chr(160)
  aline %col.base @Crypt Popups-
  aline @Crypt $chr(160) Popups have been added to the channel and query/chat popups to ease use of IRCrypt. They
  aline @Crypt $chr(160) can be used instead of the aliases mentioned below- any function listed below can be performed
  aline @Crypt $chr(160) via popups as well. Please read the rest of this help before using them though.
  aline @Crypt $chr(160)
  aline %col.base @Crypt Quick start-
  aline @Crypt $chr(160) The simplest way to start using IRCrypt is to select the popup "Set key", enter a key, then select
  aline @Crypt $chr(160) the popup "Send key" to send the key to the target. Now you can use /enc to encode text for
  aline @Crypt $chr(160) that window. (or prefix your text with a ~, the default encryption prefix)
  aline @Crypt $chr(160)
  aline %col.base @Crypt How to define keys-
  aline @Crypt $chr(160) To set a key for private conversation, type /key nickname key. Any encrypted text you send to this
  aline @Crypt $chr(160) nickname will now be encrypted using that key, and any private text from this user will be decrypted
  aline @Crypt $chr(160) with this key.
  aline @Crypt $chr(160)
  aline @Crypt $chr(160) To set a key for channel encryption, type /key #channel key. All encrypted text send to and
  aline @Crypt $chr(160) received from that channel will be encoded/decoded using that key.
  aline @Crypt $chr(160)
  aline %col.base @Crypt How to give your keys to others-
  aline @Crypt $chr(160) To tell a user what key you are using to encrypt their private text, type /sendkey nickname. Of
  aline @Crypt $chr(160) course, they must be using IRCrypt to make any use of this key. To tell a user what key you are
  aline @Crypt $chr(160) using in a certain channel, type /sendkey nickname #channel. To tell an entire channel what
  aline @Crypt $chr(160) key you are using for that channel, type /sendkey #channel. If you are going to use IRCrypt in a
  aline @Crypt $chr(160) channel, all the users in that channel should agree on a key ahead of time and not change it.
  aline @Crypt $chr(160)
  aline @Crypt $chr(160) When someone sends you a key, you may or may not automatically accept the key, depending on
  aline @Crypt $chr(160) your settings. If you do not automatically accept the key, you will be noted of this and you may, as
  aline @Crypt $chr(160) the note will say, type /takekey to accept the key.
  aline @Crypt $chr(160)
  aline %col.base @Crypt How to request keys from others-
  aline @Crypt $chr(160) To ask a user what key they are using to encrypt private text to you, type /askkey nickname.
  aline @Crypt $chr(160) When (if) they reply, you will automatically accept the key. To ask a user what key they are using
  aline @Crypt $chr(160) to encrypt text in a certain channel, type /askkey nickname #channel. When (if) they reply, you
  aline @Crypt $chr(160) will automatically accept that key and use it for that channel.
  aline @Crypt $chr(160)
  aline @Crypt $chr(160) When someone requests a key from you, you may or may not automatically return the requested key,
  aline @Crypt $chr(160) depending on your settings. If you do not automatically send the key, you will be noted of this and you
  aline @Crypt $chr(160) will be told to type /givekey to send the requested key.
  aline @Crypt $chr(160)
  aline %col.base @Crypt How to encode text- (finally!)
  aline @Crypt $chr(160) Simply type /enc message to encode in the proper window. The key for that channel or user will
  aline @Crypt $chr(160) automatically be looked up and used. The text will be encrypted and sent to the window. You can
  aline @Crypt $chr(160) also simply prefix your text with a ~, which will encrypt it. This character can be changed in the
  aline @Crypt $chr(160) IRCrypt configuration.
  aline @Crypt $chr(160)
  aline %col.base @Crypt How to decode text-
  aline @Crypt $chr(160) If you have the (proper) key for a channel or user, text they send you will be automatically decoded.
  aline @Crypt $chr(160) If you have an improper key, the text will simply appear garbled. Once you and your friends agree on
  aline @Crypt $chr(160) a key, you should probably not change them needlessly, to prevent having an incorrect key.
  aline @Crypt $chr(160)
  aline %col.base @Crypt Manual decoding-
  aline @Crypt $chr(160) If for some reason you need to manually decode encrypted text, type /decrypt from encryptedmessage.
  aline @Crypt $chr(160) "from" is the #channel or nickname that the text is from, and is used to locate the proper key.
  aline @Crypt $chr(160)
  aline %col.base @Crypt Viewing keys-
  aline @Crypt $chr(160) If you need to view keys in your database, type /viewkey nickname/#channel to view the keys for
  aline @Crypt $chr(160) a nickname or channel, or type /viewkey to view all keys.
  aline @Crypt $chr(160)
  aline %col.base @Crypt Configuration options-
  aline @Crypt $chr(160) Type /cryptcfg (or use the popups) to access IRCrypt configuration. Here you can define who you
  aline @Crypt $chr(160) are willing to automatically accept keys from/automatically send requested keys to, and also you can
  aline @Crypt $chr(160) choose whether or not you wish to see the encoded version of the text you type. (normally the
  aline @Crypt $chr(160) encrypted version is hidden and only your original message is displayed in your window.) Also, you
  aline @Crypt $chr(160) can define whether to use CTCP replies when sending private encrypted messages. (instead of
  aline @Crypt $chr(160) standard text.) The advantage of CTCP replies is that the receipient does not see both the encrypted
  aline @Crypt $chr(160) junk AND the decoded text- only the decoded text is shown. With standard text, the "junk" is shown
  aline @Crypt $chr(160) as well. (it is recommended that you leave this option on.) You can also disable the flood check if
  aline @Crypt $chr(160) needed.
  aline @Crypt $chr(160)
  aline @Crypt $chr(160) You can also define a prefix character that tells IRCrypt to encrypt that line of text without having to
  aline @Crypt $chr(160) use a popup or the /enc command. This defaults to ~, for example "~this text will be encrypted".
  aline @Crypt $chr(160)
  aline %col.base @Crypt Note on use in DCC chats-
  aline @Crypt $chr(160) Neither incoming nor outgoing text can be hidden when using IRCrypt in a DCC chat.
  aline @Crypt $chr(160)
  aline %col.base @Crypt Note on Peace and Protection-
  aline @Crypt $chr(160) You can download a general version of IRCrypt for non-P&P users at the P&P homepage as well.
  aline @Crypt $chr(160) (http://pairc.com/pnp/)
}
; -----------------------------------------------------
; Popups
; -----------------------------------------------------
menu channel {
  -
  IRCrypt
  .Encrypt text...:_askr enc Text to encrypt?
  .-
  .Keys
  ..Set key for channel...:set %_arhelp key # | _askr _arhelp New key for # $+ ?
  ..View key for channel:viewkey #
  ..Send key to channel:sendkey #
  ..-
  ..Ask for key
  ...Channel key:askkey # #
  ...Your key:askkey #
  ..-
  ..Clear ALL keys:clearkeys
  ..View ALL keys:viewkey
  .-
  .Help...:crypt
  .Configure...:cryptcfg
}
menu query {
  -
  IRCrypt
  .Encrypt text...:_askr enc Text to encrypt?
  .-
  .Keys
  ..Set key for user...:set %_arhelp key $1 | _askr _arhelp New key for $1 $+ ?
  ..View key for user:viewkey $1
  ..Send key to user:sendkey $1
  ..-
  ..Trade keys (send + ask for):sendkey $1 | askkey $1
  ..-
  ..Ask for key
  ...Your key:askkey $1
  ...Channel key
  ....$comchan($active,1):askkey $1 $comchan($1,1)
  ....$comchan($active,2):askkey $1 $comchan($1,2)
  ....$comchan($active,3):askkey $1 $comchan($1,3)
  ....-
  ....Other...:set %_arhelp askkey $1 | _askr _arhelp Channel to ask for key from?
  .-
  .Help...:crypt
  .Configure...:cryptcfg
}
; -----------------------------------------------------
; Configuration
; -----------------------------------------------------
menu @IRCrypt {
  dclick /_ccdbc
  Close window:window -c $active
}
alias ircryptcfg cryptcfg
alias cryptcfg {
  window -c @IRCrypt
  window -l @IRCrypt $_winpos(15%,8%,8%,8%) @IRCrypt %font.basic
  titlebar @IRCrypt configuration
  set %.line 1
  :loop
  _ccfgl %.line
  if ($_vi(.line) < 20) goto loop
}
alias -l _ccfgl {
  if ($1 == 1) rline @IRCrypt 1 - Double click on an option to toggle or change it -
  elseif ($1 == 3) rline @IRCrypt 3 When you are sent a key, auto-accept from-
  elseif ($1 == 4) rline @IRCrypt 4 • People on notify list - $_tf2o(%crypt.acceptnotify)
  elseif ($1 == 5) rline @IRCrypt 5 • People on notify list who match custom notify mask- $_tf2o(%crypt.anmatch)
  elseif ($1 == 6) rline @IRCrypt 6 • People on user list ABOVE level - %crypt.acceptlevel
  elseif ($1 == 7) rline @IRCrypt 7 • Anyone (not recommended) - $_tf2o(%crypt.acceptall)
  elseif ($1 == 9) rline @IRCrypt 9 When you are asked for a key, auto-send to-
  elseif ($1 == 10) rline @IRCrypt 10 • People on notify list - $_tf2o(%crypt.givenotify)
  elseif ($1 == 11) rline @IRCrypt 11 • People on notify list who match custom notify mask- $_tf2o(%crypt.gnmatch)
  elseif ($1 == 12) rline @IRCrypt 12 • People on user list ABOVE level - %crypt.givelevel
  elseif ($1 == 13) rline @IRCrypt 13 • Anyone (not recommended) - $_tf2o(%crypt.giveall)
  elseif ($1 == 15) rline @IRCrypt 15 Hide encrypted version of text that you send - $_tf2o(%crypt.hideout)
  elseif ($1 == 16) rline @IRCrypt 16 Send private encryption as CTCP reply (recommended) - $_tf2o(%crypt.ctcpout)
  elseif ($1 == 17) rline @IRCrypt 17 Perform flood check? (8+ encrypted messages in 15 seconds) - $_tf2o(%crypt.fcheck)
  elseif ($1 == 19) rline @IRCrypt 19 Prefix character to use encryption - %crypt.prefix
  else rline @IRCrypt $1 $chr(160)
}
alias _ccdbc {
  set %.ln $sline(@IRCrypt,1).ln
  if (%.ln == 4) set %crypt.acceptnotify $_not(%crypt.acceptnotify)
  elseif (%.ln == 10) set %crypt.givenotify $_not(%crypt.givenotify)
  elseif (%.ln == 5) set %crypt.anmatch $_not(%crypt.anmatch)
  elseif (%.ln == 11) set %crypt.gnmatch $_not(%crypt.gnmatch)
  elseif (%.ln == 7) set %crypt.acceptall $_not(%crypt.acceptall)
  elseif (%.ln == 13) set %crypt.giveall $_not(%crypt.giveall)
  elseif (%.ln == 15) set %crypt.hideout $_not(%crypt.hideout)
  elseif (%.ln == 16) set %crypt.ctcpout $_not(%crypt.ctcpout)
  elseif (%.ln == 17) set %crypt.fcheck $_not(%crypt.fcheck)
  elseif ((%.ln == 6) || (%.ln == 12)) {
    if ($1 !isnum) _askr _ccdbc Require people on user list to be above what level?
    if (%.ln == 6) set %crypt.acceptlevel $1
    else set %crypt.givelevel $1
  }
  elseif (%.ln == 19) {
    if ($1 != !) { set %_arhelp _ccdbc ! | _pentry _arhelp Automatically encrypt text if first character is what?2 }
    if ($2 == $null) set %crypt.prefix (none)
    else set %crypt.prefix $2
  }
  _ccfgl %.ln
}
; -----------------------------------------------------
; Default settings
; -----------------------------------------------------
on 1:load:{
  unset %crypt.flood %crypt.hold %crypt.warned
  if (%crypt.givelevel == $null) {
    set %crypt.acceptnotify $false
    set %crypt.givenotify $false
    set %crypt.anmatch $true
    set %crypt.gnmatch $true
    set %crypt.acceptall $false
    set %crypt.giveall $false
    set %crypt.acceptlevel 24
    set %crypt.givelevel 24
    set %crypt.hideout $false
    set %crypt.ctcpout $true
    set %crypt.fcheck $true
    set %crypt.prefix ~
  }
}
