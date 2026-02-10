extends Node
class_name Debug

static var debug_mode: bool = true

static func log(msg: String, include_stack: bool = false, max_frames: int = 12, caller: Object = null) -> void:
    if not debug_mode:
        return

    if caller is Node:
        msg += "\nCaller node: " + String((caller as Node).get_path())

    if not include_stack:
        print(msg)
        return

    var stack: Array = get_stack()
    # Skip this function and any internal frames.
    var stack_str := _format_stack(stack, 2, max_frames)
    if stack_str == "":
        print(msg)
    else:
        print(msg + "\n" + stack_str)


static func _format_stack(stack: Array, skip: int, max_frames: int) -> String:
    if stack == null or stack.is_empty():
        return ""

    var start := clampi(skip, 0, stack.size())
    var end := clampi(start + maxi(max_frames, 1), start, stack.size())

    var lines: PackedStringArray = []
    lines.append("Stack trace:")
    for i in range(start, end):
        if typeof(stack[i]) != TYPE_DICTIONARY:
            continue
        var frame := stack[i] as Dictionary
        var src := str(frame.get("source", ""))
        var line := str(frame.get("line", "?"))
        var fn := str(frame.get("function", ""))
        if fn != "":
            lines.append("  at %s:%s (%s)" % [src, line, fn])
        else:
            lines.append("  at %s:%s" % [src, line])
    return "\n".join(lines)
