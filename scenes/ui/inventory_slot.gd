extends PanelContainer

func setup(item_name: String, quantity: int):
	# Assuming you have a Label node named "Label"
	$Label.text = "%s: %d" % [item_name, quantity]
