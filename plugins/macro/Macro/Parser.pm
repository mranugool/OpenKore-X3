# $Id: Parser.pm r6759 2009-07-05 04:00:00Z ezza $
package Macro::Parser;

use strict;
use encoding 'utf8';

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(parseMacroFile parseCmd isNewCommandBlock);
our @EKSPORT_OK = qw(parseCmd isNewCommandBlock);

use Globals;
use Utils qw/existsInList/;
use List::Util qw(max min sum);
use Log qw(message warning error);
use Text::Balanced qw/extract_bracketed/;
use Macro::Data;
use Macro::Utilities qw(refreshGlobal getnpcID getItemIDs getItemPrice getStorageIDs getInventoryIDs
	getPlayerID getMonsterID getVenderID getRandom getRandomRange getInventoryAmount getCartAmount getShopAmount
	getStorageAmount getVendAmount getConfig getWord q4rx q4rx2 getArgFromList getListLenght);

our ($rev) = q$Revision: 6759 $ =~ /(\d+)/;

my $tempmacro = 0;

# adapted config file parser
sub parseMacroFile {
	my ($file, $no_undef) = @_;
	unless ($no_undef) {
		undef %macro;
		undef %automacro;
		undef @perl_name
	}

	my %block;
	my $inBlock = 0;
	my $macroCountOpenBlock = 0;
	my ($macro_subs, @perl_lines);
	open my $fp, "<:utf8", $file or return 0;
	while (<$fp>) {
		$. == 1 && s/^\x{FEFF}//; # utf bom
		s/(.*)[\s\t]+#.*$/$1/;	# remove last comments
		s/^\s*#.*$//;		# remove comments
		s/^\s*//;		# remove leading whitespaces
		s/\s*[\r\n]?$//g;	# remove trailing whitespaces and eol
		s/  +/ /g;		# trim down spaces - very cool for user's string data?
		next unless ($_);

		if (!%block && /{$/) {
			my ($key, $value) = $_ =~ /^(.*?)\s+(.*?)\s*{$/;
			if ($key eq 'macro') {
				%block = (name => $value, type => "macro");
				$macro{$value} = []
			} elsif ($key eq 'automacro') {
				%block = (name => $value, type => "auto")
			} elsif ($key eq 'sub') {
				%block = (name => $value, type => "sub")
			} else {
				%block = (type => "bogus");
				warning "$file: ignoring line '$_' in line $. (munch, munch, strange block)\n"
			}
			next
		}

		if (%block && $block{type} eq "macro") {
			if ($_ eq "}") {
				if ($macroCountOpenBlock) { # If the '}' is being used to terminate a block of commands from 'if'
					push(@{$macro{$block{name}}}, '}');
					
					if ($macroCountOpenBlock) {
						$macroCountOpenBlock--;
					}
				} else {
					undef %block
				}
			} else {
				if (isNewCommandBlock($_)) {
					$macroCountOpenBlock++
				} elsif (!$macroCountOpenBlock && ($_ =~ /^}\s*else\s*{$/ || $_ =~ /}\s*elsif.*{$/ || $_ =~ /^case.*{$/ || $_ =~ /^else*{$/)) {
					warning "$file: ignoring '$_' in line $. (munch, munch, not found the open block command)\n";
					next
				}

				push(@{$macro{$block{name}}}, $_);
			}
			
			next
		}

		if (%block && $block{type} eq "auto") {
			if ($_ eq "}") {
				if ($block{loadmacro}) {
					if ($macroCountOpenBlock) {
						push(@{$macro{$block{loadmacro_name}}}, '}');
						
						if ($macroCountOpenBlock) {
							$macroCountOpenBlock--;
						}
					} else {
						undef $block{loadmacro}
					}
				} else {
					undef %block
				}
			} elsif ($_ eq "call {") {
				$block{loadmacro} = 1;
				$block{loadmacro_name} = "tempMacro".$tempmacro++;
				$automacro{$block{name}}->{call} = $block{loadmacro_name};
				$macro{$block{loadmacro_name}} = []
			} elsif ($block{loadmacro}) {
				if (isNewCommandBlock($_)) {
					$macroCountOpenBlock++
				} elsif (!$macroCountOpenBlock && ($_ =~ /^}\s*else\s*{$/ || $_ =~ /}\s*elsif.*{$/ || $_ =~ /^case.*{$/ || $_ =~ /^else*{$/)) {
					warning "$file: ignoring '$_' in line $. (munch, munch, not found the open block command)\n";
					next
				}

				push(@{$macro{$block{loadmacro_name}}}, $_);
			} else {
				my ($key, $value) = $_ =~ /^(.*?)\s+(.*)/;
				unless (defined $key) {
					warning "$file: ignoring '$_' in line $. (munch, munch, not a pair)\n";
					next
				}
				if ($amSingle{$key}) {
					$automacro{$block{name}}->{$key} = $value
				} elsif ($amMulti{$key}) {
					push(@{$automacro{$block{name}}->{$key}}, $value)
				} else {
					warning "$file: ignoring '$_' in line $. (munch, munch, unknown automacro keyword)\n"
				}
			}
			
			next
		}
		
		if (%block && $block{type} eq "sub") {
			if ($_ eq "}") {
				if ($inBlock > 0) {
					push(@perl_lines, $_);
					$inBlock--;
					next
				}
				$macro_subs = join('', @perl_lines);
				sub_execute($block{name}, $macro_subs);
				push(@perl_name, $block{name}) unless existsInList(join(',', @perl_name), $block{name});
				undef %block; undef @perl_lines; undef $macro_subs;
				$inBlock = 0
			}
			elsif ($_ =~ /^}.*?{$/ && $inBlock > 0) {push(@perl_lines, $_)}
			elsif ($_ =~ /{$/) {$inBlock++;	push(@perl_lines, $_)}
			else {push(@perl_lines, $_)}
			next
		}
		
		if (%block && $block{type} eq "bogus") {
			if ($_ eq "}") {undef %block}
			next
		}

		my ($key, $value) = $_ =~ /(?:^(.*?)\s|})+(.*)/;
		unless (defined $key) {
			warning "$file: ignoring '$_' in line $. (munch, munch, strange food)\n";
			next
		}

		if ($key eq "!include") {
			my $f = $value;
			if (!File::Spec->file_name_is_absolute($value) && $value !~ /^\//) {
				if ($file =~ /[\/\\]/) {
					$f = $file;
					$f =~ s/(.*)[\/\\].*/$1/;
					$f = File::Spec->catfile($f, $value)
				} else {
					$f = $value
				}
			}
			if (-f $f) {
				my $ret = parseMacroFile($f, 1);
				return $ret unless $ret
			} else {
				error "$file: Include file not found: $f\n";
				return 0
			}
		}
	}
	#close $fp;
	return 0 if %block;
	return 1
}

sub sub_execute {
	return if $Settings::lockdown;
	
	my ($name, $arg) = @_;
	my $run = "sub ".$name." {".$arg."}";
	eval($run);			# cycle the macro sub between macros only
	$run = "eval ".$run;
	Commands::run($run);		# exporting sub to the &main::sub, becarefull on your sub name
					# dont name your new sub equal to any &main::sub, you should take
					# the risk yourself.
	message "[macro] registering sub $name ...\n", "menu";
}

# parses a text for keywords and returns keyword + argument as array
# should be an adequate workaround for the parser bug
#sub parseKw {
#	my @pair = $_[0] =~ /\@($macroKeywords)\s*\(\s*(.*)\s*\)/i;
#	return unless @pair;
#	if ($pair[0] eq 'arg') {
#		return $_[0] =~ /\@(arg)\s*\(\s*(".*?",\s*\d+)\s*\)/
#	} elsif ($pair[0] eq 'random') {
#		return $_[0] =~ /\@(random)\s*\(\s*(".*?")\s*\)/
#	}
#	while ($pair[1] =~ /\@($macroKeywords)\s*\(/) {
#		@pair = $pair[1] =~ /\@($macroKeywords)\s*\((.*)/
#	}
#	return @pair
#}

sub parseKw {
	my @full = $_[0] =~ /@($macroKeywords)s*((s*(.*?)s*).*)$/i;
	my @pair = ($full[0]);
	my ($bracketed) = extract_bracketed ($full[1], '()');
	return unless $bracketed;
	push @pair, substr ($bracketed, 1, -1);

	return unless @pair;
	if ($pair[0] eq 'arg') {
		return $_[0] =~ /\@(arg)\s*\(\s*(".*?",\s*(\d+|\$[a-zA-Z][a-zA-Z\d]*))\s*\)/
	} elsif ($pair[0] eq 'random') {
		return $_[0] =~ /\@(random)\s*\(\s*(".*?")\s*\)/
	}
	while ($pair[1] =~ /\@($macroKeywords)\s*\(/) {
		@pair = parseKw ($pair[1])
	}
	return @pair
}

# parses all macro perl sub-routine found in the macro script
sub parseSub {
	#Taken from sub parseKw :D
	my @full = $_[0] =~ /(?:^|\s+)(\w+)s*((s*(.*?)s*).*)$/i;
	my @pair = ($full[0]);
	my ($bracketed) = extract_bracketed ($full[1], '()');
	return unless $bracketed;
	push @pair, substr ($bracketed, 1, -1);

	return unless @pair;

	while ($pair[1] =~ /(?:^|\s+)(\w+)\s*\(/) {
		@pair = parseSub ($pair[1])
	}

	return @pair
}

# substitute variables
sub subvars {
# should be working now
	my ($pre, $nick) = @_;
	my ($var, $tmp);
	
	# variables
	$pre =~ s/(?:^|(?<=[^\\]))\$(\.?[a-z][a-z\d]*)/defined $varStack{$1} ? $varStack{$1} : ''/gei;
=pod
	while (($var) = $pre =~ /(?:^|[^\\])\$(\.?[a-z][a-z\d]*)/i) {
		$tmp = (defined $varStack{$var})?$varStack{$var}:"";
		$var = q4rx $var;
		$pre =~ s/(^|[^\\])\$$var([^a-zA-Z\d]|$)/$1$tmp$2/g;
		last if defined $nick
	}
=cut
	
	# doublevars
	$pre =~ s/\$\{(.*?)\}/defined $varStack{"#$1"} ? $varStack{"#$1"} : ''/gei;
=pod
	while (($var) = $pre =~ /\$\{(.*?)\}/i) {
		$tmp = (defined $varStack{"#$var"})?$varStack{"#$var"}:"";
		$var = q4rx $var;
		$pre =~ s/\$\{$var\}/$tmp/g
	}
=cut

	return $pre
}

# command line parser for macro
# returns undef if something went wrong, else the parsed command or "".
sub parseCmd {
	my ($cmd, $self) = @_;
	return "" unless defined $cmd;
	my ($kw, $arg, $targ, $ret, $sub, $val);

	# refresh global vars only once per command line
	refreshGlobal();
	
	while (($kw, $targ) = parseKw($cmd)) {
		$ret = "_%_";
		# first parse _then_ substitute. slower but more safe
		$arg = subvars($targ) unless $kw eq 'nick';
		my $randomized = 0;

		if ($kw eq 'npc')           {$ret = getnpcID($arg)}
		elsif ($kw eq 'cart')       {($ret) = getItemIDs($arg, $::cart{'inventory'})}
		elsif ($kw eq 'Cart')       {$ret = join ',', getItemIDs($arg, $::cart{'inventory'})}
		elsif ($kw eq 'inventory')  {($ret) = getInventoryIDs($arg)}
		elsif ($kw eq 'Inventory')  {$ret = join ',', getInventoryIDs($arg)}
		elsif ($kw eq 'store')      {($ret) = getItemIDs($arg, \@::storeList)}
		elsif ($kw eq 'storage')    {($ret) = getStorageIDs($arg)}
		elsif ($kw eq 'Storage')    {$ret = join ',', getStorageIDs($arg)}
		elsif ($kw eq 'player')     {$ret = getPlayerID($arg)}
		elsif ($kw eq 'monster')    {$ret = getMonsterID($arg)}
		elsif ($kw eq 'vender')     {$ret = getVenderID($arg)}
		elsif ($kw eq 'venderitem') {($ret) = getItemIDs($arg, \@::venderItemList)}
		elsif ($kw eq 'venderItem') {$ret = join ',', getItemIDs($arg, \@::venderItemList)}
		elsif ($kw eq 'venderprice'){$ret = getItemPrice($arg, \@::venderItemList)}
		elsif ($kw eq 'venderamount'){$ret = getVendAmount($arg, \@::venderItemList)}
		elsif ($kw eq 'random')     {$ret = getRandom($arg); $randomized = 1}
		elsif ($kw eq 'rand')       {$ret = getRandomRange($arg); $randomized = 1}
		elsif ($kw eq 'invamount')  {$ret = getInventoryAmount($arg)}
		elsif ($kw eq 'cartamount') {$ret = getCartAmount($arg)}
		elsif ($kw eq 'shopamount') {$ret = getShopAmount($arg)}
		elsif ($kw eq 'storamount') {$ret = getStorageAmount($arg)}
		elsif ($kw eq 'config')     {$ret = getConfig($arg)}
		elsif ($kw eq 'arg')        {$ret = getWord($arg)}
		elsif ($kw eq 'eval')       {$ret = eval($arg) unless $Settings::lockdown}
		elsif ($kw eq 'listitem')   {$ret = getArgFromList($arg)}
		elsif ($kw eq 'listlenght') {$ret = getListLenght($arg)}
		elsif ($kw eq 'nick')       {$arg = subvars($targ, 1); $ret = q4rx2($arg)}
		return unless defined $ret;
		return $cmd if $ret eq '_%_';
		$targ = q4rx $targ;
		unless ($randomized) {
			$cmd =~ s/\@$kw\s*\(\s*$targ\s*\)/$ret/g
		} else {
			$cmd =~ s/\@$kw\s*\(\s*$targ\s*\)/$ret/
		}
	}
	
	unless ($Settings::lockdown) {
		# any round bracket(pair) found after parseKw sub-routine were treated as macro perl sub-routine
		undef $ret; undef $arg;
		while (($sub, $val) = parseSub($cmd)) {
			my $sub_error = 1;
			foreach my $e (@perl_name) {
				if ($e eq $sub) {
					$sub_error = 0;
				}
			}
			if ($sub_error) {$self->{error} = "Unrecognized --> $sub <-- Sub-Routine"; return ""}
			$arg = subvars($val);
			my $sub1 = $sub."(".$arg.")";
			$ret = eval($sub1);
			return unless defined $ret;
			$val = q4rx $val;		
			$cmd =~ s/$sub\s*\(\s*$val\s*\)/$ret/g
		}
	}

	$cmd = subvars($cmd);
	return $cmd
}

# check if on the line there commands that open new command blocks
sub isNewCommandBlock {
	my ($line) = @_;
	
	if ($line =~ /^if.*{$/ || $line =~ /^case.*{$/ || $line =~ /^switch.*{$/ || $line =~ /^else.*{$/) {
		return 1;
	} else {
		return 0;
	}
}

1;
