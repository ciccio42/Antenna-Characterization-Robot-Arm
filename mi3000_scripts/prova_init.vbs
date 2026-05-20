Dim OK
Dim iStep
Dim Amp
Dim Phase
Dim CurRecord

ACDF_NAME = "prova_init"
ACDF_DATA = "prova_init_data"
DATA_BASE_PATH = "E:\Test_braccio\AcquiredData\" & ACDF_DATA & ".MDB"
TMP_MDB = "E:\Test_braccio\AcquiredData\SinglePt.mdb"
N_POS = 75

' message definitions
INIT_OK = "INIT OK"
INIT_FAIL = "INIT FAIL"
START_ACQUISITION = "START ACQUISITION"
STOP_ACQUISITION = "STOP ACQUISITION"
DATA_ACQUISITION_OK = "DATA ACQUISITION OK"
DATA_ACQUISITION_FAIL = "DATA ACQUISITION FAIL"


init_file = "E:\Test_braccio\init_file.txt"
command_file = "E:\Test_braccio\command_file.txt"

Set FSO = CreateObject("Scripting.FileSystemObject")
Set init_file_str = FSO.OpenTextFile(init_file, 2, True) '8 for appending

' File Command
Set command_file_str = CreateObject("ADODB.stream")
command_file_str.Type = 2
command_file_str.Charset = "utf-8"
command_txt  = "None"


'Create ACDF data
OK = ClsDirectAcq.CreateDataFile(ACDF_NAME , TMP_MDB)
If OK Then
     Status "Created acqusition datafile: " & ACDF_DATA 
  Else
    Status "Error creating acquisition datafile: " & ACDF_DATA 
    CauseAbort
End If

Set mDAOref = CreateObject("dao.dbengine.36")
Set mdbDef = mDAOref.OpenDatabase(DATA_BASE_PATH)
Set mrsDef = mdbDef.OpenRecordset("AcDF_MotionData")
mrsDef.MoveFirst
mrsDef.Edit
' Set number of Record Increments
mrsDef.Fields("scan sector 1 number") = N_POS
mrsDef.Update
' Close record set
mrsDef.Close 


mdbDef.tabledefs.delete("RasterScan")
mdbDef.tabledefs.refresh

' Create a raster scan table
set mtblDef = mdbDef.createtabledef("RasterScan")
 
'  Create Index Fields for raster scan table
' Create and append fields for record, scan,
' record increment, frequency, and beam.
Set mfldDef = mtblDef.CreateField("Record", 4)
mtblDef.Fields.Append mfldDef

Set mfldDef = mtblDef.CreateField("Scan", 4)
mtblDef.Fields.Append mfldDef

Set mfldDef = mtblDef.CreateField("Rinc", 4)
mtblDef.Fields.Append mfldDef

Set mfldDef = mtblDef.CreateField("Freq", 4)
mtblDef.Fields.Append mfldDef

Set mfldDef = mtblDef.CreateField("Beam", 4)
mtblDef.Fields.Append mfldDef


' Create an index for the data.
Set mindxDef = mtblDef.CreateIndex("RasterScanIndex")
mindxDef.Primary = True
mindxDef.Unique = True

' Create & append fields for the index as scan,
' record increment, frequency, and beam.
Set mfldDef = mindxDef.CreateField("Scan")
mindxDef.Fields.Append mfldDef

Set mfldDef = mindxDef.CreateField("Rinc")
mindxDef.Fields.Append mfldDef

Set mfldDef = mindxDef.CreateField("Freq")
mindxDef.Fields.Append mfldDef

Set mfldDef = mindxDef.CreateField("Beam")
mindxDef.Fields.Append mfldDef

' Add the index to the table
mtblDef.Indexes.Append mindxDef


Set mfldDef = mtblDef.CreateField("Bin1Amptd", 6)
mtblDef.Fields.Append mfldDef

Set mfldDef = mtblDef.CreateField("Bin1Phase", 6)
mtblDef.Fields.Append mfldDef

' Add raster scan table to RandomPos Data file
mdbDef.TableDefs.Append mtblDef


'Init
OK = ClsDirectAcq.ConfigureInstruments
If OK Then
     	Status "Configuration Instruments Done" 
 	init_file_str.write(INIT_OK)
   Else
    	Status "Configuration Instruments Error"
	init_file_str.write(INIT_FAIL)
	CauseAbort
End If
'init_file_str.write(INIT_OK)


' Data Acquisition Loop
Set mrsDef = mdbDef.OpenRecordset("RasterScan")
CurRecord = 1

'N_POS
command_txt = "RESET"
row = 0
Do While command_txt <> STOP_ACQUISITION
	' Wait for command

	'command_file_str.Open
	'Do Until command_txt = START_ACQUISITION Or command_txt = STOP_ACQUISITION
	'	command_file_str.LoadFromFile command_file
	'	command_file_str.Position = 0 ' Reset pointer
	'	command_txt = command_file_str.ReadText
	'	Status "Wait for start acquisition command: " & command_txt 
	'Loop
	'command_file_str.Close
	
	Do Until command_txt = START_ACQUISITION Or command_txt = STOP_ACQUISITION
		Set command_file_str_reader = FSO.OpenTextFile(command_file, 1)
		Do While Not command_file_str_reader.AtEndOfStream
			command_txt = command_file_str_reader.ReadLine()
		Loop
		command_file_str_reader.close() 	
	Loop

	If command_txt = START_ACQUISITION Then
		' Acquire Data
		Status "Starting data acquisition number: " & row
		' OK = ClsDirectAcq.InitForScan(1)
		OK = ClsDirectAcq.DoOneScan(1, True)
	
	
		' Send Data Acquisition State
		Set command_file_str_writer = FSO.OpenTextFile(command_file, 2, True)
		If OK Then
			' Save results in DB
			' 1. Get measurements
			clsdata.opendatabase TMP_MDB
			clsdata.GetScanAmpPhase 1,1,1,1, Amp, Phase
			Status "Record " & CurRecord & " Rinc " & row
			Status "Read Amp: " & Amp(0) 
			Status "Read Phase: " & Phase(0)
			clsdata.closedatabase
			' 2. Add new row
      			mrsDef.AddNew
			mrsDef.fields("Record") = CurRecord
        		mrsDef.fields("Scan") = 1
	       		mrsDef.fields("Rinc") = row + 1
			mrsDef.fields("Freq") = 1
			mrsDef.fields("Beam") = 1
			mrsDef.fields("Bin1Amptd") = Amp(0) 
	       		mrsDef.fields("Bin1Phase") = Phase(0)
			mrsDef.Update
			CurRecord = CurRecord + 1
			row = row + 1
			


			Status "Data Acquisition State: " & DATA_ACQUISITION_OK
			command_file_str_writer.write(DATA_ACQUISITION_OK)
			command_txt = DATA_ACQUISITION_OK
		ELSE
			Status "Data Acquisition State: " & DATA_ACQUISITION_FAIL
			command_file_str_writer.write(DATA_ACQUISITION_FAIL)
			command_txt = DATA_ACQUISITION_FAIL
		End If
		command_file_str_writer.Close
		Set command_file_str_writer = Nothing
	
	ElseIf command_txt = STOP_ACQUISITION Then
		Status "STOP DATA ACQUISITION"
	End If		
Loop

' Release Section
OK = clsDirectAcq.CloseDataFile()
init_file_str.Close
command_file_str.Close 'ToDo De-comment
clsdata.closedatabase
mrsDef.Close

Set init_file = Nothing
Set command_file = Nothing
Set FSO = Nothing
Set command_file_str = Nothing