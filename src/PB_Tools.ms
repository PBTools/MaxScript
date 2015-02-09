
-- Feb 14 2013
-- Added:(initial) Random BG /Default BG Swithcher

-- Dec 12 2012
-- Added: Select by MatID

-- May 14 2012
-- Added: Mesh Copy/Paste & Material Copy/Paste from MaxTools script
-- Fixed: Preserve UVs and Poly Bridge script now check if the selection is a Editable Poly or not, hence will not throw a error message.

-- Mar 14 2012
--Rotate selected face UV by 90 deg offset

-- May 06 2011
-- Toggle Preserve UVs Re Added

-- Apr 14 2011
-- Updated:[Toggle UV Element] Now works on multiple selections
-- FIX:[ToggleWirePO]Selection bug.

-- Mar 16 2011
-- Added:Flow connect selected (Works on 3dsmax 2010 & above)
		-- Only works on more than one selected edge.Not on single edge yet.

-- Mar 15 2010

-- Dec 12 2008
-- Added : Channel Info cleaner (PB_cleanChannels)
-- Toggle Wire Per Object

macroScript Toggle_Wire	
	category:"PB_Tools"
	toolTip:"Toggle Wire Per Object"
	
-- updated: 21-11-2008 : works now on multiple selections

(
	for i = 1 to selection.count do
		(
			if selection[i].visibility == off then 
			
			selection[i].visibility = on

		else 
			selection[i].visibility = off 
		)


)


--Work Like Jang Sir for a bit :)

macroScript Jang_Mode	
	category:"PB_Tools"
	toolTip:"Jang Mode"


(
	toolMode.coordsys #screen
	toolmode.axisConstraints = #XY
	max showaxisicon
)

-- Toggle Shade Mode

macroScript Shade_Toggle
	category:"PB_Tools"
	toolTip:"Toggle Shaded/Material Mode"


(
	if displayColor.shaded == #material 
		
		then displayColor.shaded = #object 
	
	else displayColor.shaded = #material
)

-- Toggle between all the snap modes (2D/2.5D/3D)

macroScript Smart_Snap
	category:"PB_Tools"
	toolTip:"SmartSnap"


(
			--initialize code
			snapMode.active = true
			snapMode.type = #2_5D
			
			--toggle code
			if snapMode.type == #3D then snapMode.type = #2_5D 
		else 
			if snapMode.type == #2_5D then snapMode.type = #2D 
		else 
			snapMode.type = #3D 
)


-- Toggle Lock/Unlock Transforms of Multiple objects (credit : Grants)

macroScript Lock_Transforms
	category:"PB_Tools"
	toolTip:"Lock/Unlock Transforms"
