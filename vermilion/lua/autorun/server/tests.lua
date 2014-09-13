concommand.Add("dump_von", function(vplayer, cmd, args, fullstring)
	local test = von.deserialize(file.Read(args[1], "DATA"))
	PrintTable(test)
	print(test)
end)

concommand.Add("funcinfo", function(vplayer, cmd, args, fullstring)
	PrintTable(debug.getinfo(MsgC))
end)