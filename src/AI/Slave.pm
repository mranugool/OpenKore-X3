package AI::Slave;

use strict;
use Time::HiRes qw(time);
use base qw/Actor::Slave/;
use Globals;
use Log qw/message warning error debug/;
use Utils;
use Misc;
use Translation;

use AI::Slave::Homunculus;
use AI::Slave::Mercenary;

# homunculus commands/skills can only be used
# if the homunculus is within this range
use constant MAX_DISTANCE => 17;

sub checkSkillOwnership {}

sub action {
	my $slave = shift;
	
	my $i = (defined $_[0] ? $_[0] : 0);
	return $slave->{slave_ai_seq}[$i];
}

sub args {
	my $slave = shift;
	
	my $i = (defined $_[0] ? $_[0] : 0);
	return \%{$slave->{slave_ai_seq_args}[$i]};
}

sub dequeue {
	my $slave = shift;
	
	shift @{$slave->{slave_ai_seq}};
	shift @{$slave->{slave_ai_seq_args}};
}

sub queue {
	my $slave = shift;
	
	unshift @{$slave->{slave_ai_seq}}, shift;
	my $args = shift;
	unshift @{$slave->{slave_ai_seq_args}}, ((defined $args) ? $args : {});
}

sub clear {
	my $slave = shift;
	
	if (@_) {
		my $changed;
		for (my $i = 0; $i < @{$slave->{slave_ai_seq}}; $i++) {
			if (defined binFind(\@_, $slave->{slave_ai_seq}[$i])) {
				delete $slave->{slave_ai_seq}[$i];
				delete $slave->{slave_ai_seq_args}[$i];
				$changed = 1;
			}
		}

		if ($changed) {
			my (@new_seq, @new_args);
			for (my $i = 0; $i < @{$slave->{slave_ai_seq}}; $i++) {
				if (defined $slave->{slave_ai_seq}[$i]) {
					push @new_seq, $slave->{slave_ai_seq}[$i];
					push @new_args, $slave->{slave_ai_seq_args}[$i];
				}
			}
			@{$slave->{slave_ai_seq}} = @new_seq;
			@{$slave->{slave_ai_seq_args}} = @new_args;
		}

	} else {
		undef @{$slave->{slave_ai_seq}};
		undef @{$slave->{slave_ai_seq_args}};
	}
}

sub suspend {
	my $slave = shift;
	
	my $i = (defined $_[0] ? $_[0] : 0);
	$slave->{slave_ai_seq_args}[$i]{suspended} = time if $i < @{$slave->{slave_ai_seq_args}};
}

sub mapChanged {
	my $slave = shift;
	
	my $i = (defined $_[0] ? $_[0] : 0);
	$slave->{slave_ai_seq_args}[$i]{mapChanged} = time if $i < @{$slave->{slave_ai_seq_args}};
}

sub findAction {
	my $slave = shift;
	
	return binFind(\@{$slave->{slave_ai_seq}}, $_[0]);
}

sub inQueue {
	my $slave = shift;
	
	foreach (@_) {
		# Apparently using a loop is faster than calling
		# binFind() (which is optimized in C), because
		# of function call overhead.
		#return 1 if defined binFind(\@homun_ai_seq, $_);
		foreach my $seq (@{$slave->{slave_ai_seq}}) {
			return 1 if ($_ eq $seq);
		}
	}
	return 0;
}

sub isIdle {
	my $slave = shift;
	
	return $slave->{slave_ai_seq}[0] eq "";
}

sub is {
	my $slave = shift;
	
	foreach (@_) {
		return 1 if ($slave->{slave_ai_seq}[0] eq $_);
	}
	return 0;
}

