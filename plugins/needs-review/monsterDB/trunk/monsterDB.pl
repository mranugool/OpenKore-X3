############################
# MonsterDB plugin for OpenKore by Damokles
#
# This software is open source, licensed under the GNU General Public
# License, version 2.
#
# This plugin extends all functions which use 'checkMonsterCondition'.
# Basically these are AttackSkillSlot, equipAuto, AttackComboSlot, monsterSkill.
#
# Following new checks are possible:
#
# target_Element (list)
# target_notElement (list)
# target_Race (list)
# target_notRace (list)
# target_Size (list)
# target_notSize (list)
# target_hpLeft (range)
#
# In equipAuto you have to leave the target_ part,
# this is due some coding inconsistency in the funtions.pl
#
# You can use monsterEquip if you think that equipAuto is to slow.
# It supports the new equip syntax. It is event-driven and is called
# when a monster: is attacked, changes status, changes element
#
# Note: It will check all monsterEquip blocks but it respects priority.
# If you check in the first block for element fire and in the second
# for race Demi-Human and in both you use different arrows but in the
# Demi-Human block you use a bow, it will take the arrows form the first
# matching block and equip the bow since the fire block didn't specified it.
#
#
# Note: monsterEquip will modify your attackEquip_{slot} so don't be surprised
# about having other attackEquips as you set before.
#
# Be careful with right and leftHand those slots will not be checked for
# two-handed weapons that may conflict.
#
# Example:
# monsterEquip {
# 	target_Element Earth
# 	equip_arrow Fire Arrow
# }
#
# For the element names just scroll a bit down and you'll find it.
# You can check for element Lvls too, eg. target_Element Dark4
#
# $Revision: 5549 $
# $Id: monsterDB.pl 5549 2007-03-21 00:55:47Z h4rry_84 $
############################

package monsterDB;

use strict;
use Plugins;
use Globals qw(%config %monsters $accountID %equipSlot_lut @ai_seq @ai_seq_args);
use Settings;
use Log qw(message warning error debug);
use Misc qw(bulkConfigModify);
use Translation qw(T TF);
use Utils;


Plugins::register('monsterDB', 'extends Monster infos', \&onUnload);
my $hooks = Plugins::addHooks(
	['checkMonsterCondition', \&extendedCheck, undef],
	['packet_skilluse', \&onPacketSkillUse, undef],
	['packet/skill_use_no_damage', \&onPacketSkillUseNoDamage, undef],
	['packet_attack', \&onPacketAttack, undef],
	['attack_start', \&onAttackStart, undef],
	['changed_status', \&onStatusChange, undef],
);


my @monsterDB;
my @element_lut = qw(Neutral Water Earth Fire Wind Poison Holy Dark Sense Undead);
my @race_lut = qw(Formless Undead Brute Plant Insect Fish Demon Demi-Human Angel Dragon);
my @size_lut = qw(Small Medium Large);
my %skillChangeElement = qw(
	NPC_CHANGEWATER Water
	NPC_CHANGEGROUND Earth
	NPC_CHANGEFIRE Fire
	NPC_CHANGEWIND Wind
	NPC_CHANGEPOISON Poison
	NPC_CHANGEHOLY Holy
	NPC_CHANGEDARKNESS Dark
	NPC_CHANGETELEKINESIS Sense
);

debug ("MonsterDB: Finished init.\n",'monsterDB',2);
loadMonDB(); # Load MonsterDB into Memory

sub onUnload {
	Plugins::delHooks($hooks);
	@monsterDB = undef;
}

sub loadMonDB {
	@monsterDB = undef;
	my @temp;
	debug ("MonsterDB: Loading DataBase\n",'monsterDB',2);
	my $file = Settings::getTableFilename('monsterDB.txt');
	error ("MonsterDB: cannot load $file\n",'monsterDB',0) unless (-r $file);
	{ open my $fp, '<', $file; @temp = <$fp> }
	my $i = 0;
	foreach my $line (@temp) {
		next unless ($line =~ /(\d{4})\s+(\d+)\s+(\d)\s+(\d)\s+(\d+)/);
		$monsterDB[(int($1) - 1000)] = [$2,$3,$4,$5];
		$i++;
	}
	message TF("%d monsters in database\n", $i), 'monsterDB';
}

