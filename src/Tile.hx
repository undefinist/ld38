import luxe.Sprite;
import luxe.Vector;
import luxe.components.sprite.SpriteAnimation;

class Tile extends Sprite {

    private static var tile_connections:Array<Direction> = [
        Right, Left | Right, Up | Down | Left | Right, Up | Left,
        Right, Left | Right, Up | Left
    ];

    public var type:TileType;
    public var directions:Direction;
    var index:Int;
    public var tile_x:Int;
    public var tile_y:Int;

    public var offset:Vector;

    public function new(index:Int, x:Int, y:Int) {
        this.index = index;
        directions = tile_connections[index - 1];
        type = index <= 4 ? River : Road;

        var tex = Luxe.resources.texture("assets/tiles.png");

        super({ name: "tile", name_unique: true, texture: tex,
            size: new Vector(16, 16) });

        offset = new Vector();
        placement(x, y);
    }

    override function init() {
        var anim:SpriteAnimation = add(new SpriteAnimation({name:"anim"}));
        anim.add_from_json('{"default":{"frame_size":{"x":16,"y":16},"frameset":["1-7"],"speed":0}}');
        anim.animation = "default";
        anim.frame = index;
    }

    public function rotate(dir:Int) {
        directions = directions.rotate(dir);
        rotation_z += dir * 90;
    }

    public function placement(x:Int, y:Int) {
        pos.set_xy(Board.LEFT + x * 16, Board.TOP + y * 16);
        tile_x = x;
        tile_y = y;
        offset.set_xy(0, 0);
    }

    override function update(dt:Float) {
        pos.set_xy(Board.LEFT + tile_x * 16 + offset.x, Board.TOP + tile_y * 16 + offset.y);
    }

}

@:enum
abstract TileType(Int) from Int to Int {
    var River = 1;
    var Road = 2;
}

@:enum
abstract Direction(Int) from Int to Int {
    var Up = 1;
    var Right = 2;
    var Down = 4;
    var Left = 8;

    public inline function rotate(dir:Int) {
        if(dir >= 0) { // clockwise
            var lbit = (this & 8) >> 3;
            return (this << 1) & 15 | lbit;
            // lshift by 1 and wrap the lmost bit
        }
        else { // anti-clockwise
            var rbit = this & 1;
            return (this >> 1) & 15 | (rbit << 3);
            // rshift by 1 and wrap the rmost bit
        }
    }

    public inline function has(value:Direction):Bool {
        return this & value != 0;
    }
}

typedef TileInfo = {
    var index:Int;
    var rotation:Int;
}
