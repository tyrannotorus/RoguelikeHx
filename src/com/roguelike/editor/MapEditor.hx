package com.roguelike.editor;

import com.roguelike.Actor;
import com.roguelike.editor.EditorSelectionBar;
import com.roguelike.managers.MapManager;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;

/**
 * MapEditor.as
 * - Like map, but editable.
 */
class MapEditor extends Map {
	
	// currentStates
	private static inline var DRAG_MAP:String = "DRAG_MAP";
		
	private var currentState:String;
	private var dialogLayer:Sprite;

	private var editorSelectionBar:EditorSelectionBar;
	private var selectedTile:Tile;
	private var selectedActor:Actor;
	private var dragStarted:Bool;
	private var mouseDown:Bool;
			
	/**
	 * Constructor.
	 */
	public function new() {
		
		super();
		
		// Listen for dispatches from the editorDispatcher.
		var editorDispatcher:EditorDispatcher = EditorDispatcher.getInstance();
		editorDispatcher.addEventListener(Event.CHANGE, onEditorDispatch);
		
		// Create the dialog layer.
		dialogLayer = new Sprite();
		dialogLayer.mouseEnabled = false;
		addChild(dialogLayer);
		
		editorSelectionBar = new EditorSelectionBar();
		editorSelectionBar.x = 10;
		editorSelectionBar.y = Main.GAME_HEIGHT - 35;
		dialogLayer.addChild(editorSelectionBar);
				
		// Load the map.
		var mapData:MapData = MapManager.getInstance().getMapData("hellmouth.txt");
		loadMap(mapData);
	}
	
	/**
	 * Listen to EditorDispatcher events, mostly dispatching menu events.
	 * @param {EditorEvent} e
	 */
	private function onEditorDispatch(e:EditorEvent):Void {
		
		var editorEvent:String = e.data;
		
		switch(editorEvent) {
			
			case EditorEvent.TILES:
				currentState = EditorEvent.TILES;
				enableActorsOnMap(false);
				
			case EditorEvent.ACTORS:
				currentState = EditorEvent.ACTORS;
				enableActorsOnMap(true);
				
			case EditorEvent.PROPS:
				currentState = EditorEvent.PROPS;
				enableActorsOnMap(false);
				
			case EditorEvent.TILE_SELECTED:
				selectedTile = editorSelectionBar.getSelectedTile();
				enableActorsOnMap(false);
				
			case EditorEvent.ZOOM_OUT:
				modifyScale(-0.1);
				
			case EditorEvent.ZOOM_IN:
				modifyScale(0.1);
				
			case EditorEvent.HELP:
				trace("EditorEvent.HELP");
				
			case EditorEvent.CLOSE_EDITOR:
				dispatchEvent(new EditorEvent(EditorEvent.CLOSE_EDITOR, mapData, true));
		}
	}
	
	/**
	 * Something on-screen has been moused over.
	 * @param {MouseEvent.MOUSE_OVER} e
	 */
	private function onMouseOver(e:MouseEvent):Void {
		
		// An actor as been dragged from the field back to the EditorSelectionBar.
		if (currentState == EditorEvent.ACTORS && Std.is(e.target, EditorSelectionBar)) {
			if (selectedActor != null) {
				if (selectedActor.currentTile != null) {
					selectedActor.currentTile.removeOccupant();
					selectedActor.currentTile.highlight(false);
					selectedActor.startDrag(true);
					addChild(selectedActor);
				}
			}
		
		// Otherwise
		} else {
			e.stopImmediatePropagation();
			highlightTile(e.target, true);
		}
	}
	
	/**
	 * Something on-screen has been moused out.
	 * @param {MouseEvent.MOUSE_OUT} e
	 */
	private function onMouseOut(e:MouseEvent):Void {
		e.stopImmediatePropagation();
		highlightTile(e.target, false);
	}

	/**
	 * Highlight/Unhighlight a tile.
	 * @param {Dynamic} displayObject
	 * @param {Bool} value
	 */
	private function highlightTile(displayObject:Dynamic, value:Bool):Void {
		
		switch(currentState) {
			
			// Highlight the tile an actor is on.
			case EditorEvent.ACTORS:
				if (Std.is(displayObject, Actor)) {
					var actor:Actor = cast displayObject;
					if (actor.currentTile != null) {
						actor.currentTile.highlight(value);
					}
				} else if (Std.is(displayObject, Tile)) {
					var tile:Tile = cast displayObject;
					if (Std.is(tile.occupant, Actor)) {
						tile.highlight(value);
					}
				}
				
			// Highlight the tile.
			case EditorEvent.TILES:
				if (Std.is(displayObject, Tile)) {
					var tile:Tile = cast displayObject;
					
					if (mouseDown) {
						tile.clone(selectedTile);
					}
					
					tile.highlight(value);
				}
		}
	}
	
