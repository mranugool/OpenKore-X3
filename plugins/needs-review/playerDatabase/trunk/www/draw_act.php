<?php

require('bootstrap.php');

use RO\Sprite\SpriteList;
use RO\Sprite\Sprite;

use RO\Action\ActionListFile;

use RO\Drawing\Item;
use RO\Drawing\Character;

//$start = microtime(true);
//$head = new ActionListFile("files/head.act");
//$end = microtime(true);
//echo $end - $start;
//exit;


// TODO: Na hora, implementar POST para receber os ID's dos arquivos que ser�o usados
$head = new Item("files/head.act", "files/head.spr");
$body = new Item("files/body.act", "files/body.spr");
$item1 = new Item("files/��_�þ����۸���.act", "files/��_�þ����۸���.spr");
$item2 = new Item("files/��_�����ǵη縶��.act", "files/��_�����ǵη縶��.spr");
$item3 = new Item("files/��_�������������.act", "files/��_�������������.spr");
$item4 = new Item("files/��_�����ѻ���.act", "files/��_�����ѻ���.spr");
$item5 = new Item("files/��_�Ӹ�����������.act", "files/��_�Ӹ�����������.spr");
$item6 = new Item("files/��_����ũ.act", "files/��_����ũ.spr");
$item7 = new Item("files/��_���۷���.act", "files/��_���۷���.spr");
$item8 = new Item("files/ȭ��Ʈ���̽�_��.act","files/ȭ��Ʈ���̽�_��.spr"); // item visual
$char = new Character($body, $head);
$char->setShield($item7);
$char->setWeapon($item6);
$char->setHat($item1);
$char->setCostume($item8);

$action = isset($_GET['action']) ? $_GET['action'] : 0;
$frame  = isset($_GET['frame'])  ? $_GET['frame']  : 0;

$char->output($action, $frame);

$head_al = new ActionListFile("files/head.act");
$head_sl = new SpriteList("files/head.spr");
$body_al = new ActionListFile("files/body.act");
$body_sl = new SpriteList("files/body.spr");

//echo "Version: {$head_al->getVersion()}\n";

exit;
$headSL = new SpriteList("files/head.spr");
$bodySL = new SpriteList("files/body.spr");

$pos = isset($_GET['pos']) ? $_GET['pos'] : 0;

$body['image'] = $bodySL->getSprite($pos)->createImage();
$body['x'] = 1;
$body['y'] = -27;
$body['extraX'] = 1;
$body['extraY'] = -60;
$body['realWidth'] = imagesx($body['image']);
$body['realHeight'] = imagesy($body['image']);
$body['width'] = 46;
$body['height'] = 75;

$head['image'] = $headSL->getSprite($pos)->createImage();
$head['x'] = -1;
$head['y'] = -67;
$head['extraX'] = 0;
$head['extraY'] = -56;
$head['realWidth'] = imagesx($head['image']);
$head['realHeight'] = imagesy($head['image']);
$head['width'] = $head['realWidth'];
$head['height'] = $head['realHeight'];

$img = imagecreatetruecolor(200, 200);

imagecopyresized($img, $body['image'], 100 + $body['x'] - ($body['width'] / 2), 100 + $body['y'] - ($body['height'] / 2), 0, 0, $body['width'], $body['height'], $body['realWidth'], $body['realHeight']);
imagecopyresized($img, $head['image'], 100 + ($body['extraX'] - $head['extraX'] + $head['x']) - ($head['width'] / 2), 100 + ($body['extraY'] - $head['extraY'] + $head['y']) - ($head['height'] / 2), 0, 0, $head['width'], $head['height'], $head['realWidth'], $head['realHeight']);

function DrawCharacter($body, $parts, $width, $hwight) {
	$img = imagecreatetruecolor($width, $height);
	
	
}

header('content-type: ', 'image/gif');
imagegif($img);