package org.calacademy.video.farallones.view {
	import flash.text.TextField;
	import org.calacademy.video.farallones.view.ControlIndicator;

	public class QueuePosition extends ControlIndicator {
		public var position_txt:TextField;
		private var _pos:int = 0;
		
		public function QueuePosition () {
			super();
			this.update(null);
			reset();
		}
        
		public function get position ():int {
			return _pos;
		}

		public function setPosition (pos:int):void {
			if (pos == 0) {
				this.position_txt.text = "-";
			} else {
				this.position_txt.text = String(pos);
			}
		}
		
		override public function reset ():void {
			_pos = 0;
			this.position_txt.text = "-";
		}

		override public function update (data:Object):void {
			if (!this.onStage) return;
			
			_pos = 0;
			
			if (data != null) {
				if (data.camcontrol != null) {
					if (data.camcontrol.queue_position != undefined) {
						if (int(data.camcontrol.in_queue) == 1) {
							_pos = int(data.camcontrol.queue_position);
						}
					}
				}
			}
			
			setPosition(_pos);
		}
	}
}
