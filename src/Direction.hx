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
