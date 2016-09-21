# xConf plugin by 4epT (ICQ 2227733)
# Based on Lims idea
# Edited by Dairey, manticora
# Last changes 12.09.2010
# Plug-in for change mon_control/pickupitems/items_control/priority files, using console commands.
#
# Examples of commands:
# mconf Spore 0 0 0
# mconf 1014 0 0 0
#
# iconf Meat 50 1 0
# iconf 517 50 1 0
#
# pconf Fluff -1
# pconf 914 -1
#
# priconf Pupa, Poring, Lunatic


package xConf;

use Plugins;
use Globals;
use Log qw(message error debug);

## startup
Plugins::register('xConf', 'commands for change items_control, mon_control, pickupitems, priority', \&Unload, \&Reload);

## Register command 'xConf'
my $chooks = Commands::register(
	['iconf', 'edit items_control.txt', \&xConf],
	['mconf', 'edit mon_control.txt', \&xConf],
	['pconf', 'edit pickupitems.txt', \&xConf],
	['sconf', 'edit shop.txt', \&xConf],
	['priconf', 'edit priority.txt', \&priconf],
);

sub Reload {
	Commands::unregister($chooks);
	message "xConf plugin reloading\n", 'success'
}
sub Unload {
	Commands::unregister($chooks);
	message "xConf plugin unloading\n", 'success'
}

sub xConf {
	my ($cmd, $args) = @_;
	my ($key, $value) = $args =~ /([\s\S]+?)(?: |   )([\-\d\.]+[\s\S]*)/;
	$key = $args if !$key;
debug "KEY: $key, VALUE: $value\n";
	if (!$key) {
		error "Syntax Error in function '$cmd'. Not found <key>\nUsage: $cmd <key> [<value>]\n";
		return
	}
	my ($file,$found,$name, %inf_hash, %ctrl_hash) = undef;

	if ($cmd eq 'mconf') {
		%inf_hash  = %monsters_lut;
		%ctrl_hash = %mon_control;
		$file = 'mon_control.txt'
	} elsif ($cmd eq 'pconf') {
		%inf_hash  = %items_lut;
		%ctrl_hash = %pickupitems;
		$file = 'pickupitems.txt'
	} elsif ($cmd eq 'iconf') {
		%inf_hash  = %items_lut;
		%ctrl_hash = %items_control;
		$file = 'items_control.txt'
	} elsif ($cmd eq 'sconf') {
		%inf_hash = %items_lut;
		%ctrl_hash = %shop;
		$file = 'shop.txt'
	}

	## Check $key in tables\monsters.txt & items.txt

	if ($key ne "all") {
		if ($inf_hash{$key}) {
debug "'$inf_hash{$key}' ID: $key is found in 'tables\\monsters.txt'.\n";
		$found = 1;
		$key = $inf_hash{$key}
		} else {
			foreach $name (values %inf_hash) {
				if ($found = (lc($key) eq lc($name))) {
					$key = $name;
debug "'$name' is found in 'tables\\monsters.txt'.\n";
					last
				}
			}
		}
		if (!$found) {error "WARNING: '$key' is not found in 'tables\\monsters.txt' and in 'tables\\items.txt'!\n"}
	}
	
	if ($value eq '') {
		if ($cmd eq 'sconf') {
			my $i = 0;
			$found = 0;
			until ($ctrl_hash{items}[$i]{name} eq "") {
				if ($ctrl_hash{items}[$i]{name} eq $args) {
					$found = 1;
					message "$file: $ctrl_hash{items}[$i]{name} $ctrl_hash{items}[$i]{price} $ctrl_hash{items}[$i]{amount}\n", 'list'
				}
			$i++;
			}
			if (!$found) {
				error "The key '$key' is not found in '$file'\n";
			}
		} else {
			if ($ctrl_hash{lc($key)}) {
				$key = lc($key);
				if ($cmd eq 'mconf') {
				message "$file: $key $ctrl_hash{$key}{attack_auto} $ctrl_hash{$key}{teleport_auto} $ctrl_hash{$key}{teleport_search} $ctrl_hash{$key}{skillcancel_auto} $ctrl_hash{$key}{attack_lvl} $ctrl_hash{$key}{attack_jlvl} $ctrl_hash{$key}{attack_hp} $ctrl_hash{$key}{attack_sp} $ctrl_hash{$key}{weight}\n", 'list'
				} elsif ($cmd eq 'pconf') {
					message "$file: $key $pickupitems{$key}\n", 'list'
				} elsif ($cmd eq 'iconf') {
					message "$file: $key $items_control{$key}{keep} $items_control{$key}{storage} $items_control{$key}{sell} $items_control{$key}{cart_add} $items_control{$key}{cart_get}\n", 'list'
				} elsif ($cmd eq 'priconf') {
					message "$file: $key $priority{$key}\n", 'list'
				}
			} else {
				error "The key '$key' is not found in '$file'\n"
			}
		}
		return
	}
	filewrite($file, $key, $value)
}

## write FILE
sub filewrite {
	my ($file, $key, $value) = @_;
	my $controlfile = Settings::getControlFilename($file);
debug "sub WRITE = FILE: $file, KEY: $key, VALUE: $value\n";
	open(FILE, "<:utf8", $controlfile);
	my @lines = <FILE>;
	close(FILE);
	chomp @lines;

	my $used = 0;
	my $nochanges = 1;
	foreach my $line (@lines) {
		my ($what) = $line =~ /([\s\S]+?)(?: |   )(?:[\-\d\.]+[\s\S]*)/;
		my $tmp = "";
		if (lc($what) eq lc($key)) {
			if ($file eq 'shop.txt') {
				$tmp = join ('	', $key, $value);
			} else {
				$tmp = join (' ', $key, $value);
			}
			if ($line ne $tmp) {
				$nochanges = 0;
				$line = $tmp;
			}
			$used = 1;
		}
	}
	if ($used == 0) {
		$nochanges = 0;
		if ($file eq 'shop.txt') {
			push (@lines, $key.'	'.$value)
		} else {
			push (@lines, $key.' '.$value)
		}
	}
	message "$file: $key $value\n", 'system';
	if ($nochanges == 0) {
		open(WRITE, ">:utf8", $controlfile);
		print WRITE join ("\n", @lines);
		close(WRITE);
		Commands::run("reload $file")
	}
}


sub priconf {
	my ($cmd, $args) = @_;
	my @mobs = split /\s*,\s*/, $args;
	if (@mobs == 0) { 
		error "Syntax Error in function 'priconf'.\nUsage: priconf monster1, monster2, ...\n";
		return
	}
	my $controlfile = Settings::getControlFilename('priority.txt');
	open(my $file,"<:utf8",$controlfile);
	my @lines = ();
	my $begin = 1;
	while (my $line = <$file>) {
		my $tmp = $line;
		$tmp =~ s/\x{FEFF}//g;
		chomp($tmp);
		
		if (($tmp =~ /^#/) or ($tmp =~ /^\s*$/)) {
			push @lines, $line;
			next;
		}
		
		if ($begin == 1) {
			foreach (@mobs) { push @lines, $_."\n" }
			$begin = 0;		
		}
		
		my $ok = 1;
		foreach (@mobs) {
			if (lc($_) eq lc($tmp)) {
				$ok = 0;
				last;
			}
		}
		if ($ok == 1) {
			push @lines, $line;
		}
	}
	close($file);
	open($file,">:utf8",$controlfile);
	print $file @lines;
	close($file);
	Commands::run("reload priority.txt");
}
return 1;