sub iterate {
	my $slave = shift;
	
	if ($slave->{appear_time} && $field->baseName eq $slave->{map}) {
		my $slave_dist = blockDistance ($slave->position, $char->position);
		
		# auto-follow
		if (
			$slave->{slave_AI} == AI::AUTO
			&& (AI::action eq "move" || AI::action eq "route")
			&& !$char->{sitting}
			&& !AI::args->{mapChanged}
			&& !AI::args->{time_move} != $char->{time_move}
			&& !timeOut(AI::args->{ai_move_giveup})
			&& $slave_dist < MAX_DISTANCE
			&& ($slave->isIdle
				|| blockDistance(AI::args->{move_to}, $slave->{pos_to}) >= MAX_DISTANCE)
			&& (!defined $slave->findAction('route') || !$slave->args($slave->findAction('route'))->{follow_route})
		) {
			$slave->clear('move', 'route');
			if (!checkLineWalkable($slave->{pos_to}, $char->{pos_to})) {
				$slave->route(undef, @{$char->{pos_to}}{qw(x y)});
				$slave->args->{follow_route} = 1 if $slave->action eq 'route';
				debug sprintf("Slave follow route (distance: %.2f)\n", $slave->distance()), 'homunculus';
	
			} elsif (timeOut($slave->{move_retry}, 0.5)) {
				# No update yet, send move request again.
				# We do this every 0.5 secs
				$slave->{move_retry} = time;
				# NOTE:
				# The default LUA uses sendHomunculusStandBy() for the follow AI
				# however, the server-side routing is very inefficient
				# (e.g. can't route properly around obstacles and corners)
				# so we make use of the sendHomunculusMove() to make up for a more efficient routing
				$slave->sendMove ($char->{pos_to}{x}, $char->{pos_to}{y});
				debug sprintf("Slave follow move (distance: %.2f)\n", $slave->distance()), 'homunculus';
			}
=pod
		# homunculus is found
		} elsif ($slave->{slave_lost}) {
			if ($slave_dist < MAX_DISTANCE) {
				delete $slave->{slave_lost};
				delete $slave->{lostRoute};
				my $action = $slave->findAction('route');
				if (defined $action && $slave->args($action)->{lost_route}) {
					for (my $i = 0; $i <= $action; $i++) {
						$slave->dequeue
					}
				}
				if (timeOut($slave->{standby_time}, 1)) {
					$slave->sendStandBy;
					$slave->{standby_time} = time;
				}
				message TF("Found %s!\n", $slave), 'homunculus';
	
			# attempt to find homunculus on it's last known coordinates
			} elsif ($AI == AI::AUTO && !$slave->{lostRoute}) {
				if ($config{homunculus_StandByAuto}) {
					message TF("Stand By Homun\n", $slave), 'teleport';
					$slave->sendStandBy;
				} elsif ($config{teleportAuto_lostHomunculus}) {
					message TF("Teleporting to get %s back\n", $slave), 'teleport';
					useTeleport(1);
				} else {
					my $x = $slave->{pos_to}{x};
					my $y = $slave->{pos_to}{y};
					my $distFromGoal = $config{$slave->{configPrefix}.'followDistanceMax'};
					$distFromGoal = MAX_DISTANCE if ($distFromGoal > MAX_DISTANCE);
					main::ai_route($field->baseName, $x, $y, distFromGoal => $distFromGoal, attackOnRoute => 1, noSitAuto => 1);
					$slave->args->{lost_route} = 1 if $slave->action eq 'route';
					message TF("Trying to find %s at location %d, %d (you are currently at %d, %d)\n", $slave, $x, $y, $char->{pos_to}{x}, $char->{pos_to}{y}), 'homunculus';
				}
				$slave->{lostRoute} = 1;
			}
		
		# homunculus is lost
		} elsif ($slave->{actorType} eq 'Homunculus' && $slave_dist >= MAX_DISTANCE && !$slave->{slave_lost}) {
			$slave->{slave_lost} = 1;
			message TF("You lost %s!\n", $slave), 'homunculus';
=cut
		# if your homunculus is idle, make it move near you
		} elsif (
			$slave->{slave_AI} == AI::AUTO
			&& $slave->isIdle
			&& $slave_dist > ($config{$slave->{configPrefix}.'followDistanceMin'} || 3)
			&& $slave_dist < MAX_DISTANCE
			&& timeOut($slave->{standby_time}, 2)
		) {
			$slave->sendStandBy;
			$slave->{standby_time} = time;
			debug sprintf("Slave standby (distance: %.2f)\n", $slave->distance()), 'homunculus';
	
		# if you are idle, move near the homunculus
		} elsif (
			$slave->{actorType} eq 'Homunculus' &&
			$AI == AI::AUTO && AI::isIdle && !$slave->isIdle
			&& $config{$slave->{configPrefix}.'followDistanceMax'}
			&& $slave_dist > $config{$slave->{configPrefix}.'followDistanceMax'}
		) {
			main::ai_route($field->baseName, $slave->{pos_to}{x}, $slave->{pos_to}{y}, distFromGoal => ($config{$slave->{configPrefix}.'followDistanceMin'} || 3), attackOnRoute => 1, noSitAuto => 1);
			message TF("%s moves too far (distance: %.2f) - Moving near\n", $slave, $slave->distance), 'homunculus';
	
		# Main Homunculus AI
		} else {
			return unless $slave->{slave_AI};
			return if $slave->processClientSuspend;
			$slave->processAttack;
			$slave->processTask('route', onError => sub {
				my ($task, $error) = @_;
				if (!($task->isa('Task::MapRoute') && $error->{code} == Task::MapRoute::TOO_MUCH_TIME())
				 && !($task->isa('Task::Route') && $error->{code} == Task::Route::TOO_MUCH_TIME())) {
					error("$error->{message}\n");
				}
			});
			$slave->processTask('move');
			return unless $slave->{slave_AI} == AI::AUTO;
			$slave->processAutoAttack;
		}
	}
}

sub slave_setMapChanged {
	my ($slave, $index) = @_;
	$index = 0 if ($index eq "");
	if ($index < @{$slave->{slave_seq_args}}) {
		$slave->{slave_seq_args}[$index]{'mapChanged'} = time;
	}
}

