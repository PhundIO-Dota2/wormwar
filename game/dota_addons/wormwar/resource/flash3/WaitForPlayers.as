package  {
	import flash.display.MovieClip;
	import flash.utils.*;
	import flash.events.MouseEvent;
	import scaleform.clik.events.*;
	import flash.geom.Point;
	import flash.text.*
	
	//import some stuff from the valve lib
	import ValveLib.*;
	
	public class WaitForPlayers extends MovieClip {
		
		public var gameAPI:Object;
		public var globals:Object;
		public var abilityNames:Array = new Array("Crypt_Craving","Reverse","Goo_Bomb","Segment_Bomb","Fiery_Jaw")

		public function WaitForPlayers() {
			// constructor code
		}
		
		//set initialise this instance's gameAPI
		public function setup(api:Object, globals:Object) {
			this.gameAPI = api;
			this.globals = globals;
			
			var tf:TextFormat = runesTitle.getTextFormat()
			runesTitle.text = Globals.instance.GameInterface.Translate("#Runes")
			runesTitle.setTextFormat(tf)
			runeHelpText.wordWrap = true;

			runeHelpText.text = Globals.instance.GameInterface.Translate("#RuneHelpText")

			// this is such an awful way of doing the skill rollout stuff.. but i don't have many abilities so w/e
			for (var i:int = 0; i < abilityNames.length; i++) {
				var rune:MovieClip = getChildByName(abilityNames[i]) as MovieClip
				rune.addEventListener(MouseEvent.ROLL_OVER, onMouseRollOverRune);
				rune.addEventListener(MouseEvent.ROLL_OUT, onMouseRollOutRune);
			}

			trace("##Called WaitForPlayers Setup!");
			visible = true;
		}
		
		public function onMouseRollOverRune(keys:MouseEvent) {
       		var rune:MovieClip = keys.target as MovieClip;
       		var runeName:String = keys.target.name
       		trace("roll over! " + runeName);

			// Workout where to put it
            var lp:Point = rune.localToGlobal(new Point(0, 0));
			
            globals.Loader_heroselection.gameAPI.OnSkillRollOver(lp.x, lp.y, runeName);
       	}
		
		public function onMouseRollOutRune(keys:MouseEvent) {
			globals.Loader_heroselection.gameAPI.OnSkillRollOut();
		}

		//onScreenResize
		public function screenResize(stageW:int, stageH:int, xScale:Number, yScale:Number, wide:Boolean) {
			trace("Stage Size: ",stageW,stageH);

			this.width = this.width*yScale;
			this.height	 = this.height*yScale;

			// this is always called at the resolution the player is currently at.
			this.x = stageW - this.width/2;
			this.y = stageH - this.height/2;
			
			//Now we just set the scale of this element, because these parameters are already the inverse ratios
			this.scaleX = xScale;
			this.scaleY = yScale;
		}
	}	
}

