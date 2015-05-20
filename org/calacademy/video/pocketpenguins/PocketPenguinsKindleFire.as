package org.calacademy.video.pocketpenguins {
	import org.calacademy.video.pocketpenguins.PocketPenguinsAndroid;

	public class PocketPenguinsKindleFire extends PocketPenguinsAndroid {
		public function PocketPenguinsKindleFire () {
			super();
		}
		
		override protected function _setIsSleepSuppress ():void {
			_isSleepSuppress = false;
		}
	}
}
