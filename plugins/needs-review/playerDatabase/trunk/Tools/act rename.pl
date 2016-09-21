#!/usr/bin/perl
use strict;
use warnings;
use feature qw(say);

sub ren() {
    return((rename($_[0],$_[1])) ? 1 : 0);
}

open(my $arq,'+<idnum2itemresnametable.txt') || die '$!\n';
while(<$arq>) {
    chomp;
    my($n, $v) = /^(\d+)#(.+)#$/;
	if ($n) {
		say((&ren('data/sprite/�Ǽ��縮/��/��_' . $v . '.act','data/sprite/�Ǽ��縮/��/M' . $n . '.act')) ? '[+] data/sprite/�Ǽ��縮/��/��_' . $v . ' was successfully renamed to data/sprite/�Ǽ��縮/��/M' . $n : '[!] Error renaming file data/sprite/�Ǽ��縮/��/��_' . $v);
		say((&ren('data/sprite/�Ǽ��縮/��/��_' . $v . '.spr','data/sprite/�Ǽ��縮/��/M' . $n . '.spr')) ? '[+] data/sprite/�Ǽ��縮/��/��_' . $v . ' was successfully renamed to data/sprite/�Ǽ��縮/��/M' . $n : '[!] Error renaming file data/sprite/�Ǽ��縮/��/��_' . $v);
		say((&ren('data/sprite/�Ǽ��縮/��/��_' . $v . '.act','data/sprite/�Ǽ��縮/��/F' . $n . '.act')) ? '[+] data/sprite/�Ǽ��縮/��/��_' . $v . ' was successfully renamed to data/sprite/�Ǽ��縮/��/F' . $n : '[!] Error renaming file data/sprite/�Ǽ��縮/��/��_' . $v);
		say((&ren('data/sprite/�Ǽ��縮/��/��_' . $v . '.spr','data/sprite/�Ǽ��縮/��/F' . $n . '.spr')) ? '[+] data/sprite/�Ǽ��縮/��/��_' . $v . ' was successfully renamed to data/sprite/�Ǽ��縮/��/F' . $n : '[!] Error renaming file data/sprite/�Ǽ��縮/��/��_' . $v);
		say((&ren('data/sprite/������/' . $v . '.act','data/sprite/������/' . $n . '.act'))               ? '[+] data/sprite/������/' . $v . ' was successfully renamed to data/sprite/������/' . $n               : '[!] Error renaming file data/sprite/������/' . $v);
		say((&ren('data/sprite/������/' . $v . '.spr','data/sprite/������/' . $n . '.spr'))               ? '[+] data/sprite/������/' . $v . ' was successfully renamed to data/sprite/������/' . $n               : '[!] Error renaming file data/sprite/������/' . $v);		
	}
}

close($arq);