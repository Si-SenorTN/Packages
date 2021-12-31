local set = {}

function set.properties(object: Instance, properties: {[string]: any})
	for propertyName, propertyValue in pairs(properties) do
		object[propertyName] = propertyValue
	end

	return object
end

function set.attributes(object: Instance, attributes: {[string]: any})
	for attributeName, attributeValue in pairs(attributes) do
		object:SetAttribute(attributeName, attributeValue)
	end

	return object
end

return set