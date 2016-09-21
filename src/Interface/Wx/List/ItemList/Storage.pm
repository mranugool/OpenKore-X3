package Interface::Wx::List::ItemList::Storage;

use strict;
use base 'Interface::Wx::List::ItemList';

use Globals qw/$char $conState %cart %storage @storageID/;
use Misc qw/storageGet/;
use Translation qw/T TF/;

sub new {
	my ($class, $parent, $id) = @_;
	
	my $self = $class->SUPER::new ($parent, $id, [
		{key => 'count', max => %cart && $cart{items_max} ? $cart{items_max} : '100'},
	]);
	
	$self->{hooks} = Plugins::addHooks (
 		['packet/map_loaded',                 sub { $self->clear }],
		['packet/storage_opened',             sub { $self->onInfo; }],
		['packet/storage_closed',             sub { $self->onInfo; }],
		['packet/storage_items_stackable',    sub { $self->update; }],
		['packet/storage_items_nonstackable', sub { $self->update; }],
		['packet/storage_item_added',         sub { $self->onItemsChanged($_[1]{item}) }],
		['packet/storage_item_removed',       sub { $self->onItemsChanged($_[1]{item}) }],
	);
	
	$self->onInfo;
	$self->update;
	
	return $self;
}

sub unload {
	my ($self) = @_;
	
	Plugins::delHooks ($self->{hooks});
}

sub onInfo {
	my ($self) = @_;
	
	if ($storage{opened}) {
		$self->setStat ('count', $storage{items}, $storage{items_max});
	} else {
		$self->clear;
	}
}

sub onItemsChanged {
	my $self = shift;
	
	$self->setItem(@$_) for map { [$_->{binID}, $_] } @_;
}

sub update {
	my ($self, $handler, $args) = @_;
	
	$self->Freeze;
	$self->setItem(@$_) for map { [$storage{$_}{binID}, $storage{$_}] } @storageID;
	$self->Thaw;
}

sub clear { $_[0]->removeAllItems }

sub getSelection {
	my %storage_lut = map { $storage{$_}{binID} => $storage{$_} } @storageID;
	map { $storage_lut{$_} } @{$_[0]{selection}}
}

sub _onRightClick {
	my ($self) = @_;
	
	return unless scalar (my @selection = $self->getSelection);
	
	my $title;
	if (@selection > 3) {
		my $total = 0;
		$total += $_->{amount} foreach @selection;
		$title = TF('%d items', scalar @selection);
		$title .= TF('%d total)', $total) unless $total == @selection;
	} else {
		$title = join '; ', map { join ' ', @$_{'amount', 'name'} } @selection;
	}
	$title .= '...';
	
	my @menu;
	push @menu, {title => $title};
	
	my ($canCart) = (%cart && $char->cartActive);
	
	push @menu, {title => T('Move all to inventory') . "\tDblClick", callback => sub { $self->_onActivate; }};
	push @menu, {title => T('Move all to cart'), callback => sub { $self->_onCart; }} if $canCart;
	
	$self->contextMenu (\@menu);
}

sub _onActivate {
	my ($self) = @_;
	
	Commands::run ('storage get ' . join ',', map {$_->{binID}} $self->getSelection);
}

sub _onCart {
	my ($self) = @_;
	
	foreach ($self->getSelection) {
		Commands::run ('storage gettocart ' . $_->{binID});
	}
}

1;
