package;


enum abstract ImageSizes(Int) from Int to Int {
	var screenHeight = 600;
	var screenWidth = 800;
	var spriteFrames = 3;
	var catScalePercent = 20;
	var mouseScalePercent = 10;
}

enum abstract LaserNumbers(Int) from Int to Int {
	var eyePulseMin = 8;
	var eyePulseMax = 15;
	var eyeOffsetX = 40;
	var eyeOffsetY = 15;
	var colour = 0xFF33CC;
	var width = 10;
	var squareOfMaxLaserDistance = 40000;
	var damage = 5;

	@:op(A>B) private static function gt(lhs:LaserNumbers, rhs:LaserNumbers):Bool;
	@:op(A>=B) private static function gte(lhs:LaserNumbers, rhs:LaserNumbers):Bool;
	@:op(A<B) private static function lt(lhs:LaserNumbers, rhs:LaserNumbers):Bool;
	@:op(A<=B) private static function lte(lhs:LaserNumbers, rhs:LaserNumbers):Bool;
}

enum abstract MouseNumbers(Int) from Int to Int {
	var initialCount = 4;
	var maxCount = 230;
	var breedChance = 50;
	var directionChance = 50;
	var distanceMin = 1;
	var distanceMax = 10;

	@:op(A>B) private static function gt(lhs:MouseNumbers, rhs:MouseNumbers):Bool;
	@:op(A>=B) private static function gte(lhs:MouseNumbers, rhs:MouseNumbers):Bool;
	@:op(A<B) private static function lt(lhs:MouseNumbers, rhs:MouseNumbers):Bool;
	@:op(A<=B) private static function lte(lhs:MouseNumbers, rhs:MouseNumbers):Bool;
}

enum abstract MouseDirection(Int) from Int to Int {
	var Right;
	var Down;
	var Left;
	var Up;
	var All;
}

enum abstract WinningNumbers(Int) from Int to Int {
	var size = 100;
	var colour = 0xFFFFFF;
	var dropShadowX = 7;
	var dropShadowY = 5;
	var dropShadowColour = 0x909090;
}

enum abstract TextStrings(String) from String to String {
	var winner = "Winner!";
	var paused = "Paused";
}

class Utils {
	static public function randomInt(start:Int, end:Int):Int {
		var multiplier = end - start;
		return Math.floor(Math.random() * multiplier) + start;
	}

	static inline public function randomChance(chance:Int):Bool {
		return randomInt(0, chance) == 0;
	}
}

class Main extends hxd.App {

	var spriteTileSplit:Array<h2d.Tile>;
	var cat:h2d.SpriteBatch;
	var catFace:Cat;
	var catEyes:Cat;
	var laser:h2d.Graphics;
	var mice:h2d.SpriteBatch;
	var music:hxd.snd.Channel;
	var pausedOverlay:h2d.Bitmap;
	var pausedText:h2d.Text;
	var winningText:h2d.Text;

	var paused:Bool = false;
	var winner:Bool = false;

	override function init() {
		hxd.System.setNativeCursor(hxd.Cursor.Hide);

		s2d.scaleMode = h2d.Scene.ScaleMode.LetterBox(ImageSizes.screenWidth, ImageSizes.screenHeight);
		var sprites = hxd.Res.sprites.toTile();
		spriteTileSplit = sprites.split(ImageSizes.spriteFrames, true);
		cat = new h2d.SpriteBatch(sprites);
		cat.hasUpdate = true;
		cat.hasRotationScale = true;

		catFace = new Cat(spriteTileSplit[0]);
		cat.add(catFace);
		catEyes = new Cat(spriteTileSplit[1]);
		s2d.addChild(cat);

		mice = new h2d.SpriteBatch(sprites);
		mice.hasUpdate = true;
		mice.hasRotationScale = true;
		for (i in 0...MouseNumbers.initialCount) {
			var mouse = new Mouse(spriteTileSplit[2]);
			mice.add(mouse);
			mouse.x = ImageSizes.screenWidth / 2;
			mouse.y = ImageSizes.screenHeight / 2;
		}
		s2d.addChild(mice);
		laser = new h2d.Graphics(s2d);

		var font = hxd.res.DefaultFont.get();
		font.resizeTo(WinningNumbers.size);

		winningText = new h2d.Text(font);
		winningText.text = TextStrings.winner;
		winningText.textColor = WinningNumbers.colour;
		winningText.dropShadow = {
			dy: WinningNumbers.dropShadowY,
			dx: WinningNumbers.dropShadowX,
			color: WinningNumbers.dropShadowColour,
			alpha: 1
		};

		pausedText = new h2d.Text(font);
		pausedText.text = TextStrings.paused;
		pausedText.textColor = WinningNumbers.colour;
		pausedText.dropShadow = {
			dy: WinningNumbers.dropShadowY,
			dx: WinningNumbers.dropShadowX,
			color: WinningNumbers.dropShadowColour,
			alpha: 1
		};
		pausedOverlay = new h2d.Bitmap(h2d.Tile.fromColor(0, s2d.width, s2d.height, 0.5));

		music = hxd.Res.gaslampfunworks.play(true, 0.25);

		s2d.addEventListener(checkPause);
	}

	function checkPause(event:hxd.Event) {
		switch(event.kind) {
			case EFocusLost:
				paused = true;
			case EKeyDown:
				if (event.keyCode == hxd.Key.P) {
					paused = !paused;
				} else {
					paused = false;
				}
			case EPush:
				paused = false;
			default:
		}

		music.pause = paused;

		if (!winner) {
			for (mouse in mice.getElements()) {
				cast(mouse, Mouse).paused = paused;
			}

			if (paused && pausedText.parent == null) {
				s2d.addChild(pausedOverlay);
				s2d.addChild(pausedText);
				pausedText.x = screenWidth / 2 - pausedText.textWidth / 2;
				pausedText.y = screenHeight / 2 - pausedText.textHeight / 2;
			} else if (!paused && pausedText.parent != null) {
				s2d.removeChild(pausedOverlay);
				s2d.removeChild(pausedText);
			}
		}
	}

