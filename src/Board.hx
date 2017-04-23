import Tile;
import luxe.Sprite;
import luxe.Color;
import luxe.Vector;
import luxe.components.sprite.SpriteAnimation;
import luxe.Input.MouseEvent;
import luxe.Input.MouseButton;

class Board {

    private static inline var ROWS = 5;
    private static inline var COLUMNS = 5;
    public static inline var TOP = 320 - 16 - 16;
    public static inline var LEFT = 480 - 16 - 16;

    var current_tile:Tile;
    var tiles:Array<Array<Tile>>;
    var last_x:Int;
    var last_y:Int;
    var tile_bag:TileBag;
    var tile_preview_index:Int;
    var tile_preview:Sprite;
    var tile_preview_anim:SpriteAnimation;
    var tile_preview_rot:Int;

    var path_finding:Array<Tile>;
    var path_finding_checked:Array<Tile>;

    var drag_start:Vector;
    var dragging:Bool;
    var drag_tile_x:Int;
    var drag_tile_y:Int;
    var drag_orientation:Int;
    var shift_valid:Bool;

    public function new() {
        var spr = new Sprite({ name:"board", pos:Luxe.screen.mid, size:new Vector(ROWS * 16, COLUMNS * 16), color:new Color().rgb(0xffffff)});

        tiles = new Array<Array<Tile>>();
        for(i in 0...ROWS) {
            tiles.push(new Array<Tile>());
            for(j in 0...COLUMNS) {
                tiles[i].push(null);
                var spr = new Sprite({ name:"cell", name_unique: true, pos: new Vector(LEFT + j * 16, TOP + i * 16), size: new Vector(14, 14), color: new Color().rgb(0x000000)});
            }
        }



        var tex = Luxe.resources.texture("assets/tiles.png");
        tile_preview = new Sprite({ name:"preview", pos:new Vector(480, TOP - 24), texture:tex, size:new Vector(16, 16)});
        tile_preview_anim = tile_preview.add(new SpriteAnimation({name:"anim"}));
        tile_preview_anim.add_from_json('{"default":{"frame_size":{"x":16,"y":16},"frameset":["1-7"],"speed":0}}');
        tile_preview_anim.animation = "default";

        tile_bag = new TileBag();
        tile_preview_index = 1;
        next_tile(2, 2);

        drag_start = new Vector();
        dragging = false;
    }

    public function next_tile(x:Int, y:Int) {
        if(current_tile == null) {
            current_tile = new Tile(tile_preview_index, x, y);
            for(i in 0...tile_preview_rot) {
                current_tile.rotate(1);
            }
            preview_tile();
            place_tile();
        }
        else
            current_tile.placement(x, y);
    }

    public function place_tile() {
        tiles[current_tile.tile_y][current_tile.tile_x] = current_tile;
        last_x = current_tile.tile_x;
        last_y = current_tile.tile_y;

        for(t in find_completed_paths()) {
        //    if(current_tile == t)
        //        continue;
            tiles[t.tile_y][t.tile_x] = null;
            t.destroy();
        }

        current_tile = null;
    }

    public function preview_tile() {
        var info = tile_bag.next();
        tile_preview_index = info.index;
        tile_preview_anim.frame = tile_preview_index;
        tile_preview_rot = info.rotation;
        tile_preview.rotation_z = 90 * tile_preview_rot;
    }

    public function valid_placement(x:Int, y:Int):Bool {
        if(x < 0 || y < 0 || x >= 5 || y >= 5)
            return false;
        return tiles[y][x] == null;
    }

