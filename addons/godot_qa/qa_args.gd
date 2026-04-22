extends RefCounted

const ENABLE_SETTING := "godot_qa/enabled"


static func parse_user_args(args: PackedStringArray) -> Dictionary:
	var options := {}
	var raw_args: Array[String] = []
	var enabled := false

	for raw_arg in args:
		if raw_arg == "--qa":
			enabled = true
			raw_args.append(raw_arg)
			continue
		if not raw_arg.begins_with("--qa-"):
			continue

		enabled = true
		raw_args.append(raw_arg)

		var trimmed := raw_arg.trim_prefix("--qa-")
		var split_index := trimmed.find("=")
		if split_index == -1:
			options[trimmed.replace("-", "_")] = true
			continue

		var key := trimmed.substr(0, split_index).replace("-", "_")
		var value := trimmed.substr(split_index + 1)
		options[key] = value

	return {
		"enabled": enabled,
		"raw_args": raw_args,
		"options": options,
	}
