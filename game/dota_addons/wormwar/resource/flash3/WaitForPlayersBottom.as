package  {
	import flash.display.MovieClip;
	
	//import some stuff from the valve lib
	import ValveLib.Globals;
	import ValveLib.ResizeManager;
	
	public class WaitForPlayersBottom extends MovieClip {
		
		public var gameAPI:Object;
		public var globals:Object;

		public function WaitForPlayersBottom() {
			// constructor code
		}
		
		//set initialise this instance's gameAPI
		public function setup(api:Object, globals:Object) {
			this.gameAPI = api;
			this.globals = globals;
			
			//this.bottomCreditsText.wordWrap = true;
			//this.bottomCreditsText.text = Globals.instance.GameInterface.Translate("#BottomCreditsText")

			this.visible = true;
			trace("##Called WaitForPlayersBottom Setup!");
		}
		
		//onScreenResize
		public function screenResize(stageW:int, stageH:int, xScale:Number, yScale:Number, wide:Boolean) {
			this.width = this.width*yScale;
			this.height	 = this.height*yScale;

			// this is always called at the resolution the player is currently at.
			this.x = stageW/2;
			this.y = (stageH - this.height/2) - 20;
			
			//trace("#Result Resize: ",this.x,this.y,yScale);
			
			//Now we just set the scale of this element, because these parameters are already the inverse ratios
			this.scaleX = xScale;
			this.scaleY = yScale;
			
			//trace("#WaitForPlayers2 Resize");
		}
	}	
}

