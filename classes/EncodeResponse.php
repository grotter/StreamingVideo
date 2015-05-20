<?php

    /**
	 * Do some data type-specific encoding 
     *
     * @package AxisCamControl
     * @author Rotter, Greg
     **/
	class EncodeResponse {
		protected $_type;
		protected $_validTypes = array('xml', 'json');
		
		public function __construct () {
			$this->setType();
		}
		
		/**
		 * Set encoding type, defaults to json
		 *
		 * @param string $type xml or json 
		 * @author Rotter, Greg
		 */
		public function setType ($type = '') {
			if (!isset($type)
				|| empty($type)
				|| !$type
				|| !in_array($type, $this->_validTypes)) {
				// invalid param, set default and quit
				$this->_type = 'json';
				return;
			}
			
			$this->_type = $type;
		}
		
		public function getEncodedData ($data) {
			switch ($this->_type) {
				case 'xml':
					return $this->_getXML($data);
					break;
				case 'json':
					return $this->_getJSON($data);
					break;
			}
			
			return '0';
		}
		
		private function _writeXML ($xml, $data) {
		    foreach ($data as $key => $value) {
		        // some xml parsers fail if node names are strictly numeric
				if (is_numeric($key)) {
			    	$key = 'numeric-' . $key;
				}
		
				if (is_array($value)) {
		            $xml->startElement($key);
		            $this->_writeXML($xml, $value);
		            $xml->endElement();
		            continue;
		        }
				
		        $xml->writeElement($key, $value);
		    }
		}
		
		protected function _getXML ($data) {
			$xml = new XmlWriter();
			$xml->openMemory();
			$xml->startDocument('1.0', 'UTF-8');
			$xml->setIndent(true);
			
			$xml->startElement('response');
			$this->_writeXML($xml, $data);
			$xml->endElement();
			
			return $xml->outputMemory(true);
		}
		
		protected function _getJSON ($data) {
			// prepend callback function if it looks like a JSONP request
			$callback = '';
			
			if (isset($_REQUEST['callback'])
				&& !empty($_REQUEST['callback'])) {
					$callback = $_REQUEST['callback'];
			}
			
			if (isset($_REQUEST['jsoncallback'])
				&& !empty($_REQUEST['jsoncallback'])) {
					$callback = $_REQUEST['jsoncallback'];
			}
			
			// do the encoding			
			$data = json_encode($data);
			
			if (empty($callback)) {
				return $data;
			}
			
			return $callback . '(' . $data . ');';
		}
	}

?>
