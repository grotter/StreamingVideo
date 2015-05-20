package org.calacademy.video.sharklagoondual.view {
	import org.casalib.display.CasaMovieClip;
	import org.casalib.display.CasaTextField;
	import flash.text.*;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.display.MovieClip;
	
	public class StreamOption extends CasaMovieClip {
		public var pic_mc:MovieClip;
		
		private var _title:String;
		private var _prefix:String;
		private var _isActive:Boolean = false;
		protected var _layoutVars:Object;
		
		public var title_txt:CasaTextField = new CasaTextField();

		public function StreamOption (title:String, prefix:String) {
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
			this.addEventListener(MouseEvent.MOUSE_OVER, _onMouseOver);
			this.addEventListener(MouseEvent.MOUSE_OUT, _onMouseOut);
		}
		
		protected function _setLayoutVars ():void {
			_layoutVars = {
				fontSize: 10,
				topMargin: 5,
				colorOff: 0xdddddd,
				colorOn: 0x8BFF06
			};
		}
		
		public function set active (boo:Boolean):void {
			if (!boo) this._isActive = false;
			var frame:int = boo ? 2 : 1;
			this.gotoAndStop(frame);
			if (!boo) this.title_txt.textColor = _layoutVars.colorOff;
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
			this.title_txt.textColor = _layoutVars.colorOn;
		}
		
		private function _onMouseUp (e:MouseEvent):void {
			if (this._isActive || !this.enabled) return;
			this._isActive = true;
			trace(this._prefix);
			this.dispatchEvent(new Event(this._prefix));
		}

		private function _onMouseOver (e:MouseEvent):void {
			this.gotoAndStop(2);
			if (!this._isActive) {
				this.title_txt.textColor = _layoutVars.colorOn;
			}
		}
		private function _onMouseOut (e:MouseEvent):void {
			if (!this._isActive) {
				this.gotoAndStop(1);
				this.title_txt.textColor = _layoutVars.colorOff;
			}
		}

		private function _getTextField (color:Number):CasaTextField {
			
			var myFormat:TextFormat = new TextFormat();
			myFormat.font = (new WhitneySemibold()).fontName;
			myFormat.size = _layoutVars.fontSize;
			myFormat.leftMargin = 12;
			myFormat.rightMargin = 12;
			myFormat.align = TextFormatAlign.CENTER;
			myFormat.leading = 2;
			
			title_txt.defaultTextFormat = myFormat;
			title_txt.embedFonts = true;
			title_txt.textColor = color;
			title_txt.selectable = false;
			title_txt.antiAliasType = AntiAliasType.ADVANCED;
			title_txt.wordWrap = true;
			var upperTitle = this._title.toUpperCase();
			title_txt.text = upperTitle;
			title_txt.width = this.width;
			title_txt.y = _layoutVars.topMargin;

			return title_txt;
		}
		
		private function _initTitle ():void {
      
      var main_txt = this._getTextField(_layoutVars.colorOff);
      this.addChild(main_txt);

		}
	}
}
