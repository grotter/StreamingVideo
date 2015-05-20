<?php

class FarallonesHotspots extends Webcam {
	public function FarallonesHotspots () {
		parent::__construct();
	}
	
	public function getHotspotsData () {
		$query = 'SELECT code, title, rotation FROM farallones_hotspot ORDER BY title ASC';
		$resource = $this->getDBResource($query);
		if (!$resource) return false;
		
		$arr = array();
		
		while ($row = mysql_fetch_assoc($resource)) {
			$arr[] = $row;
		}
		
		return $arr;
	}
	
	public function getRotationFromHotspotCode ($code) {
		$query = 'SELECT rotation FROM farallones_hotspot WHERE code = "' . mysql_real_escape_string(trim($code)) . '"';
		$resource = $this->getDBResource($query);
		if (!$resource) return 0;
		if (mysql_num_rows($resource) != 1) return 0;
		
		$row = mysql_fetch_assoc($resource);
		return $row['rotation'];
	}
}

?>
