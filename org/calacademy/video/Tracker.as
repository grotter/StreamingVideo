package org.calacademy.video {
	import com.google.analytics.AnalyticsTracker; 
	import com.google.analytics.GATracker;
	import org.casalib.util.FlashVarUtil;
	import org.casalib.display.CasaSprite;
	import org.casalib.util.StageReference;
	import org.calacademy.video.Config;
	
	public class Tracker extends CasaSprite {
		private static var _instance:Tracker;
		private var _ga:AnalyticsTracker;
		
		public function Tracker (singletonEnforcer:SingletonEnforcer) {
			super();
			
			if (!Config.DEBUG && Config.ga_account != null) {
				StageReference.getStage().addChild(this);
				_ga = new GATracker(this, Config.ga_account);
			}
		}
		
		public function track (category:String, code:*, label:String = null):void {
			if (_ga == null) return;
			var trackString:String = String(code);

			if (FlashVarUtil.hasKey("trackingsuffix")) {
				trackString += " / " + FlashVarUtil.getValue("trackingsuffix");	
			}

			trace("\tTrack: " + category + ", " + trackString + ", " + label);
			_ga.trackEvent(category, trackString, label);
		}
		
		public static function getInstance():Tracker {
			if (Tracker._instance == null) {
				Tracker._instance = new Tracker(new SingletonEnforcer());
			}
			
			return Tracker._instance;
		}
	}
}

class SingletonEnforcer {}