##### ATTACK #####
sub processAttack {
	my $slave = shift;
	#Benchmark::begin("ai_homunculus_attack") if DEBUG;

	if ($slave->action eq "attack" && $slave->args->{suspended}) {
		$slave->args->{ai_attack_giveup}{time} += time - $slave->args->{suspended};
		delete $slave->args->{suspended};
	}

	if ($slave->action eq "attack" && $slave->args->{move_start}) {
		# We've just finished moving to the monster.
		# Don't count the time we spent on moving
		$slave->args->{ai_attack_giveup}{time} += time - $slave->args->{move_start};
		undef $slave->args->{unstuck}{time};
		undef $slave->args->{move_start};

	} elsif ($slave->action eq "attack" && $slave->args->{avoiding} && $slave->args->{attackID}) {
		my $target = Actor::get($slave->args->{attackID});
		$slave->args->{ai_attack_giveup}{time} = time + $target->{time_move_calc} + 3;
		undef $slave->args->{avoiding};

	} elsif ((($slave->action eq "route" && $slave->action (1) eq "attack") || ($slave->action eq "move" && $slave->action (2) eq "attack"))
	   && $slave->args->{attackID} && timeOut($slave->{slave_attack_route_adjust}, 1)) {
		# We're on route to the monster; check whether the monster has moved
		my $ID = $slave->args->{attackID};
		my $attackSeq = ($slave->action eq "route") ? $slave->args (1) : $slave->args (2);
		my $target = Actor::get($ID);

		if ($target->{type} ne 'Unknown' && $attackSeq->{monsterPos} && %{$attackSeq->{monsterPos}}
		 && distance(calcPosition($target), $attackSeq->{monsterPos}) > $attackSeq->{attackMethod}{maxDistance}) {
			# Monster has moved; stop moving and let the attack AI readjust route
			$slave->dequeue;
			$slave->dequeue if $slave->action eq "route";

			$attackSeq->{ai_attack_giveup}{time} = time;
			debug "Slave target has moved more than $attackSeq->{attackMethod}{maxDistance} blocks; readjusting route\n", "ai_attack";

		} elsif ($target->{type} ne 'Unknown' && $attackSeq->{monsterPos} && %{$attackSeq->{monsterPos}}
		 && distance(calcPosition($target), calcPosition($slave)) <= $attackSeq->{attackMethod}{maxDistance}) {
			# Monster is within attack range; stop moving
			$slave->dequeue;
			$slave->dequeue if $slave->action eq "route";

			$attackSeq->{ai_attack_giveup}{time} = time;
			debug "Slave target at ($attackSeq->{monsterPos}{x},$attackSeq->{monsterPos}{y}) is now within " .
				"$attackSeq->{attackMethod}{maxDistance} blocks; stop moving\n", "ai_attack";
		}
		$slave->{slave_attack_route_adjust} = time;
	}

	if ($slave->action eq "attack" &&
	    (timeOut($slave->args->{ai_attack_giveup}) ||
		 $slave->args->{unstuck}{count} > 5) &&
		!$config{$slave->{configPrefix}.'attackNoGiveup'}) {
		my $ID = $slave->args->{ID};
		my $target = Actor::get($ID);
		$target->{homunculus_attack_failed} = time if $monsters{$ID};
		$slave->dequeue;
		message TF("%s can't reach or damage target, dropping target\n", $slave), 'homunculus_attack';
		if ($config{$slave->{configPrefix}.'teleportAuto_dropTarget'}) {
			message TF("Teleport due to dropping %s attack target\n", $slave), 'teleport';
			useTeleport(1);
		}

	} elsif ($slave->action eq "attack" && !$monsters{$slave->args->{ID}} && (!$players{$slave->args->{ID}} || $players{$slave->args->{ID}}{dead})) {
		# Monster died or disappeared
		$timeout{'ai_homunculus_attack'}{'time'} -= $timeout{'ai_homunculus_attack'}{'timeout'};
		my $ID = $slave->args->{ID};
		$slave->dequeue;

		if ($monsters_old{$ID} && $monsters_old{$ID}{dead}) {
			message TF("%s target died\n", $slave), 'homunculus_attack';
			Plugins::callHook("homonulus_target_died");
			monKilled();

			# Pickup loot when monster's dead
			if ($AI == AI::AUTO && $config{itemsTakeAuto} && $monsters_old{$ID}{dmgFromPlayer}{$slave->{ID}} > 0 && !$monsters_old{$ID}{homunculus_ignore}) {
				AI::clear("items_take");
				AI::ai_items_take($monsters_old{$ID}{pos}{x}, $monsters_old{$ID}{pos}{y},
					$monsters_old{$ID}{pos_to}{x}, $monsters_old{$ID}{pos_to}{y});
			} else {
				# Cheap way to suspend all movement to make it look real
				$slave->clientSuspend(0, $timeout{'ai_attack_waitAfterKill'}{'timeout'});
			}

			## kokal start
			## mosters counting
			my $i = 0;
			my $found = 0;
			while ($monsters_Killed[$i]) {
				if ($monsters_Killed[$i]{'nameID'} eq $monsters_old{$ID}{'nameID'}) {
					$monsters_Killed[$i]{'count'}++;
					monsterLog($monsters_Killed[$i]{'name'});
					$found = 1;
					last;
				}
				$i++;
			}
			if (!$found) {
				$monsters_Killed[$i]{'nameID'} = $monsters_old{$ID}{'nameID'};
				$monsters_Killed[$i]{'name'} = $monsters_old{$ID}{'name'};
				$monsters_Killed[$i]{'count'} = 1;
				monsterLog($monsters_Killed[$i]{'name'})
			}
			## kokal end

		} else {
			message TF("%s target lost\n", $slave), 'homunculus_attack';
		}

	} elsif ($slave->action eq "attack") {
		# The attack sequence hasn't timed out and the monster is on screen

		# Update information about the monster and the current situation
		my $args = $slave->args;
		my $ID = $args->{ID};
		my $target = Actor::get($ID);
		my $myPos = $slave->{pos_to};
		my $monsterPos = $target->{pos_to};
		my $monsterDist = distance($myPos, $monsterPos);

		my ($realMyPos, $realMonsterPos, $realMonsterDist, $hitYou);
		my $realMyPos = calcPosition($slave);
		my $realMonsterPos = calcPosition($target);
		my $realMonsterDist = distance($realMyPos, $realMonsterPos);
		if (!$config{$slave->{configPrefix}.'runFromTarget'}) {
			$myPos = $realMyPos;
			$monsterPos = $realMonsterPos;
		}

		my $cleanMonster = checkMonsterCleanness($ID);


		# If the damage numbers have changed, update the giveup time so we don't timeout
		if ($args->{dmgToYou_last}   != $target->{dmgToPlayer}{$slave->{ID}}
		 || $args->{missedYou_last}  != $target->{missedToPlayer}{$slave->{ID}}
		 || $args->{dmgFromYou_last} != $target->{dmgFromPlayer}{$slave->{ID}}) {
			$args->{ai_attack_giveup}{time} = time;
			debug "Update slave attack giveup time\n", "ai_attack", 2;
		}
		$hitYou = ($args->{dmgToYou_last} != $target->{dmgToPlayer}{$slave->{ID}}
			|| $args->{missedYou_last} != $target->{missedToPlayer}{$slave->{ID}});
		$args->{dmgToYou_last} = $target->{dmgToPlayer}{$slave->{ID}};
		$args->{missedYou_last} = $target->{missedToPlayer}{$slave->{ID}};
		$args->{dmgFromYou_last} = $target->{dmgFromPlayer}{$slave->{ID}};
		$args->{missedFromYou_last} = $target->{missedFromPlayer}{$slave->{ID}};

		$args->{attackMethod}{type} = "weapon";
		
		### attackSkillSlot begin
		for (my ($i, $prefix) = (0, 'attackSkillSlot_0'); $prefix = "attackSkillSlot_$i" and exists $config{$prefix}; $i++) {
			next unless $config{$prefix};
			if (checkSelfCondition($prefix) && checkMonsterCondition("${prefix}_target", $target)) {
				my $skill = new Skill(auto => $config{$prefix});
				next unless $slave->checkSkillOwnership ($skill);
				
				next if $config{"${prefix}_maxUses"} && $target->{skillUses}{$skill->getHandle()} >= $config{"${prefix}_maxUses"};
				next if $config{"${prefix}_target"} && !existsInList($config{"${prefix}_target"}, $target->{name});
				
				# Donno if $char->getSkillLevel is the right place to look at.
				# my $lvl = $config{"${prefix}_lvl"} || $char->getSkillLevel($party_skill{skillObject});
				my $lvl = $config{"${prefix}_lvl"};
				my $maxCastTime = $config{"${prefix}_maxCastTime"};
				my $minCastTime = $config{"${prefix}_minCastTime"};
				debug "Slave attackSkillSlot on $target->{name} ($target->{binID}): ".$skill->getName()." (lvl $lvl)\n", "monsterSkill";
				my $skillTarget = $config{"${prefix}_isSelfSkill"} ? $slave : $target;
				AI::ai_skillUse2($skill, $lvl, $maxCastTime, $minCastTime, $skillTarget, $prefix);
				$ai_v{$prefix . "_time"} = time;
				$ai_v{$prefix . "_target_time"}{$ID} = time;
				last;
			}
		}
		### attackSkillSlot end
		
		$args->{attackMethod}{maxDistance} = $config{$slave->{configPrefix}.'attackMaxDistance'};
		$args->{attackMethod}{distance} = ($config{$slave->{configPrefix}.'runFromTarget'} && $config{$slave->{configPrefix}.'runFromTarget_dist'} > $config{$slave->{configPrefix}.'attackDistance'}) ? $config{$slave->{configPrefix}.'runFromTarget_dist'} : $config{$slave->{configPrefix}.'attackDistance'};
		if ($args->{attackMethod}{maxDistance} < $args->{attackMethod}{distance}) {
			$args->{attackMethod}{maxDistance} = $args->{attackMethod}{distance};
		}

		if (!$cleanMonster) {
			# Drop target if it's already attacked by someone else
			$target->{homunculus_attack_failed} = time if $monsters{$ID};
			message TF("Dropping target - %s will not kill steal others\n", $slave), 'homunculus_attack';
			$slave->sendMove ($realMyPos->{x}, $realMyPos->{y});
			$slave->dequeue;
			if ($config{$slave->{configPrefix}.'teleportAuto_dropTargetKS'}) {
				message TF("Teleport due to dropping %s attack target\n", $slave), 'teleport';
				useTeleport(1);
			}

		} elsif ($config{$slave->{configPrefix}.'attackCheckLOS'} &&
			 $args->{attackMethod}{distance} > 2 &&
			 !checkLineSnipable($realMyPos, $realMonsterPos)) {
			# We are a ranged attacker without LOS

			# Calculate squares around monster within shooting range, but not
			# closer than runFromTarget_dist
			my @stand = calcRectArea2($realMonsterPos->{x}, $realMonsterPos->{y},
						  $args->{attackMethod}{distance},
									  $config{$slave->{configPrefix}.'runFromTarget'} ? $config{$slave->{configPrefix}.'runFromTarget_dist'} : 0);

			# Determine which of these spots are snipable
			my $best_spot;
			my $best_dist;
			for my $spot (@stand) {
				# Is this spot acceptable?
				# 1. It must have LOS to the target ($realMonsterPos).
				# 2. It must be within $config{followDistanceMax} of
				#    $masterPos, if we have a master.
				if (checkLineSnipable($spot, $realMonsterPos) &&
				    (distance($spot, $char->{pos_to}) <= 15)) {
					# FIXME: use route distance, not pythagorean distance
					my $dist = distance($realMyPos, $spot);
					if (!defined($best_dist) || $dist < $best_dist) {
						$best_dist = $dist;
						$best_spot = $spot;
					}
				}
			}

			# Move to the closest spot
			my $msg = TF("%s has no LOS from (%d, %d) to target (%d, %d)", $slave, $realMyPos->{x}, $realMyPos->{y}, $realMonsterPos->{x}, $realMonsterPos->{y});
			if ($best_spot) {
				message TF("%s; moving to (%s, %s)\n", $msg, $best_spot->{x}, $best_spot->{y}), 'homunculus_attack';
				$slave->route(undef, @{$best_spot}{qw(x y)});
			} else {
				warning TF("%s; no acceptable place to stand\n", $msg);
				$slave->dequeue;
			}

		} elsif ($config{$slave->{configPrefix}.'runFromTarget'} && ($monsterDist < $config{$slave->{configPrefix}.'runFromTarget_dist'} || $hitYou)) {
			#my $begin = time;
			# Get a list of blocks that we can run to
			my @blocks = calcRectArea($myPos->{x}, $myPos->{y},
				# If the monster hit you while you're running, then your recorded
				# location may be out of date. So we use a smaller distance so we can still move.
				($hitYou) ? $config{$slave->{configPrefix}.'runFromTarget_dist'} / 2 : $config{$slave->{configPrefix}.'runFromTarget_dist'});

			# Find the distance value of the block that's farthest away from a wall
			my $highest;
			foreach (@blocks) {
				my $dist = ord(substr($field->{dstMap}, $_->{y} * $field->width + $_->{x}));
				if (!defined $highest || $dist > $highest) {
					$highest = $dist;
				}
			}

			# Get rid of rediculously large route distances (such as spots that are on a hill)
			# Get rid of blocks that are near a wall
			my $pathfinding = new PathFinding;
			use constant AVOID_WALLS => 4;
			for (my $i = 0; $i < @blocks; $i++) {
				# We want to avoid walls (so we don't get cornered), if possible
				my $dist = ord(substr($field->{dstMap}, $blocks[$i]{y} * $field->width + $blocks[$i]{x}));
				if ($highest >= AVOID_WALLS && $dist < AVOID_WALLS) {
					delete $blocks[$i];
					next;
				}

				$pathfinding->reset(
					field => $field,
					start => $myPos,
					dest => $blocks[$i]);
				my $ret = $pathfinding->runcount;
				if ($ret <= 0 || $ret > $config{$slave->{configPrefix}.'runFromTarget_dist'} * 2) {
					delete $blocks[$i];
					next;
				}
			}

			# Find the block that's farthest to us
			my $largestDist;
			my $bestBlock;
			foreach (@blocks) {
				next unless defined $_;
				my $dist = distance($monsterPos, $_);
				if (!defined $largestDist || $dist > $largestDist) {
					$largestDist = $dist;
					$bestBlock = $_;
				}
			}

			#message "Time spent: " . (time - $begin) . "\n";
			#debug_showSpots('runFromTarget', \@blocks, $bestBlock);
			$slave->args->{avoiding} = 1;
			$slave->move($bestBlock->{x}, $bestBlock->{y}, $ID);

		} elsif (!$config{$slave->{configPrefix}.'runFromTarget'} && $monsterDist > $args->{attackMethod}{maxDistance}
		  && !timeOut($args->{ai_attack_giveup})) {
			# The target monster moved; move to target
			$args->{move_start} = time;
			$args->{monsterPos} = {%{$monsterPos}};

			# Calculate how long it would take to reach the monster.
			# Calculate where the monster would be when you've reached its
			# previous position.
			my $time_needed;
			if (objectIsMovingTowards($target, $slave, 45)) {
				$time_needed = $monsterDist * $slave->{walk_speed};
			} else {
				# If monster is not moving towards you, then you need more time to walk
				$time_needed = $monsterDist * $slave->{walk_speed} + 2;
			}
			my $pos = calcPosition($target, $time_needed);

			my $dist = sprintf("%.1f", $monsterDist);
			debug "Slave target distance $dist is >$args->{attackMethod}{maxDistance}; moving to target: " .
				"from ($myPos->{x},$myPos->{y}) to ($pos->{x},$pos->{y})\n", "ai_attack";

			my $result = $slave->route(undef, @{$pos}{qw(x y)},
				distFromGoal => $args->{attackMethod}{distance},
				maxRouteTime => $config{$slave->{configPrefix}.'attackMaxRouteTime'},
				attackID => $ID,
				noMapRoute => 1,
				noAvoidWalls => 1);
			if (!$result) {
				# Unable to calculate a route to target
				$target->{homunculus_attack_failed} = time;
				$slave->dequeue;
 				message TF("Unable to calculate a route to %s target, dropping target\n", $slave), 'homunculus_attack';
				if ($config{$slave->{configPrefix}.'teleportAuto_dropTarget'}) {
					message TF("Teleport due to dropping %s attack target\n", $slave), 'teleport';
					useTeleport(1);
				}
			}

		} elsif ((!$config{$slave->{configPrefix}.'runFromTarget'} || $realMonsterDist >= $config{$slave->{configPrefix}.'runFromTarget_dist'})
		 && (!$config{$slave->{configPrefix}.'tankMode'} || !$target->{dmgFromPlayer}{$slave->{ID}})) {
			# Attack the target. In case of tanking, only attack if it hasn't been hit once.
			if (!$slave->args->{firstAttack}) {
				$slave->args->{firstAttack} = 1;
				my $dist = sprintf("%.1f", $monsterDist);
				my $pos = "$myPos->{x},$myPos->{y}";
				debug "Slave is ready to attack target (which is $dist blocks away); we're at ($pos)\n", "ai_attack";
			}

			$args->{unstuck}{time} = time if (!$args->{unstuck}{time});
			if (!$target->{dmgFromPlayer}{$slave->{ID}} && timeOut($args->{unstuck})) {
				# We are close enough to the target, and we're trying to attack it,
				# but some time has passed and we still haven't dealed any damage.
				# Our recorded position might be out of sync, so try to unstuck
				$args->{unstuck}{time} = time;
				debug("Slave attack - trying to unstuck\n", "ai_attack");
				$slave->move($myPos->{x}, $myPos->{y});
				$args->{unstuck}{count}++;
			}

			if ($args->{attackMethod}{type} eq "weapon" && timeOut($timeout{ai_homunculus_attack})) {
				$slave->sendAttack ($ID);#,
					#($config{homunculus_tankMode}) ? 0 : 7);
				$timeout{ai_homunculus_attack}{time} = time;
				delete $args->{attackMethod};
			}

		} elsif ($config{$slave->{configPrefix}.'tankMode'}) {
			if ($args->{'dmgTo_last'} != $target->{dmgFromPlayer}{$slave->{ID}}) {
				$args->{'ai_attack_giveup'}{'time'} = time;
				$slave->sendAttackStop;
			}
			$args->{'dmgTo_last'} = $target->{dmgFromPlayer}{$slave->{ID}};
		}
	}

	# Check for kill steal while moving
	if ($slave->is("move", "route") && $slave->args->{attackID} && $slave->inQueue("attack")) {
		my $ID = $slave->args->{attackID};
		if ((my $target = $monsters{$ID}) && !checkMonsterCleanness($ID)) {
			$target->{homunculus_attack_failed} = time;
			message TF("Dropping target - %s will not kill steal others\n", $slave), 'homunculus_attack';
			$slave->sendAttackStop;
			$monsters{$ID}{homunculus_ignore} = 1;

			# Right now, the queue is either
			#   move, route, attack
			# -or-
			#   route, attack
			$slave->dequeue;
			$slave->dequeue;
			$slave->dequeue if ($slave->action eq "attack");
			if ($config{$slave->{configPrefix}.'teleportAuto_dropTargetKS'}) {
				message TF("Teleport due to dropping %s attack target\n", $slave), 'teleport';
				useTeleport(1);
			}
		}
	}

	#Benchmark::end("ai_homunculus_attack") if DEBUG;
}

