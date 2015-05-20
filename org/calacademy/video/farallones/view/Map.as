package org.calacademy.video.farallones.view {
	import flash.display.MovieClip;
	import org.casalib.display.CasaSprite;
	import com.greensock.easing.Expo;
	import com.greensock.TweenLite;

	public class Map extends CasaSprite {
		public var radar_mc:MovieClip;
		public var compass_mc:MovieClip;
		
		public function Map () {
			super();
		}
		
		public function update (data:Object):void {
			if (data.position) {
				TweenLite.to(this.radar_mc, 1, {
					rotation: data.position,
					ease: Expo.easeOut
				});
			}
		}
		
		override public function destroy ():void {
			TweenLite.killTweensOf(this.radar_mc);
			super.destroy();
		}
	}
}
