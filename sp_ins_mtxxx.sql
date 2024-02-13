USE [swift]
GO
/****** Object:  StoredProcedure [trans].[sp_ins_mtxxx]    Script Date: 06-02-2024 10:33:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

ALTER PROCEDURE [trans].[sp_ins_mtxxx] (
/*--=============================================================================================================
-- Proceso           	: [trans].[sp_ins_mtxxx]
-- Objetivo          	: inserta y firma los mensajes automaticamente, para que la malla swift-env se los lleve a SSA
-- Ejemplo ejecucion	: 
					
						exec [trans].[sp_ins_mtxxx]
									 @swf_bco		 =  'CITIUS33XXX'
									,@ref_bch		 =  '753OUR000038720'
									,@cobr_mnd		 =  'USD'
									,@cobr_mto		 =  20.00
									,@tipo_msg		 = 'MT191'
									,@flg_firma_auto  = 1
									,@mensaje		=  '{1:F01BCHICLRMAXXX          }{2:I191CITIUS33XXXXN}{4:
									:20:753OUR000038720
									:21:G0191142016101
									:32B:USD20,
									:71B:/COMM/
									:72:PLEASE CREDIT OUR ACCT THAT WE HOLD
									WITH YOU FOR OUR EXPENSES QUOTING
									ALWAYS OUR REF 753OUR000038720 IN
									FIELD 21
									-}'
									

--
--                          			
-- Creador           	: yo
-- Fecha Creacion    	: 27-09-2023
--=============================================================================================================*/
		 @swf_bco		nvarchar(15)	
		,@ref_bch		nvarchar(35)	
		,@cobr_mnd		nvarchar(3)		
		,@cobr_mto		float  
		,@tipo_msg		nvarchar(20)
		,@mensaje		nvarchar(max)   
		,@flg_firma_auto int 
		,@cdg_error     int  			= 0 output
		,@dsc_error		nvarchar(200) 	= null output
)
AS		
BEGIN
	SET XACT_ABORT ON;
	SET NOCOUNT ON;	

	
	
-------------------------------------------------------------
--llenados en este SP 
-------------------------------------------------------------
 
declare
 @folio			int             = 0
,@casilla		varchar(3)      = null
,@sesion		int				= 0
,@secuencia		int				= 0
,@unidad		nvarchar(3)     = null
,@beneficiario  nvarchar(100)   = null
,@comentario	nvarchar(100)	= null
,@prioridad     nvarchar(100)   = null 
,@estado_msg   	nvarchar(100)   = null 
,@tipo_ingreso 	nvarchar(100)   = null 
,@rut_digita   	nvarchar(100)   = null 
,@banco_em     	nvarchar(100)   = null 
,@branch_em    	nvarchar(100)   = null 
,@banco_re     	nvarchar(100)   = null 
,@branch_re    	nvarchar(100)   = null
,@idprog_log   	nvarchar(100)   = null
,@resultado_log	nvarchar(100)   = null
,@rut			nvarchar(100)   = null
,@p_rut_log		nvarchar(100)   = null
,@p_comentario  nvarchar(100)   = null
,@fecha         datetime        = getdate()
--,@flg_firma_auto int            = 0

------------------------------------------------------------
declare  firma_c cursor for select CONVERT(INT,ISNULL(SUBSTRING(trans_vlr_parametro,1,CHARINDEX('-',trans_vlr_parametro)-1),0))
from cext01.trans.stp_parametros_comex
where trans_cdg_idproducto = 'OPE'
AND trans_nmb_agrupacion_1 = 'Proyecto STP'
AND trans_nmb_agrupacion_2 = 'Firma SWIFT'
AND trans_nmb_agrupacion_3 = 'Autorizador'


-----------------------------------------------------------

declare @folio_t table(folio int)
------------------------------------------------------------

select  @banco_re   = substring(@swf_bco,1,8)
       ,@branch_re  = substring(@swf_bco,9,3)


SELECT 
 @sesion		 = convert(int,isnull([sesion],0)) 
