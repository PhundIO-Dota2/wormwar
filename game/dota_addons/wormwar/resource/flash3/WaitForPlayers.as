package  {
	import flash.display.MovieClip;
	
	//import some stuff from the valve lib
	import ValveLib.Globals;
	import ValveLib.ResizeManager;
	
	public class WaitForPlayers extends MovieClip {
		
		public var gameAPI:Object;
		public var globals:Object;

		public function WaitForPlayers() {
			// constructor code
		}
		
		//set initialise this instance's gameAPI
		public function setup(api:Object, globals:Object) {
			this.gameAPI = api;
			this.globals = globals;
			
			this.runeHelpText.wordWrap = true;
			this.runeHelpText.text = Globals.instance.GameInterface.Translate("#RuneHelpText")

			trace("##Called WaitForPlayers Setup!");
			this.visible = true;
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

