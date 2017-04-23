import Tile;
import luxe.Sprite;
import luxe.Color;
import luxe.Vector;
import luxe.components.sprite.SpriteAnimation;
import luxe.Input.MouseEvent;
import luxe.Input.MouseButton;
import phoenix.Texture;
import luxe.tween.Actuate;
import luxe.tween.easing.*;
import luxe.Text;
import phoenix.BitmapFont;
import luxe.Entity;
import luxe.resource.Resource;

class Board extends Entity {

    private static inline var ROWS = 5;
    private static inline var COLUMNS = 5;
    public static inline var TOP = 320 - Tile.SIZE - Tile.SIZE;
    public static inline var LEFT = 200 - Tile.SIZE - Tile.SIZE;

    var current_tile:Tile;
    var tiles:Array<Array<Tile>>;
    var last_x:Int;
    var last_y:Int;
    var tile_bag:TileBag;
    var tile_preview_index:Int;
    var tile_preview:Sprite;
    var tile_preview_anim:SpriteAnimation;
    var tile_preview_rot:Int;
    var arrows:Array<Arrow>;
    var font:BitmapFont;
    var slide_sound:AudioResource;
    var score_sound:AudioResource;

    var drag_start:Vector;
    public var dragging:Bool;
    var drag_tile_x:Int;
    var drag_tile_y:Int;
    var drag_orientation:Int;
    var shift_valid:Bool;
    var shifting:Bool;

    public function new() {
        super({ name: "Board" });
    }

    override function init() {
        var tex = Luxe.resources.texture("assets/board.png");
        tex.filter_mag = tex.filter_min = FilterType.nearest;
        var spr = new Sprite({ name:"board", pos:Luxe.screen.mid, texture:tex });

        font = Luxe.resources.font('assets/font.fnt');
        var t = new Text({
            name: "next",
            text: "next",
            pos: Luxe.screen.mid.subtract_xyz(0, Tile.SIZE * 4 + 12),
            point_size : 24,
            font: font,
            sdf: true,
            align: TextAlign.center,
            align_vertical: TextAlign.center,
            color: new Color().rgb(0xcbdbfc)
        });

        tiles = new Array<Array<Tile>>();
        for(i in 0...ROWS) {
            tiles.push(new Array<Tile>());
            for(j in 0...COLUMNS) {
                tiles[i].push(null);
            }
        }

        var tex = Luxe.resources.texture("assets/tiles.png");
        tile_preview = new Sprite({ name:"preview",
            pos:Luxe.screen.mid.subtract_xyz(0, Tile.SIZE * 3.5),
            texture:tex, size:new Vector(Tile.SIZE, Tile.SIZE)});
        tile_preview_anim = tile_preview.add(new SpriteAnimation({name:"anim"}));
        tile_preview_anim.add_from_json('{"default":{"frame_size":{"x":64,"y":64},"frameset":["1-20"],"speed":0}}');
        tile_preview_anim.animation = "default";
        arrows = [];

        tile_bag = new TileBag();
        tile_preview_index = tile_bag.next().index;
        next_tile(2, 2);

        drag_start = new Vector();
        dragging = false;
        shifting = false;

        slide_sound = Luxe.resources.audio("assets/slide.wav");
        score_sound = Luxe.resources.audio("assets/score.wav");
    }

    private function next_tile(x:Int, y:Int) {
        current_tile = new Tile(tile_preview_index, x, y);
        // for(i in 0...tile_preview_rot) {
        //     current_tile.rotate(1);
        // }
        preview_tile();
        place_tile();

        var rows = [];
        var cols = [];
        for(i in 0...ROWS) {
            for(j in 0...COLUMNS) {
                if(tiles[i][j] != null) {
                    if(rows.indexOf(i) == -1)
                        rows.push(i);
                    if(cols.indexOf(j) == -1)
                        cols.push(j);
                }
            }
        }

        while(arrows.length > 0) {
            arrows.pop().destroy();
        }

        for(index in rows) {
            var shiftable_left = false;
            var shiftable_right = false;
            for(i in 0...COLUMNS) {
                var t = get_tile(i, index);
                if(!shiftable_left) {
                    if(t != null && tile_has_empty_space(i, index, Left))
                        shiftable_left = true;
                }
                t = get_tile(COLUMNS - 1 - i, index);
                if(!shiftable_right) {
                    if(t != null && tile_has_empty_space(COLUMNS - 1 - i, index, Right))
                        shiftable_right = true;
                }
            }
            if(shiftable_left)
                arrows.push(new Arrow(Left, index, this));
            if(shiftable_right)
                arrows.push(new Arrow(Right, index, this));
        }

        for(index in cols) {
            var shiftable_up = false;
            var shiftable_down = false;
            for(i in 0...ROWS) {
                var t = get_tile(index, i);
                if(!shiftable_up) {
                    if(t != null && tile_has_empty_space(index, i, Up))
                        shiftable_up = true;
                }
                t = get_tile(index, ROWS - 1 - i);
                if(!shiftable_down) {
                    if(t != null && tile_has_empty_space(index, ROWS - 1 - i, Down))
                        shiftable_down = true;
                }
            }
            if(shiftable_up)
                arrows.push(new Arrow(Up, index, this));
            if(shiftable_down)
                arrows.push(new Arrow(Down, index, this));
        }

    }