sub processClientSuspend {
	my $slave = shift;
	##### CLIENT SUSPEND #####
	# The clientSuspend AI sequence is used to freeze all other AI activity
	# for a certain period of time.

	if ($slave->action eq 'clientSuspend' && timeOut($slave->args)) {
		debug "Slave AI suspend by clientSuspend dequeued\n";
		$slave->dequeue;
	} elsif ($slave->action eq "clientSuspend" && $net->clientAlive()) {
		# When XKore mode is turned on, clientSuspend will increase it's timeout
		# every time the user tries to do something manually.
		my $args = $slave->args;

		if ($args->{'type'} eq "0089") {
			# Player's manually attacking
			if ($args->{'args'}[0] == 2) {
				if ($chars[$config{'char'}]{'sitting'}) {
					$args->{'time'} = time;
				}
			} elsif ($args->{'args'}[0] == 3) {
				$args->{'timeout'} = 6;
			} else {
				my $ID = $args->{args}[1];
				my $monster = $monstersList->getByID($ID);

				if (!$args->{'forceGiveup'}{'timeout'}) {
					$args->{'forceGiveup'}{'timeout'} = 6;
					$args->{'forceGiveup'}{'time'} = time;
				}
				if ($monster) {
					$args->{time} = time;
					$args->{dmgFromYou_last} = $monster->{dmgFromYou};
					$args->{missedFromYou_last} = $monster->{missedFromYou};
					if ($args->{dmgFromYou_last} != $monster->{dmgFromYou}) {
						$args->{forceGiveup}{time} = time;
					}
				} else {
					$args->{time} -= $args->{'timeout'};
				}
				if (timeOut($args->{forceGiveup})) {
					$args->{time} -= $args->{timeout};
				}
			}

		} elsif ($args->{'type'} eq "009F") {
			# Player's manually picking up an item
			if (!$args->{'forceGiveup'}{'timeout'}) {
				$args->{'forceGiveup'}{'timeout'} = 4;
				$args->{'forceGiveup'}{'time'} = time;
			}
			if ($items{$args->{'args'}[0]}) {
				$args->{'time'} = time;
			} else {
				$args->{'time'} -= $args->{'timeout'};
			}
			if (timeOut($args->{'forceGiveup'})) {
				$args->{'time'} -= $args->{'timeout'};
			}
		}

		# Client suspended, do not continue with AI
		return 1;
	}
}

