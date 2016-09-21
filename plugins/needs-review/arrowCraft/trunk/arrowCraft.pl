package arrowCraft;
 
#
# This plugin is licensed under the GNU GPL
# Copyright 2005 by kaliwanagan
# Fixed for OpenKore 2.0.5+
# --------------------------------------------------
#
# How to install this thing..:
#
# in control\config.txt add:
# 
#arrowCraft Zargon {
#       delay 3 # specify number of seconds to wait before crafting another arrow; defaults to 1
#       inInventory Silver Arrow <10
#       onAction attack
#}
 
use strict;
use Plugins;
use Globals;
use Log qw(message warning error debug);
use AI;
use Misc;
use Network;
use Network::Send;
 
Plugins::register('arrowCraft', 'use arrow craft without SP', \&Unload);
my $hook = Plugins::addHook('AI_pre', \&cast);
 
sub Unload {
        Plugins::delHook('AI_pre', $hook);
}
 
my %delay;
 
sub cast {
        my $prefix = "arrowCraft_";
        my $i = 0;
       
        while (exists $config{$prefix.$i}) {
                my $item = $char->inventory->getByName($config{$prefix.$i});
                $delay{'timeout'} = $config{$prefix.$i."_delay"} || 1;
                if ((@{$char->inventory->getItems()}) &&
                        (main::timeOut(\%delay)) &&
                        ($item->{'amount'} > 0) &&
                        (main::checkSelfCondition($prefix.$i))) 
                {
						Commands::run('arrowcraft use') if ($masterServer->{private});
                        sendArrowCraft($messageSender,$item->{'nameID'});
                        message ("You use Arrow Craft on item: " . $item->{'name'} . "\n", "selfSkill");
                        $delay{'time'} = time;
                }
                $i++;
        }
}
 
return 1;