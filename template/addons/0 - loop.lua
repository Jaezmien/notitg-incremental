if GAMESTATE:IsEditMode() then
	update_hooks['loop'] = function() if GAMESTATE:GetSongTime() >= 3600 then GAMESTATE:SetSongBeat( 0 ) end end
else
	mod_plr(function(p) p:SetNoteDataFromLua({}) end) -- remove mines
	GAMESTATE:SetSongEndTime( 9e6 )
end