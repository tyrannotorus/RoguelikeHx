package com.roguelike.dialogs;

import openfl.display.Bitmap;
import openfl.display.Sprite;
import com.roguelike.Matte;
import com.roguelike.MatteData;
import com.roguelike.TextData;
import com.roguelike.managers.TextManager;

/**
 * GenericDialog.hx.
 * - A sized generic dialog.
 */
class GenericDialog extends Sprite {

	private var headerContainer:Sprite;
	private var headerText:Bitmap;
	
	/**
	 * Constructor.
	 * @param {DialogData} dialogData
	 */
	public function new(dialogData:DialogData = null) {
		
		super();
		
		if (dialogData == null) {
			dialogData = new DialogData();
		}
		
		// Create the backing matte for the dialog.
		var matteBitmap:Bitmap = Matte.toBitmap(dialogData);
		matteBitmap.x = -matteBitmap.width / 2;
		matteBitmap.y = -matteBitmap.height / 2;
		addChild(matteBitmap);
		
		// Create the header and header backing matte.
		if(dialogData.headerHeight > 0) {
			var headerData:MatteData = new MatteData();
			headerData.width = dialogData.width;
			headerData.height = dialogData.headerHeight;
			headerData.topRadius = dialogData.topRadius;
			headerData.bottomRadius = 0;
			headerData.borderColor = dialogData.headerBorderColor;
			headerData.matteColor = dialogData.headerMatteColor;
			headerContainer = Matte.toSprite(headerData);
			headerContainer.buttonMode = true;
			addChild(headerContainer);
		}
		
		// Create the header text data.
		var textData:TextData = new TextData();
		textData.text = dialogData.headerText;
		textData.upColor = dialogData.headerTextColor;
		textData.shadowColor = dialogData.headerTextShadowColor;
		
		// Add the header text.
		headerText = TextManager.getInstance().toBitmap(textData);
		headerText.y = matteBitmap.x - 1;
		headerText.x = matteBitmap.y + 4;
		addChild(headerText);
		
		x = Main.GAME_WIDTH * dialogData.dialogPositionX;
		y = Main.GAME_HEIGHT * dialogData.dialogPositionY;
		
	}
}