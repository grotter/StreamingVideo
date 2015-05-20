package org.calacademy.video.farallones.view {
	import flash.events.Event;
	import flash.text.TextField;
	import org.calacademy.utils.NumberUtilExtra;
	import org.calacademy.video.farallones.view.ControlIndicator;
	import org.casalib.time.Interval;

	public class TimeLeft extends ControlIndicator {
		public var countdown_txt:TextField;
		private var _interval:Interval;
		private var _dataReceived:Boolean;
		private var _seconds_remaining:int;
		private var _seconds_active:int = 0;
		
		public function TimeLeft () {
			super();
			_interval = Interval.setInterval(_onTick, 1000);
			reset();
		}
		
		private function _getFormattedTime (seconds:int):String {
			var milli:Number = seconds * 1000; 
			return NumberUtilExtra.formatSeconds(milli, false);
		}
		
		private function _getDefaultText ():String {
			if (_seconds_active == 0) return "--:--";
			return this._getFormattedTime(_seconds_active); 
		}
		
		override public function reset ():void {
			this.countdown_txt.text = this._getDefaultText();
			_seconds_remaining = _seconds_active;
			_dataReceived = false;
		}
		
		private function _onTick ():void {
			this.countdown_txt.text = this._getFormattedTime(_seconds_remaining);
			if (_seconds_remaining > 0) _seconds_remaining--;
		}
		
		override protected function _onAdded (e:Event):void {
			super._onAdded(e);
			
			_onTick();
			_interval.start();
		}
		
		override protected function _onRemoved (e:Event):void {
			super._onRemoved(e);
			_interval.stop();
		}
		
		override public function update (data:Object):void {
			// set seconds_active if we have the data
			if (data != null) {
				if (data.camcontrol != null) {
					if (data.camcontrol.seconds_active != undefined) {
						if (!_dataReceived) {
							_seconds_active = int(data.camcontrol.seconds_active);
							_seconds_remaining = _seconds_active;
							_dataReceived = true;
						}
					}
				}
			}
		}
		
		override public function destroy ():void {
			_interval.destroy();
			super.destroy();
		}
	}
}
