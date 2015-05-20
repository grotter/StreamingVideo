<?php
    
	require_once('phpFlickr/phpFlickr.php');
	require_once('EncodeResponse.php');

	class ScreenGrab {
		protected $_tempDirectory = '/tmp';
		protected $_flickr;
		protected $_response = array(
			'success' => false,
			'data' => array()
		);
	    
		public $response;
		public $debug;
	
		public function __construct () {
			require_once('phpFlickr/flickr-key.php');
			$this->_flickr = new phpFlickr($api_key, $api_secret);
			$this->_flickr->setToken($api_token);
		
			// init server response with some empty values in the proper format
			$this->response = $this->_getEncodedResponse($this->_response);
		}
	    
		public function grab ($title = '', $description = '', $tags = '', $set_id = false) {
			$file = $this->_tempDirectory . '/' . time() . '-' . mt_rand() . '.png';
			
			// create image
			$imageData = $GLOBALS['HTTP_RAW_POST_DATA'];
			
			$fp = fopen($file, 'wb');
			fwrite($fp, $imageData);
			if ($fp === false) error_log('error writing file');
			
			fclose($fp);
			
			if (!file_exists($file)) return;
			
			if (!$this->_validate($file)) {
				// invalid, delete file from server and quit
				unlink($file);
				return;
			}
		    
			// attempt flickr upload
			$photo_id = $this->_flickr->sync_upload($file, $title, $description, $tags, '1');
		
			// delete file from server
			unlink($file);
		    
			// validate upload
			if (intval($photo_id) > 0) {
				if ($set_id !== false) {
					// attempt add to set
					$set = $this->_flickr->photosets_addPhoto($set_id, $photo_id);
					
					// @todo
					// validate set addition?
				}
				
				$this->_response['data'] = $photo_id;
				$this->_response['success'] = true;	
			}
		}
	    
		private function _validate ($file) {
			// make sure our random pixel is white
			$im = imagecreatefrompng($file);
			$rgb = imagecolorat($im, intval($_GET['x']), 0);
			$colors = imagecolorsforindex($im, $rgb);
			
			if ($colors['red'] != 255) return false;
			if ($colors['green'] != 255) return false;
			if ($colors['blue'] != 255) return false;
			
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
