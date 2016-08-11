; -----------------------------------------------------
; Peace and Protection (by misspai)
; -----------------------------------------------------
; ADDON: Whiteboard (part 1)
; -----------------------------------------------------
; A few internals
; -----------------------------------------------------
alias -l noact return   
alias -l yesact return >
alias -l tell echo $colour(info) -s *** $1- | write wbevent.log $1-
alias -l event set %ppwb.event $1- | updwbtitle | write wbevent.log $1-
alias -l popms if (%ppwb.side == server) return Server | return
alias -l popmc if (%ppwb.side == client) return Client | return
alias -l popmo if ((%ppwb.side == local) || (%ppwb.side == chan)) return Close | return
alias -l popmcu if ((%ppwb.side == server) || (%ppwb.side == client)) return Chat/Users | return
alias -l wbreset .timerwbtoolcheck off | sockclose PPWB* | unset %ppwb.* | .disable #ppwbdns | window -c @WBoard | window -c @WBoardPeople
alias -l wbkill set %ppwb.side local | titlebar @WBoard [local] $1- | sockclose PPWB* | .disable #ppwbdns | window -c @WBoardPeople | write wbevent.log ERROR- $1- | _error $1-
alias -l wbdesk if (%ppwbs.dtop) return d | return
; -----------------------------------------------------
; Options that don't reset
; -----------------------------------------------------
on 1:load:set %ppwbs.cashdraw $true | set %ppwbs.fontbold $true | set %ppwbs.font Arial 20 | set %ppwbs.pics $mircdir | set %ppwbs.autochat $true | set %ppwbs.joinpart $true | set %ppwbs.colorserv 4 | set %ppwbs.coloryou 6 | set %ppwbs.dtop $false
; -----------------------------------------------------
; Tools and drawing, etc.
; -----------------------------------------------------
on 1:close:@WBoard:{
  if (%ppwb.side == client) wbsend BYE
  elseif (%ppwb.side == server) wbsend QUIT
  wbreset
}
alias -l cancelop {
  wbflush
  if (%ppwb.old.line) %ppwb.old.cmd -ir @WBoard %ppwb.old.line
  unset %ppwb.start.x %ppwb.start.y %ppwb.old.line %ppwb.old.cmd %ppwb.reline.x %ppwb.reline.y %ppwb.skipdot
  return
}
alias -l updwbtitle {
  if (%ppwb.side == client) titlebar @WBoard : %ppwb.me on %ppwb.server $+ [[ $+ %ppwb.port $+ ]] Users: $gettok(%ppwb.users,0,32) - %ppwb.event
  elseif (%ppwb.side == server) titlebar @WBoard : %ppwb.me on [[ $+ %ppwb.port $+ ]] Users: $calc($sock(PPWB-*,0) + 1) - %ppwb.event
  elseif (%ppwb.side == chan) titlebar @WBoard [[ $+ %ppwb.server $+ ]] - %ppwb.event
}
alias wbtoolcheck if ($sline(@WBoard,0) == 1) { cancelop | dowbdclick $sline(@WBoard,1).ln }
alias -l dowbdclick {
  sline -l @WBoard $1
  sline -lr @WBoard $1
  if ($1 < 10) settool $1
  elseif ($1 == 10) { wbaux | window -ar @WBoardPeople }
  elseif ($1 == 12) {
    if (%ppwb.inverse) setinv Off $false
    else setinv On $true
  }
  elseif (($1 == 14) && (%ppwb.width < 50)) setwide $calc(%ppwb.width + 1)
  elseif (($1 == 15) && (%ppwb.width > 1)) setwide $calc(%ppwb.width - 1)
  elseif (($1 > 17) && ($1 < 34)) setcolor $calc($1 - 17)
  elseif ($1 == 17) colorsel
}
menu @WBoard {
  mouse:{
    if (%ppwb.mpic) {
      if (%ppwbs.cashdraw) {
        if (%ppwb.old.cmd) %ppwb.old.cmd -irn @WBoard %ppwb.old.line
        set %ppwb.old.line 0 1 $mouse.x $mouse.y %ppwb.mpicsz
        drawrectf -irn @WBoard %ppwb.old.line
        drawline @WBoard
      }
      else {
        if (%ppwb.old.cmd) %ppwb.old.cmd -ir @WBoard %ppwb.old.line
        set %ppwb.old.line 0 1 $mouse.x $mouse.y %ppwb.mpicsz
        drawrectf -ir @WBoard %ppwb.old.line
      }
      set %ppwb.old.cmd drawrectf
    }
    if (%ppwb.reline.x) {
      if (%ppwbs.cashdraw) {
        if (%ppwb.old.cmd) %ppwb.old.cmd -irn @WBoard %ppwb.old.line
        set %ppwb.old.line %ppwb.colorrgb %ppwb.width %ppwb.reline.x %ppwb.reline.y $mouse.x $mouse.y
        drawline -irn @WBoard %ppwb.old.line
        drawline @WBoard
      }
      else {
        if (%ppwb.old.cmd) %ppwb.old.cmd -ir @WBoard %ppwb.old.line
        set %ppwb.old.line %ppwb.colorrgb %ppwb.width %ppwb.reline.x %ppwb.reline.y $mouse.x $mouse.y
        drawline -ir @WBoard %ppwb.old.line
      }
      set %ppwb.old.cmd drawline
    }
    elseif (%ppwb.start.x) {
      if ($mouse.key & 1) {
        if (%ppwb.mode == 2) {
          drawline -r @WBoard %ppwb.colorrgb %ppwb.width %ppwb.start.x %ppwb.start.y $mouse.x $mouse.y
          if (%ppwb.side == chan) {
            if ($len(%ppwb.cache) !isnum 5-130) { wbflush | set %ppwb.cache L $wbcolsend %ppwb.width %ppwb.start.x %ppwb.start.y $mouse.x $mouse.y }
            else { set %ppwb.skipdot $_not(%ppwb.skipdot) | if (%ppwb.skipdot) set %ppwb.cache %ppwb.cache $mouse.x $mouse.y }
          }
          else {
            if ($len(%ppwb.cache) !isnum 5-200) { wbflush | set %ppwb.cache L $wbcolsend %ppwb.width %ppwb.start.x %ppwb.start.y $mouse.x $mouse.y }
            else set %ppwb.cache %ppwb.cache $mouse.x $mouse.y
          }
          set %ppwb.start.x $mouse.x
          set %ppwb.start.y $mouse.y
        }
        elseif ((%ppwb.mode == 3) || (%ppwb.mode == 4)) {
          if (%ppwbs.cashdraw) {
            if (%ppwb.old.cmd) %ppwb.old.cmd -irn @WBoard %ppwb.old.line
            set %ppwb.old.line %ppwb.colorrgb %ppwb.width %ppwb.start.x %ppwb.start.y $mouse.x $mouse.y
            drawline -irn @WBoard %ppwb.old.line
            drawline @WBoard
          }
          else {
            if (%ppwb.old.cmd) %ppwb.old.cmd -ir @WBoard %ppwb.old.line
            set %ppwb.old.line %ppwb.colorrgb %ppwb.width %ppwb.start.x %ppwb.start.y $mouse.x $mouse.y
            drawline -ir @WBoard %ppwb.old.line
          }
          set %ppwb.old.cmd drawline
        }
        elseif (%ppwb.mode == 5) {
          if (%ppwbs.cashdraw) {
            if (%ppwb.old.cmd) %ppwb.old.cmd -irn @WBoard %ppwb.old.line
            set %ppwb.old.line %ppwb.colorrgb 1 $dblcoord(%ppwb.start.x,%ppwb.start.y,$mouse.x,$mouse.y,-)
            drawrectf -irn @WBoard %ppwb.old.line
            drawrect @WBoard
          }
          else {
            if (%ppwb.old.cmd) %ppwb.old.cmd -ir @WBoard %ppwb.old.line
            set %ppwb.old.line %ppwb.colorrgb 1 $dblcoord(%ppwb.start.x,%ppwb.start.y,$mouse.x,$mouse.y,-)
            drawrectf -ir @WBoard %ppwb.old.line
          }
          set %ppwb.old.cmd drawrectf
        }
        elseif (%ppwb.mode == 6) {
          if (%ppwbs.cashdraw) {
            if (%ppwb.old.cmd) %ppwb.old.cmd -irn @WBoard %ppwb.old.line
            set %ppwb.old.line %ppwb.colorrgb %ppwb.width $dblcoord(%ppwb.start.x,%ppwb.start.y,$mouse.x,$mouse.y,-)
            drawrect -irn @WBoard %ppwb.old.line
            drawrect @WBoard
          }
          else {
            if (%ppwb.old.cmd) %ppwb.old.cmd -ir @WBoard %ppwb.old.line
            set %ppwb.old.line %ppwb.colorrgb %ppwb.width $dblcoord(%ppwb.start.x,%ppwb.start.y,$mouse.x,$mouse.y,-)
            drawrect -ir @WBoard %ppwb.old.line
          }
          set %ppwb.old.cmd drawrect
        }
        elseif (%ppwb.mode == 7) {
          if (%ppwbs.cashdraw) {
            if (%ppwb.old.cmd) %ppwb.old.cmd -irn @WBoard %ppwb.old.line
            set %ppwb.old.line %ppwb.colorrgb 1 $dblcoord(%ppwb.start.x,%ppwb.start.y,$mouse.x,$mouse.y,-)
            drawelip -irn @WBoard %ppwb.old.line
            drawrect @WBoard
          }
          else {
            if (%ppwb.old.cmd) %ppwb.old.cmd -ir @WBoard %ppwb.old.line
            set %ppwb.old.line %ppwb.colorrgb 1 $dblcoord(%ppwb.start.x,%ppwb.start.y,$mouse.x,$mouse.y,-)
            drawelip -ir @WBoard %ppwb.old.line
          }
          set %ppwb.old.cmd drawelip
        }
        elseif (%ppwb.mode == 8) {
          if (%ppwbs.cashdraw) {
            if (%ppwb.old.cmd) %ppwb.old.cmd -irn @WBoard %ppwb.old.line
            set %ppwb.old.line %ppwb.colorrgb 1 $dblcoord(%ppwb.start.x,%ppwb.start.y,$mouse.x,$mouse.y)
            drawelip -irn @WBoard %ppwb.old.line
            drawrect @WBoard
          }
          else {
            if (%ppwb.old.cmd) %ppwb.old.cmd -ir @WBoard %ppwb.old.line
            set %ppwb.old.line %ppwb.colorrgb 1 $dblcoord(%ppwb.start.x,%ppwb.start.y,$mouse.x,$mouse.y)
            drawelip -ir @WBoard %ppwb.old.line
          }
          set %ppwb.old.cmd drawelip
        }
      }
      else cancelop
    }
  }
  sclick:{
    if (%ppwb.mpic) {
      if (%ppwbs.cashdraw) {
        if (%ppwb.old.cmd) %ppwb.old.cmd -irn @WBoard %ppwb.old.line
        drawpic -n @WBoard $mouse.x $mouse.y %ppwb.mpic
        drawline @WBoard
      }
      else {
        if (%ppwb.old.cmd) %ppwb.old.cmd -ir @WBoard %ppwb.old.line
        drawpic @WBoard $mouse.x $mouse.y %ppwb.mpic
      }
      wbsend P %ppwb.me $mouse.x $mouse.y $nopath(%ppwb.mpic)
      unset %ppwb.old.cmd %ppwb.old.line %ppwb.mpic %ppwb.mpicsz
      set %ppwb.skipdrop $true
    }
    if (%ppwb.reline.x) {
      if (%ppwbs.cashdraw) {
        if (%ppwb.old.cmd) %ppwb.old.cmd -irn @WBoard %ppwb.old.line
        drawline -rn @WBoard %ppwb.colorrgb %ppwb.width %ppwb.reline.x %ppwb.reline.y $mouse.x $mouse.y
        drawline @WBoard
      }
      else {
        if (%ppwb.old.cmd) %ppwb.old.cmd -ir @WBoard %ppwb.old.line
        drawline -r @WBoard %ppwb.colorrgb %ppwb.width %ppwb.reline.x %ppwb.reline.y $mouse.x $mouse.y
      }
      if ($len(%ppwb.cache) !isnum 5-200) { wbflush | set %ppwb.cache L $wbcolsend %ppwb.width %ppwb.reline.x %ppwb.reline.y $mouse.x $mouse.y }
      else set %ppwb.cache %ppwb.cache $mouse.x $mouse.y
      set %ppwb.reline.x $mouse.x | set %ppwb.reline.y $mouse.y
      unset %ppwb.old.line %ppwb.old.cmd %ppwb.skipdot
    }
    else {
      unset %ppwb.old.line %ppwb.old.cmd %ppwb.skipdot
      if (%ppwb.mode == 2) {
        drawline -r @WBoard %ppwb.colorrgb %ppwb.width $mouse.x $mouse.y $mouse.x $mouse.y
        set %ppwb.cache L $wbcolsend %ppwb.width $mouse.x $mouse.y
      }
      if (%ppwb.mode == 10) {
        wbsend F $wbcolsend $getdot(@WBoard,$mouse.x,$mouse.y) $mouse.x $mouse.y
        drawfill -rs @WBoard %ppwb.colorrgb $getdot(@WBoard,$mouse.x,$mouse.y) $mouse.x $mouse.y
      }
      elseif (%ppwb.mode == 4) {
        set %ppwb.reline.x $mouse.x
        set %ppwb.reline.y $mouse.y
        unset %ppwb.start.x %ppwb.start.y
      }
      else {
        set %ppwb.start.x $mouse.x
        set %ppwb.start.y $mouse.y
        if (%ppwb.mode == 9) {
          set %ppwb.text $$?="Text to write?"
          if (%ppwbs.fontbold) {
            drawtext -ro @WBoard %ppwb.colorrgb %ppwbs.font %ppwb.start.x %ppwb.start.y %ppwb.text
            wbsend O $wbcolsend %ppwbs.font %ppwb.start.x %ppwb.start.y %ppwb.text
          }
          else {
            drawtext -r @WBoard %ppwb.colorrgb %ppwbs.font %ppwb.start.x %ppwb.start.y %ppwb.text
            wbsend T $wbcolsend %ppwbs.font %ppwb.start.x %ppwb.start.y %ppwb.text
          }
          unset %ppwb.start.x %ppwb.start.y
        }
      }
    }
  }
  dclick:cancelop | if ($1 != $null) dowbdclick $1
  drop:{
    if ((%ppwb.reline.x) || (%ppwb.mpic)) halt
    elseif (%ppwb.skipdrop) unset %ppwb.skipdrop
    elseif (%ppwb.mode == 2) {
      drawline -r @WBoard %ppwb.colorrgb %ppwb.width %ppwb.start.x %ppwb.start.y $mouse.x $mouse.y
      if (%ppwb.cache == $null) wbsend L $wbcolsend %ppwb.width %ppwb.start.x %ppwb.start.y $mouse.x $mouse.y
      else { set %ppwb.cache %ppwb.cache $mouse.x $mouse.y | wbflush }
    }
    elseif (((%ppwb.mode == 3) || (%ppwb.mode == 4)) && (%ppwb.old.line)) {
      if (%ppwbs.cashdraw) {
        if (%ppwb.old.cmd) %ppwb.old.cmd -irn @WBoard %ppwb.old.line
        if (%ppwb.inverse) drawline -irn @WBoard %ppwb.colorrgb %ppwb.width %ppwb.start.x %ppwb.start.y $mouse.x $mouse.y
        else drawline -rn @WBoard %ppwb.colorrgb %ppwb.width %ppwb.start.x %ppwb.start.y $mouse.x $mouse.y
        drawline @WBoard
      }
      else {
        if (%ppwb.old.cmd) %ppwb.old.cmd -ir @WBoard %ppwb.old.line
        if (%ppwb.inverse) drawline -ir @WBoard %ppwb.colorrgb %ppwb.width %ppwb.start.x %ppwb.start.y $mouse.x $mouse.y
        else drawline -r @WBoard %ppwb.colorrgb %ppwb.width %ppwb.start.x %ppwb.start.y $mouse.x $mouse.y
      }
      if (%ppwb.inverse) wbsend I $wbcolsend %ppwb.width %ppwb.start.x %ppwb.start.y $mouse.x $mouse.y
      else wbsend L $wbcolsend %ppwb.width %ppwb.start.x %ppwb.start.y $mouse.x $mouse.y
      if (%ppwb.mode == 4) { set %ppwb.reline.x $mouse.x | set %ppwb.reline.y $mouse.y }
    }
    elseif ((%ppwb.mode == 5) && (%ppwb.old.line)) {
      if (%ppwbs.cashdraw) {
        if (%ppwb.old.cmd) %ppwb.old.cmd -irn @WBoard %ppwb.old.line
        if (%ppwb.inverse) drawrectf -irn @WBoard %ppwb.colorrgb 1 $dblcoord(%ppwb.start.x,%ppwb.start.y,$mouse.x,$mouse.y,-)
        else drawrectf -rn @WBoard %ppwb.colorrgb 1 $dblcoord(%ppwb.start.x,%ppwb.start.y,$mouse.x,$mouse.y,-)
        drawline @WBoard
      }
      else {
        if (%ppwb.old.cmd) %ppwb.old.cmd -ir @WBoard %ppwb.old.line
        if (%ppwb.inverse) drawrectf -ir @WBoard %ppwb.colorrgb 1 $dblcoord(%ppwb.start.x,%ppwb.start.y,$mouse.x,$mouse.y,-)
        else drawrectf -r @WBoard %ppwb.colorrgb 1 $dblcoord(%ppwb.start.x,%ppwb.start.y,$mouse.x,$mouse.y,-)
      }
      if (%ppwb.inverse) wbsend R -if $wbcolsend 1 $dblcoord(%ppwb.start.x,%ppwb.start.y,$mouse.x,$mouse.y,-)
      else wbsend R -f $wbcolsend 1 $dblcoord(%ppwb.start.x,%ppwb.start.y,$mouse.x,$mouse.y,-)
    }
    elseif ((%ppwb.mode == 6) && (%ppwb.old.line)) {
      if (%ppwbs.cashdraw) {
        if (%ppwb.old.cmd) %ppwb.old.cmd -irn @WBoard %ppwb.old.line
        if (%ppwb.inverse) drawrect -irn @WBoard %ppwb.colorrgb %ppwb.width $dblcoord(%ppwb.start.x,%ppwb.start.y,$mouse.x,$mouse.y,-)
        else  drawrect -rn @WBoard %ppwb.colorrgb %ppwb.width $dblcoord(%ppwb.start.x,%ppwb.start.y,$mouse.x,$mouse.y,-)
        drawline @WBoard
      }
      else {
        if (%ppwb.old.cmd) %ppwb.old.cmd -ir @WBoard %ppwb.old.line
        if (%ppwb.inverse) drawrect -ir @WBoard %ppwb.colorrgb %ppwb.width $dblcoord(%ppwb.start.x,%ppwb.start.y,$mouse.x,$mouse.y,-)
        else drawrect -r @WBoard %ppwb.colorrgb %ppwb.width $dblcoord(%ppwb.start.x,%ppwb.start.y,$mouse.x,$mouse.y,-)
      }
      if (%ppwb.inverse) wbsend R -i $wbcolsend %ppwb.width $dblcoord(%ppwb.start.x,%ppwb.start.y,$mouse.x,$mouse.y,-)
      else wbsend R - $wbcolsend %ppwb.width $dblcoord(%ppwb.start.x,%ppwb.start.y,$mouse.x,$mouse.y,-)
    }
    elseif ((%ppwb.mode == 7) && (%ppwb.old.line)) {
      if (%ppwbs.cashdraw) {
        if (%ppwb.old.cmd) %ppwb.old.cmd -irn @WBoard %ppwb.old.line
        if (%ppwb.inverse) drawelip -irn @WBoard %ppwb.colorrgb 1 $dblcoord(%ppwb.start.x,%ppwb.start.y,$mouse.x,$mouse.y,-)
        else drawelip -rn @WBoard %ppwb.colorrgb 1 $dblcoord(%ppwb.start.x,%ppwb.start.y,$mouse.x,$mouse.y,-)
        drawline @WBoard
      }
      else {
        if (%ppwb.old.cmd) %ppwb.old.cmd -ir @WBoard %ppwb.old.line
        if (%ppwb.inverse) drawelip -ir @WBoard %ppwb.colorrgb 1 $dblcoord(%ppwb.start.x,%ppwb.start.y,$mouse.x,$mouse.y,-)
        else drawelip -r @WBoard %ppwb.colorrgb 1 $dblcoord(%ppwb.start.x,%ppwb.start.y,$mouse.x,$mouse.y,-)
      }
      if (%ppwb.inverse) wbsend R -ie $wbcolsend 1 $dblcoord(%ppwb.start.x,%ppwb.start.y,$mouse.x,$mouse.y,-)
      else wbsend R -e $wbcolsend 1 $dblcoord(%ppwb.start.x,%ppwb.start.y,$mouse.x,$mouse.y,-)
    }
    elseif ((%ppwb.mode == 8) && (%ppwb.old.line)) {
      if (%ppwbs.cashdraw) {
        if (%ppwb.old.cmd) %ppwb.old.cmd -irn @WBoard %ppwb.old.line
        drawelip -irn @WBoard %ppwb.colorrgb 1 $dblcoord(%ppwb.start.x,%ppwb.start.y,$mouse.x,$mouse.y)
        drawline @WBoard
      }
      else {
        if (%ppwb.old.cmd) %ppwb.old.cmd -ir @WBoard %ppwb.old.line
        drawelip -ir @WBoard %ppwb.colorrgb 1 $dblcoord(%ppwb.start.x,%ppwb.start.y,$mouse.x,$mouse.y)
      }
      wbsend R -ie $wbcolsend 1 $dblcoord(%ppwb.start.x,%ppwb.start.y,$mouse.x,$mouse.y)
    }
    unset %ppwb.start.x %ppwb.start.y %ppwb.old.line %ppwb.old.cmd
  }
  $cancelop:{}
  Tool
  .Freehand:settool 1
  .Fill:settool 9
  .-
  .Lines
  ..Single:settool 2
  ..Connected:settool 3
  .Boxes
  ..Filled:settool 4
  ..Hollow:settool 5
  .Ellipses
  ..Filled:settool 6
  ..Hollow:settool 7
  .-
  .Text:settool 8
  Clear:clearwb | wbsend C P %ppwb.me
  Flood:floodwb | wbsend C $wbcolsend %ppwb.me
  Load pic
  .Upper left corner:set %ppwb.pic $$dir="Select a bitmap:" [ [ %ppwbs.pics ] $+ ] *.bmp | drawpic @WBoard 0 0 %ppwb.pic | wbsend P 0 0 %ppwb.me $nopath(%ppwb.pic)
  .Place with mouse:unset %ppwb.mpic | set %ppwb.mpic $$dir="Select a bitmap:" [ [ %ppwbs.pics ] $+ ] *.bmp | unset %ppwb.old.line | set %ppwb.mpicsz $pic(%ppwb.mpic).width $pic(%ppwb.mpic).height
  -
  Width
  .Pixel	1:setwide 1
  .Thin	2:setwide 2
  .	3:setwide 3
  .Medium	4:setwide 4
  .	5:setwide 5
  .Thick	10:setwide 10
  .	15:setwide 15
  .Large	20:setwide 20
  .	25:setwide 25
  .Extra large	30:setwide 30
  .	40:setwide 40
  .Gigantic	50:setwide 50
  -
  Inverse
  .On:setinv On $true
  .Off:setinv Off $false
  Color
  .Custom:colorsel
  .-
  .White	0:setcolor 16
  .Black	1:setcolor 1
  .Blue	2:setcolor 2
  .Green	3:setcolor 3
  .Red	4:setcolor 4
  .Brown	5:setcolor 5
  .Purple	6:setcolor 6
  .Orange	7:setcolor 7
  .Yellow	8:setcolor 8
  .Lime	9:setcolor 9
  .Aqua	10:setcolor 10
  .Lt. Aqua	11:setcolor 11
  .Lt. Blue	12:setcolor 12
  .Pink	13:setcolor 13
  .Grey	14:setcolor 14
  .Lt. Grey	15:setcolor 15
  .-
  .Custom:colorsel
  -
  $popms
  .Close (kill server):wbsend QUIT | wbreset
  .-
  .Connection limit
  ..$_dynpop($_if(%ppwb.limit,==,0)) Allow no new connections:set %ppwb.limit 0 | tell No new users may connect to the whiteboard now.
  ..$_dynpop($_if(%ppwb.limit,>,0)) Limit total number of users:set %ppwb.limit $$?="Limit total users to how many?" | tell No more than %ppwb.limit total users will be allowed on the whiteboard at one time.
  ..$_dynpop($_if($_ifn(%ppwb.limit),==,null)) No limit on connections (default):unset %ppwb.limit | tell No limits on incoming connections will be made.
  .Size limit
  ..$_dynpop($_not(%ppwb.force)) Don't enforce a window size:unset %ppwb.force | tell No size will be imposed on other whiteboard users' windows.
  ..$_dynpop(%ppwb.force) Change all users to use your current window size:set %ppwb.force $window(@WBoard).x $window(@WBoard).y $window(@WBoard).w $window(@WBoard).h | tell All current and new users' windows will be set to your current window size. (they are free to resize it after that) | wbsend SIZE %ppwb.force
  $popmcu:wbaux | window -ar @WBoardPeople
  $popmc
  .Close (disconnect):wbsend BYE | wbreset
  $popmo:wbreset
  -
  Settings
  .Redraw
  ..$_dynpop($_not(%ppwbs.cashdraw)) Fast:tell Whiteboard will draw at the fastest possible speed, at the cost of flicker. | set %ppwbs.cashdraw $false
  ..$_dynpop(%ppwbs.cashdraw) Smooth:tell Whiteboard will draw flicker-free, at the cost of speed. | set %ppwbs.cashdraw $true
  .Desktop
  ..$_dynpop(%ppwbs.dtop) Open as desktop windows from now on:tell Whiteboard windows will open as desktop windows, seperate from mIRC, from now on. (must restart whiteboard for changes to take effect) | set %ppwbs.dtop $true
  ..$_dynpop($_not(%ppwbs.dtop)) Open as normal windows within mIRC:tell Whiteboard windows will open as windows within mIRC. (must restart whiteboard for changes to take effect) | set %ppwbs.dtop $false
  .-
  .Chat window
  ..$_dynpop(%ppwbs.autochat) Auto open when starting whiteboard:tell Whiteboard chat window will open when you start the whiteboard. | set %ppwbs.autochat $true
  ..$_dynpop($_not(%ppwbs.autochat)) Don't auto open:tell Whiteboard chat window will not open until you tell it to. | set %ppwbs.autochat $false
  ..-
  ..$_dynpop(%ppwbs.joinpart) Show users joining and parting whiteboard:tell Users joining and parting whiteboard will also be shown joining and parting the chat window. | set %ppwbs.joinpart $true
  ..$_dynpop($_not(%ppwbs.joinpart)) Don't show users joining and parting:tell Users joining and parting whiteboard will not display any extra events in the chat window. | set %ppwbs.joinpart $false
  ..-
  ..Color for server's nick
  ...Current- %ppwbs.colorserv:{}
  ...-
  ...Change
  ....White	0:setwbsc 0
  ....Black	1:setwbsc 1
  ....Blue	2:setwbsc 2
  ....Green	3:setwbsc 3
  ....Red	4:setwbsc 4
  ....Brown	5:setwbsc 5
  ....Purple	6:setwbsc 6
  ....Orange	7:setwbsc 7
  ....Yellow	8:setwbsc 8
  ....Lime	9:setwbsc 9
  ....Aqua	10:setwbsc 10
  ....Lt. Aqua	11:setwbsc 11
  ....Lt. Blue	12:setwbsc 12
  ....Pink	13:setwbsc 13
  ....Grey	14:setwbsc 14
  ....Lt. Grey	15:setwbsc 15
  ..Color for your nick
  ...Current- %ppwbs.coloryou:{}
  ...-
  ...Change
  ....White	0:setwbyc 0
  ....Black	1:setwbyc 1
  ....Blue	2:setwbyc 2
  ....Green	3:setwbyc 3
  ....Red	4:setwbyc 4
  ....Brown	5:setwbyc 5
  ....Purple	6:setwbyc 6
  ....Orange	7:setwbyc 7
  ....Yellow	8:setwbyc 8
  ....Lime	9:setwbyc 9
  ....Aqua	10:setwbyc 10
  ....Lt. Aqua	11:setwbyc 11
  ....Lt. Blue	12:setwbyc 12
  ....Pink	13:setwbyc 13
  ....Grey	14:setwbyc 14
  ....Lt. Grey	15:setwbyc 15
  .-
  .Text font
  ..%ppwbs.font:{}
  ..-
  ..Change...:set %ppwbs.font $$?="Name of font? (ex: Arial)" $$?="Font size? (ex: 20)"
  .Text bold
  ..$_dynpop(%ppwbs.fontbold) On:set %ppwbs.fontbold $true
  ..$_dynpop($_not(%ppwbs.fontbold)) Off:set %ppwbs.fontbold $false
  .-
  .Pics dir
  ..%ppwbs.pics:{}
  ..-
  ..Change...:set %ppwbs.pics $$sdir="Directory to load BMP pics from?" $mircdir
  -
  Event log:run notepad wbevent.log
  -
  Help:wbhelp
}
alias -l setwbsc tell Nickname of server will be color $1 in the chat window/userlist. | set %ppwbs.colorserv $1 | if ($window(@WBoardPeople) != $null) wbaux
alias -l setwbyc tell Your nickname will be color $1 in the chat window/userlist. | set %ppwbs.coloryou $1 | if ($window(@WBoardPeople) != $null) wbaux
alias -l drawelip if ($left($1,1) == -) drawrect $1 $+ e $2- | else drawrect -e $1-
alias -l drawrectf if ($left($1,1) == -) drawrect $1 $+ f $2- | else drawrect -f $1-
alias -l clearwb { clear @WBoard | drawrect -rf @WBoard 16777215 1 0 0 $window(@WBoard).dw $window(@WBoard).dh }
alias -l floodwb { clear @WBoard | drawrect -rf @WBoard %ppwb.colorrgb 1 0 0 $window(@WBoard).dw $window(@WBoard).dh }
alias -l setinv {
  iline -l @WBoard 12 Inverse:  $+ $1 $+ 
  dline -l @WBoard 13
  set %ppwb.inverse $2
}
alias -l settool {
  iline -l @WBoard $calc(%ppwb.mode - 1) $noact $gettok($line(@WBoard,$calc(%ppwb.mode - 1),1),2-,32)
  dline -l @WBoard %ppwb.mode
  iline -l @WBoard $1 $yesact $gettok($line(@WBoard,$1,1),2-,32)
  dline -l @WBoard $calc($1 + 1)
  set %ppwb.mode $calc($1 + 1)
}
alias -l setwide {
  set %ppwb.width $1
  iline -l @WBoard 13 Width:  $+ $1 $+ 
  dline -l @WBoard 14
}
alias -l setcolor {
  if ((%ppwb.color == 16) || (%ppwb.color == 0)) {
    iline -l @WBoard $calc(%ppwb.color + 17) $noact $gettok($line(@WBoard,$calc(%ppwb.color + 17),1),2-,32)
    dline -l @WBoard $calc(%ppwb.color + 18)
  }
  else {
    iline -lc $+ %ppwb.color @WBoard $calc(%ppwb.color + 17) $noact $gettok($line(@WBoard,$calc(%ppwb.color + 17),1),2-,32)
    dline -l @WBoard $calc(%ppwb.color + 18)
  }
  set %ppwb.color $1
  if (($1 != 16) && ($1 != 0)) iline -lc $+ $1 @WBoard $calc($1 + 17) $yesact $gettok($line(@WBoard,$calc($1 + 17),1),2-,32)
  else iline -l @WBoard $calc($1 + 17) $yesact $gettok($line(@WBoard,$calc($1 + 17),1),2-,32)
  dline -l @WBoard $calc($1 + 18)
  if ($1 != 0) set %ppwb.colorrgb $gettok(%ppwb.colors,%ppwb.color,32)
  else set %ppwb.colorrgb $2
}
alias -l colorsel {
  window -c @Pick
  window -pef $+ $wbdesk @Pick 10 10 400 400 @Pick
  titlebar @Pick a color, Enter or right-click to confirm
  drawpic @Pick 0 0 $scriptdirppwb.bmp
  .timercolorselchk -om 0 100 cselchk
}
alias -l cselchk if (($window(@Pick).state != normal) || ($active != @Pick)) { window -c @Pick | .timercolorselchk off }
alias -l csfill {
  set %curr 1
  :loop
  csfill2 $1-3 %curr
  if (%curr < 32) { inc %curr | goto loop }
  drawrect @Pick
}
alias -l csfill2 {
  drawrect -frn @Pick $rgb($round($calc($1 + (255 - $1) * $4 / 32),0),$round($calc($2 + (255 - $2) * $4 / 32),0),$round($calc($3 + (255 - $3) * $4 / 32),0)) 1 $calc(($4 - 1) % 8 * 20 + 228) $calc(287 - $int($calc(($4 - 1) / 8)) * 20) 20 20
  drawrect -frn @Pick $rgb($round($calc($1 * $4 / 32),0),$round($calc($2 * $4 / 32),0),$round($calc($3 * $4 / 32),0)) 1 $calc(($4 - 1) % 8 * 20 + 228) $calc(367 - $int($calc(($4 - 1) / 8)) * 20) 20 20
}
; -----------------------------------------------------
; Custom color pick
; -----------------------------------------------------
menu @Pick {
  mouse:{
    if ($mouse.key & 1) {
      editbox -a $rgb($getdot(@Pick,$mouse.x,$mouse.y))
      drawrect -fr @Pick $getdot(@Pick,$mouse.x,$mouse.y) 1 185 322 32 27
    }
  }
  sclick:{
    editbox -a $rgb($getdot(@Pick,$mouse.x,$mouse.y))
    drawrect -fr @Pick $getdot(@Pick,$mouse.x,$mouse.y) 1 185 322 32 27
    if ($inrect($mouse.x,$mouse.y,228,227,160,160) == $false) csfill $replace($rgb($getdot(@Pick,$mouse.x,$mouse.y)),$chr(44),$chr(32))
  }
  drop:{
    editbox -a $rgb($getdot(@Pick,$mouse.x,$mouse.y))
    drawrect -fr @Pick $getdot(@Pick,$mouse.x,$mouse.y) 1 185 322 32 27
    if ($inrect($mouse.x,$mouse.y,228,227,160,160) == $false) csfill $replace($rgb($getdot(@Pick,$mouse.x,$mouse.y)),$chr(44),$chr(32))
  }
  $docpick($editbox($active)):{}
}
on 1:input:@Pick:docpick $1- | halt
alias -l docpick {
  if (($gettok($1,0,44) != 3) || ($2 != $null)) { window -c @Pick | return }
  setcolor 0 $rgb($gettok($1,1,44),$gettok($1,2,44),$gettok($1,3,44))
  .timercolorselchk off | window -c @Pick
  return
}
; -----------------------------------------------------
; Coordinates for open ellipse/etc.
; -----------------------------------------------------
; $dblcoord(x,y,mousex,mousey) returns x y w h x y w h to draw a pair of rect or ellipse properly to simulate width
; fifth param '-' to only return one set of coords (filled object)
alias -l dblcoord {
  if (($1 < $3) && ($2 < $4)) return $dblcoord2($1,$2,$3,$4,$5-)
  elseif (($1 < $3) && ($4 < $2)) return $dblcoord2($1,$4,$3,$2,$5-)
  elseif (($3 < $1) && ($2 < $4)) return $dblcoord2($3,$2,$1,$4,$5-)
  else return $dblcoord2($3,$4,$1,$2,$5-)
}
alias -l dblcoord2 {
  if ($5 == -) return $1-2 $calc($3 - $1) $calc($4 - $2)
  else return $1-2 $calc($3 - $1) $calc($4 - $2) $calc($1 + %ppwb.width) $calc($2 + %ppwb.width) $calc($3 - $1 - %ppwb.width - %ppwb.width) $calc($4 - $2 - %ppwb.width - %ppwb.width)
}
; -----------------------------------------------------
; Command send
; -----------------------------------------------------
alias -l wbflush if (%ppwb.cache) wbsend %ppwb.cache | unset %ppwb.cache
alias -l wbsend {
  if (%ppwb.side == server) { if ($sock(PPWB-*,0) > 0) sockwrite -n PPWB-* $1- }
  elseif (%ppwb.side == client) { if ($sock(PPWBDATA,0) > 0) sockwrite -n PPWBDATA $1- }
  elseif (%ppwb.side == chan) {
    if ($me ison %ppwb.server) {
      if (%ppwb.antifl < 1) _qc %ppwb.server PPWB $1-
      else .timer 1 %ppwb.antifl _qc %ppwb.server PPWB $1-
      set -u3 %ppwb.antifl $calc(1 + [ %ppwb.antifl ] )
    }
  }
}
alias -l wbcolsend if (%ppwb.color == 0) return %ppwb.colorrgb | return $chr($calc(%ppwb.color + 64))
; -----------------------------------------------------
; P&P Tools
; -----------------------------------------------------
menu menubar {
 -
  WhiteBoard
  .Start a whiteboard server
  ..Port 5050 (default):wb
  ..-
  ..Other port...:_askr wb Port to run whiteboard on?
  .Connect to a whiteboard
  ..Port 5050... (default):_askr wb Nickname or address (IP or named) of user to connect to?
  ..-
  ..Other port...:_askr _wb2s Nickname or address (IP or named) of user to connect to?
  .-
  .Open local whiteboard:wb 0
  .-
  .Current channel
  ..Open whiteboard:wb #
  ..-
  ..Set mode +l 5050	(allows whiteboard use):wblimit #
  ..Add [whiteboard] to topic	(allows whiteboard use):wbtopic #
  .$chan(1)
  ..Open whiteboard:wb $chan(1)
  ..-
  ..Set mode +l 5050	(allows whiteboard use):wblimit $chan(1)
  ..Add [whiteboard] to topic	(allows whiteboard use):wbtopic $chan(1)
  .$chan(2)
  ..Open whiteboard:wb $chan(2)
  ..-
  ..Set mode +l 5050	(allows whiteboard use):wblimit $chan(2)
  ..Add [whiteboard] to topic	(allows whiteboard use):wbtopic $chan(2)
  .$chan(3)
  ..Open whiteboard:wb $chan(3)
  ..-
  ..Set mode +l 5050	(allows whiteboard use):wblimit $chan(3)
  ..Add [whiteboard] to topic	(allows whiteboard use):wbtopic $chan(3)
  .$chan(4)
  ..Open whiteboard:wb $chan(4)
  ..-
  ..Set mode +l 5050	(allows whiteboard use):wblimit $chan(4)
  ..Add [whiteboard] to topic	(allows whiteboard use):wbtopic $chan(4)
  .-
  .Help:wbhelp
}
alias _wb2s set %_arhelp wb $1 | _askr _arhelp Port to connect to?
alias -l wblimit {
  if ($me !isop $1) _error You must be an op to change channel modes.
  if ($chan($1).limit != $null) .raw mode $1 -l
  .raw mode $1 +l 5050
}
alias -l wbtopic {
  if (($me !isop $1) && (t isin $chan($1).mode)) _error You must be an op to change the channel topic
  .raw topic $1 :[whiteboard] $chan($1).topic
}
