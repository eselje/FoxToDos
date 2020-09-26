
DEFINE CLASS Todos AS Custom
	DIMENSION aToDos[1]	&& Array of ToDo Objects
	nTodos = 0
	cTableName = "data\ToDos"


	PROCEDURE Init
	SET EXCLUSIVE OFF
	

	PROCEDURE OpenTodos
	IF NOT USED(This.cTableName)
		USE (This.cTableName)
	ENDIF
	RETURN USED(This.cTableName)


	PROCEDURE Load
	LOCAL n
	This.OpenTodos()
	SET DELETED ON 
	COUNT TO This.nToDos
	DIMENSION This.aToDos[This.nToDos]
	n = 1
	SCAN 
		This.aToDos[n]=CREATEOBJECT("Todo", id)
		n = n + 1
	ENDSCAN
	This.CloseTodos()
	RETURN This.nToDos

	
	PROCEDURE New
	This.nTodos = This.nTodos + 1
	DIMENSION This.aToDos[This.nToDos]
	This.aTodos[This.nTodos] = CREATEOBJECT("Todo")
	This.aTodos[This.nTodos].Save()
	RETURN This.nToDos
	
	
	PROCEDURE CloseToDos
	LPARAMETERS lLeaveOpen
	IF NOT lLeaveOpen
		USE IN SELECT("ToDos")
	ENDIF

	PROCEDURE Complete
	oToDo =CREATEOBJECT("ToDo", ToDos.id)
	oToDo.oData.Completed=.t.
	RETURN oToDo.Save()

	PROCEDURE Delete
	oToDo =CREATEOBJECT("ToDo", ToDos.id)
	RETURN oToDo.Delete()



ENDDEFINE 



DEFINE CLASS ToDo AS Custom
	Name = "ToDo"
	cId = ""
	oData = .null.
	lNew = .f.
	lSaved = .f.
	lLoaded = .f.
	oException = .null.


	PROCEDURE Init
	LPARAMETERS cId
	This.cId = cId
	IF EMPTY(cId)
		This.New()
	ELSE 
		This.Load(This.cId)
	ENDIF 
	ENDPROC


	PROCEDURE New
	lUsed = This.OpenToDos()
	SCATTER BLANK NAME This.oData MEMO
	This.lNew = .t. 
	This.CloseTodos(lUsed)
	RETURN This.oData


	PROCEDURE Load
	LPARAMETERS cId
	LOCAL lUsed
	cId = EVL(cId,This.cId)
	IF NOT EMPTY(cId)
		TRY 
			lUsed = This.OpenToDos()
			LOCATE FOR id = cId
			IF FOUND()
				SCATTER NAME This.oData MEMO
				This.cId = cId 
				This.lLoaded = .t.
				This.lNew = .f.
			ENDIF
		CATCH TO oEx
			This.oException = oEx
		FINALLY
			This.CloseTodos(lUsed)
		ENDTRY
	ENDIF 
	RETURN This.lLoaded


	PROCEDURE Save
	LOCAL lUsed
	This.lSaved = .F.
	IF This.lLoaded OR This.lNew
		lUsed = This.OpenToDos()
		TRY 
			IF This.lNew
				* There are many ways to create a GUID, including calls to CoCreateGUID in Ole32.dll, but this is easy
				* From https://fox.wikis.com/wc.dll?Wiki~GUIDGenerationCode~VB
				LOCAL oGUID
				oGUID = CreateObject("scriptlet.typelib")
				This.oData.Id = Strextract(oGUID.GUID, "{", "}" )
				This.oData.Entered = DATETIME()
				INSERT INTO ToDos FROM NAME This.oData 
				This.cId = This.oData.Id
			ELSE
				LOCATE FOR id = This.cId
				GATHER NAME This.oData MEMO
			ENDIF
			This.lSaved = .t.
			This.lNew = .f.
		CATCH TO oEx
			This.oException = oEx
		FINALLY
			This.CloseTodos(lUsed)
		ENDTRY 
	ENDIF 
	RETURN This.lSaved


	PROCEDURE Delete
	LOCAL lUsed, lReturn
	IF NOT EMPTY(This.cId)
		lUsed = This.OpenToDos()
		LOCATE FOR id = This.cId
		lReturn = FOUND()
		IF lReturn
			DELETE
		ENDIF
		This.CloseTodos(lUsed)
	ENDIF 
	RETURN lReturn


	PROCEDURE OpenTodos
	LOCAL lUsed
	lUsed = USED("ToDos")
	IF NOT lUsed
		USE data\ToDos IN 0
	ENDIF
	SELECT ToDos
	RETURN lUsed

	PROCEDURE CloseToDos
	LPARAMETERS lLeaveOpen
	IF NOT lLeaveOpen
		USE IN SELECT("ToDos")
	ENDIF
	
ENDDEFINE
