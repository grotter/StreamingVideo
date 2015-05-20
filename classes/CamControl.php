<?php

	class CamControl extends Webcam {
		private $_lastQueuePosition = 1;
		private $_uid_cam = 0;
		private $_formData = array();
		private $_session_id;
		private $_reactivationTime = 0;
	
		public $secondsActive;
		public $isAdminDisabled = false;
	
		public function CamControl () {
			parent::__construct();
			
			$this->secondsActive = $this->debug ? 30 : 90;	
			$this->_formData = StringUtil::getCleanArray($_REQUEST);
			$this->_uid_cam = intval($this->_formData['uid_cam']);
			$this->isAdminDisabled = $this->_isAdminDisabled();
		
			if (isset($this->_formData['code'])
				&& !empty($this->_formData['code'])) {
				$this->_session_id = $this->_formData['code'];
			} else {
				session_start();
				$this->_session_id = session_id();
			}
		
			$this->pulse();
			
			if (!$this->isAdminDisabled
				&& isset($this->_formData['join_queue'])
				&& !empty($this->_formData['join_queue'])) {
				
				$this->_setLastQueuePosition();
				$this->_joinQueue();
				$this->_setActive();
				
			}
		}
	
		private function _isAdminDisabled () {
			$query = "SELECT MAX(time_end) AS max_time_end FROM control_kill WHERE uid_cam = {$this->_uid_cam}";
			$resource = $this->getDBResource($query);
			if (!$resource) return false;
		
		    if (mysql_num_rows($resource) == 1) {				
				$row = mysql_fetch_assoc($resource);
                $this->_reactivationTime = intval($row['max_time_end']);

				if ($this->_reactivationTime >= intval(time())) {
					return true;
				}
			}
			
			return false;
		}
	
		public function isActive ($row) {
			return ($row['in_queue'] == 1
					&& $row['queue_position'] == 1
					&& $row['active_time'] > 0);
		}
	
		public function getClientInfo () {
			$query = "SELECT
						*
					  FROM
						control_queue
					  WHERE
						session_id = '{$this->_session_id}'
						AND
						done_controlling = 0
						AND
						uid_cam = {$this->_uid_cam}";
		
			$resource = $this->getDBResource($query);
			if (!$resource) return false;
		
			if (mysql_num_rows($resource) == 1) {
				$row = mysql_fetch_assoc($resource);
				$row['seconds_remaining'] = 0;
			
				// append seconds remaining if currently controlling
				if ($this->isActive($row)) {
					$seconds_remaining = $this->secondsActive - (intval(time()) - $row['active_time']);
					if ($seconds_remaining < 0) $seconds_remaining = 0;
					$row['seconds_remaining'] = $seconds_remaining; 
				}
			
				return $row;
			} else {
				return array();
			}
		}
	
		public function pulse () {
			$now = time();
			$affectedRows = 0;
		
			// prune the queue of inactive clients
			$past = strtotime('-8 seconds');
		
			$query = "UPDATE
						control_queue
					  SET
						in_queue = 0
					  WHERE
						pulse_time < $past
						AND
						uid_cam = {$this->_uid_cam}";
		
			$resource = $this->getDBResource($query);
			$affectedRows += mysql_affected_rows($this->db);
		
			if ($this->isAdminDisabled) {
				// reset currently active client
				$query = "UPDATE
							control_queue
						  SET
							active_time = 0
						  WHERE
							active_time != 0
							AND
							queue_position = 1
							AND
							in_queue = 1
							AND
							uid_cam = {$this->_uid_cam}";

				$resource = $this->getDBResource($query); 
			} else {
				// kick off active client after timeup 
				$query = "UPDATE
							control_queue
						  SET
							in_queue = 0,
							done_controlling = 1
						  WHERE
							($now - active_time) > {$this->secondsActive}
							AND
							active_time != 0
							AND
							queue_position = 1
							AND
							in_queue = 1
							AND
							uid_cam = {$this->_uid_cam}";

				$resource = $this->getDBResource($query);
				$affectedRows += mysql_affected_rows($this->db);
			}
			
			// advance the queue if necessary
			if ($affectedRows) $this->_advanceQueue();
		
			// update pulse time
			$clientInfo = $this->getClientInfo();
		
			if ($clientInfo === false
				|| !isset($clientInfo['uid_control_queue'])
				|| empty($clientInfo['uid_control_queue'])) return;
		
			$query = "UPDATE
						control_queue
					  SET
						pulse_time = {$now}
					  WHERE
						uid_control_queue = {$clientInfo['uid_control_queue']}";
					
			$resource = $this->getDBResource($query);
		}
	
		private function _advanceQueue () {
			// create an ordered array of current queue ids
			$query = "SELECT
						uid_control_queue
					  FROM
						control_queue
					  WHERE
						in_queue = 1
						AND
						uid_cam = {$this->_uid_cam}
					  ORDER BY
						queue_position ASC";
	
			$resource = $this->getDBResource($query);
			if (!$resource) return false;
			$arr = array();
		
			while ($row = mysql_fetch_assoc($resource)) {
				$arr[] = $row['uid_control_queue'];
			}
		
			// update all per array index
			$i = 1;
		
			foreach ($arr as $uid_control_queue) {
				$query = "UPDATE control_queue SET queue_position = $i WHERE uid_control_queue = $uid_control_queue";
				$resource = $this->getDBResource($query);
				$i++;
			}   
		} 
	
		private function _setLastQueuePosition () {
			// if we have active clients in the queue, get the highest value
			$query = "SELECT
						MAX(queue_position) AS last_queue_position
					  FROM
						control_queue
					  WHERE
						uid_cam = {$this->_uid_cam}
						AND
						in_queue = 1";
					
			$resource = $this->getDBResource($query);
			if (!$resource) return false;
			$row = mysql_fetch_assoc($resource);
		
			// increment highest if one exists
			if (!empty($row['last_queue_position'])) {
				$this->_lastQueuePosition = $row['last_queue_position'] + 1;
			}
		}
	
		private function _joinQueue () {
			$clientInfo = $this->getClientInfo();
			if ($clientInfo === false) return false;
			$now = time();
		
			if (!empty($clientInfo)) {
				// client session already in the system
				if ($clientInfo['in_queue']) {
					// already in the queue, do nothing
	                return true;
				} else {
					// rejoin the queue
					$query = "UPDATE
								control_queue
							  SET
								pulse_time = {$now},
								queue_position = {$this->_lastQueuePosition},
								active_time = 0,
								in_queue = 1
							  WHERE
								uid_control_queue = {$clientInfo['uid_control_queue']}";
				}
			} else {
				// join the queue
				$user_ip = mysql_real_escape_string($_SERVER['REMOTE_ADDR']);
			
				$query = "INSERT INTO control_queue (
					uid_cam,		 	 	 	 	 	
					session_id,   	 	 	 	 	 	 	 
					queue_position,	 	 	 	 	 	 	 	
					pulse_time,	  	 	 	 	 		 	 	 	 	 	 	
					in_queue,
					user_ip       
				) VALUES (
					{$this->_uid_cam},
					'{$this->_session_id}',
					{$this->_lastQueuePosition},
					{$now},
					1,
					'$user_ip'
				)";
			}
		
			return $this->getDBResource($query);
		}
	
		private function _setActive () {
			$now = time();
		
			$query = "UPDATE
						control_queue
					  SET
						active_time = $now
					  WHERE
						session_id = '{$this->_session_id}'
						AND
						uid_cam = {$this->_uid_cam}
						AND
						queue_position = 1
						AND
						in_queue = 1
						AND
						active_time = 0";
	
			$resource = $this->getDBResource($query);
		}
	
		public function getResponse () {
			$clientInfo = $this->getClientInfo();
			
			if ($this->_reactivationTime == 0) {
				$clientInfo['time_reactivation'] = '0';
			} else {
				$secs = $this->_reactivationTime + 45; // add a few extra seconds
				$clientInfo['time_reactivation'] = date('n/j/y, g:ia', $secs);
			}
			
			$clientInfo['admin_disabled'] = $this->isAdminDisabled ? '1' : '0';
			$clientInfo['seconds_active'] = $this->secondsActive;
			return array('client_info' => $clientInfo);
		}
	}

?>
