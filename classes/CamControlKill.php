<?php

	class CamControlKill extends Webcam {
		private $_uid_cam = 0;
		private $_minutes = 0;
		private $_errors = array();
		private $_now;
	
		public function CamControlKill () {
			parent::__construct();
			
			$this->_now = time();	
			$this->_uid_cam = intval($_REQUEST['uid_cam']);
			$this->_minutes = intval($_REQUEST['minutes']);
		
			if ($this->_isValid()) {
				$this->_submit();
			} else {
				$this->_errors[] = 'Invalid submission data.';
			}
		}
	
		private function _isValid () {
			if ($this->_uid_cam > 0) {
				if ($this->_minutes > 0) {
					return true;
				}
			}
		
			return false;
		}
	
		private function _submit () {
			// delete any currently running kills for this cam
			$query = "DELETE FROM control_kill WHERE uid_cam = {$this->_uid_cam} AND time_end >= {$this->_now}";
			$resource = $this->getDBResource($query);
			
			if (!$resource) {
				$this->_errors[] = 'Database error (1)';
				return false;
			}
			
			// do insertion
			if ($this->debug) {
				$time_end = $this->_now + 30;
			} else {
				$time_end = $this->_now + (60 * $this->_minutes);
			}

			$query = "INSERT INTO control_kill (
				uid_cam,
				time_start,
				time_end
			) VALUES (
				{$this->_uid_cam},
				{$this->_now},
				{$time_end}
			)";
			
			$resource = $this->getDBResource($query);
			
			if (!$resource) {
				$this->_errors[] = 'Database error (2)';
				return false;
			}
			
			return true; 
		}
	
		public function getResponse () {
			if (empty($this->_errors)) {
				$time_end = $this->_now + (60 * $this->_minutes);
				$time_end = date('g:i a', $time_end);
				
				return array(
					'success' => 1,
					'time_end' => $time_end,
					'errors' => array()
				);
			} else {
				return array(
					'success' => 0,
					'time_end' => '-',
					'errors' => $this->_errors
				);
			}
		}
	}

?>
