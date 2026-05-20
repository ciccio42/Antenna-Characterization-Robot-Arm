Dim OK
Dim iStep
dim axis(2)

'ACDF_NAME = "prova_init"
'ACDF_DATA = "prova_init_data"

axis = GetRFandPosition(0)

Status "RF and Position result " & axis


'OK = ClsDirectAcq.CreateDataFile(ACDF_NAME , ACDF_DATA)

'If OK Then
'     Status "Created acqusition datafile: " & ACDF_DATA 
'  Else
'    Status "Error creating acquisition datafile: " & ACDF_DATA 
'    CauseAbort
'End If

iStep = 1
'OK = ClsDirectAcq.InitForScan(iStep)
'OK = ClsDirectAcq.DoOneScan(iStep, False, -1)

'OK = clsDirectAcq.CloseDataFile()

'Acquire ACDF_NAME 
'If not isAbort then
'	Status "Acquisition Completed"
'ELSE
'	STATUS "Acquisition Aborted"
'END IF