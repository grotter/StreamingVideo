<?php

class AxisCamControl {
	protected $_timeout = 15;
	protected $_url;
	protected $_userame;
	protected $_password;
	
	protected $_response = array(
		'success' => false,
		'data' => array()
	);
	
	protected $_validQueries = array(
		'query',
		'position',
		'move',
		'zoom',
		'continuouszoommove',
		'continuouspantiltmove',
		'gotoserverpresetname',
		'gotoserverpresetno'
	);
	
	public $response;
	public $debug;
	
	public function __construct ($url, $username, $password) {
		$this->_url = $url;
	    $this->_username = $username;
		$this->_password = $password;
		$this->debug = (isset($_REQUEST['debug']) && $_REQUEST['debug'] == '1');
		
		if ($this->debug) {
			ini_set('display_errors', '1');
			ini_set('error_reporting', E_ALL);
			error_reporting(E_ALL);
		} else {
			ini_set('display_errors', '0');
			ini_set('error_reporting', 0);
			error_reporting(0);
		}
		
		// init server response with some empty values in the proper format
		$this->response = $this->_getEncodedResponse($this->_response);
	}
	
	public function move ($dir = 'left') {
		return $this->connect(array(
			'move' => $dir
		));
	}
	
	public function getPosition ($key = 'pan') {
		$response = $this->connect(array(
			'query' => 'position'
		));
		
		if (!$response) return false;
		
		// parse the response
		$arr = explode("\n", $response);
		
		foreach ($arr as $line) {
			$line = trim($line);
			
			// look for our key
			$pair = explode('=', $line);
			if ($pair[0] == $key) return $pair[1];
		}
		
		return false;
	}
	
	public function getParsedHotspots ($data) {
		$arr = explode("\n", $data);
		
		if (count($arr) < 2) {
			return false;
		}
		
		$assoc = array();
	    $i = 1;
		
		while ($i < count($arr)) {
			$posArr = explode("=", $arr[$i]);
			
			if (count($posArr) == 2) {
				$assoc[$posArr[0]] = $posArr[1];
			}
			
			$i++;
		}
		
		if (count($assoc) > 0) return $assoc;
		return false;
	}
	
	public function connect ($arr = array()) {
		if (!$this->_isValidData($arr)) {
			trigger_error('Invalid request');
			return false;
		}
		
		$url = "http://{$this->_username}:{$this->_password}@{$this->_url}";
		
		$ch = curl_init();
		curl_setopt($ch, CURLOPT_URL, $url);
		curl_setopt($ch, CURLOPT_TIMEOUT, $this->_timeout);
		curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query($arr));
		curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

		$result = curl_exec($ch);
		
		if ($result === false) {
			trigger_error(curl_error($ch));
			curl_close($ch);
			return false;
		}
		
		curl_close($ch);
		return $result;
	}
	
	protected function _isValidData ($arr = array()) {
		foreach ($arr as $key => $val) {
			if (!in_array($key, $this->_validQueries)) {
				return false;
			}
		}
		
		return true;
	}
	
	/**
	 * A simple getter for retrieving appropriatly encoded response
	 *
	 * @param string $encoding 'json', 'xml' or 'data'. Defaults to 'data', which returns an associative array; otherwise return an encoded string
	 * @return mixed Data as an encoded string, an associative array or FALSE if empty or not set
	 * @author Rotter, Greg
	 */
	public function getResponse ($encoding = 'data') {
		$this->response = $this->_getEncodedResponse($this->_response);
		
		if (!isset($this->response[$encoding])
			|| empty($this->response[$encoding])) {	
			return false;
		}
		
		return $this->response[$encoding];
	}
	
	protected function _getEncodedResponse ($data) {
		$foo = new EncodeResponse();
		
		$foo->setType('json');
		$json = $foo->getEncodedData($data);
		
		$foo->setType('xml');
		$xml = $foo->getEncodedData($data);
		
		return array(
			'data' => $data,
	    	'json' => $json,
			'xml' => $xml
		);
	}
}

?>
