## $Id$
##
## BEGIN LICENSE BLOCK
##
## Copyright (C) 2002  Damon Courtney
## 
## This program is free software; you can redistribute it and/or
## modify it under the terms of the GNU General Public License
## version 2 as published by the Free Software Foundation.
## 
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License version 2 for more details.
## 
## You should have received a copy of the GNU General Public License
## along with this program; if not, write to the
##     Free Software Foundation, Inc.
##     51 Franklin Street, Fifth Floor
##     Boston, MA  02110-1301, USA.
##
## END LICENSE BLOCK

if {![info exists tk_patchLevel]} { return }
if {$::tcl_platform(platform) ne "unix"} { return }

set consoleInterp [interp create]
$consoleInterp eval [list set tcl_library $tcl_library]
$consoleInterp eval [list set tk_library $tk_library]
$consoleInterp eval [list ::tcl::tm::add {*}[::tcl::tm::list]]
$consoleInterp alias exit exit
$consoleInterp eval {package require msgcat}
$consoleInterp eval {package require Tk}

proc console { sub {optarg {}} } [subst -nocommands {
    switch -exact -- \$sub {
       title {
	   $consoleInterp eval wm title . [list \$optarg]
       }
       hide {
	   $consoleInterp eval wm withdraw .
       }
       show {
	   $consoleInterp eval wm deiconify .
       }
       eval {
	   $consoleInterp eval \$optarg
       }
       default {
	   error "bad option \\\"\$sub\\\": should be hide, show, or title"
       }
   }
}]

proc consoleinterp {sub cmd} {
   switch -exact -- $sub {
       eval {
	   uplevel #0 $cmd
       }
       record {
	   history add $cmd
	   catch {uplevel #0 $cmd} retval
	   return $retval
       }
       default {
	   error "bad option \"$sub\": should be eval or record"
       }
   }
}
$consoleInterp alias consoleinterp consoleinterp

bind . <Destroy> [list +if {[string match . %W]} [list catch \
       [list $consoleInterp eval tkConsoleExit]]]

rename puts tcl_puts
proc puts {args} [subst -nocommands {
   switch -exact -- [llength \$args] {
       1 {
	   if {[string match -nonewline \$args]} {
	       if {[catch {uplevel 1 [linsert \$args 0 tcl_puts]} msg]} {
		   regsub -all tcl_puts \$msg puts msg
		   return -code error \$msg
	       }
	   } else {
	       $consoleInterp eval [list tkConsoleOutput stdout \
		       "[lindex \$args 0]\n"]
	   }
       }
       2 {
	   if {[string match -nonewline [lindex \$args 0]]} {
	       $consoleInterp eval [list tkConsoleOutput stdout \
		       [lindex \$args 1]]
	   } elseif {[string match stdout [lindex \$args 0]]} {
	       $consoleInterp eval [list tkConsoleOutput stdout \
		       "[lindex \$args 1]\n"]
	   } elseif {[string match stderr [lindex \$args 0]]} {
	       $consoleInterp eval [list tkConsoleOutput stderr \
		       "[lindex \$args 1]\n"]
	   } else {
	       if {[catch {uplevel 1 [linsert \$args 0 tcl_puts]} msg]} {
		   regsub -all tcl_puts \$msg puts msg
		   return -code error \$msg
	       }
	   }
       }
       3 {
	   if {![string match -nonewline [lindex \$args 0]]} {
	       if {[catch {uplevel 1 [linsert \$args 0 tcl_puts]} msg]} {
		   regsub -all tcl_puts \$msg puts msg
		   return -code error \$msg
	       }
	   } elseif {[string match stdout [lindex \$args 1]]} {
	       $consoleInterp eval [list tkConsoleOutput stdout \
		       [lindex \$args 2]]
	   } elseif {[string match stderr [lindex \$args 1]]} {
	       $consoleInterp eval [list tkConsoleOutput stderr \
		       [lindex \$args 2]]
	   } else {
	       if {[catch {uplevel 1 [linsert \$args 0 tcl_puts]} msg]} {
		   regsub -all tcl_puts \$msg puts msg
		   return -code error \$msg
	       }
	   }
       }
       default {
	   if {[catch {uplevel 1 [linsert \$args 0 tcl_puts]} msg]} {
	       regsub -all tcl_puts \$msg puts msg
	       return -code error \$msg
	   }
       }
   }
}]
$consoleInterp alias puts puts

set tcl_interactive 1

########################################################################
# Evaluate the Tk library script console.tcl in the console interpreter
########################################################################
$consoleInterp eval source [list [file join $tk_library console.tcl]]

console hide

$consoleInterp eval {
   if {![llength [info commands tkConsoleExit]]} {
       tk::unsupported::ExposePrivateCommand tkConsoleExit
   }
}

$consoleInterp eval {
   if {![llength [info commands tkConsoleOutput]]} {
       tk::unsupported::ExposePrivateCommand tkConsoleOutput
   }
}

# Restore normal [puts] if console widget goes away...
proc Oc_RestorePuts {slave} {
    rename puts {}
    rename tcl_puts puts
    interp delete $slave
}
$consoleInterp alias Oc_RestorePuts Oc_RestorePuts $consoleInterp
$consoleInterp eval {
    bind Console <Destroy> +Oc_RestorePuts
}

unset consoleInterp

console title "Debug Console"