    private function place_tile() {
        tiles[current_tile.tile_y][current_tile.tile_x] = current_tile;
        last_x = current_tile.tile_x;
        last_y = current_tile.tile_y;

        clear_tiles(find_completed_paths());

        var full = true;
        for(row in tiles) {
            for(t in row) {
                if(t == null) {
                    full = false;
                    break;
                }
            }
            if(!full)
                break;
        }
        if(full) { // game over
            tile_preview.destroy();
            var text:Text = Luxe.scene.get("next");
            text.destroy();
            events.fire("on_game_over");
        }

        current_tile = null;
    }

    private function clear_tiles(list:Array<Tile>) {
        if(list.length == 0)
            return;

        list.sort(function(a, b) {
            var i = a.tile_y * COLUMNS + a.tile_x;
            var j = b.tile_y * COLUMNS + b.tile_x;
            return i > j ? 1 : -1;
        });

        var i = 0;
        var total = 0;
        for(t in list) {
            tiles[t.tile_y][t.tile_x] = null;
            Actuate.tween(t.size, 0.35, {x: Tile.SIZE * 1.1, y: Tile.SIZE * 1.1})
                .delay(i++ * 0.2)
                .onComplete(function() {
                    t.size.set_xy(Tile.SIZE, Tile.SIZE);
                    Actuate.tween(t.color, 0.5, {a: 0}).onComplete(function() {
                        t.destroy();
                    });
                });

            var score = Math.round(Math.pow(2, i) * 5);
            var text = new Text({
                text: Std.string(score),
                pos: new Vector(LEFT + t.tile_x * Tile.SIZE, TOP + t.tile_y * Tile.SIZE - 16),
                point_size : 36,
                font: font,
                sdf: true,
                align: TextAlign.center,
                align_vertical: TextAlign.center,
                color: new Color().rgb(0xcbdbfc),
                outline: 0.1,
                outline_color: new Color().rgb(0x306082)
            });
            Actuate.tween(text.color, 0.45, {a:0}).delay(0.75 + i * 0.2);
            Actuate.tween(text.pos, 0.5, {y: text.pos.y - 32})
                .delay(0.75 + i * 0.2)
                .onComplete(function() {
                    text.destroy();
                });

            Luxe.timer.schedule((i - 1) * 0.2, Luxe.audio.play.bind(score_sound.source));


            total += score;
        }

        events.fire("Board.on_score", total);
    }

    private function preview_tile() {
        var info = tile_bag.next();
        tile_preview_index = info.index;
        tile_preview_anim.frame = tile_preview_index;
        tile_preview_rot = info.rotation;
        tile_preview.rotation_z = 90 * tile_preview_rot;
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

    override function update(dt:Float) {

    }

    override function onmousedown(e:MouseEvent) {
        if(!dragging && e.button == MouseButton.left) {
            if(shifting)
                return;
            var mid = Luxe.screen.mid;
            var half = Tile.SIZE * 2.5 - 16;
            if(e.pos.x > mid.x - half && e.pos.y > mid.y - half &&
                e.pos.x < mid.x + half && e.pos.y < mid.y + half) {
                dragging = true;
                drag_start.copy_from(e.pos);
                drag_tile_x = Math.floor((drag_start.x - (mid.x - half)) / Tile.SIZE);
                drag_tile_y = Math.floor((drag_start.y - (mid.y - half)) / Tile.SIZE);
                drag_orientation = 0;
            }
        }
    }

    override function onmousemove(e:MouseEvent) {
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
                if(diff.x > Tile.SIZE) diff.x = Tile.SIZE;
                else if(diff.x < -Tile.SIZE) diff.x = -Tile.SIZE;
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
                if(diff.y > Tile.SIZE) diff.y = Tile.SIZE;
                else if(diff.y < -Tile.SIZE) diff.y = -Tile.SIZE;
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

    override function onmouseup(e:MouseEvent) {
        if(dragging && e.button == MouseButton.left) {
            dragging = false;

            var diff = e.pos.clone().subtract(drag_start);
            var adx = Math.abs(diff.x);
            var ady = Math.abs(diff.y);
            if(adx < Tile.SIZE / 2 && ady < Tile.SIZE / 2 || !shift_valid) {
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
                shift_row(drag_tile_y, Math.round(diff.x));
            }
            else {
                shift_col(drag_tile_x, Math.round(diff.y));
            }
        }
    }

    public function shift_row(index:Int, dir:Int) {
        if(shifting)
            return;
        for(i in 0...COLUMNS) {
            if(dir < 0) {
                shift_tile(i, index, Left);
            }
            else {
                shift_tile(COLUMNS - 1 - i, index, Right);
            }
        }
        next_tile(dir >= 0 ? 0 : COLUMNS - 1, index);
        Luxe.audio.play(slide_sound.source, 0.75);
        shifting = true;
        Luxe.timer.schedule(0.4, function() { shifting = false; });
    }

    public function shift_col(index:Int, dir:Int) {
        if(shifting)
            return;
        for(i in 0...ROWS) {
            if(dir < 0) {
                shift_tile(index, i, Up);
            }
            else {
                shift_tile(index, ROWS - 1 - i, Down);
            }
        }
        next_tile(index, dir >= 0 ? 0 : ROWS - 1);
        Luxe.audio.play(slide_sound.source, 0.75);
        shifting = true;
        Luxe.timer.schedule(0.4, function() { shifting = false; });
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
                    t.shift(-1, 0);
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
                    t.shift(1, 0);
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
                    t.shift(0, -1);
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
                    t.shift(0, 1);
                    tiles[y + 1][x] = t;
                    tiles[y][x] = null;
                }
            }
        }
    }

}
