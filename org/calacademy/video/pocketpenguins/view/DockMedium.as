package org.calacademy.video.pocketpenguins.view {
	import org.calacademy.video.pocketpenguins.view.Dock;
	import org.calacademy.video.pocketpenguins.view.StreamIcon;
	
	public class DockMedium extends Dock {		
		public function DockMedium (data:XML) {
			super(data); 
		}
		
		override protected function _getIcon (title:String, prefix:String):StreamIcon {
			return new StreamIconMedium(title, prefix);
		}
		
		override protected function _setLayoutVars ():void {
			_layoutVars = {
				x: 105,
				y: 126,
				arrowOffset: 41,
				containerOffsetY: 10
			};
		}
	}
}
