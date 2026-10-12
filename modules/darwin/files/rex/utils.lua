local function must(result, err)
	if err then
		error(err, 0)
	end
	return result
end

return { must = must }
