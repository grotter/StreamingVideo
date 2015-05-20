package org.calacademy.video.pocketpenguins.view {
	import org.calacademy.video.pocketpenguins.view.StreamIcon;
	
	public class StreamIconMedium extends StreamIcon {
		public function StreamIconMedium (title:String, prefix:String) {
			super(title, prefix);
		}
		
		override protected function _setLayoutVars ():void {
			_layoutVars = {
				width: 82,
				height: 82,
				fontSize: 17,
				titleSpacing: 6
			};
		}
	}
}
