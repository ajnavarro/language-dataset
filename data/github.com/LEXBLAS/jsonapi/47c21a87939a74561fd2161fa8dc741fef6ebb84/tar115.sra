$PBExportHeader$tar115.sra
$PBExportComments$Generated Application Object
forward
global type tar115 from application
end type
global transaction sqlca
global dynamicdescriptionarea sqlda
global dynamicstagingarea sqlsa
global error error
global message message
end forward

global type tar115 from application
string appname = "tar115"
end type
global tar115 tar115

on tar115.create
appname="tar115"
message=create message
sqlca=create transaction
sqlda=create dynamicdescriptionarea
sqlsa=create dynamicstagingarea
error=create error
end on

on tar115.destroy
destroy(sqlca)
destroy(sqlda)
destroy(sqlsa)
destroy(error)
destroy(message)
end on

event open;open(w_jsontest)
end event

