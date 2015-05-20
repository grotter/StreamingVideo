package org.calacademy.video.monitor.data {
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;

	import org.casalib.load.DataLoad;
	import org.casalib.util.LocationUtil;
	import org.casalib.events.RemovableEventDispatcher;

	public class SendPulse extends RemovableEventDispatcher {
		protected var _data:DataLoad;
		protected static var _instance:SendPulse;

		public function SendPulse (singletonEnforcer:*) {
			super();
		}

		public function pulse (server:String, stream:String, level:String):void {
			var variables:URLVariables = new URLVariables();
            variables.server = server;
            variables.stream = stream;
            variables.level = level;

            // var pulseTarget:String = "http://www.calacademy.org/webcams/monitor/";
            // if (LocationUtil.isIde()) pulseTarget = "http://staging.calacademy.org/webcams/monitor/";

            var pulseTarget:String = "http://internal-prod.calacademy.org/webcams/monitor/";

			var request:URLRequest = new URLRequest(pulseTarget);
            request.data = variables;
            request.method = URLRequestMethod.POST;

            if (_data) _data.destroy();
			_data = new DataLoad(request);

			try {
				trace("sending pulse: " + stream);
				_data.start();
			} catch (e:*) {
				trace("SendPulse.pulse");
				trace(e);
			}
		}

		public static function getInstance ():SendPulse {
			if (SendPulse._instance == null) {
				SendPulse._instance = new SendPulse(new SingletonEnforcer());
			}

			return SendPulse._instance;
		}

		override public function destroy ():void {
			// super.destroy();

			try {
				if (_data) {
					_data.destroy();
					_data = null;
				}
			} catch (e:Error) {
				// trace(e);
			}
		}
	}
}

class SingletonEnforcer {}
