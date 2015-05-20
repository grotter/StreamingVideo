<?php

	class Monitor extends Webcam {	
		public function Monitor () {
			parent::__construct();
		}
		
		public function pulse ($server, $stream, $level) {		
			$data = !isset($_SERVER['REMOTE_ADDR']) ? array('REMOTE_ADDR' => '-') : $_SERVER;
			$data['server'] = $server;
			$data['stream'] = $stream;
			$data['level'] = $level;
			
			$data = StringUtil::getCleanArray($data);

			$query = "UPDATE
						stream_monitor
					  SET
						ip = '{$data['REMOTE_ADDR']}',
						last_pulse = CURRENT_TIMESTAMP
					  WHERE
						server = '{$data['server']}'
						AND
						stream = '{$data['stream']}'
						AND
						level = '{$data['level']}'";
		
			$resource = $this->getDBResource($query);
		}
	
		public function getStreams ($data = false) {
			$query = 'SELECT server, stream, level, bitrate, fcsubscribe, width, height, last_pulse FROM stream_monitor WHERE active = 1';
			$resource = $this->getDBResource($query);

			$arr = array(
				'data' => array(),
				'string' => array()
			);

			while ($row = mysql_fetch_assoc($resource)) {
				$arr['data'][] = $row;
				$arr['string'][] = $row['server'] . $row['stream'] . $row['level'] . '|' . $row['last_pulse'];
			}

			if ($data) return $arr['data'];
			return implode("\n", $arr['string']);	
		}
	}

?>