(
	for i in 1 to $selection.count do (try(setTransformLockFlags $selection[i] #{1,2,3,4,5,6,7,8,9})catch())
)

-- Clear channels from 3-64
-- Caution : Save file before running
macroScript PB_clearChannels
	category:"PB_Tools"
	toolTip:"Clear Map Channels above 1"
(
	i = 65
	while i > 2 do
	(
		i -= 1	
		channelInfo.ClearChannel  $ i
		macros.run "Modifier Stack" "Convert_to_Mesh"
		clearUndoBuffer() 
		print i

	)
	macros.run "Modifier Stack" "Convert_to_Poly"
)

-- MAX FUNCTIONS 

--Bridge
			
macroScript PB_MaxBridge
category:"PB_Tools"
toolTip:"MaxBridge"
(	
	if selection[1] != undefined and classof selection[1] == Editable_Poly then
	(
		$.EditablePoly.Bridge ()
	)

)
-- Mar 15 2010
macroScript PB_Toggle_UVElement
    category:"PB_Tools"
    toolTip:"Toggle UV Element Mode"
(
	theObj = selection[1]
	
	if theObj.modifiers[1] != undefined then 
	(
		if (theObj.modifiers[#unwrap_uvw].getTVElementMode()==true) then 
		(
			theObj.modifiers[#unwrap_uvw].setTVElementMode(false) 
		)
			else 
		(
			theObj.modifiers[#unwrap_uvw].setTVElementMode(true) 
		)
	)
)
-- Flow Connect without Auto ring, on selected edges only

macroScript PB_FlowConnect
category:"PB_Tools"
toolTip:"Flow Connect Selected"
(
	
	PolyToolsUI.FlowConnectAutoLoop = false
	PolyBoost.Flowfunc PolyToolsUI.FlowConnectAutoLoop

)


-- Oct 7 2010

macroScript Pb_Tgl_PresUVs
category:"PB_Tools"
toolTip:"Toggle_PreserveUVs"
(
	if selection[1] != undefined and classof selection[1] == Editable_Poly then
	(
		if $.preserveUVs == off then $.preserveUVs = on else $.preserveUVs = off
	)
)

-- Sep 29 2011
-- Lock selected UV shortcut in 3dsmax 2012  doesn't work.
-- So the alternative.

macroScript Pb_Lock_UV
 category:"PB_Tools"
 toolTip:"Lock Selected UV"
(

$.modifiers[#unwrap_uvw].unwrap.lock ()

)


macroScript Pb_Rotate_UV_90
 category:"PB_Tools"
 toolTip:"Rotate selected face UV 90"
(

max modify mode
obj = selection[1]

modPanel.addModToSelection (Unwrap_UVW ()) ui:on
obj.modifiers[#Unwrap_UVW].rotateSelectedCenter (degToRad -90.0)

maxOps.CollapseNodeTo obj 1 off

	clearListener()
	actionMan.executeAction 369982487 "40006"  -- Editable Poly: Face Level
)

-- Mesh Copy/Paste
macroScript PB_MeshCopy
category:"PB_Tools"
toolTip:"Mesh Copy Selected"
(
	if $ != undefined then
		(
			theObjs = $
			if (doesfileexist (getdir #scripts+"\\temp\\")) != true then
				(
					makeDir (getdir #scripts+"\\temp\\tempfile.max")
					savenodes theObjs (getdir #scripts+"\\temp\\tempfile.max")
				)
				else
				(
					
					savenodes theObjs (getdir #scripts+"\\temp\\tempfile.max")
				)
			
			print "Copied!"
		)
		else
		(
			messagebox "Nothing selected."
		)
		
	
	
)
	
macroScript PB_MeshPaste
	category:"PB_Tools"
	toolTip:"Mesh Paste Selected"
	(
		if (doesfileexist (getdir #scripts+"\\temp\\")) != true then
			(
				messagebox "Nothing to paste!"
			)
			else
			(
				mergeMAXFile (getdir #scripts+"\\temp\\tempfile.max") #AutoRenameDups #useSceneMtlDups 
				print "Pasted!"
			)
	)
	
-- Material Copy/ Paste selected
macroScript PB_MaterialCopy
category:"PB_Tools"
toolTip:"Material Copy Selected"
(
		thecopypastedir = getdir #autoback
		thecopypastefile = "\\pastematfile.mat"
		thecopypastestring = thecopypastedir + thecopypastefile

		selectedmat=medit.GetCurMtl()
		pastelib=loadTempMaterialLibrary thecopypastestring   
		if pastelib == undefined then (
			loadDefaultMatLib           
			saveTempMaterialLibrary currentMaterialLibrary thecopypastestring
			pastelib=loadTempMaterialLibrary thecopypastestring
		)
	   
		for i=1 to pastelib.count do
		(
			deleteitem pastelib (i)
		)
		--currentMaterialLibrary
		append pastelib selectedmat
		saveTempMaterialLibrary pastelib thecopypastestring
)

macroScript PB_MaterialPaste
category:"PB_Tools"
toolTip:"Material Paste Selected"
(
	thecopypastedir = getdir #autoback
	thecopypastefile = "\\pastematfile.mat"
	thecopypastestring = thecopypastedir + thecopypastefile
   
	pastelib=loadTempMaterialLibrary thecopypastestring
	selectedmatslot= activeMeditSlot
	pastedmat=pastelib[1]
	setMeditMaterial selectedmatslot pastedmat
)

-- Shortcut for collapsing to in the modifier stack, keeping instance alive
--smita
	
macroScript PB_CollapseTo
category:"PB_Tools"
toolTip:"Collapse to Node"
(
	theObj = getCurrentSelection()
	if theObj.count ==1 then
	(
		maxOps.CollapseNodeTo theObj[1] 1 off
	)
)

macroScript PB_SelByMatID
category:"PB_Tools"
toolTip:"Select by MatID"
(
	
	-- Dec 12,2012
	-- select only one face
	-- selects all the faces in the object with the selected faces matID
	-- Limit: Works only on Editable poly object.Please select only one face


	theFace = ($.getselection #face) as array

	theMatID = polyop.getFaceMatID  $ theFace[1]

	$.EditablePoly.selectByMaterial theMatID


			if $ != undefined then
			(
				theObj = selection[1]
				if (classof theObj) != Editable_Poly then 
				(
					messagebox "Please select an Editable Poly object."
				)
				else
				(
					theFace = (theObj.getselection #face) as array
					theMatID = polyop.getFaceMatID  theObj theFace[1]

					theObj.EditablePoly.selectByMaterial theMatID	

				)
		
			)
			else
			(
				messagebox "Please select an object."
			)
)

		
macroScript PB_BGColorRandom
category:"PB_Tools"
toolTip:"BGColor_Random"
ButtonText:"BGColor_Random"
(
	viewport.EnableSolidBackgroundColorMode true

	completeredraw()
	
	v1 = random 0.5 1.0
	v2 = random 0.5 1.0
	v3 = random 0.5 1.0


	SetUIColor 41 [v1,v2,v3]
	colorMan.repaintUI #repaintAll 

)
			
macroScript PB_BGColorDefault
category:"PB_Tools"
toolTip:"BGColor_Default"
ButtonText:"BGColor_Default"
(
	viewport.EnableSolidBackgroundColorMode true

	completeredraw()
	defaultColor = [0.5,0.5,0.5]
	SetUIColor 41 defaultColor
	colorMan.repaintUI #repaintAll 

)
