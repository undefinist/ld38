
import luxe.GameConfig;
import luxe.Input;
import luxe.Vector;
import phoenix.Texture;
import luxe.Sprite;
import luxe.Input.MouseEvent;
import luxe.Text;
import phoenix.BitmapFont;
import luxe.Color;
import luxe.tween.easing.*;
import luxe.tween.Actuate;

class Main extends luxe.Game {

    var board:Board;
    var score:Int;
    var score_text:Text;
    var visual_score:Float;
    var is_game_over:Bool;

    override function config(config:GameConfig) {

        config.window.title = 'luxe game';
        config.window.width = 400;
        config.window.height = 640;
        config.window.fullscreen = false;

        config.preload.textures.push({ id: "assets/tiles.png" });
        config.preload.textures.push({ id: "assets/board.png" });
        config.preload.textures.push({ id: "assets/triangle.png" });
        config.preload.fonts.push({ id:'assets/font.fnt' });
        config.preload.sounds.push({ id:'assets/slide.wav', is_stream: false });
        config.preload.sounds.push({ id:'assets/score.wav', is_stream: false });

        return config;

    } //config

    override function ready() {

        Luxe.renderer.clear_color.rgb(0x306082);

        var tex = Luxe.resources.texture("assets/tiles.png");
        tex.filter_mag = tex.filter_min = FilterType.nearest;

        board = new Board();
        score = 0;
        visual_score = 0;
        is_game_over = false;

        var font = Luxe.resources.font('assets/font.fnt');
        score_text = new Text({
            text: "0",
            pos: new Vector(200, 572),
            point_size : 48,
            font: font,
            sdf: true,
            align: TextAlign.center,
            align_vertical: TextAlign.center,
            color: new Color().rgb(0xcbdbfc)
        });

        board.events.listen("Board.on_score", on_score);
        board.events.listen("on_game_over", on_game_over);


    } //ready

    override function onkeyup(event:KeyEvent) {

        if(event.keycode == Key.escape) {
            Luxe.shutdown();
        }

    } //onkeyup

    override function update(dt:Float) {
        if(score > visual_score) {
            if(score - visual_score < 1)
                visual_score = score;
            else
                visual_score = luxe.utils.Maths.lerp(visual_score, score, 7*dt);
            var rounded:Int = Math.round(visual_score);
            score_text.text = Std.string(rounded);
        }

        if(is_game_over) {
            if(Luxe.input.mousepressed(left)) {
                Luxe.scene.empty();
                ready();
            }
        }
    }

    private function on_score(value:Int) {
        score += value;
        score_text.scale = new Vector(1.2, 1.2);
        Actuate.tween(score_text.scale, 1, {x:1, y:1});
    }

    private function on_game_over(_) {
        var font = Luxe.resources.font('assets/font.fnt');
        var game_over_text = new Text({
            text: "game over",
            pos: new Vector(200, 640 - 572),
            point_size : 48,
            font: font,
            sdf: true,
            align: TextAlign.center,
            align_vertical: TextAlign.center,
            color: new Color().rgb(0xcbdbfc)
        });
        game_over_text.color.a = 0;
        Actuate.tween(game_over_text.color, 0.75, {a:1}).onComplete(function() {
            var restart_text = new Text({
                text: "click to restart",
                pos: new Vector(200, 640 - 572 + 32),
                point_size : 32,
                font: font,
                sdf: true,
                align: TextAlign.center,
                align_vertical: TextAlign.center,
                color: new Color().rgb(0xcbdbfc)
            });
            restart_text.color.a = 0;
            Actuate.tween(restart_text.color, 0.75, {a:1}).onComplete(function() {
                is_game_over = true;
            });
        });
    }

} //Main
