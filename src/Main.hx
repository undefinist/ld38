
import luxe.GameConfig;
import luxe.Input;
import luxe.Vector;
import phoenix.Texture;
import luxe.Sprite;
import luxe.Input.MouseEvent;

class Main extends luxe.Game {

    var board:Board;

    override function config(config:GameConfig) {

        config.window.title = 'luxe game';
        config.window.width = 480;
        config.window.height = 640;
        config.window.fullscreen = false;

        config.preload.textures.push({ id: "assets/tiles.png" });

        return config;

    } //config

    override function ready() {

        Luxe.camera.zoom = 2;

        Luxe.input.bind_key("rotate_left", Key.key_q);
        Luxe.input.bind_key("rotate_right", Key.key_e);
        Luxe.input.bind_key("rotate_right", Key.lctrl);
        Luxe.input.bind_key("up", Key.up);
        Luxe.input.bind_key("down", Key.down);
        Luxe.input.bind_key("left", Key.left);
        Luxe.input.bind_key("right", Key.right);
        Luxe.input.bind_key("up", Key.key_w);
        Luxe.input.bind_key("down", Key.key_s);
        Luxe.input.bind_key("left", Key.key_a);
        Luxe.input.bind_key("right", Key.key_d);
        Luxe.input.bind_key("place", Key.enter);
        Luxe.input.bind_key("place", Key.space);


        var tex = Luxe.resources.texture("assets/tiles.png");
        tex.filter_mag = tex.filter_min = FilterType.nearest;

        board = new Board();
    } //ready

    override function onkeyup(event:KeyEvent) {

        if(event.keycode == Key.escape) {
            Luxe.shutdown();
        }

    } //onkeyup

    override function update(delta:Float) {
        board.update(delta);
    } //update

    override function onmousedown(e:MouseEvent) {
        board.onmousedown(e);
    }

    override function onmousemove(e:MouseEvent) {
        board.onmousemove(e);
    }

    override function onmouseup(e:MouseEvent) {
        board.onmouseup(e);
    }

} //Main