    public function valid_rotation():Bool {
        var valid = true;
        var tile:Tile;
        tile = get_tile(current_tile.tile_x, current_tile.tile_y - 1);
        if(tile != null) {
            if(current_tile.directions.has(Up) != tile.directions.has(Down))
                valid = false;
            else if(tile.directions.has(Down) && current_tile.type != tile.type)
                valid = false;
        }
        tile = get_tile(current_tile.tile_x, current_tile.tile_y + 1);
        if(tile != null) {
            if(current_tile.directions.has(Down) != tile.directions.has(Up))
                valid = false;
            else if(tile.directions.has(Up) && current_tile.type != tile.type)
                valid = false;
        }
        tile = get_tile(current_tile.tile_x - 1, current_tile.tile_y);
        if(tile != null) {
            if(current_tile.directions.has(Left) != tile.directions.has(Right))
                valid = false;
            else if(tile.directions.has(Right) && current_tile.type != tile.type)
                valid = false;
        }
        tile = get_tile(current_tile.tile_x + 1, current_tile.tile_y);
        if(tile != null) {
            if(current_tile.directions.has(Right) != tile.directions.has(Left))
                valid = false;
            else if(tile.directions.has(Left) && current_tile.type != tile.type)
                valid = false;
        }
        return valid;
    }

    private function get_tile(x:Int, y:Int):Tile {
        if(x < 0 || y < 0 || x >= 5 || y >= 5)
            return null;
        return tiles[y][x];
    }

    private function find_completed_paths():Array<Tile> {
        var all_paths:Array<Tile> = [];
        var path_finding:Array<Tile> = [];
        var path_finding_checked:Array<Tile> = [];

        for(row in tiles) {
            for(t in row) {
                if(t == null || path_finding_checked.indexOf(t) != -1)
                    continue;
                if(do_find_completed_paths(t, path_finding)) {
                    for(o in path_finding)
                        all_paths.push(o);
                }
                while(path_finding.length > 0) {
                    path_finding_checked.push(path_finding.pop());
                }
            }
        }
        return all_paths;
    }

    private function do_find_completed_paths(tile:Tile, path_finding:Array<Tile>):Bool {
        var hasEnd = true;

        if(tile.directions.has(Up)) {
            hasEnd = false;
            if(tile.tile_y == 0)
                hasEnd = true;
            else {
                var tile2 = get_tile(tile.tile_x, tile.tile_y - 1);
                if(tile2 != null && tile2.directions.has(Down) && tile2.type == tile.type) {
                    if(path_finding_push_exist(tile2, path_finding))
                        hasEnd = true;
                    else
                        hasEnd = do_find_completed_paths(tile2, path_finding);
                }
            }
        }
        if(!hasEnd)
            return false;

        if(tile.directions.has(Down)) {
            hasEnd = false;
            if(tile.tile_y == ROWS - 1)
                hasEnd = true;
            else {
                var tile2 = get_tile(tile.tile_x, tile.tile_y + 1);
                if(tile2 != null && tile2.directions.has(Up) && tile2.type == tile.type) {
                    if(path_finding_push_exist(tile2, path_finding))
                        hasEnd = true;
                    else
                        hasEnd = do_find_completed_paths(tile2, path_finding);
                }
            }
        }
        if(!hasEnd)
            return false;

        if(tile.directions.has(Left)) {
            hasEnd = false;
            if(tile.tile_x == 0)
                hasEnd = true;
            else {
                var tile2 = get_tile(tile.tile_x - 1, tile.tile_y);
                if(tile2 != null && tile2.directions.has(Right) && tile2.type == tile.type) {
                    if(path_finding_push_exist(tile2, path_finding))
                        hasEnd = true;
                    else
                        hasEnd = do_find_completed_paths(tile2, path_finding);
                }
            }
        }
        if(!hasEnd)
            return false;

        if(tile.directions.has(Right)) {
            hasEnd = false;
            if(tile.tile_x == COLUMNS - 1)
                hasEnd = true;
            else {
                var tile2 = get_tile(tile.tile_x + 1, tile.tile_y);
                if(tile2 != null && tile2.directions.has(Left) && tile2.type == tile.type) {
                    if(path_finding_push_exist(tile2, path_finding))
                        hasEnd = true;
                    else
                        hasEnd = do_find_completed_paths(tile2, path_finding);
                }
            }
        }
        if(!hasEnd)
            return false;

        return hasEnd;
    }

    private function path_finding_push_exist(tile:Tile, path_finding:Array<Tile>) {
        if(path_finding.indexOf(tile) == -1) {
            path_finding.push(tile);
            return false;
        }
        return true;
    }

