extends Node
class_name Debug

static var debug_mode: bool = true

static func log(msg: String) -> void:
    if debug_mode:
        print(msg)
