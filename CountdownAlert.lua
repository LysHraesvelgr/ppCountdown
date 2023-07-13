
Instance.properties = properties({
	{ name="Time", type="Text", value="00:00:30", onUpdate="onTimeUpdate" },
	{ name="Actions", type="PropertyGroup", items={
		{ name="Reset", type="Action" },
	}},
	{ name="Alerts", type="PropertyGroup", items={
		{ name="onCountdownTick", type="Alert", args={time="hh:mm:ss"} },
		{ name="onCountdownEnd", type="Alert" },
	}}
})

Instance.startTimeString = ""
Instance.totalTime = seconds(0)
Instance.currentTime = seconds(0)

function Instance:onInit()
	self:onTimeUpdate()
	self:Reset()
end

function split(str, sep)
	local fields = {}
	local pattern = string.format("([^%s]+)", sep)
	str:gsub(pattern, function(c) 
		fields[#fields+1] = c 
	end)
	return fields
 end

function toTimeNumber(str)
	local num = tonumber(str)
	if (not num) then
		print("Time property must be in the format of [hours:mins:seconds] or [mins:seconds] or [seconds]", 324)
		return 0
	end
	return num
end

function getClockUnits(str)

	local tbl = {
		hours="0",
		mins="0",
		secs="0",
		fields = 0
	}

	local fields = split(str, ":")
	tbl.fields = #fields 
	if (#fields==0) then
		return tbl
	elseif (#fields==1) then
		tbl.secs = fields[1]
	elseif (#fields==2) then
		tbl.mins = fields[1]
		tbl.secs = fields[2]
	else
		tbl.hours = fields[1]
		tbl.mins = fields[2]
		tbl.secs = fields[3]
	end

	return tbl
end

function Instance:onTimeUpdate()

	local units = getClockUnits(self.properties.Time)
	self.totalTime = hours(toTimeNumber(units.hours)) + minutes(toTimeNumber(units.mins)) + seconds(toTimeNumber(units.secs))
	
end

function Instance:onReset()
	self:Reset()
end

function Instance:Reset()

	self.startTimeString = self.properties.Time
	self.currentTime = self.totalTime

	getAnimator():stopTimer(self, self.onCountdownTick)
	getAnimator():createTimer(self, self.onCountdownTick, seconds(1), true)

	self:raiseCountdownTick()

end

function Instance:addTime(time)

	if (type(time) == "string") then
		local units = getClockUnits(time)
		local negate = false
		if (time:sub(1,1) == '-' and units.fields>1) then
			negate = true
		end
		time = hours(toTimeNumber(units.hours)) + minutes(toTimeNumber(units.mins)) + seconds(toTimeNumber(units.secs))
		if (negate) then
			time = time * -1
		end
	end

	if (self.currentTime + time > self.totalTime) then
		if (self.currentTime == self.totalTime) then
			return
		end
		self.currentTime = self.totalTime
	elseif (self.currentTime + time < seconds(0)) then
		if (self.currentTime == seconds(0)) then
			return
		end
		self.currentTime = seconds(0)
	else
		self.currentTime = self.currentTime + time
	end

	getAnimator():stopTimer(self, self.onCountdownTick)
	getAnimator():createTimer(self, self.onCountdownTick, seconds(1), true)

	self:raiseCountdownTick()

end

function pad(time, units)
	if (not units) then
		units = "00"
	end

	local str = tostring(time)
	if (time<10 and #units>1) then
		str = "0" .. str
	end	
	return str
end

function Instance:raiseCountdownTick()
	local total_secs = math.floor(self.currentTime:toSeconds())
	local secs = math.floor(total_secs % 60)
	local mins = math.floor((total_secs/60) % 60)
	local hours = math.floor((total_secs/60/60) % 60)

	local units = getClockUnits(self.startTimeString)

	local formatted_time = "0"
	if (units.fields == 1) then
		local secs = math.floor(total_secs)
		formatted_time = tostring(secs)
	elseif (units.fields==2) then
		local mins = math.floor(total_secs/60)
		formatted_time = pad(mins, units.mins) .. ":" .. pad(secs)
	else
		local hours = math.floor(total_secs/60/60)
		formatted_time = pad(hours, units.hours) .. ":" .. pad(mins) .. ":" .. pad(secs)
	end

	self.properties.Alerts.onCountdownTick:raise({time=formatted_time})

end

function Instance:onCountdownTick()

	self.currentTime = self.currentTime - seconds(1)
	if (self.currentTime <= seconds(0)) then
		self.currentTime = seconds(0)
		self.properties.Alerts.onCountdownEnd:raise()
		getAnimator():stopTimer(self, self.onCountdownTick)
	end

	self:raiseCountdownTick()

end

