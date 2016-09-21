#########################################################################
#  OpenKore - Packet Receiveing
#  This module contains functions for Receiveing packets to the server.
#
#  This software is open source, licensed under the GNU General Public
#  License, version 2.
#  Basically, this means that you're allowed to modify and distribute
#  this software. However, if you distribute modified versions, you MUST
#  also distribute the source code.
#  See http://www.gnu.org/licenses/gpl.html for the full license.
#
#  $Revision: 7841 $
#  $Id: kRO.pm 6687 2009-04-19 19:04:25Z technologyguild $
########################################################################
# Korea (kRO)
# The majority of private servers use eAthena, this is a clone of kRO

package Network::Receive::kRO::Sakexe_2007_10_02a;

use strict;
use base qw(Network::Receive::kRO::Sakexe_2007_05_07a);

use Globals qw(%config);
use I18N qw(bytesToString);
use Log qw(message);
use Misc qw(stripLanguageCode chatLog);


# TODO: maybe we should try to not use globals in here at all but instead pass them on?

sub new {
	my ($class) = @_;
	my $self = $class->SUPER::new(@_);
	my %packets = (
		'0289' => ['cash_buy_fail', 'V2 v', [qw(cash_points kafra_points fail)]], # 12
		'02A6' => ['gameguard_request'], # 22
		'02AD' => ['login_pin_code_request', 'v V', [qw(flag key)]], # 8
		'02B1' => ['quest_all_list', 'v V', [qw(len amount)]], # -1
		'02B2' => ['quest_all_mission', 'v V', [qw(len amount)]], # -1
		'02B3' => ['quest_add', 'V C V2 v', [qw(questID active time_start time amount)]], # 107
		'02B4' => ['quest_delete', 'V', [qw(questID)]], # 6
		'02B5' => ['quest_update_mission_hunt', 'v2 a*', [qw(len amount mobInfo)]],#-1
		'02B7' => ['quest_active', 'V C', [qw(questID active)]], # 7
		'02B8' => ['party_show_picker', 'a4 v C3 a8 v C', [qw(sourceID nameID identified broken upgrade cards location type)]], # 22
		'02B9' => ['hotkeys'], # 191 # hotkeys:27
		'02BB' => ['equipitem_damaged', 'v a4', [qw(slot ID)]], # 8
		'02C1' => ['main_chat', 'v a4 a4 a*', [qw(len accountID color message)]], # -1
		'02C5' => ['party_invite_result', 'Z24 V', [qw(name type)]], # 30
		'02C6' => ['party_invite', 'a4 Z24', [qw(ID name)]], # 30
		'02C9' => ['party_allow_invite', 'C', [qw(type)]], # 3
		'02CC' => ['instance_window_queue', 'C', [qw(flag)]], # 4
		'02CE' => ['instance_window_leave', 'V a4', [qw(flag enter_limit_date)]], # 10
		'02D0' => ['inventory_items_nonstackable', 'v a*', [qw(len itemInfo)]],#-1
		'02D1' => ['storage_items_nonstackable', 'v a*', [qw(len itemInfo)]],#-1
		'02D2' => ['cart_items_nonstackable', 'v a*', [qw(len itemInfo)]],#-1
		'02D3' => ['bind_on_equip', 'v', [qw(index)]], # 4
		'02D4' => ['inventory_item_added', 'v3 C3 a8 v C2 a4 v', [qw(index amount nameID identified broken upgrade cards type_equip type fail expire unknown)]], # 29
		'02D5' => ['isvr_disconnect'], # 2
		'02D7' => ['show_eq', 'v Z24 v7 C a*', [qw(len name type hair_style tophead midhead lowhead hair_color clothes_color sex equips_info)]], # -1 #type is job
		'02D9' => ['show_eq_msg_other', 'V2', [qw(unknown flag)]], # 10
		'02DA' => ['show_eq_msg_self', 'C', [qw(type)]], # 3
		'02DC' => ['battleground_message', 'v a4 Z24 Z*', [qw(len ID name message)]], # -1
		'02DD' => ['battleground_emblem', 'a4 Z24 v', [qw(emblemID name ID)]], # 32
		'02DE' => ['battleground_score', 'v2', [qw(score_lion score_eagle)]], # 6
		'02DF' => ['battleground_position', 'a4 Z24 v3', [qw(ID name job x y)]], # 36
		'02E0' => ['battleground_hp', 'a4 Z24 v2', [qw(ID name hp max_hp)]], # 34
	);
	
	foreach my $switch (keys %packets) {
		$self->{packet_list}{$switch} = $packets{$switch};
	}

	return $self;
}

sub battleground_score {
	my ($self, $args) = @_;
	message TF("Battleground score - Lions: '%d' VS Eagles: '%d'\n", $args->{score_lion}, $args->{score_eagle}), "info";
}

sub main_chat {
	my ($self, $args) = @_;
	my $message = bytesToString($args->{message});
	stripLanguageCode(\$message);
	$message =~ s/.$//;
	my ($domain, $chatMsgUser, $chatMsg);
	if (($domain, $chatMsgUser, $chatMsg) = $message =~ /\[(.*)\] (.*?): (.*)/) {
		$chatMsgUser =~ s/ $//;
		$message = "[$domain] $chatMsgUser: $chatMsg";
	} 
	chatLog("M", "$message\n") if ($config{logSystemChat});
	message "$message\n", "schat";

	Plugins::callHook('packet_mainChat', {
		accountID => $args->{accountID},
		MsgColor => $args->{color},
		MsgUser => $chatMsgUser,
		Msg => $chatMsg,
	});
}

=pod
//2007-02-27aSakexe to 2007-10-02aSakexe
0x0288,10,cashshopbuy,2:4:6
0x0289,12
0x02a6,22
0x02a7,22
0x02a8,162
0x02a9,58
0x02ad,8
0x02b0,85
0x02b1,-1
0x02b2,-1
0x02b3,107
0x02b4,6
0x02b5,-1
0x02b6,7,queststate,2:6
0x02b7,7
0x02b8,22
0x02b9,191
0x02ba,11,hotkey,2:4:5:9
0x02bb,8
0x02bc,6
0x02bf,10
0x02c0,2
0x02c1,-1
0x02c2,-1
0x02c4,26,partyinvite2,2
0x02c5,30
0x02c6,30
0x02c7,7,replypartyinvite2,2:6
0x02c8,3
0x02c9,3
0x02ca,3
0x02cb,20
0x02cc,4
0x02cd,26
0x02ce,10
0x02cf,6
0x02d0,-1
0x02d1,-1
0x02d2,-1
0x02d3,4
0x02d4,29
0x02d5,2
0x02d6,6,viewplayerequip,2
0x02d7,-1
0x02d8,10,equiptickbox,6
0x02d9,10
0x02da,3
0x02db,-1,battlechat,2:4
0x02dc,-1
0x02dd,32
0x02de,6
0x02df,36
0x02e0,34
=cut

1;