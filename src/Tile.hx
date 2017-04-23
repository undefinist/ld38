import luxe.Sprite;
import luxe.Vector;
import luxe.components.sprite.SpriteAnimation;
import Direction;
import luxe.tween.Actuate;
import luxe.tween.easing.*;

class Tile extends Sprite {

    public static inline var SIZE:Int = 64;

    private static var tile_connections:Array<Direction> = [
        Right, Left, Up, Down,
        Left | Up, Up | Right, Right | Down, Down | Left,
        Left | Right, Up | Down, Left | Right, Up | Down,
        Left | Up, Up | Right, Right | Down, Down | Left,
        Right, Left, Up, Down
    ];

    public var type:TileType;
    public var directions:Direction;
    var index:Int;
    public var tile_x:Int;
    public var tile_y:Int;
    public var visual_pos:Vector;

    public var offset:Vector;

    public function new(index:Int, x:Int, y:Int) {
        this.index = index;
        directions = tile_connections[index - 1];
        type = index <= 10 ? River : Road;

        var tex = Luxe.resources.texture("assets/tiles.png");

        super({ name: "tile", name_unique: true, texture: tex,
            size: new Vector(Tile.SIZE, Tile.SIZE) });
        color.a = 0;
        Actuate.tween(color, 0.5, {a:1}).ease(Quint.easeOut);

        visual_pos = new Vector();
        offset = new Vector();
        placement(x, y);
    }

    override function init() {
        var anim:SpriteAnimation = add(new SpriteAnimation({name:"anim"}));
        anim.add_from_json('{"default":{"frame_size":{"x":64,"y":64},"frameset":["1-20"],"speed":0}}');
        anim.animation = "default";
        anim.frame = index;
    }

    public function rotate(dir:Int) {
        directions = directions.rotate(dir);
        rotation_z += dir * 90;
    }

    public function placement(x:Int, y:Int) {
        tile_x = x;
        tile_y = y;
        offset.set_xy(0, 0);
        visual_pos.set_xy(Board.LEFT + x * Tile.SIZE, Board.TOP + y * Tile.SIZE);
    }

    public function shift(offset_x:Int, offset_y:Int) {
        tile_x += offset_x;
        tile_y += offset_y;
        Actuate.tween(offset, 0.35, {x: offset_x * SIZE, y: offset_y * SIZE})
            .ease(Quint.easeOut)
            .onComplete(function() {
                placement(tile_x, tile_y);
            });
        size.x = SIZE * 0.8;
        size.y = SIZE * 1.1;
        if(offset_x > offset_y) {
            size.x = SIZE * 1.1;
            size.y = SIZE * 0.8;
        }
        Actuate.tween(size, 0.34, {x: SIZE, y: SIZE}).ease(Quint.easeOut);
    }

    override function update(dt:Float) {
        pos.copy_from(visual_pos).add(offset);
    }

}

@:enum
abstract TileType(Int) from Int to Int {
    var River = 1;
    var Road = 2;
}

typedef TileInfo = {
    var index:Int;
    var rotation:Int;
}