	/**
	 * User has mouse downed. Determine the user's intention.
	 * @param {MouseEvent.MOUSE_DOWN} e
	 */
	private function onMouseDown(e:MouseEvent):Void {
		
		mouseDown = true;

		switch(currentState) {
			
			case EditorEvent.ACTORS:
				
				destroyActor();
		
				// Mousedown upon an actor.
				if (Std.is(e.target, Actor)) {
					var actor:Actor = cast e.target;
					if (actor.currentTile != null) {
						selectedActor = actor;
					} else {
						selectedActor = actor.clone();
						allActors.push(selectedActor);
						addEventListener(Event.ENTER_FRAME, animateActors);
					}
				
				// Mousedown upon a tile.
				} else if (Std.is(e.target, Tile)) {
					var tile:Tile = cast e.target;
					if (tile.occupant != null) {
						selectedActor = tile.occupant;
					}
				}
				
				if(selectedActor != null) {
					dragStarted = false;
					selectedActor.mouseEnabled = false;
					editorSelectionBar.mouseChildren = false;
					addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
				}
			
			case EditorEvent.TILES:
						
				if (Std.is(e.target, Tile)) {
					
					var tile:Tile = cast e.target;
			
					if (e.shiftKey == true) {
						currentState = DRAG_MAP;
						mapLayer.mouseChildren = false;
						mapLayer.startDrag();
			
					} else if (selectedTile != null) {
						tile.clone(selectedTile);
					}
				}
		}
	}
	
	/**
	 * User has mouse upped.
	 * @param {MouseEvent.MOUSE_UP} e
	 */
	private function onMouseUp(e:Event):Void {
			
		editorSelectionBar.mouseChildren = true;
		
		mouseDown = false;
		
		switch(currentState) {
			
			case DRAG_MAP:
				mapLayer.mouseChildren = true;
				mapLayer.stopDrag();
				mapLayer.x = Math.floor(mapLayer.x);
				mapLayer.y = Math.floor(mapLayer.y);
									
			case EditorEvent.ACTORS:
			
				// The character has been dragged.
				if (dragStarted) {
					selectedActor.mouseEnabled = true;
					selectedActor.mouseChildren = true;
					
					if(selectedActor.currentTile != null) {
						selectedActor.currentTile.highlight(false);
					}
								
					// Drop the character back into the inventory.
					if (Std.is(e.target, EditorSelectionBar)) {
						destroyActor();
					}
			
				// Actor was clicked, not dragged. Flip him horizontally.
				} else if (selectedActor != null && selectedActor.currentTile != null) {
					selectedActor.scaleX *= -1;
				}
			
				enableActorsOnMap(true);
				
				removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			
				selectedActor = null;
				dragStarted = false;
		}
	}
	
	/**
	 * Enable all the actors in the field for dragging.
	 * @param {Bool} value
	 */
	private function enableActorsOnMap(value:Bool):Void {
		for (i in 0...allActors.length) {
			allActors[i].currentTile.mouseChildren = value;
			allActors[i].currentTile.buttonMode = value;
		}
	}
	
	private function destroyActor():Void {
		
		if (selectedActor != null) {
			
			if (selectedActor.parent != null) {
				selectedActor.parent.removeChild(selectedActor);
			}
				
			selectedActor.stopDrag();
			
			var actorIndex:Int = allActors.indexOf(selectedActor);
			if (actorIndex != -1) {
				allActors.splice(actorIndex, 1);
			}
			
			if (allActors.length == 0) {
				this.removeEventListener(Event.ENTER_FRAME, animateActors);
			}
		}
		
		selectedActor = null;
		dragStarted = false;
	}
	
	/**
	 * The mouse is held and being dragged on the screen.
	 * @param {MouseEvent.MOUSE_MOVE} e
	 */
	private function onMouseMove(e:MouseEvent):Void {

		if (currentState == EditorEvent.ACTORS) {
			
			editorSelectionBar.mouseChildren = false;
			
			// The user has now started to drag an actor.
			if (!dragStarted) {
				selectedActor.mouseEnabled = false;
				selectedActor.mouseChildren = false;
				dragStarted = true;
				
				if(selectedActor.currentTile == null){
					selectedActor.startDrag(true);
					addChild(selectedActor);
				}
			}
			
			// Add actor to a tile.
			if (e.target != selectedActor.currentTile) {
				if (Std.is(e.target, Tile)) {
					var tile:Tile = cast e.target;
					if(tile.occupant == null) {
						selectedActor.stopDrag();
						tile.addOccupant(selectedActor);
					}
				}
			}
		}
	}
	
	override private function addListeners():Void {
		addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
		addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
		addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		addEventListener(Event.MOUSE_LEAVE, onMouseUp);
	}
	
	override private function removeListeners():Void {
		removeEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
		removeEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
		removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		removeEventListener(Event.MOUSE_LEAVE, onMouseUp);
	}
	
	public function cleanUp():Void {
		EditorDispatcher.getInstance().removeEventListener(Event.CHANGE, onEditorDispatch);
		removeListeners();
		removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
	}
}
