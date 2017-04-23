import luxe.Sprite;
import luxe.Vector;
import phoenix.Texture;
import luxe.Input.MouseEvent;
import luxe.Input.MouseButton;

class Arrow extends Sprite {

    var dir:Direction;
    var index:Int;
    var board:Board;
    var hover:Bool;

    public function new(dir:Direction, index:Int, board:Board) {
        this.dir = dir;
        this.index = index;
        this.board = board;
        hover = false;

        var tex = Luxe.resources.texture("assets/triangle.png");
        tex.filter_mag = tex.filter_min = FilterType.nearest;

        var pos = Luxe.screen.mid;
        var rot = 0;
        switch dir {
        case Up:
            pos.y -= Tile.SIZE * 3 - 21;
            pos.x = Board.LEFT + index * Tile.SIZE;
        case Down:
            pos.y += Tile.SIZE * 3 - 21;
            pos.x = Board.LEFT + index * Tile.SIZE;
            rot = 2;
        case Left:
            pos.x -= Tile.SIZE * 3 - 21;
            pos.y = Board.TOP + index * Tile.SIZE;
            rot = 3;
        case Right:
            pos.x += Tile.SIZE * 3 - 21;
            pos.y = Board.TOP + index * Tile.SIZE;
            rot = 1;
        }

        super({ name: "Arrow", name_unique: true, texture: tex,
            pos: pos, rotation_z: rot * 90 });

    }

    override function update(dt:Float) {
        if(hover)
            color.rgb(0xb0b0b0);
        else
            color.rgb(0xffffff);
        if(hover && Luxe.input.mousepressed(left)) {
            switch dir {
            case Up: board.shift_col(index, -1);
            case Down: board.shift_col(index, 1);
            case Left: board.shift_row(index, -1);
            case Right: board.shift_row(index, 1);
            }
        }
    }

    override function onmousemove(e:MouseEvent) {
        if(!board.dragging && point_inside_AABB(e.pos))
            hover = true;
        else
            hover = false;
    }

}