    public function update(dt:Float) {
        if(Luxe.input.inputpressed("up") && valid_placement(last_x, last_y - 1))
            next_tile(last_x, last_y - 1);
        if(Luxe.input.inputpressed("down") && valid_placement(last_x, last_y + 1))
            next_tile(last_x, last_y + 1);
        if(Luxe.input.inputpressed("left") && valid_placement(last_x - 1, last_y))
            next_tile(last_x - 1, last_y);
        if(Luxe.input.inputpressed("right") && valid_placement(last_x + 1, last_y))
            next_tile(last_x + 1, last_y);

        if(current_tile == null)
            return;

        if(Luxe.input.inputpressed("rotate_left"))
            current_tile.rotate(-1);
        else if(Luxe.input.inputpressed("rotate_right"))
            current_tile.rotate(1);

        if(valid_rotation()) {
            current_tile.color = new luxe.Color().rgb(0xffffff);
            if(Luxe.input.inputpressed("place"))
                place_tile();
        }
        else
            current_tile.color = new luxe.Color().rgb(0xff0000);
    }

    public function onmousedown(e:MouseEvent) {
        if(!dragging && e.button == MouseButton.left) {
            var mid = Luxe.screen.mid;
            if(e.pos.x > mid.x - 80 && e.pos.y > mid.y - 80 && e.pos.x < mid.x + 80 && e.pos.y < mid.y + 80) {
                dragging = true;
                drag_start.copy_from(e.pos);
                drag_tile_x = Math.floor((drag_start.x - (mid.x - 80)) / 32);
                drag_tile_y = Math.floor((drag_start.y - (mid.y - 80)) / 32);
                drag_orientation = 0;
            }
        }
    }

    public function onmousemove(e:MouseEvent) {
        if(dragging) {
            var diff = e.pos.clone().subtract(drag_start);

            if(drag_orientation == 0) {
                if(Math.abs(diff.x) >= 4 || Math.abs(diff.y) >= 4) {
                    drag_orientation = Math.abs(diff.x) > Math.abs(diff.y) ? -1 : 1;
                    shift_valid = false;
                }
            }
            else if(drag_orientation == -1){
                if(Math.abs(diff.x) < 4) {
                    drag_orientation = 0;
                    for(i in 0...COLUMNS) {
                        var t = get_tile(i, drag_tile_y);
                        if(t != null)
                            t.offset.set_xy(0, 0);
                    }
                    drag_start.copy_from(e.pos);
                }
            }
            else if(drag_orientation == 1){
                if(Math.abs(diff.y) < 4) {
                    drag_orientation = 0;
                    for(i in 0...ROWS) {
                        var t = get_tile(drag_tile_x, i);
                        if(t != null)
                            t.offset.set_xy(0, 0);
                    }
                    drag_start.copy_from(e.pos);
                }
            }

            if(drag_orientation == -1) {
                if(diff.x > 16) diff.x = 16;
                else if(diff.x < -16) diff.x = -16;
                var shiftable = false;
                for(i in 0...COLUMNS) {
                    if(diff.x < 0) {
                        var t = get_tile(i, drag_tile_y);
                        if(!shiftable)
                            shiftable = tile_has_empty_space(i, drag_tile_y, Left);
                        if(t != null && shiftable) {
                            shift_valid = true;
                            t.offset.set_xy(diff.x, 0);
                        }
                    }
                    else {
                        var t = get_tile(COLUMNS - 1 - i, drag_tile_y);
                        if(!shiftable)
                            shiftable = tile_has_empty_space(COLUMNS - 1 - i, drag_tile_y, Right);
                        if(t != null && shiftable) {
                            shift_valid = true;
                            t.offset.set_xy(diff.x, 0);
                        }
                    }
                }
            }
            else if(drag_orientation == 1){
                if(diff.y > 16) diff.y = 16;
                else if(diff.y < -16) diff.y = -16;
                var shiftable = false;
                for(i in 0...ROWS) {
                    if(diff.y < 0) {
                        var t = get_tile(drag_tile_x, i);
                        if(!shiftable)
                            shiftable = tile_has_empty_space(drag_tile_x, i, Up);
                        if(t != null && shiftable) {
                            shift_valid = true;
                            t.offset.set_xy(0, diff.y);
                        }
                    }
                    else {
                        var t = get_tile(drag_tile_x, ROWS - 1 - i);
                        if(!shiftable)
                            shiftable = tile_has_empty_space(drag_tile_x, ROWS - 1 - i, Down);
                        if(t != null && shiftable) {
                            shift_valid = true;
                            t.offset.set_xy(0, diff.y);
                        }
                    }
                }
            }
        }
    }

