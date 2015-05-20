package org.calacademy.video.sharklagoondual.view {
	import flash.display.MovieClip;
	import org.casalib.display.CasaSprite;
	import org.calacademy.video.Config;
	import org.calacademy.video.sharklagoondual.view.StreamOption;
	import org.calacademy.video.events.ContentEvent;
	import com.greensock.TweenLite;
	import com.greensock.easing.*;
	import flash.events.Event;
	
	public class Navbar extends CasaSprite {		
		
		public var empty_mc:CasaSprite;
		
		private var _data:XML;
		private var _optionContainer:CasaSprite;
		private var _options:Vector.<StreamOption>;
		private var _isFirstRun:Boolean = true;

		protected var _layoutVars:Object;
		
		public function Navbar (data:XML) {
			super();
			this._setLayoutVars();
			this._data = data;
			this.addEventListener(Event.ADDED_TO_STAGE, _onAdded);
		}
		
		protected function _setLayoutVars ():void {
			_layoutVars = {
				x: 10,
				y: 0
			};
		}
		
		protected function _getOption (title:String, prefix:String):StreamOption {
			return new StreamOption(title, prefix);
		}
		
		private function _onAdded (e:Event):void {

			//var targetY:Number = Config.stageHeight - this.height;
			//var targetY:Number = stage.stageHeight - this.height;
			//this.y = targetY;

			this._optionContainer = new CasaSprite();
			this._options = new Vector.<StreamOption>();

			// add stream options
			var i:int = 0;

			for each (var node:XML in this._data.cam) {

				var title:String = node.shorttitle.toString();
				var prefix:String = node.prefix.toString();
				var option:StreamOption = _getOption(title, prefix);
				option.addEventListener(prefix, _onOptionSelect);
				option.x = i * (option.width + 10);
				option.y = _layoutVars.y;
				_options.push(option);
				this._optionContainer.addChild(option);
				i++;
				
			}

			// layout option container
			this._optionContainer.y = _layoutVars.y
			this._optionContainer.x = _layoutVars.x;
			this.empty_mc.addChild(_optionContainer);
			
		}
		
		public function select (prefixOrIndex:*, restart:Boolean = false):void {
			if (typeof(prefixOrIndex) == "string") {
				for each (var option:StreamOption in _options) {
					if (option.prefix == prefixOrIndex) {
						option.select(restart);
						return;
					} 
				}
				// invalid prefix, just select the first
				_options[0].select(restart);
			} else {
				_options[prefixOrIndex].select(restart);
			}
		}
		
		public function set enabled (boo:Boolean):void {
			for each (var option:StreamOption in _options) {
				option.enabled = boo;
			}
		}
		
		public function reenableAll ():void {
			for each (var option:StreamOption in _options) {
				option.enabled = true;
				option.active = false;
			}
		}
		
		private function _onSelected (e:*):void {
			this.dispatchEvent(new ContentEvent(e.type));
		}

		private function _onOptionSelect (e:*):void {
			// set active state
				var inst:Navbar = this;
			for each (var option:StreamOption in _options) {
				option.active = (option.prefix == e.type);

				if (option.active) {
					if (this._isFirstRun) {
						_onSelected(e);
					} else {
						inst._onSelected(e);
					}
				}

			}
		}
	}
}