,@secuencia      = convert(int,isnull([secuencia],0))
,@casilla        = [casilla]
,@unidad         = [unidad ]
,@prioridad      = [prioridad]
,@estado_msg     = [estado_msg]
,@tipo_ingreso   = [tipo_ingreso]
,@rut_digita     = [rut_digita]
,@banco_em       = [banco_em]
,@branch_em      = [branch_em]
,@beneficiario   = [beneficiario]
,@comentario     = [comentario]
,@idprog_log     = [idprog_log]
,@resultado_log  = [resultado_log]
,@p_rut_log		 = [p_rut_log]		 
,@p_comentario   = [p_comentario]  
--,@flg_firma_auto = convert(int,isnull([flg_firma_auto],0)) 
FROM  
(
	SELECT trans_dsc_parametro 
	,trans_vlr_parametro 
	FROM [cext01].[trans].[stp_parametros_comex]
	where trans_cdg_idproducto = 'ISOSW'
	AND trans_nmb_agrupacion_1 = 'Proyecto ISO20022'
	AND trans_nmb_agrupacion_2 = 'SP_INYECTA' 
) AS SourceTable  
PIVOT  
(  
  max(trans_vlr_parametro)  
  FOR trans_dsc_parametro IN ([sesion]
							, [secuencia]
							, [casilla]
							, [unidad ]
							, [prioridad]
							, [estado_msg]
							, [tipo_ingreso]
							, [rut_digita]
							, [banco_em]
							, [branch_em]
							, [beneficiario]
							, [comentario]
							, [idprog_log]
							, [resultado_log]
							, [p_rut_log]		
							, [p_comentario] 
							--, [flg_firma_auto]
							)  
) AS PivotTable; 


insert into @folio_t
exec [dbo].[proc_sw_trae_folio_MS] 'ENVIO'

select @folio = folio from @folio_t

------------------------------------
--deja el mensaje en estado INY
------------------------------------

exec [cext01].[ope].[sp_sel_EncriptaMensajeS_MS] 
@id_mensaje			= @folio
,@sesion			= @sesion 
,@secuencia			= @secuencia
,@casilla			= @casilla
,@unidad			= @unidad 
,@tipo_msg			= @tipo_msg 
,@prioridad			= @prioridad  
,@estado_msg		= @estado_msg 
,@tipo_ingreso		= @tipo_ingreso     
,@rut_digita		= @rut_digita  
,@banco_re			= @banco_re
,@branch_re			= @branch_re
,@banco_em			= @banco_em
,@branch_em			= @branch_em	
,@moneda			= @cobr_mnd         
,@monto				= @cobr_mto   
,@referencia		= @ref_bch
,@beneficiario		= @beneficiario 
,@txt_mensaje		= @mensaje
,@comentario 		= @comentario  


------------------------------------
--deja el mensaje en estado INY
------------------------------------


EXEC proc_sw_msgsend_log_i01_MS
 @id_mensaje 		= @folio 
,@fecha_log 		= @fecha  
,@rutais_log 		= @rut_digita  
,@idprog_log 		= @idprog_log
,@opcion_log 		= @tipo_ingreso
,@casilla_destino 	= @casilla 
,@estado_destino 	= @estado_msg  
,@unidad_log 		= @unidad  
,@resultado_log 	= @resultado_log  
,@comentario_log 	= @comentario 

----------------------------------------------------

EXEC [dbo].[proc_sw_env_del_firnul_MS] 
@p_id_mensaje = @folio 
,@p_rut_solic = @rut_digita 
,@p_fecha_solic = @fecha


--------------------------------------------------------
--llama sp de firma 
--------------------------------------------------------
IF @flg_firma_auto <> 1 
BEGIN 

SELECT   @cdg_error = 0
		,@dsc_error = 'Datos procesados con exito sin firmar'

END
ELSE 
BEGIN

			OPEN firma_c 
			FETCH NEXT FROM firma_c   
			INTO @rut
			WHILE @@FETCH_STATUS = 0
			BEGIN
			
					exec [dbo].[proc_sw_env_ing_firma_MS]
															@p_id_mensaje = @folio 
															,@p_rut_firma = @rut
															,@p_tipo_firma = 'B' 
															,@p_estado = 'N' 
															,@p_revfir = 'F' 
															,@p_rut_solic = @rut_digita 
															,@p_fecha_solic = @fecha 
															,@p_avisado = 'S'
			
			
				
				FETCH NEXT FROM firma_c   
				INTO @rut
			END   
			CLOSE firma_c;  
			DEALLOCATE firma_c; 
			
			
			-------------------------------------------------------------
			--AUTORIZACIÓN 
			-------------------------------------------------------------
			
			EXEC [dbo].[proc_sw_env_graba_sap_MS]
			@p_casilla = @casilla 
			,@p_id_mensaje =  @folio  
			,@p_rut_log = @p_rut_log
			,@p_fecha_sap = @fecha 
			,@p_comentario = @p_comentario
			
			
			------------------------------------------------------------------
			--PASO FINAL ULTI VIKTOR xD
			------------------------------------------------------------------
			
			exec [dbo].[proc_sw_env_graba_aum_MS]
			@p_id_mensaje = @folio  
			,@p_casilla = @casilla  
			,@p_rut_log = @p_rut_log
			,@p_fecha_aum = @fecha 
			,@p_comentario = @p_comentario
			
			------------------------------------------------------------------
			
			SELECT   @cdg_error = 0
		            ,@dsc_error = 'Datos procesados con exito firmadas'
END 
	
END;