sub extendedCheck {
	my (undef, $args) = @_;

	return 0 if !$args->{monster} || $args->{monster}->{nameID} eq '';

	my $monsterInfo = $monsterDB[(int($args->{monster}->{nameID}) - 1000)];

	if (!defined $monsterInfo) {
		debug("monsterDB: Monster {$args->{monster}->{name}} not found\n", 'monsterDB', 2);
		return 0;
	} #return if monster is not in DB


	my $element = $element_lut[($monsterInfo->[3] % 10)];
	my $element_lvl = int($monsterInfo->[3] / 20);
	my $race = $race_lut[$monsterInfo->[2]];
	my $size = $size_lut[$monsterInfo->[1]];

	if ($args->{monster}->{element} && $args->{monster}->{element} ne '') {
		$element = $args->{monster}->{element};
		debug("monsterDB: Monster $args->{monster}->{name} has changed element to $args->{monster}->{element}\n", 'monsterDB', 3);
	}

	if ($args->{monster}->statusActive('BODYSTATE_STONECURSE, BODYSTATE_STONECURSE_ING')) {
		$element = 'Earth';
		debug("monsterDB: Monster $args->{monster}->{name} is petrified changing element to Earth\n", 'monsterDB', 3);
	}

	if ($args->{monster}->statusActive('BODYSTATE_FREEZING')) {
		$element = 'Water';
		debug("monsterDB: Monster $args->{monster}->{name} is frozen changing element to Water\n", 'monsterDB', 3);
	}

	if ($config{$args->{prefix} . '_Element'}
	&& (!existsInList($config{$args->{prefix} . '_Element'},$element)
		&& !existsInList($config{$args->{prefix} . '_Element'},$element.$element_lvl))) {
	return $args->{return} = 0;
	}

	if ($config{$args->{prefix} . '_notElement'}
	&& (existsInList($config{$args->{prefix} . '_notElement'},$element)
		|| existsInList($config{$args->{prefix} . '_notElement'},$element.$element_lvl))) {
	return $args->{return} = 0;
	}

	if ($config{$args->{prefix} . '_Race'}
	&& !existsInList($config{$args->{prefix} . '_Race'},$race)) {
	return $args->{return} = 0;
	}

	if ($config{$args->{prefix} . '_notRace'}
	&& existsInList($config{$args->{prefix} . '_notRace'},$race)) {
	return $args->{return} = 0;
	}

	if ($config{$args->{prefix} . '_Size'}
	&& !existsInList($config{$args->{prefix} . '_Size'},$size)) {
	return $args->{return} = 0;
	}

	if ($config{$args->{prefix} . '_notSize'}
	&& existsInList($config{$args->{prefix} . '_notSize'},$size)) {
	return $args->{return} = 0;
	}

	if ($config{$args->{prefix} . '_hpLeft'}
	&& !inRange(($monsterInfo->[0] + $args->{monster}->{deltaHp}),$config{$args->{prefix} . '_hpLeft'})) {
	return $args->{return} = 0;
	}

	return 1;
}

sub onPacketSkillUse { monsterHp($monsters{$_[1]->{targetID}}, $_[1]->{disp}) if $_[1]->{disp} }

sub onPacketSkillUseNoDmg {
	my (undef,$args) = @_;
	return 1 unless $monsters{$args->{targetID}} && $monsters{$args->{targetID}}{nameID};
	if (
		$args->{targetID} eq $args->{sourceID} && $args->{targetID} ne $accountID
		&& $skillChangeElement{$args->{skillID}}
	) {
		$monsters{$args->{targetID}}{element} = $skillChangeElement{$args->{skillID}};
		monsterEquip($monsters{$args->{targetID}});
		return 1;
	}
}

sub onPacketAttack { monsterHp($monsters{$_[1]->{targetID}}, $_[1]->{msg}) if $_[1]->{msg} }

sub monsterHp {
	my ($monster, $message) = @_;
	return 1 unless $monster && $monster->{nameID};
	
	return 1 unless my $monsterInfo = $monsterDB[(int($monster->{nameID}) - 1000)];
	$$message =~ s~(?=\n)~TF(" (HP: %d/%d)", $monsterInfo->[0] + $monster->{deltaHp}, $monsterInfo->[0])~se;
}

sub onAttackStart {
	my (undef,$args) = @_;
	monsterEquip($monsters{$args->{ID}});
}

sub onStatusChange {
	my (undef, $args) = @_;

	return unless $args->{changed};
	my $actor = $args->{actor};
	return unless (UNIVERSAL::isa($actor, 'Actor::Monster'));
	my $index = binFind(\@ai_seq, 'attack');
	return unless defined $index;
	return unless $ai_seq_args[$index]->{target} == $actor->{ID};
	monsterEquip($actor);
}

sub monsterEquip {
	my $monster = shift;
	return unless $monster;
	my %equip_list;

	my %args = ('monster' => $monster);
	my $slot;

	for (my $i=0;exists $config{"monsterEquip_$i"};$i++) {
		$args{prefix} = "monsterEquip_${i}_target";
		if (extendedCheck(undef,\%args)) {
			foreach $slot (%equipSlot_lut) {
				if ($config{"monsterEquip_${i}_equip_$slot"}
				&& !$equip_list{"attackEquip_$slot"}
				&& defined Actor::Item::get($config{"monsterEquip_${i}_equip_$slot"})) {
					$equip_list{"attackEquip_$slot"} = $config{"monsterEquip_${i}_equip_$slot"};
					debug "monsterDB: using ".$config{"monsterEquip_${i}_equip_$slot"}."\n",'monsterDB';
				}
			}
		}
	}
	foreach (keys %equip_list) {
		$config{$_} = $equip_list{$_};
	}
	Actor::Item::scanConfigAndEquip('attackEquip');
}

1;
