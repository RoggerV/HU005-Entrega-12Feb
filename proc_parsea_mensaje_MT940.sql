USE [swift]
GO
/****** Object:  StoredProcedure [dbo].[proc_parsea_mensaje_MT940]    Script Date: 15-11-2023 9:39:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
--Parámetros/Ejemplo:
--@swf_bco                         =  'CITIUS33XXX'
--@ref_bch                          =  '753OUR000038720'
--@cobr_mnd                      =  'USD'
--@cobr_mto                      =  20.00
--@tipo_msg                       = 'MT191'
--@flg_firma_auto              = 1
--@mensaje                         =  '{1:F01BCHICLRMAXXX          }{2:I191CITIUS33XXXXN}{4: 
 
-- =============================================


IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE type = 'P' AND name = 'proc_parsea_mensaje_MT940')

BEGIN

    DECLARE @sql NVARCHAR(MAX);

				SET @sql = N'CREATE PROCEDURE  [dbo].[proc_parsea_mensaje_MT940]
@mensaje varchar(MAX),	 
@cdg_error     int  			= 0 output
,@dsc_error		varchar(200) 	= null output

AS
DECLARE
@iter int,
--Akzio 201812 se agregan variables para tag108
@POS_TAG108 int,
@POS_TAG108_FIN int,
@TAG108 varchar(50),

@TIPO_MENSAJE varchar(10), 
@BANCO varchar(20) , 
@REFERENCIA varchar(50) ,
@MONTO VARCHAR(50) ,
@MONEDA varchar(3) ,
@error varchar(max), 
@MONTO_FLOAT FLOAT,
@INDICE INTEGER
BEGIN


BEGIN TRY

IF PATINDEX(''%{1:%'',@mensaje) = 0 
BEGIN
	SET @error = ''Mensaje no contiene encabezado {1:''
	RETURN 
END 

SET @mensaje = REPLACE( @mensaje , ''<'',CHAR(13))
SET @mensaje = REPLACE( @mensaje , ''>'',CHAR(10))

IF PATINDEX(''%{2:I%'',@mensaje) >0  -- Inicio de 2:I
BEGIN
select

@TIPO_MENSAJE = CASE WHEN PATINDEX(''%{2:I%'',@mensaje) >0 
   THEN ''MT''+SUBSTRING(@mensaje,PATINDEX(''%{2:I%'',@mensaje)+4,3) 
   ELSE '''' END ,
@BANCO = CASE WHEN PATINDEX(''%{2:I%'',@mensaje) >0 
   THEN SUBSTRING(@mensaje,PATINDEX(''%{2:I%'',@mensaje)+7,12) 
   ELSE '''' END
END
IF CHARINDEX('':20:'',@mensaje) >0
BEGIN
    
	SET @REFERENCIA = SUBSTRING(@mensaje,CHARINDEX('':20:'',@mensaje)+5,15)

END 

 
IF  CHARINDEX('':62F'',@mensaje) >0
BEGIN
	SET @iter = 0
	SET @MONEDA = SUBSTRING(@mensaje,CHARINDEX('':62F:'',@mensaje)+12,3) 
	WHILE (SUBSTRING(@mensaje,PATINDEX(''%:62F:%'',@mensaje)+15+@iter,1) <> CHAR(13)) and
	((SUBSTRING(@mensaje,PATINDEX(''%:62F:%'',@mensaje)+15+@iter,1) = CHAR(13)) or
	SUBSTRING(@mensaje,PATINDEX(''%:62F:%'',@mensaje)+15+@iter,1) = CHAR(48) or
	SUBSTRING(@mensaje,PATINDEX(''%:62F:%'',@mensaje)+15+@iter,1) = CHAR(49) or
	SUBSTRING(@mensaje,PATINDEX(''%:62F:%'',@mensaje)+15+@iter,1) = CHAR(50) or
	SUBSTRING(@mensaje,PATINDEX(''%:62F:%'',@mensaje)+15+@iter,1) = CHAR(51) or
	SUBSTRING(@mensaje,PATINDEX(''%:62F:%'',@mensaje)+15+@iter,1) = CHAR(52) or
	SUBSTRING(@mensaje,PATINDEX(''%:62F:%'',@mensaje)+15+@iter,1) = CHAR(53) or
	 SUBSTRING(@mensaje,PATINDEX(''%:62F:%'',@mensaje)+15+@iter,1) = CHAR(54) or
	 SUBSTRING(@mensaje,PATINDEX(''%:62F:%'',@mensaje)+15+@iter,1) = CHAR(55) or
	 SUBSTRING(@mensaje,PATINDEX(''%:62F:%'',@mensaje)+15+@iter,1) = CHAR(56) or
	  SUBSTRING(@mensaje,PATINDEX(''%:62F:%'',@mensaje)+15+@iter,1) = CHAR(57) or
	  SUBSTRING(@mensaje,PATINDEX(''%:62F:%'',@mensaje)+15+@iter,1) = CHAR(44) )
		BEGIN
		   
			SET @iter = @iter + 1;
			
		END;
	SET @MONTO = SUBSTRING(@mensaje,PATINDEX(''%:62F:%'',@mensaje)+15,@iter)


	IF SUBSTRING(@MONTO,LEN(@MONTO),LEN(@MONTO)) = '',''
		SET @MONTO = REPLACE(@MONTO,'','','''')
	ELSE
		SET @MONTO = REPLACE(@MONTO,'','',''.'')
	
END
ELSE IF PATINDEX(''%:62M:%'',@mensaje) >0
BEGIN
	SET @iter = 0
	SET @MONEDA = SUBSTRING(@mensaje,CHARINDEX('':62M:'',@mensaje)+12,3) 
WHILE (SUBSTRING(@mensaje,PATINDEX(''%:62M:%'',@mensaje)+15+@iter,1) <> CHAR(13)) and
	((SUBSTRING(@mensaje,PATINDEX(''%:62M:%'',@mensaje)+15+@iter,1) = CHAR(13)) or
	SUBSTRING(@mensaje,PATINDEX(''%:62M:%'',@mensaje)+15+@iter,1) = CHAR(48) or
	SUBSTRING(@mensaje,PATINDEX(''%:62M:%'',@mensaje)+15+@iter,1) = CHAR(49) or
	SUBSTRING(@mensaje,PATINDEX(''%:62M:%'',@mensaje)+15+@iter,1) = CHAR(50) or
	SUBSTRING(@mensaje,PATINDEX(''%:62M:%'',@mensaje)+15+@iter,1) = CHAR(51) or
	SUBSTRING(@mensaje,PATINDEX(''%:62M:%'',@mensaje)+15+@iter,1) = CHAR(52) or
	SUBSTRING(@mensaje,PATINDEX(''%:62M:%'',@mensaje)+15+@iter,1) = CHAR(53) or
	 SUBSTRING(@mensaje,PATINDEX(''%:62M:%'',@mensaje)+15+@iter,1) = CHAR(54) or
	 SUBSTRING(@mensaje,PATINDEX(''%:62M:%'',@mensaje)+15+@iter,1) = CHAR(55) or
	 SUBSTRING(@mensaje,PATINDEX(''%:62M:%'',@mensaje)+15+@iter,1) = CHAR(56) or
	  SUBSTRING(@mensaje,PATINDEX(''%:62M:%'',@mensaje)+15+@iter,1) = CHAR(57) or
	  SUBSTRING(@mensaje,PATINDEX(''%:62M:%'',@mensaje)+15+@iter,1) = CHAR(44) )
	
		BEGIN
		    SET @iter = @iter + 1;
		END;
	SET @MONTO = SUBSTRING(@mensaje,PATINDEX(''%:62M:%'',@mensaje)+15,@iter)
	IF SUBSTRING(@MONTO,LEN(@MONTO),LEN(@MONTO)) = '',''
		SET @MONTO = REPLACE(@MONTO,'','','''')
	ELSE
		SET @MONTO = REPLACE(@MONTO,'','',''.'')
END
EXEC	 [trans].[sp_ins_mtxxx]
		@swf_bco = @BANCO,
		@ref_bch = @REFERENCIA,
		@cobr_mnd = @MONEDA,
		@cobr_mto =@MONTO,
		@tipo_msg = @TIPO_MENSAJE,
		@mensaje = @mensaje,
		@flg_firma_auto = 1,
		@cdg_error = @cdg_error OUTPUT,
		@dsc_error = @dsc_error OUTPUT

END TRY
BEGIN CATCH

SELECT	@cdg_error as N''@cdg_error'',
		@dsc_error as N''@dsc_error''


END CATCH

END'


    EXEC sp_executesql  @sql;

END

GO
USE [swift]
GO
/****** Object:  StoredProcedure [dbo].[proc_parsea_mensaje_MT940]    Script Date: 15-11-2023 9:39:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
--Parámetros/Ejemplo:
--@swf_bco                         =  'CITIUS33XXX'
--@ref_bch                          =  '753OUR000038720'
--@cobr_mnd                      =  'USD'
--@cobr_mto                      =  20.00
--@tipo_msg                       = 'MT191'
--@flg_firma_auto              = 1
--@mensaje                         =  '{1:F01BCHICLRMAXXX          }{2:I191CITIUS33XXXXN}{4: 
 
-- =============================================
ALTER PROCEDURE  [dbo].[proc_parsea_mensaje_MT940]
@mensaje varchar(MAX),	 
@cdg_error     int  			= 0 output
,@dsc_error		varchar(200) 	= null output

AS
DECLARE
@iter int,
--Akzio 201812 se agregan variables para tag108
@POS_TAG108 int,
@POS_TAG108_FIN int,
@TAG108 varchar(50),

@TIPO_MENSAJE varchar(10), 
@BANCO varchar(20) , 
@REFERENCIA varchar(50) ,
@MONTO VARCHAR(50) ,
@MONEDA varchar(3) ,
@error varchar(max), 
@MONTO_FLOAT FLOAT,
@INDICE INTEGER

BEGIN


BEGIN TRY

IF PATINDEX('%{1:%',@mensaje) =0 
BEGIN
	SET @error = 'Mensaje no contiene encabezado {1:'
	RETURN 
END 

SET @mensaje = REPLACE( @mensaje , '<',CHAR(13))
SET @mensaje = REPLACE( @mensaje , '>',CHAR(10))

IF PATINDEX('%{2:I%',@mensaje) >0  -- Inicio de 2:I
BEGIN
select

@TIPO_MENSAJE = CASE WHEN PATINDEX('%{2:I%',@mensaje) >0 
   THEN 'MT'+SUBSTRING(@mensaje,PATINDEX('%{2:I%',@mensaje)+4,3) 
   ELSE '' END ,
@BANCO = CASE WHEN PATINDEX('%{2:I%',@mensaje) >0 
   THEN SUBSTRING(@mensaje,PATINDEX('%{2:I%',@mensaje)+7,12) 
   ELSE '' END
END
IF CHARINDEX(':20:',@mensaje) >0
BEGIN
    
	SET @REFERENCIA = SUBSTRING(@mensaje,CHARINDEX(':20:',@mensaje)+5,15)

END 

 
IF  CHARINDEX(':62F',@mensaje) >0
BEGIN
	SET @iter = 0
	SET @MONEDA = SUBSTRING(@mensaje,CHARINDEX(':62F:',@mensaje)+12,3) 
	WHILE (SUBSTRING(@mensaje,PATINDEX('%:62F:%',@mensaje)+15+@iter,1) <> CHAR(13)) and
	((SUBSTRING(@mensaje,PATINDEX('%:62F:%',@mensaje)+15+@iter,1) <> CHAR(10)))
		BEGIN
			SET @iter = @iter + 1;
		END;
	SET @MONTO = SUBSTRING(@mensaje,PATINDEX('%:62F:%',@mensaje)+15,@iter)
	IF SUBSTRING(@MONTO,LEN(@MONTO),LEN(@MONTO)) = ','
		SET @MONTO = REPLACE(@MONTO,',','')
	ELSE
		SET @MONTO = REPLACE(@MONTO,',','.')
	
END
ELSE IF PATINDEX('%:62M:%',@mensaje) >0
BEGIN
	SET @iter = 0
	SET @MONEDA = SUBSTRING(@mensaje,CHARINDEX(':62M:',@mensaje)+12,3) 
	WHILE (SUBSTRING(@mensaje,PATINDEX('%:62M:%',@mensaje)+15+@iter,1) <> CHAR(13)) and
	((SUBSTRING(@mensaje,PATINDEX('%:62M:%',@mensaje)+15+@iter,1) = CHAR(13)) or
	SUBSTRING(@mensaje,PATINDEX('%:62M:%',@mensaje)+15+@iter,1) = CHAR(48) or
	SUBSTRING(@mensaje,PATINDEX('%:62M:%',@mensaje)+15+@iter,1) = CHAR(49) or
	SUBSTRING(@mensaje,PATINDEX('%:62M:%',@mensaje)+15+@iter,1) = CHAR(50) or
	SUBSTRING(@mensaje,PATINDEX('%:62M:%',@mensaje)+15+@iter,1) = CHAR(51) or
	SUBSTRING(@mensaje,PATINDEX('%:62M:%',@mensaje)+15+@iter,1) = CHAR(52) or
	SUBSTRING(@mensaje,PATINDEX('%:62M:%',@mensaje)+15+@iter,1) = CHAR(53) or
	 SUBSTRING(@mensaje,PATINDEX('%:62M:%',@mensaje)+15+@iter,1) = CHAR(54) or
	 SUBSTRING(@mensaje,PATINDEX('%:62M:%',@mensaje)+15+@iter,1) = CHAR(55) or
	 SUBSTRING(@mensaje,PATINDEX('%:62M:%',@mensaje)+15+@iter,1) = CHAR(56) or
	  SUBSTRING(@mensaje,PATINDEX('%:62M:%',@mensaje)+15+@iter,1) = CHAR(57) or
	  SUBSTRING(@mensaje,PATINDEX('%:62M:%',@mensaje)+15+@iter,1) = CHAR(44) )
		BEGIN
			SET @iter = @iter + 1;
		END;
	SET @MONTO = SUBSTRING(@mensaje,PATINDEX('%:62M:%',@mensaje)+15,@iter)
	IF SUBSTRING(@MONTO,LEN(@MONTO),LEN(@MONTO)) = ','
		SET @MONTO = REPLACE(@MONTO,',','')
	ELSE
		SET @MONTO = REPLACE(@MONTO,',','.')
END


EXEC	 [trans].[sp_ins_mtxxx]
		@swf_bco = @BANCO,
		@ref_bch = @REFERENCIA,
		@cobr_mnd = @MONEDA,
		@cobr_mto =@MONTO,
		@tipo_msg = @TIPO_MENSAJE,
		@mensaje = @mensaje,
		@flg_firma_auto = 1,
		@cdg_error = @cdg_error OUTPUT,
		@dsc_error = @dsc_error OUTPUT	

END TRY
BEGIN CATCH

SELECT	@cdg_error as N'@cdg_error',
		@dsc_error as N'@dsc_error'


END CATCH

END