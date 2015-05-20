package org.calacademy.video.net {
	import org.casalib.events.RemovableEventDispatcher;
	
	public class NCListener extends RemovableEventDispatcher {
		private static var _instance:NCListener;
		
		public function NCListener (singletonEnforcer:SingletonEnforcer) {
			super();
		}
		
		public static function getInstance():NCListener {
			if (NCListener._instance == null) {
				NCListener._instance = new NCListener(new SingletonEnforcer());
			}
			
			return NCListener._instance;
		}
	}
}

class SingletonEnforcer {}
