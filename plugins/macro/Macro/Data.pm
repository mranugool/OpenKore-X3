# $Id: Data.pm r6753 2009-07-02 00:43:00Z ezza $
package Macro::Data;

use strict;

require Exporter;
our ($rev) = q$Revision: 6753 $ =~ /(\d+)/;
our @ISA = qw(Exporter);
our @EXPORT = qw(@perl_name %macro %automacro %varStack $queue $onHold %amSingle %amMulti $macroKeywords);

our @perl_name;
our %macro;
our %automacro;
our %varStack;
our $queue;
our $onHold;
our $inBlock;

our %amSingle = (
	'map' => 1,          # map check
	'mapchange' => 1,    # map change check
	'class' => 1,        # job class check
	'timeout' => 1,      # setting: re-check timeout
	'delay' => 1,        # option: delay before the macro starts
	'run-once' => 1,     # option: run automacro only once
	'disabled' => 1,     # option: automacro disabled
	'call' => 1,         # setting: macro to be called
	'spell' => 1,        # check: cast sensor
	'notMonster' => 1,   # check: disallow monsters other than ~
	'pm' => 1,           # check: private message
	'pubm' => 1,         # check: public chat
	'system' => 1,       # check: system chat
	'guild' => 1,        # check: guild chat
	'party' => 1,        # check: party chat
	'console' => 1,      # check: console message
	'overrideAI' => 1,   # option: override AI
	'orphan' => 1,       # option: orphan handling
	'macro_delay' => 1,  # option: default macro delay
	'hook' => 1,         # check: openkore hook
	'priority' => 1,     # option: automacro priority
	'exclusive' => 1,    # option: is macro interruptible
	'playerguild' => 1,  # check: player guilds
	'eval' => 1,         # check : eval
	'whenGround' => 1,   # check : when ground statuses
	'areaSpell' => 1     # check : area spell
);

our %amMulti = (
	'set' => 1,          # set: variable
	'save' => 1,         # setting: save hook arguments
	'monster' => 1,      # check: monster on screen
	'aggressives' => 1,  # check: aggressives
	'location' => 1,     # check: player's location
	'var' => 1,          # check: variable / value
	'varvar' => 1,       # check: nested variable / value
	'base' => 1,         # check: base level
	'job' => 1,          # check: job level
	'hp' => 1,           # check: player's hp
	'sp' => 1,           # check: player's sp
	'spirit' => 1,       # check: spirit spheres
	'weight' => 1,       # check: player's weight
	'cartweight' => 1,   # check: cart weight
	'soldout' => 1,      # check: sold out shop slots
	'zeny' => 1,         # check: player's zeny
	'cash' => 1,         # check: player's cash
	'player' => 1,       # check: player name near
	'equipped' => 1,     # check: equipment
	'status' => 1,       # check: player's status
	'inventory' => 1,    # check: item amount in inventory
	'storage' => 1,      # check: item amount in storage
	'shop' => 1,         # check: item amount in shop
	'cart' => 1,         # check: item amount in cart
	'localtime' => 1     # check: localtime
);

our $macroKeywords =
	"npc"          . "|" .
	"store"        . "|" .
	"player"       . "|" .
	"monster"      . "|" .
	"venderitem"   . "|" .
	"venderprice"  . "|" .
	"venderamount" . "|" .
	"random"       . "|" .
	"rand"         . "|" .
	"invamount"    . "|" .
	"cartamount"   . "|" .
	"shopamount"   . "|" .
	"storamount"   . "|" .
	"[Ii]nventory" . "|" .
	"[Ss]torage"   . "|" .
	"[Cc]art"      . "|" .
	"vender"       . "|" .
	"config"       . "|" .
	"eval"         . "|" .
	"arg"          . "|" .
	"listitem"     . "|" .
   	"nick"         . "|" .
	"listlenght"
;

1;
