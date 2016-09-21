<?php
/**
 * Representa uma a��o na lista de a��es
 *
 * Essa classe representa uma a��o na lista de a��es (ActionList, *.act)
 *
 * @package    Action
 * @author     HwapX(aka Hacker_wap)
 * @copyright  2012-2013 HwapX
 * @license    http://www.php.net/license/3_01.txt  PHP License 3.01
 * @version    Release: @0.0.0@
 * @see        ActionList, Frame
 */

namespace RO\Action;

use RO\Action\Frame;

/**
 * Representa uma anima��o
 */

class Action {
	private $frames = [];
	
	/**
	 * @param $f array de imagens
	 */
	public function __construct($f = []) {
		$this->frames = $f;
	}
	
	/**
	 * Adiciona um frame � anima��o
	 */
	public function addFrame($frame) {
		$this->frames[] = $frame;
	}
	
	/**
	 * Retorna o frame correspondente ao indice informado
	 */
	public function getFrame($index) {
		return $this->frames[$index];
	}
}
?>