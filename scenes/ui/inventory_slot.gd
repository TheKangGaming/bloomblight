extends PanelContainer

func setup(item_name: String, quantity: int):
	# Find the Label node (ensure you have one named "Label"!)
	var label = $Label
	
	if label:
		label.text = "%s\nx%d" % [item_name, quantity]
	else:
		printerr("InventorySlot Error: No Label node found!")