##### AUTO-ATTACK #####
sub processAutoAttack {
	my $slave = shift;
	# The auto-attack logic is as follows:
	# 1. Generate a list of monsters that we are allowed to attack.
	# 2. Pick the "best" monster out of that list, and attack it.

	#Benchmark::begin("ai_homunculus_autoAttack") if DEBUG;

	if ((($slave->isIdle || $slave->action eq 'route') && (AI::isIdle || AI::is(qw(follow sitAuto take items_gather items_take attack skill_use))))
	     # Don't auto-attack monsters while taking loot, and itemsTake/GatherAuto >= 2
	  && timeOut($timeout{ai_homunculus_attack_auto})
	  && (!$config{$slave->{configPrefix}.'attackAuto_notInTown'} || !$field->isCity)) {

		# If we're in tanking mode, only attack something if the person we're tanking for is on screen.
		my $foundTankee;
		if ($config{$slave->{configPrefix}.'tankMode'}) {
			if ($config{$slave->{configPrefix}.'tankModeTarget'} eq $char->{name}) {
				$foundTankee = 1;
			} else {
				foreach (@playersID) {
					next if (!$_);
					if ($config{$slave->{configPrefix}.'tankModeTarget'} eq $players{$_}{'name'}) {
						$foundTankee = 1;
						last;
					}
				}
			}
		}

		my $attackTarget;
		my $priorityAttack;

		if (!$config{$slave->{configPrefix}.'tankMode'} || $foundTankee) {
			# This variable controls how far monsters must be away from portals and players.
			my $portalDist = $config{'attackMinPortalDistance'} || 0; # Homun do not have effect on portals
			my $playerDist = $config{'attackMinPlayerDistance'};
			$playerDist = 1 if ($playerDist < 1);
		
			my $routeIndex = $slave->findAction("route");
			my $attackOnRoute;
			if (defined $routeIndex) {
				$attackOnRoute = $slave->args($routeIndex)->{attackOnRoute};
			} else {
				$attackOnRoute = 2;
			}

			### Step 1: Generate a list of all monsters that we are allowed to attack. ###
			my @aggressives;
			my @partyMonsters;
			my @cleanMonsters;
			my $myPos = calcPosition($slave);

			# List aggressive monsters
			@aggressives = AI::ai_getPlayerAggressives($slave->{ID}) if ($config{$slave->{configPrefix}.'attackAuto'} && $attackOnRoute);

			# There are two types of non-aggressive monsters. We generate two lists:
			foreach (@monstersID) {
				next if (!$_ || !checkMonsterCleanness($_));
				my $monster = $monsters{$_};
				next if !$field->isWalkable($monster->{pos}{x}, $monster->{pos}{y}); # this should NEVER happen
				next if !checkLineWalkable($myPos, $monster->{pos}); # ignore unrecheable monster. there's a bug in bRO's gef_fild06 where a lot of petites are bugged in some unrecheable cells

				my $pos = calcPosition($monster);

				# List monsters that party members are attacking
				if ($config{$slave->{configPrefix}.'attackAuto_party'} && $attackOnRoute
				 && ($monster->{dmgFromYou} || $monster->{dmgFromParty} || $monster->{dmgToYou} || $monster->{dmgToParty} || $monster->{missedYou} || $monster->{missedToParty})
				 && timeOut($monster->{homunculus_attack_failed}, $timeout{ai_attack_unfail}{timeout})) {
					push @partyMonsters, $_;
					next;
				}

				### List normal, non-aggressive monsters. ###

				# Ignore monsters that
				# - Have a status (such as poisoned), because there's a high chance (WHY?)
				#   they're being attacked by other players
				# - Are inside others' area spells (this includes being trapped).
				# - Are moving towards other players.
				# - Are behind a wall
				next if (#( $monster->{statuses} && scalar(keys %{$monster->{statuses}}) ) || 
					objectInsideSpell($monster)
					|| objectIsMovingTowardsPlayer($monster));
					
				if ($config{$slave->{configPrefix}.'attackCanSnipe'}) {
					next if (!checkLineSnipable($slave->{pos_to}, $pos));
				} else {
					next if (!checkLineWalkable($slave->{pos_to}, $pos));
				}

				my $safe = 1;
				if ($config{$slave->{configPrefix}.'attackAuto_onlyWhenSafe'}) {
					foreach (@playersID) {
						next if ($_ eq $slave->{ID});
						if ($_ && !$char->{party}{users}{$_}) {
							$safe = 0;
							last;
						}
					}
				}
				
				my $control = mon_control($monster->{name});
				if ($config{$slave->{configPrefix}.'attackAuto'} >= 2
				 && ($control->{attack_auto} == 1 || $control->{attack_auto} == 3)
				 && $attackOnRoute >= 2 && $safe
				 && !positionNearPlayer($pos, $playerDist) && !positionNearPortal($pos, $portalDist)
				 && !$monster->{dmgFromYou}
				 && timeOut($monster->{homunculus_attack_failed}, $timeout{ai_attack_unfail}{timeout})) {
					push @cleanMonsters, $_;
				}
			}

			### Step 2: Pick out the "best" monster ###

			my $highestPri;

			# Look for the aggressive monster that has the highest priority
			foreach (@aggressives) {
				my $monster = $monsters{$_};
				my $pos = calcPosition($monster);
				# Don't attack monsters near portals
				next if (positionNearPortal($pos, $portalDist));

				# Don't attack ignored monsters
				if ((my $control = mon_control($monster->{name},$monster->{nameID}))) {
					next if ( ($control->{attack_auto} == -1)
						|| ($control->{attack_lvl} ne "" && $control->{attack_lvl} > $char->{lv})
						|| ($control->{attack_jlvl} ne "" && $control->{attack_jlvl} > $char->{lv_job})
						|| ($control->{attack_hp}  ne "" && $control->{attack_hp} > $char->{hp})
						|| ($control->{attack_sp}  ne "" && $control->{attack_sp} > $char->{sp})
						);
				}

				my $name = lc $monster->{name};
				if (defined($priority{$name}) && $priority{$name} > $highestPri) {
					$highestPri = $priority{$name};
				}
			}

			my $smallestDist;
			if (!defined $highestPri) {
				# If not found, look for the closest aggressive monster (without priority)
				foreach (@aggressives) {
					my $monster = $monsters{$_};
					next if !timeOut($monster->{homunculus_attack_failed}, $timeout{ai_attack_unfail}{timeout});
					my $pos = calcPosition($monster);
					# Don't attack monsters near portals
					next if (positionNearPortal($pos, $portalDist));

					if (!defined($smallestDist) || (my $dist = distance($myPos, $pos)) < $smallestDist) {
						$smallestDist = $dist;
						$attackTarget = $_;
					}
				}
			} else {
				# If found, look for the closest aggressive monster with the highest priority
				foreach (@aggressives) {
					my $monster = $monsters{$_};
					my $pos = calcPosition($monster);
					# Don't attack monsters near portals
					next if (positionNearPortal($pos, $portalDist));

					# Don't attack ignored monsters
					if ((my $control = mon_control($monster->{name},$monster->{nameID}))) {
						next if ( ($control->{attack_auto} == -1)
							|| ($control->{attack_lvl} ne "" && $control->{attack_lvl} > $char->{lv})
							|| ($control->{attack_jlvl} ne "" && $control->{attack_jlvl} > $char->{lv_job})
							|| ($control->{attack_hp}  ne "" && $control->{attack_hp} > $char->{hp})
							|| ($control->{attack_sp}  ne "" && $control->{attack_sp} > $char->{sp})
							);
					}

					my $name = lc $monster->{name};
					if ((!defined($smallestDist) || (my $dist = distance($myPos, $pos)) < $smallestDist)
					  && $priority{$name} == $highestPri) {
						$smallestDist = $dist;
						$attackTarget = $_;
						$priorityAttack = 1;
					}
				}
			}

			if (!$attackTarget) {
				undef $smallestDist;
				# There are no aggressive monsters; look for the closest monster that a party member/master is attacking
				foreach (@partyMonsters) {
					my $monster = $monsters{$_};
					my $pos = calcPosition($monster);
					if (!defined($smallestDist) || (my $dist = distance($myPos, $pos)) < $smallestDist) {
						$smallestDist = $dist;
						$attackTarget = $_;
					}
				}
			}

			if (!$attackTarget) {
				# No party monsters either; look for the closest, non-aggressive monster that:
				# 1) nobody's attacking
				# 2) has the highest priority

				undef $smallestDist;
				foreach (@cleanMonsters) {
					my $monster = $monsters{$_};
					next unless $monster;
					my $pos = calcPosition($monster);
					my $dist = distance($myPos, $pos);
					my $name = lc $monster->{name};

					if (!defined($smallestDist) || $priority{$name} > $highestPri
					  || ( $priority{$name} == $highestPri && $dist < $smallestDist )) {
						$smallestDist = $dist;
						$attackTarget = $_;
						$highestPri = $priority{$monster};
					}
				}
			}
		}
		# If an appropriate monster's found, attack it. If not, wait ai_attack_auto secs before searching again.
		if ($attackTarget) {
			$slave->setSuspend(0);
			$slave->attack($attackTarget, $priorityAttack);
		} else {
			$timeout{'ai_homunculus_attack_auto'}{'time'} = time;
		}
	}

	#Benchmark::end("ai_homunculus_autoAttack") if DEBUG;
}

sub sendAttack {
	my ($slave, $targetID) = @_;
	$messageSender->sendHomunculusAttack ($slave->{ID}, $targetID);
}

sub sendMove {
	my ($slave, $x, $y) = @_;
	$messageSender->sendHomunculusMove ($slave->{ID}, $x, $y);
}

sub sendStandBy {
	my ($slave) = @_;
	$messageSender->sendHomunculusStandBy ($slave->{ID});
}

1;
