package org.calacademy.video.farallones.view {
	import org.casalib.display.CasaSprite;
	import flash.text.*;
	import org.casalib.util.DateUtil;
	import org.casalib.util.NumberUtil;
	import org.casalib.util.StringUtil;
	import com.greensock.TweenLite;
	import com.greensock.easing.Expo;

	public class LiveStreamDataDisplay extends CasaSprite {
		private var _style:StyleSheet;
		private var _initialized:Boolean = false;
		public var info_txt:TextField;
		public var bg_s:CasaSprite;
		
		public function LiveStreamDataDisplay () {
			super();
			this.alpha = 0;
			_setStyle();
		}
		
		private function _fadeUp ():void {
			TweenLite.to(this, 1, {
				alpha: 1,
				delay: .2,
				ease: Expo.easeOut
			});
		}
		
		public function update (data:Object):void {
			var str:String = "";

			//time
			if (int(data.timestamp)) {
				if (!_initialized) {
					_fadeUp();
					_initialized = true;
				}
				
				var now:Date = new Date(int(data.timestamp) * 1000);
				str += DateUtil.formatDate(now, "g:i") + " <span class='small'>" + DateUtil.formatDate(now, "A") + "</span>";
			} else {
				str += "- ";
			}
			
			//temp
			if (data.temperature.fahrenheit) {
				str += " " + Math.round(data.temperature.fahrenheit) + "°<span class='small'>F</span> ";
			} else {
				str += " - ";
			}

			//wind
			if (data.wind.direction) {
				str += " " + data.wind.direction.toUpperCase() + " " + NumberUtil.roundDecimalToPlace(data.wind.speed, 1) + " <span class='small'>MPH</span> ";
			} else {
				str += " - ";
			}
			
			_setText(this.info_txt, StringUtil.trim(str));
			this.bg_s.width = this.info_txt.width + 14;
		}
		
		private function _setStyle ():void {
			_style = new StyleSheet();
			
            _style.setStyle(".small", {
	        	fontSize: "15px",
				fontFamily: "GG Superscript Sans",
				color: "#ffffff"
			});
		}
		
		private function _setText (target:TextField, str:String):void {
			target.autoSize = TextFieldAutoSize.LEFT;
			target.multiline = false;
			target.selectable = false;
			
			target.styleSheet = _style;
			target.htmlText = str;
			target.antiAliasType = AntiAliasType.ADVANCED;
		}
	}
}