    public function onmouseup(e:MouseEvent) {
        if(e.button == MouseButton.left) {
            dragging = false;

            var diff = e.pos.clone().subtract(drag_start);
            var adx = Math.abs(diff.x);
            var ady = Math.abs(diff.y);
            if(adx < 8 && ady < 8 || !shift_valid) {
                for(i in 0...COLUMNS) {
                    var t = get_tile(i, drag_tile_y);
                    if(t != null)
                        t.offset.set_xy(0, 0);
                }
                for(i in 0...ROWS) {
                    var t = get_tile(drag_tile_x, i);
                    if(t != null)
                        t.offset.set_xy(0, 0);
                }
            }
            else if(adx > ady) {
                drag_row(drag_tile_y, Math.round(diff.x));
            }
            else {
                drag_col(drag_tile_x, Math.round(diff.y));
            }
        }
    }

    private function drag_row(index:Int, dir:Int) {
        for(i in 0...COLUMNS) {
            if(dir < 0) {
                shift_tile(i, index, Left);
            }
            else {
                shift_tile(COLUMNS - 1 - i, index, Right);
            }
        }
        next_tile(dir >= 0 ? 0 : COLUMNS - 1, index);
    }

    private function drag_col(index:Int, dir:Int) {
        for(i in 0...ROWS) {
            if(dir < 0) {
                shift_tile(index, i, Up);
            }
            else {
                shift_tile(index, ROWS - 1 - i, Down);
            }
        }
        next_tile(index, dir >= 0 ? 0 : ROWS - 1);
    }

    private function tile_has_empty_space(x:Int, y:Int, dir:Direction):Bool {
        var t = get_tile(x, y);
        if(t == null)
            return true;
        switch dir {
            case Left:
                if(x == 0)
                    return false;
                else
                    return get_tile(x - 1, y) == null;
            case Right:
                if(x == COLUMNS - 1)
                    return false;
                else
                    return get_tile(x + 1, y) == null;
            case Up:
                if(y == 0)
                    return false;
                else
                    return get_tile(x, y - 1) == null;
            case Down:
                if(y == ROWS - 1)
                    return false;
                else
                    return get_tile(x, y + 1) == null;
        }
    }

    private function shift_tile(x:Int, y:Int, dir:Direction) {
        var t = get_tile(x, y);
        if(t == null)
            return;

        switch dir {
        case Left:
            if(x == 0)
                return;
            else {
                var t0 = get_tile(x - 1, y);
                if(t0 == null) {
                    t.placement(x - 1, y);
                    tiles[y][x - 1] = t;
                    tiles[y][x] = null;
                }
            }
        case Right:
            if(x == COLUMNS - 1)
                return;
            else {
                var t0 = get_tile(x + 1, y);
                if(t0 == null) {
                    t.placement(x + 1, y);
                    tiles[y][x + 1] = t;
                    tiles[y][x] = null;
                }
            }
        case Up:
            if(y == 0)
                return;
            else {
                var t0 = get_tile(x, y - 1);
                if(t0 == null) {
                    t.placement(x, y - 1);
                    tiles[y - 1][x] = t;
                    tiles[y][x] = null;
                }
            }
        case Down:
            if(y == ROWS - 1)
                return;
            else {
                var t0 = get_tile(x, y + 1);
                if(t0 == null) {
                    t.placement(x, y + 1);
                    tiles[y + 1][x] = t;
                    tiles[y][x] = null;
                }
            }
        }
    }

}