	override function update(dt:Float) {
		if (paused) {
			return;
		}

		laser.clear();
		catEyes.remove();
		catFace.x = s2d.mouseX - catFace.scaledWidth * 0.5;
		catFace.y = s2d.mouseY - catFace.scaledHeight * 0.5;

		if (winner) {
			return;
		}

		var miceArray = [for (m in mice.getElements()) cast(m, Mouse)];
		if (miceArray.length > 0) {
			if (hxd.Key.isDown(hxd.Key.MOUSE_LEFT)) {
				cat.add(catEyes);
				catEyes.x = catFace.x;
				catEyes.y = catFace.y;
				var catCentre = catFace.centre;
				for (chosenMouse in miceArray) {
					var mouseCentre = chosenMouse.centre;
					var distance = Math.pow(catCentre[0] - mouseCentre[0], 2) + Math.pow(catCentre[1] - mouseCentre[1], 2);
					if (Math.floor(distance) <= LaserNumbers.squareOfMaxLaserDistance) {
						fireAt(chosenMouse, catCentre, mouseCentre);
						break;
					}
				}
			}

			if (miceArray.length < MouseNumbers.maxCount && Utils.randomChance(MouseNumbers.breedChance)) {
				var lastMouse = miceArray.pop();
				var mouse = new Mouse(spriteTileSplit[2]);
				mice.add(mouse);
				mouse.x = lastMouse.x;
				mouse.y = lastMouse.y;
			}
		} else {
			winner = true;
			s2d.addChild(winningText);
			s2d.under(winningText);
			winningText.x = screenWidth / 2 - winningText.textWidth / 2;
			winningText.y = screenHeight / 2 - winningText.textHeight / 2;
		}
	}

	function fireAt(mouse:Mouse, catCentre:Array<Float>, mouseCentre:Array<Float>) {
		var rightEyeX = catCentre[0] + LaserNumbers.eyeOffsetX;
		var rightEyeY = catCentre[1] + LaserNumbers.eyeOffsetY;
		var leftEyeX = catCentre[0] - LaserNumbers.eyeOffsetX;
		var leftEyeY = rightEyeY;

		laser.beginFill(0, 0);
		laser.lineStyle(LaserNumbers.width, LaserNumbers.colour);

		laser.moveTo(rightEyeX, rightEyeY);
		laser.lineTo(mouseCentre[0], mouseCentre[1]);
		laser.moveTo(leftEyeX, leftEyeY);
		laser.lineTo(mouseCentre[0], mouseCentre[1]);

		var eyePulse = Utils.randomInt(LaserNumbers.eyePulseMin, LaserNumbers.eyePulseMax);
		laser.beginFill(LaserNumbers.colour, 1);
		laser.lineStyle(0, 0, 0);
		laser.drawCircle(rightEyeX, rightEyeY, eyePulse);
		laser.drawCircle(leftEyeX, leftEyeY, eyePulse);
		laser.drawCircle(mouseCentre[0], mouseCentre[1], Utils.randomInt(LaserNumbers.eyePulseMin, LaserNumbers.eyePulseMax));
		laser.endFill();

		mouse.hit();
	}

	static function main() {
		hxd.Res.initEmbed();
		new Main();
	}
}


class ElementWithCentre extends h2d.SpriteBatch.BatchElement {
	public var centre(get,null): Array<Float>;
	public var scaledHeight(get,null): Float;
	public var scaledWidth(get,null): Float;

	function get_centre() {
		return [
			x + scaledWidth * 0.5,
			y + scaledHeight * 0.5,
		];
	}

	function get_scaledWidth() {
		return t.width * scaleX;
	}

	function get_scaledHeight() {
		return t.height * scaleY;
	}
}


class Cat extends ElementWithCentre {

	public function new(t:h2d.Tile) {
		super(t);
		scale = ImageSizes.catScalePercent / 100;
	}

}

class Mouse extends ElementWithCentre {

	var health:Int = 100;
	var direction:Int;
	public var paused:Bool = false;

	public function new(t:h2d.Tile) {
		super(t);
		scale = ImageSizes.mouseScalePercent / 100;
		changeDirection();
	}

	function changeDirection() {
		direction = Utils.randomInt(0, 4);
	}

	override function update(dt:Float) {
		if (paused) {
			return true;
		}
		var distance = Utils.randomInt(MouseNumbers.distanceMin, MouseNumbers.distanceMax);
		var change = Utils.randomChance(MouseNumbers.directionChance);

		super.update(dt);

		switch (direction) {
			case MouseDirection.Right:
				x += distance;
				var max = ImageSizes.screenWidth - scaledWidth;
				if (x > max) {
					x = max;
					direction = MouseDirection.Left;
					change = false;
				}
			case MouseDirection.Left:
				x -= distance;
				if (x < 0) {
					x = 0;
					direction = MouseDirection.Right;
					change = false;
				}
			case MouseDirection.Down:
				y += distance;
				var max = ImageSizes.screenHeight - scaledHeight;
				if (y > max) {
					y = max;
					direction = MouseDirection.Up;
					change = false;
				}
			case MouseDirection.Up:
				y -= distance;
				if (y < 0) {
					y = 0;
					direction = MouseDirection.Down;
					change = false;
				}
			default:
		}

		if (change) {
			changeDirection();
		}

		return true;
	}

	public function hit() {
		health -= LaserNumbers.damage;
		if (health <= 0) {
			remove();
		}
	}
}
