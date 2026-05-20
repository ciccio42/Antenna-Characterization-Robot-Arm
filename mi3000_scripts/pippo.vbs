' '*************************************************************************************************************
' Name:  RandomPositionAcq.vbs
'
' Author: jdg;  MI Technologies, Duluth, Georgia
' Date: June, 2006
'
 'Rev: May 2016. Accommodate 3 positions.
'
'
' Description:
'  - VB Script file to accomplish custom RandomPos acquisition.
'  - Assumes:
'      An acquisition definition file created that defines 1 or more bins,
'        3 axes (Scan, Step1 and Step2), Postion scan, Scan axis of nominal Record Incs (later modified), 
'        2 Step axis position, multiple frequencies. Confirmation plot should be off, but okay to be on.
'
'      And a text file (.txt) file of the same name and stored in the same user directory as the acq def file
'        consisting of lines containing comma-separated position triples - only one triplet per line.
'        The axes must in scan axis, step axes order as defined in the acquisition definition file.
'
'      mdebug set to TRUE generates more status messages; set to FALSE to limit messages.
'
'  - Strategy:
'      The position file is read. The number of triplets becomes the number of record increments.
'      The User (RandomPos) acq definition name must be entered and the file must exist.
'
'      The user (RandomPos) data file is determined based on user entry.
'
'       If the data filename is blank, the acq def filename is used.
'       If a specific version number is used, that filename is used.
'       If a filename is entered without a version number, an attempt is made to find prev versions
'          and increment to the next version number.
'       If the file is not found, version "_1" will be used.
'
'      The user (RandomPos) acq def file is copied to a working acq def file.
'      A working acq data file is created by clsdirectacq.createdatafile.
'      The working acq data file is copied to the user (RandomPos) acq data file.
'      The working acq data file is modified as a single pt acquisition,  the record axes fields are set to 0.
'      clsdirectacq.configure instruments. Scan and step axes will be configured.
'
'      The user (RandomPos) data file is modified by the number of record increments. A raster scan table is added with
'        index, position, and bin fields.  Set scan and step axis 1 to record.
'
'      The working acq data file is modified setting the scan and step 1 IDs to 0
'
'      clsdirectacq.datafilename is set to the working acq data file, which reintializes some variables.
'
'      clsdirectacq.configureinstruments is called to initialize and configure all instruments of the acquisition.
'         The second configure will initialize variables to not call InitScan and InitStep. PositionTo will move axes.
'      
'
'      Acquisition loop
'        For all Record Increments:
'          Move scan, step 1 and step 2 axes to next position. Read and save when halted.

'          clsdirectacq.doonescan( scannumber = 1, TRUE)
'
'          clsdata.opendatabase working acq data file
'
'          For all bins:
'            For all frequencies:
'              Read bin data (Amp & Phase) via clsdata.getscanampphase and save
'            End of for all freqs
'
'           clsdata.closedatabase
'
'          End for all bins
'
'          open raster scan record set for user data file
'          For all freqs
'            Add new record of scan, step 1 and step 2 positions and all bins and update
'          End of for all freqs
'
'        End of for all record increments
'      End of acquisition loop
'
'      clsdirectacq.closedatafile
'
'      Save in registry User data file as last data file
'
' *************************************************************************************************************

Option Explicit

                                                      ' The Acquisition Definition Axes
                                                      
 Dim mAxisID                              ' system axis number of Scan and Step axes
 
Dim mstrAngles                        ' Axis Values

Dim mdblAngles                       ' Axis Values

Dim mNumOfPositions     ' Number of RIs
Dim mNumFreqs                       ' Number of freqs in acqusition
Dim mNumBeams                    ' Number of beams in acquisition
Dim mFreqBeforeBeam
Dim mNumBins                         ' Number of channels in final acquisition
Dim mNumPosns                     ' Number of positions to move and record

Dim mblnPosAvail
Dim mblnBinAvail

