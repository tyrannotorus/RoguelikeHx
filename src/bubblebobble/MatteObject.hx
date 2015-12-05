package bubblebobble;

import com.tyrannotorus.utils.Colors;
import com.tyrannotorus.utils.Constants;

/**
 * MatteObject.hx
 * Matte Object parameter for user with Matte.as.
 */
class MatteObject {
	
	public var primaryColor:Int = Colors.GALLERY;
	public var borderColor:Int = Colors.DUSTY_GREY;
	public var borderWidth:Int = 1;
	public var topRadius:Int = 1;
	public var bottomRadius:Int = 1;
	public var width:Int = 100;
	public var height:Int = 100;
	public var shadowColor:Int = Colors.TRANSPARENT;
	public var shadowOffsetX:Int = 1;
	public var shadowOffsetY:Int = 1;
		
	/**
	 * Constructor.
	 * @param {Dynamic} parameters
	 */
	public function new(parameters:Dynamic = null) {
		
		// No parameters were passed. Use default values.
		if (parameters == null) {
			return;
		}
		
		// Set our local variables according the the parameters parameter.
		for (fieldName in Reflect.fields(parameters)) {

			if (!Reflect.hasField(this, fieldName)) {
				trace("MatteObject.new() Uknown parameter " + fieldName + " passed");
				continue;
			}
			
			Reflect.setField(this, fieldName, Reflect.field(parameters, fieldName));
		}
	}
}
