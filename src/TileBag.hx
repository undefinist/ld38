import Tile;

class TileBag {

    var list:Array<TileInfo>;

    public function new() {
        list = [];
        refill();
    }

    public function next():TileInfo {
        if(list.length == 0) {
            refill();
        }
        return list.pop();
    }

    private function refill() {
        while(list.length > 0)
            list.pop();
        for(i in 1...21) {
            for(j in 0...1) {
                list.push({index: i, rotation: j});
            }
        }
        shuffle();
    }

    private function shuffle() {
        for (i in 0...list.length) {
            var j = Luxe.utils.random.int(0, list.length);
            var a = list[i];
            var b = list[j];
            list[i] = b;
            list[j] = a;
        }
    }

}
