package org.calacademy.video.pocketpenguins.view {
	import flash.display.MovieClip;
	import org.casalib.display.CasaSprite;
	import org.calacademy.video.Config;
	import org.calacademy.video.pocketpenguins.view.StreamIcon;
	import org.calacademy.video.events.ContentEvent;
	import com.greensock.TweenLite;
	import com.greensock.easing.*;
	import flash.events.Event;
	
	public class Dock extends CasaSprite {		
		public var empty_mc:CasaSprite;
		public var arrowOutline_mc:MovieClip;
		public var arrow_mc:MovieClip;
		public var stroke_mc:MovieClip;
		
		private var _data:XML;
		private var _iconContainer:CasaSprite;
		private var _icons:Vector.<StreamIcon>;
		private var _isFirstRun:Boolean = true;
		protected var _layoutVars:Object;
		
		public function Dock (data:XML) {
			super();
			this._setLayoutVars();
			this.cacheAsBitmap = true;
			this._data = data;
			this.addEventListener(Event.ADDED_TO_STAGE, _onAdded); 
		}
		
		protected function _setLayoutVars ():void {
			_layoutVars = {
				x: 72,
				y: 90,
				arrowOffset: 28,
				containerOffsetY: 6
			};
		}
		
		protected function _getIcon (title:String, prefix:String):StreamIcon {
			return new StreamIcon(title, prefix);
		}
		
		private function _onAdded (e:Event):void {
			this._iconContainer = new CasaSprite();
			this._icons = new Vector.<StreamIcon>();
			
			// add icons
			var i:int = 0;
			
			for each (var node:XML in this._data.cam) {
				var title:String = node.shorttitle.toString();
				var prefix:String = node.prefix.toString();
                
				var icon:StreamIcon = _getIcon(title, prefix);
				icon.addEventListener(prefix, _onIconSelect);
				icon.y = i * _layoutVars.y;
				
				_icons.push(icon);
				this._iconContainer.addChild(icon);
				
				i++;
			}
			
			// layout icon container
			var h:Number = Config.stageHeight / this.scaleX;
			this._iconContainer.y = Math.round((h - this._iconContainer.height) / 2) + _layoutVars.containerOffsetY;
			this._iconContainer.x -= _layoutVars.x;
			this.empty_mc.addChild(_iconContainer); 
			
			this.hide(false);
		}
		
		public function show ():void {
			TweenLite.killTweensOf(this);
			
			var targetX:Number = Config.stageWidth + 1;
			
			TweenLite.to(this, 1, {
				x: targetX,
				ease: Expo.easeOut
			});
		}
		
		public function hide (tween:Boolean = true):void {
			TweenLite.killTweensOf(this);
			
			var targetX:Number = Config.stageWidth + this.width;
			_onCollapsed();
			
			if (!tween) {
				this.x = targetX;
				return;
			}
			
			TweenLite.to(this, 2.3, {
				x: targetX,
				ease: Expo.easeOut
			});
		}
		
		public function select (prefixOrIndex:*, restart:Boolean = false):void {
			if (typeof(prefixOrIndex) == "string") {
				for each (var icon:StreamIcon in _icons) {
					if (icon.prefix == prefixOrIndex) {
						icon.select(restart);
						return;
					} 
				}
				
				// invalid prefix, just select the first
				_icons[0].select(restart);
			} else {
				_icons[prefixOrIndex].select(restart);
			}
		}
		
		public function set enabled (boo:Boolean):void {
			for each (var icon:StreamIcon in _icons) {
				icon.enabled = boo;
			}
		}
		
		public function reenableAll ():void {
			// move the arrow off screen
			TweenLite.killTweensOf(this.arrow_mc);
			TweenLite.killTweensOf(this.arrowOutline_mc);
			this.arrow_mc.y = this.arrowOutline_mc.y = -this.arrowOutline_mc.height;
			
			for each (var icon:StreamIcon in _icons) {
				icon.enabled = true;
				icon.active = false;
			}
		}
		
		private function _onSelected (e:*):void {
			this.dispatchEvent(new ContentEvent(e.type));
			// this.dispatchEvent(new ContentEvent(ContentEvent.SELECT));
		}
		
		private function _onCollapsed ():void {
			this.dispatchEvent(new ContentEvent(ContentEvent.COLLAPSED));
		}
		
		private function _onIconSelect (e:*):void {
			// set active state
			var inst:Dock = this;
			
			for each (var icon:StreamIcon in _icons) {
				icon.active = (icon.prefix == e.type);
				
				if (icon.active) {
					var targY:Number = icon.y + _iconContainer.y + _layoutVars.arrowOffset;
					
					if (this._isFirstRun) {
						// first selection shouldn't animate
						this.arrow_mc.y = targY;
						this.arrowOutline_mc.y = targY;
						this._isFirstRun = false;
						_onSelected(e);
					} else {
						TweenLite.killTweensOf(this.arrow_mc);
						TweenLite.killTweensOf(this.arrowOutline_mc);
						
						TweenLite.to(this.arrow_mc, 1, {
							y: targY,
							ease: Expo.easeOut,
							delay: .2,
							onComplete: function () {
								inst._onSelected(e);
							}
						});

						TweenLite.to(this.arrowOutline_mc, 1, {
							y: targY,
							ease: Expo.easeOut,
							delay: .2
						});	
					}
				} 
			}
		}
	}
}
