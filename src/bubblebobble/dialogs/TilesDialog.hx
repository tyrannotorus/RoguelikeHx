package bubblebobble.dialogs;

import bubblebobble.dialogs.DraggableDialog;
import com.tyrannotorus.assetloader.AssetEvent;
import com.tyrannotorus.assetloader.AssetLoader;
import com.tyrannotorus.utils.Colors;
import com.tyrannotorus.utils.Utils;
import haxe.ds.ObjectMap;
import openfl.display.Bitmap;
import openfl.display.Sprite;
import openfl.events.MouseEvent;

/**
 * TilesDialog.hx.
 * - A draggable dialog with for use within the level editor.
 * - Loads a selection of tiles.
 */
class TilesDialog extends DraggableDialog {
	
	private static inline var WIDTH:Int = 96;
	private static inline var HEIGHT:Int = 128;

	private var tilesContainer:Sprite;
	private var tilesArray:Array<Bitmap>;
	private var tilesMap:ObjectMap<Dynamic,Bitmap>;
	private var selectTileContainer:Sprite;
	private var selectedTile:Bitmap;
	
	/**
	 * Constructor.
	 */
	public function new() {
		
		var dialogData:DialogData = new DialogData();
		dialogData.headerText = "Acrade\nTiles";
		dialogData.headerHeight = 20;
		dialogData.headerTextShadowColor = Colors.BLACK;
		dialogData.width = WIDTH;
		dialogData.height = HEIGHT;
		dialogData.shadowColor = Colors.MIDNIGHT_BLUE;
		dialogData.shadowOffsetX = -3;
		dialogData.shadowOffsetY = 2;
		
		super(dialogData);
				
		headerText.y += 1;
		tilesContainer = new Sprite();
		tilesContainer.x = 6;
		tilesContainer.y = 22;
		tilesContainer.mouseChildren = true;
		addChild(tilesContainer);
		
		selectTileContainer = new Sprite();
		selectTileContainer.addChild(selectedTile = new Bitmap());
		selectTileContainer.x = WIDTH - 20;
		selectTileContainer.y = 2;
		addChild(selectTileContainer);
		
		addListeners();
	}
	
	/**
	 * Makes the tile publically accessible.
	 * @return {Bitmap}
	 */
	public function getSelectedTile():Bitmap {
		return selectedTile;
	}
	
	/**
	 * User has clicked the tiles container.
	 * @return {MouseEvent.CLICK} e
	 */
	private function onTileClick(e:MouseEvent):Void {

		var tileBitmap:Bitmap = tilesMap.get(e.target);
		
		// Invalid. Something was clicked, but it wasn't a tile.
		if (tileBitmap == null) {
			e.stopImmediatePropagation();
			return;
		}
		
		// Swap in and position the new tile.
		selectedTile.bitmapData = tileBitmap.bitmapData;
		selectedTile.x = selectedTile.y = (16 - selectedTile.width) / 2;
	}
	
	/**
	 * Initiate load of the tileset.
	 */
	public function loadTiles():Void {
		var assetLoader:AssetLoader = new AssetLoader();
		assetLoader.addEventListener(AssetEvent.LOAD_COMPLETE, onTilesLoaded);
		assetLoader.loadAsset("tiles/tiles.zip");
	}
		
	/**
	 * Tileset has loaded.
	 * @param {AssetEvent.LOAD_COMPLETE} e
	 */
	private function onTilesLoaded(e:AssetEvent):Void {
		
		var assetLoader:AssetLoader = cast(e.target, AssetLoader);
		assetLoader.removeEventListener(AssetEvent.LOAD_COMPLETE, onTilesLoaded);
		
		if (e.assetData == null) {
			trace("TilesDialog.onTilesLoaded() Failure.");
			return;
		}
		
		tilesMap = new ObjectMap<Dynamic,Bitmap>();
				
		var xPosition:Float = 0;
		var yPosition:Float = 0;
		var rowHeight:Float = 0;
		var maxWidth:Float = WIDTH - 13;
		
		// Load the fields.
		var fieldsArray:Array<String> = Reflect.fields(e.assetData);
		fieldsArray.sort(Utils.sortAlphabetically);
		
		for (idxField in 0...fieldsArray.length) {
			var fieldString:String = fieldsArray[idxField];
			var tileBitmap:Bitmap = Reflect.field(e.assetData, fieldString);
			var tileSprite:Sprite = new Sprite();
			tileSprite.addChild(tileBitmap);
			tileSprite.buttonMode = true;
			
			tileSprite.x = xPosition;
			xPosition += tileBitmap.width + 2;
			
			tileSprite.y = yPosition;
			
			if (rowHeight < tileBitmap.height) {
				rowHeight = tileBitmap.height;
			}
			
			if (xPosition > maxWidth) {
				xPosition = 0;
				yPosition += rowHeight + 2;
				rowHeight = 0;
			}
			
			tilesMap.set(tileSprite, tileBitmap);
			tilesContainer.addChild(tileSprite);
		}
		
		addChild(tilesContainer);
	}
	
	/**
	 * Stop outward propagation on MOUSE_DOWN
	 * @param {MouseEvent.MOUSE_DOWN} e
	 */
	private function onMouseDown(e:MouseEvent):Void {
		e.stopImmediatePropagation();
	}

	/**
	 * Add listeners.
	 */
	override private function addListeners():Void {
		tilesContainer.addEventListener(MouseEvent.CLICK, onTileClick);
		headerContainer.addEventListener(MouseEvent.MOUSE_DOWN, onStartDialogDrag);
		headerContainer.addEventListener(MouseEvent.MOUSE_UP, onStopDialogDrag);
		this.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
	}
	
	/**
	 * Removes listeners.
	 */
	override private function removeListeners():Void {
		tilesContainer.removeEventListener(MouseEvent.CLICK, onTileClick);
		headerContainer.removeEventListener(MouseEvent.MOUSE_DOWN, onStartDialogDrag);
		headerContainer.removeEventListener(MouseEvent.MOUSE_UP, onStopDialogDrag);
		this.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
	}

	
}