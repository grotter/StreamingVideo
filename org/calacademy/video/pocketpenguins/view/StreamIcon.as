package org.calacademy.video.pocketpenguins.view {
	import org.casalib.display.CasaMovieClip;
	import org.casalib.display.CasaTextField;
	import flash.text.*;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.display.MovieClip;
	
	public class StreamIcon extends CasaMovieClip {
		public var pic_mc:MovieClip;
		
		private var _title:String;
		private var _prefix:String;
		private var _isActive:Boolean = false;
		protected var _layoutVars:Object;
		
		public function StreamIcon (title:String, prefix:String) {
			super();
			this.stop();
			this._setLayoutVars();
			this._title = title;
			this._prefix = prefix;
			
			// set pic 
			try {
				this.pic_mc.gotoAndStop(this._prefix);
			} catch (e:Error) {
				trace(e);
			}

			_initTitle();
			
			this.addEventListener(MouseEvent.MOUSE_UP, _onMouseUp);
		}
		
		protected function _setLayoutVars ():void {
			_layoutVars = {
				width: 58,
				height: 57,
				fontSize: 13,
				titleSpacing: 3
			};
		}
		
		public function set active (boo:Boolean):void {
			if (!boo) this._isActive = false;
			var frame:int = boo ? 2 : 1;
			this.gotoAndStop(frame);
		}
		
		public function get active ():Boolean {
			return this._isActive;
		}
		
		public function get prefix ():String {
			return this._prefix;
		}
		
		public function select (restart:Boolean = false):void {
			if (restart) {
				this.enabled = true;
				this._isActive = false;
			}
			
			this._onMouseUp(null);
		}
		
		private function _onMouseUp (e:MouseEvent):void {
			if (this._isActive || !this.enabled) return;
			this._isActive = true;
			this.dispatchEvent(new Event(this._prefix));
		}
		
		private function _getTextField (color:Number):CasaTextField {
			var myFormat:TextFormat = new TextFormat();
			myFormat.font = (new WhitneySemibold()).fontName;
			myFormat.size = _layoutVars.fontSize;
			
			var title_txt:CasaTextField = new CasaTextField();
			title_txt.defaultTextFormat = myFormat;
			title_txt.embedFonts = true;
			title_txt.autoSize = TextFieldAutoSize.LEFT;
			title_txt.textColor = color;
			title_txt.selectable = false;
			title_txt.antiAliasType = AntiAliasType.ADVANCED;
			title_txt.text = this._title;
			
			title_txt.x = Math.round((_layoutVars.width - title_txt.width) / 2);
			title_txt.y = _layoutVars.height + _layoutVars.titleSpacing;
			
			return title_txt;
		}
		
		private function _initTitle ():void {
            var main_txt = this._getTextField(0xffffff);
			var shadow_txt = this._getTextField(0x000000);
			shadow_txt.x += 1;
			shadow_txt.y += 1;
			shadow_txt.alpha = .6;
			
			this.addChild(shadow_txt);
			this.addChild(main_txt);
		}
	}
}