Dim mRandomPos_Def_Filename
Dim mRandomPos_Data_Filename
Dim mAcq_Def_Filename
Dim mAcq_Data_Filename

Dim mDAOref
Dim mdbDef
Dim mtblDef
Dim mfldDef
Dim mrsDef
Dim mindxDef

Dim mDeBug 
 
' ***************************************************************************
' The Sequencer runs in global scope.  Immediately jump to a module.
Call Main

If isAbort Then
  Status "SEQUENCE ABORTED."
End If
' ***************************************************************************

' ***************************************************************************
'* Subroutine Name  : Main                                                 
'* Description: Main driver for the VBScript.                       
'*                 
'* Parameters: None                                                                                                       
' ***************************************************************************
Private Sub Main()
  Dim i

  Dim OK
  Dim Response
  Dim fso

  Dim startangle
  Dim stopangle
  Dim incangle
 
  mdebug = false

  mFreqBeforeBeam = 1
  mNumBeams = 1
  mNumPosns = 3        ' set number of position to move

  ReDim mAxisID(mnumposns - 1)

                                                                ' Prompt for RandomPos filenames
  mRandomPos_def_filename = "RandomPos"
  mRandomPos_data_filename = "RandomPos"

'  mRandomPos_Def_Filename = InputBox("Enter the name of the Acquisition Definition File:")
'  mRandomPos_Data_Filename = InputBox("Enter the name of the Acquired Data File:")

  status "Def Filename: " & mRandomPos_def_filename
  status "Data Filename: "  & mRandomPos_data_filename

                                                                 ' Get position position for acquisition
  OK =ReadPositionData
  If OK Then
    Status "Position data file successfully read"
    Status "Number of Position Points: " & CStr(mNumOfPositions)
  Else
    Status "Error reading Position file "
    CauseAbort
    Exit Sub
  End If

                                                                 'Check for mRandomPos_Def_Filename existence
  Set fso = CreateObject("Scripting.FileSystemObject")

  OK = fso.FileExists(AcdfDir & NameOnly(mRandomPos_Def_Filename) & ".mdb")
  if not OK then
    status "The Acquisition Definition File does not exist."
    CauseAbort
    Exit Sub
  End If

                                                                  'Get next available filenumber
  mRandomPos_Data_Filename = AutoIncrementFile(mRandomPos_Data_Filename, "AcquiredData\")
  status "Data Filename after Autoincrement processing: " & mRandomPos_data_filename

  Response = MsgBox( _
           "Acquisition Definition File: " &  mRandomPos_Def_Filename & vbCrLf & vbCrLf & _
           "Acquired Data File: " & mRandomPos_Data_Filename & vbCrLf & vbCrLf & _
           "Click OK to begin Acquisition; Cancel to abort.", _
           vbOKCancel + vbInformation, "Start Acquisition")
        
  If Response = vbCancel Then
     CauseAbort
     Exit Sub
  End If

  if mdebug = true then
    status "User Dir: " & userdir
    status "Acdf Dir: " & acdfdir
  end if 
  
  macq_def_filename = userdir & "\AcquisitionDefinition\" & "SinglePt.mdb"
  macq_data_filename = userdir & "\AcquiredData\" & "SinglePt.mdb"

  if mdebug = true then
    status "Acq def file: " & macq_def_filename
    status "Acq data file: " & macq_data_filename
  end if

                                                                   ' Copy RandomPos def file to acq def file
  fso.copyfile acdfdir & mRandomPos_def_filename & ".mdb", macq_def_filename  

                                                                     'create the acquisitiondata file, Set Registry
  OK = clsDirectAcq.CreateDataFile(macq_Def_Filename, macq_Data_Filename)
  If OK Then
     Status "Created acqusition datafile: " & macq_Data_Filename
  Else
    Status "Error creating acquisition datafile: " & macq_Data_Filename
    CauseAbort
    Exit Sub
  End If

  status "Registry data file: " & datafilename

                                                                 ' Copy acq data file to RandomPos data file
  fso.copyfile macq_data_filename, mRandomPos_data_filename  


                                                                 ' Modify acq data file
                                                                 ' Set refeences
  if mdebug = true then
    status "Creating references to DAO, etc"
  end if

  Set mDAOref = CreateObject("dao.dbengine.36")

  if mdebug = true then
     status "Opening acq data file to modify"
  end if

  Set mdbDef = mDAOref.OpenDatabase(macq_data_filename)

                                                                 ' Open record set
  Set mrsDef = mdbDef.OpenRecordset("AcDF_Miscdata")
  mrsDef.MoveFirst
  mrsDef.Edit
                                                                ' Set type of recording to single point
  mrsDef.Fields("Type of Recording") = 1
                                                                ' Freq before beam
  mrsDef.Fields("Acquisition Order") = 1
  mrsDef.Update
  mrsDef.Close
  
  Set mrsDef = mdbDef.OpenRecordset("AcDF_MotionData")
  mrsDef.MoveFirst
  mrsDef.Edit

  
  mrsdef.fields("scan sector 1 start") = csng(mstrAngles(0,0))
  
  mrsDef.fields("RecordScan") = 0

  for i = 1 to (mNumPosns - 1)
     mrsDef.fields("RecordStep" & cstr(i)) = 0
     mrsdef.fields("step " & cstr(i) & " sector 1 start") = csng(mstrangles(i,0))
  next
  
  
  mrsDef.Update

  mrsDef.Close
  mdbDef.Close                                     ' Close acq data file

  status "Configuring instruments for acquisition"

  OK = clsdirectacq.configureinstruments
  If OK Then
     Status "Instruments configured"
  Else
    Status "Error configuring instruments"
    CauseAbort
    Exit Sub
  End If

 
                                                                 ' system axis number of scan axis
  mAxisID(0) = clsDirectAcq.ScanAxisNumber     
  status "Scan axis ID: " & mAxisID(0)

                                                                  ' system axis number of step 1, 2 axis
  for i = 1 to mNumPosns - 1
    mAxisID(i) = clsDirectAcq.StepAxisNumber(i)  
    status "Step" & cstr(i) & " axis ID: " & mAxisID(i)
  next
   

  clsDirectAcq.CloseDataFile

  if mdebug = true then
     status "Opening acq data file to modify"
  end if

  Set mdbDef = mDAOref.OpenDatabase(macq_data_filename)  
  Set mrsDef = mdbDef.OpenRecordset("AcDF_MotionData")
  mrsDef.MoveFirst
  mrsDef.Edit
  mrsDef.Fields("Scan ID") = 0

  for i = 1 to mNumPosns - 1
    mrsDef.Fields("Step " & cstr(i) & " ID") = 0
  next

  mrsDef.Update

  mrsDef.Close
  mdbDef.Close                                     ' Close acq data file
  
                                                                 ' Modify RandomPos data file
                                                                 ' Set refeences
  if mdebug = true then
     status "Opening User data file to modify"
  end if
                                                                ' Open RandomPos data file
  Set mdbDef = mDAOref.OpenDatabase(mRandomPos_data_filename)

                                                                 ' Open record set
  Set mrsDef = mdbDef.OpenRecordset("AcDF_MotionData")
  mrsDef.MoveFirst
  mrsDef.Edit
                                                                 ' Set number of Record Increments
  mrsDef.Fields("scan sector 1 number") = mNumOfPositions
  startangle = mrsDef.fields("scan sector 1 start")
  stopangle = mrsDef.fields("scan sector 1 stop")

  if mnumofpositions > 1 then

    incangle = (stopangle - startangle) / (mnumofpositions - 1)
  else
    incangle = 0.0
  end if
                                                                ' Set increment angle
  mrsDef.fields("scan sector 1 increment") = incangle
  
  mrsDef.fields("RecordScan") = 1
  for i = 1 to mNumPosns - 1
     mrsDef.fields("RecordStep" & cstr(i)) = 1
  next

  
  mrsDef.Update
                                                                 ' Close record set
  mrsDef.Close

                                                                 ' Open record set
  mNumBins = 0
  i = 0

  Set mrsDef = mdbDef.OpenRecordset("AcDF_1795Bins")
  mrsDef.MoveFirst

  do while mrsDef.fields("BinPrimary") <> "OFF" and i < 16
     mrsDef.movenext
     mNumBins = mNumBins + 1
  Loop
                                                                   ' Close record set
  mrsDef.Close  

  mdbDef.tabledefs.delete("RasterScan")
  mdbDef.tabledefs.refresh
                                                                   ' Create a raster scan table in RandomPos Data file
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

 

                                                                   ' Create Data Fields for raster scan table
  ReDim mblnPosAvail(mNumPosns - 1)
  ReDim mblnBinAvail(mNumBins - 1)

  For i = 0 to mNumPosns - 1
    mblnPosAvail(i) = True
  next

  For i = 0 to mNumBins - 1
    mblnBinAvail(i) = True
  Next


                                                                  ' Create position fields & append
  For i = 0 To  mNumPosns - 1
     If mblnPosAvail(i) = true Then
       Set mfldDef = mtblDef.CreateField("Pos" & CStr(i + 1), 6)
       mtblDef.Fields.Append mfldDef        
     End If
   Next
                                                                 ' Create Bin fields & append
   For i = 0 To mNumBins - 1
     If mblnBinAvail(i) = true Then

       Set mfldDef = mtblDef.CreateField("Bin" & CStr(i + 1) & "Amptd", 6)
       mtblDef.Fields.Append mfldDef

       Set mfldDef = mtblDef.CreateField("Bin" & CStr(i + 1) & "Phase", 6)
       mtblDef.Fields.Append mfldDef

     End If
   Next
                                                                   ' Add raster scan table to RandomPos Data file
  mdbDef.TableDefs.Append mtblDef

  clsdirectacq.datafilename = macq_data_filename

  status "Number scans: " & clsdirectacq.nscans
  status "Number freqs: " & clsdirectacq.nfreqs
  mnumfreqs = clsdirectacq.nfreqs
  status "Number beams: " & clsdirectacq.nbeams
  status "Number bins: " & clsdirectacq.nbins
  status "Number axes: " & mnumposns

  status "Configuring instruments for acquisition"

  OK = clsdirectacq.configureinstruments
  If OK Then
     Status "Instruments configured"
  Else
    Status "Error configuring instruments"
    CauseAbort
    Exit Sub
  End If

  OK = TakeData
  if not OK then
    Status "Error in acquisition"
    CauseAbort
    Exit Sub
  End If

  PutRegistry "UserDirectories", "CurrentAcDF", NameOnly(mRandomPos_Def_Filename)
  Status "Current AcDF: " & nameonly(mRandomPos_def_filename)
  PutRegistry "UserDirectories", "CurrentDataDirectory", mRandomPos_Data_Filename
  Status "Current Data Directory: " & mRandomPos_data_filename
  PutRegistry "UserDirectories", "CurrentDataFile", NameOnly(mRandomPos_Data_Filename)
  Status "Current Data File: " & nameonly(mRandomPos_data_filename)
      
End Sub

' ***************************************************************************
'* Function Name    : TakeData                                                 
'* Description: Perform a stepped acquisition                        
'* Parameters: None                                                                    
'*
'* Return Value:  True or False                                                   
' ***************************************************************************
Private Function TakeData()
  Dim bins
  Dim freqs
  Dim RIs
  Dim OK
  Dim RetVal
  Dim CurRecord

  Dim Amps
  Dim Phases

  Dim Amp
  Dim Phase

  Dim K
  Dim L
  Dim KLimit
  Dim LLimit
  Dim i

  status "Begin acquisition"
                                                         ' Redim variables for Amp, Phase for all bins & freqs at one position
  ReDim Amps(mNumBins - 1, mNumFreqs - 1)
  ReDim Phases(mNumBins - 1, mNumFreqs - 1)

 
  ReDim mdblAngles(mnumposns - 1)
                                                  ' Open Record set for raster scan table in RandomPos data file
  Set mrsDef = mdbDef.OpenRecordset("RasterScan")

  CurRecord = 1

                                                        ' For all RIs, repeat this sequence
  for RIs = 0 to (mNumOfPositions - 1)

     if isabort then
       status "Acquisition aborted"
       mrsdef.close
       mdbDef.close

       clsdirectacq.closedatafile
       TakeData = False
       exit function
     end if

     status "RI: " & CStr(RIs) & " ; Scan Angle: " & mstrAngles(0,RIs) & " , Step Angle 1: " & mstrAngles(1,RIs) & " , Step Angle 2: " & mstrAngles(2,RIs)
                                                         ' Position Scan and Step 1 Axes
     for i = 0 to mnumposns - 1
       status "PositionTo Axis ID "& mAxisID(i) & " move to " & mstrAngles (i,RIs)

       OK = clsDirectAcq.PositionTo(mAxisID(i), mstrAngles (i,RIs), True, 100, False)
       if not OK then
          if i = 0 then
            Status "Cannot position Scan Axis"
          else
            Status "Cannot position Step " & cstr(i) & " Axis"
          end if
          TakeData = False
          exit function
       End if

     next
                                                        ' Wait for axes to position
     OK = false
     RetVal = clsDirectAcq.WaitForAxesStopped
     If RetVal = 1 Then 
       OK = True
     End If
     if not OK then
        Status "Axes cannot complete positioning"
        TakeData = False
        exit function
     End if

     for i = 0 to mnumposns - 1
       mdblAngles(i) = clsDirectAcq.GetPosition(mAxisID(i))
    next


    if isabort then
      status "Acquisition aborted"
      mrsdef.close
      mdbDef.close

      clsdirectacq.closedatafile
      TakeData = False
      exit function
    end if

                                                     ' Do a multi-freq acquisition at position already attained 
                                                     ' for a particular external state
      OK = clsdirectacq.DoOneScan(1,True)
      if not OK then
        status "Cannot Do One Scan"
        TakeData = False
        Exit Function
      else
        if mdebug = true then
          status "Completed Do One Scan"
        end if
      End If

     clsdata.opendatabase "SinglePt"


                                                      ' Read amp and Phase for all freqs for current bin
    For bins = 0 to mNumBins - 1

      For freqs = 0 to mNumFreqs - 1
         clsdata.GetScanAmpPhase 1,1,freqs + 1,bins + 1,Amp, Phase
         Amps(bins,freqs) = Amp(0)
         Phases(bins,freqs) = Phase(0)
         if mdebug or (freqs = 0) then
           status "Bin: " & cstr(bins) & " , Freq: " & cstr(freqs) & " ; Amp: " & Amp(0) & " , Phase: " & Phase(0)
         end if
      Next        ' Freq

    Next           ' Bin

    clsdata.closedatabase

                                                      ' Store positions and bin data for all freqs and beams in RasterScan table
    If mFreqBeforeBeam = 0 Then
      KLimit = mNumFreqs
    Else
      KLimit = mNumBeams
    End If

    For K = 1 To KLimit             ' For all beams. Usually 1

      If mFreqBeforeBeam = 0 Then
        LLimit = mNumBeams
      Else
        LLimit = mNumFreqs
      End If

      For L = 1 To LLimit          ' For all freqs
                                                 
                                                  ' Add new record to new raster scan table
        mrsDef.AddNew
                                                  ' Populate all fields of the record set
                                                  ' First index fields
        mrsDef.fields("Record") = CurRecord
        mrsDef.fields("Scan") = 1
        mrsDef.fields("Rinc") = RIs + 1

        If mFreqBeforeBeam = 0 Then
           mrsDef.fields("Freq") = K
           mrsDef.fields("Beam") = L
        Else
           mrsDef.fields("Freq") = L
           mrsDef.fields("Beam") = K
        End If
                                                ' Now Position fields
       For i = 0 to mNumPosns - 1
          mrsDef.fields("Pos" & CStr(i + 1)) = mdblAngles(i)
       Next

                                                  ' Now Bin fields
        For i = 0 To mNumBins - 1
          mrsDef.fields("Bin" & CStr(i + 1) & "Amptd") = Amps(i,L-1)
          mrsDef.fields("Bin" & CStr(i + 1) & "Phase") = Phases(i,L-1)
        Next
                                                   ' Write new record set to raster scan table
        mrsDef.Update                         

        CurRecord = CurRecord + 1

      Next      ' Next Freq

    Next        ' Next Beam

  Next          ' Next Record Inc

  mrsdef.close
  mdbdef.close


  clsDirectAcq.CloseDataFile

  TakeData = true
  Status "Acquisition complete."

End Function

' ***************************************************************************
'* Function Name    : Read Position Pairs                            
'* Description:   Read all position pairs                                 
'*
'* Parameters: None                                                                  
'*                  :                                                        
'* Return Value:   True or False                                                 
' ***************************************************************************
Private Function ReadPositionData()

Dim Positions
Dim CommaPosition
Dim VerString
Dim FileDone
Dim OK
Dim fso
Dim f
Dim varArray
Dim I


 Const ForReading = 1
 Const TristateFalse = 0


  Set fso = CreateObject("Scripting.FileSystemObject")
                                                                   ' Does position file exist?
  OK = fso.FileExists(AcdfDir & NameOnly(mRandomPos_Def_Filename) & ".txt")
  if not OK then
    status "Position file for this Acquisition Definition File does not exist."
   ReadPositionData = false
    Exit Function 
  End If

  Set f = fso.OpenTextFile(AcdfDir & NameOnly(mRandomPos_Def_Filename) & ".txt", ForReading,TristateFalse)

  mNumOfPositions = 0
                                                                  ' Get number of position pairs
  do while f.atendofstream = false
      Positions = f.ReadLine
      Positions = trim(Positions)
      if Positions <> "" then
        mNumOfPositions = mNumOfPositions + 1
      end if 
      if mNumOfPositions > 25000 then
        exit do
      end if
  loop
  f.close
                                                                 ' Redim variables for the angles
                                                                 
                                                               ' Redim variables for the angles
  redim mstrAngles(mNumPosns - 1, mNumOfPositions - 1)                                                                 

  Set f = fso.OpenTextFile(AcdfDir & NameOnly(mRandomPos_Def_Filename) & ".txt", ForReading,TristateFalse)
  FileDone = False
  Positions= f.ReadLine
  Positions = trim(Positions)
  mNumOfPositions = 0

  Do While FileDone = False and mnumofpositions < 25000
  
  
        if positions <> "" then

        varArray = Split(positions, ",")
        if ubound(varArray) <> (mNUmPosns - 1) then 

          status "Invalid format in Position List File. Comma not found."
          ReadPositionData = false
          Exit Function 
        end if

        For I = 0 to mNumPosns - 1

          if Not IsNumeric(varArray(I)) then

            status "Line: " & CSTR(mnumofpositions) & " ;  Angle is non-numeric."
             ReadPositionData = false
            Exit Function 
          End If
 
           mstrAngles(I, mNumOfPositions) = varArray(I)

           if mdebug = true then
              if i = 0 then
                status "Scan angle: " & cstr(vararray(i))
              else
                status "Step angle " & Cstr(i) & ": " & cstr(vararray(i))
              end if
           end if

         Next

         mNumOfPositions = mNumOfPositions + 1

      end if

      if  f.AtEndOfStream = True then
         FileDone = True
      else
         Positions = f.ReadLine
         positions = trim(positions)
      end if

    Loop

    f.Close
   ReadPositionData = True
End Function


' ***************************************************************************
'* Function Name    : NameOnly                                               
'* Description      : Return the filename only: no path, extension           
'*                  :                                                        
'* Parameters       :                                                        
'*                  :                                                        
'* Return Value     :                                                  
' ***************************************************************************
Private Function NameOnly(FullPath)
  Dim pos
  Dim FileName

  pos = InStrRev(FullPath, "\")
  FileName = Right(FullPath, Len(FullPath) - pos)
  pos = InStr(FileName, ".")
  If pos <> 0 Then
    FileName = Left(FileName, pos - 1)
  End If
  NameOnly = FileName

End Function

' ***************************************************************************
'* Function Name    : AutoIncrementFile                                      
'* Description      : Look into the directory and return a filename with     
'*                              the maximum version number plus 1                      
'* Parameters       : Template - Name For the matching files                 
'*                  :                                                        
'* Return Value     : String For the maximum file version                    
' ***************************************************************************
Private Function AutoIncrementFile(Template, SubDir)
  Dim MaxVersion
  Dim Version
  Dim VerString
  Dim fso, f
  Dim folder, ListOfFiles
  Dim B, E
  Dim FileName
  
                                             ' Get the Name only filename

  if template = "" then                      ' Use def name if data name is "".                 
    AutoIncrementFile = UserDir & "\" & SubDir &  mRandomPos_Def_Filename  & ".MDB"
    exit function
  end if
    
  FileName = NameOnly(Template)
                                             ' See if version already specified
  B = InStrRev(Filename, "_")
  if B > (len(Filename) - 4) and isnumeric(mid(filename, B + 1)) then 
                                             ' If so, use that version regardless of prev
    AutoIncrementFile = UserDir & "\" & SubDir &  Filename  & ".MDB"
    exit function
  end if
                                             ' Filename was not blank or specific version
                                             ' Retrieve Files in the directory
  Set fso = CreateObject("Scripting.FileSystemObject")
  Set folder = fso.GetFolder(UserDir & "\" & SubDir)

  Set ListOfFiles = folder.Files
  MaxVersion = 0
                                             '* Loop through all the files and find the maximum version  
  For Each f In ListOfFiles                  ' f strips off path. 

                                             '* Make sure the filename that matches the Template is a MDB file
    If Left(f.Name, Len(FileName)) = FileName And _
       UCase(GetExtension(f.Name)) = "MDB" Then
       
      B = instr(f.name, "_")                 ' Make sure version number is there
                                             ' B is start of version number (after the underscore).
                                             ' Parse to the '.' in '.mdb'.
      if B > 0 then
        B = InStr(f.Name, FileName) + Len(FileName) + 1

        VerString = Mid(f.Name, B, Len(f.Name) - Len(FileName) - Len(".mdb") - 1)

        If (IsNumeric(VerString)) Then
          Version = VerString
          If CLng(Version) > CLng(MaxVersion) Then
            MaxVersion = Version
          End If
        End If
      End If
    End If
  Next

  AutoIncrementFile = UserDir & "\" & SubDir &  FileName & "_" & (MaxVersion + 1) & ".MDB"

End Function


' ***************************************************************************
'* Function Name    : GetExtension                                           
'* Description      : Return the files extension                             
'* Parameters       : filename - name of the file                            
'*                  :                                                        
'* Return Value     : String as the file's extension                         
' ***************************************************************************
Private Function GetExtension(FileName)
  GetExtension = Right(FileName, Len(FileName) - InStr(FileName, "."))
End Function
