package org.calacademy.video.farallones.data {
	import org.calacademy.video.Config;
	import org.calacademy.video.data.Database;
	
	public class DatabaseFarallones extends Database {
		
		public function DatabaseFarallones (singletonEnforcer:*) {
			super(singletonEnforcer);
		}
		
		public function isActive ():Boolean {
			if (_xml.@isinactive == undefined) return true;
			return (int(_xml.@isinactive) != 1);
		}
		
		override protected function _setConfig ():void {
			super._setConfig();
			
			if (_isConstantSpecified("camcontrolpulse")) {
				Config.camControlPulse = _xml.constants.camcontrolpulse;
			}
			
			_setMsg("inactive-encoder", "msgInactiveEncoder");
		}
		
		public static function getInstance ():DatabaseFarallones {
			if (DatabaseFarallones._instance == null) {
				DatabaseFarallones._instance = new DatabaseFarallones(new SingletonEnforcerFarallones());
			}
			
			return DatabaseFarallones._instance;
		}
	}
}

class SingletonEnforcerFarallones {}
