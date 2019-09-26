--------------------------------------------------------
--  DDL for Package PKG_APEX_DASHBOARD
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "EPC_CUSTOM"."PKG_APEX_DASHBOARD" AS 
/* This package supplies methods for the APEX application "PENTA Reports and Utilities" */

FUNCTION f_getUDFValue(p_in_column_name in varchar2, p_in_udf_row_id in varchar2, p_in_eff_date in date) return varchar2;
FUNCTION f_getUDFDate(p_in_column_name in varchar2, p_in_udf_row_id in varchar2, p_in_eff_date in date) return date;
--FUNCTION f_getCOValue (p_in_udf_row_id in varchar2, p_in_eff_date in date) return number;
FUNCTION f_getCOValue (p_in_job_id in varchar2, p_in_eff_date in date) return number;
--Reporting
PROCEDURE P_DELETE_FROM_EPC_JOB_VARIANCE(P_IN_AS_OF_DATE IN DATE );
  
PROCEDURE P_LOAD_EPC_JOB_VARIANCE(P_IN_DATE IN DATE);
--Interface

  /* TODO enter package declarations (types, exceptions, methods etc) here */ 

PROCEDURE LOCK_EPC_JOB_VARIANCE_RPT(p_in_locked IN varchar2);

FUNCTION num_business_days(start_date IN DATE, end_date IN DATE) RETURN NUMBER; 



END PKG_APEX_DASHBOARD;

/
--------------------------------------------------------
--  DDL for Package Body PKG_APEX_DASHBOARD
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "EPC_CUSTOM"."PKG_APEX_DASHBOARD" AS

    FUNCTION f_getUDFValue(p_in_column_name in varchar2, p_in_udf_row_id in varchar2, p_in_eff_date in date) return varchar2
    AS
    p_out varchar2(2000);

    BEGIN
        
     
        SELECT ALPHA_VALUE INTO p_out 
            FROM PENTA.UDF_VALUES WHERE 
            UDF_TABLE_NAME = 'JOB'
            AND UDF_COLUMN_NAME = p_in_column_name
            AND VALUE_CD = penta.pk_udfdata.f_value(p_in_udf_row_id, p_in_column_name,p_in_eff_Date) ;
        RETURN p_out;
    END;

    FUNCTION f_getUDFDate(p_in_column_name in varchar2, p_in_udf_row_id in varchar2, p_in_eff_date in date) return date
    AS
    p_out date;

    BEGIN
        
        SELECT max(D_EFF_DATE) into p_out
            FROM PENTA.UDF_DATA_HIST H
            WHERE UDF_TABLE_NAME = 'JOB'
            AND UDF_COLUMN_NAME = p_in_column_name
            AND D_EFF_DATE <= p_in_eff_date
            AND UDF_ROW_ID = p_in_udf_row_id;
     
        RETURN p_out;
    END;

    FUNCTION f_getCOValue (p_in_job_id in varchar2, p_in_eff_date in date) return number
    AS
    
    P_out number;
    BEGIN
       SELECT SUM(CURR_APPROVED_CR_AMT) into p_out
       FROM PENTA.CHANGEREQUEST_V C
       WHERE C.JOB_ID = p_in_job_id AND D_ISSUE_DATE  <= p_in_eff_Date;
       
       
       /* SELECT NUMBER_VALUE into p_out
        FROM PENTA.UDF_DATA_HIST
        WHERE UDF_TABLE_NAME = 'JOB'
            AND UDF_COLUMN_NAME = 'CHANGE_ORDER_VALUE'
            AND CREATION_DATE = (select max(CREATION_DATE) FROM PENTA.UDF_DATA_HIST  WHERE UDF_TABLE_NAME = 'JOB'
                                    AND UDF_COLUMN_NAME = 'CHANGE_ORDER_VALUE'
                                    AND UDF_ROW_ID = p_in_udf_row_id
                                    AND CREATION_DATE <= p_in_eff_date)
            AND UDF_ROW_ID = p_in_udf_row_id; */
            RETURN p_out;
    END;
  /*------------------------------------------------------------------------------------------------------------------*/
  PROCEDURE P_DELETE_FROM_EPC_JOB_VARIANCE(P_IN_AS_OF_DATE IN DATE ) AS
  BEGIN
     DELETE FROM EPC_JOB_VARIANCE WHERE AS_OF_DATE = P_IN_AS_OF_DATE;
     COMMIT;
  END P_DELETE_FROM_EPC_JOB_VARIANCE;


/*------------------------------------------------------------------------------------------------------------------*/
  PROCEDURE P_LOAD_EPC_JOB_VARIANCE(P_IN_DATE IN DATE) AS
  BEGIN
      insert into epc_custom.epc_job_variance
          (AS_OF_DATE
          , PM_PC
          , JOB_ID
          , NAME
          , EARNED_REVENUE_JTD
          , BILLED
          , TOTAL_APPROVED_CONTRACT
          , REVENUE_OVER_UNDERBILLED
          , PCT_M_SPENT
          , PCT_WORK_COMPLETED
          , LAST_COST_DAYS
          , LOWER_THRESHOLD
          , UPPER_THRESHOLD
          , INVOICE_JOB_ID
          , CUSTOMER_PO_NUMBER
          , CHANGE_ORDER_VALUE
          , ESTIMATED_COST_JTD
          , COST_JTD
          , CUS_ID
          , CUS_NAME
          , CCC_STATUS
          , CCC_DATE
          , FAC_STATUS
          , FAC_DATE
          , CONTRACT_TYPE
          )
          (select
          P_IN_DATE "AS_OF_DATE"
          ,EPC_CUSTOM.pkg_cr_utilities.fn_getEmployeeName(j.pmgr_emp_id) "PM/PC"
          ,j.job_id
          ,j.NAME
          ,PENTA.pk_jobRevenue.f_earned (j.job_id ,P_IN_DATE,SYSDATE) "EARNED_REVENUE_JTD"
          ,PENTA.pk_jobrevenue.f_billed (j.job_id,P_IN_DATE,P_IN_DATE) "BILLED"
          ,PENTA.pk_jobrevenue.f_contract(j.job_id,15, P_IN_DATE,P_IN_DATE) "Total Approved Contract" --Includes change orders
          ,-1*PENTA.pk_jobRevenue.f_overUnderBilled(j.job_id, P_IN_DATE,SYSDATE)  "Revenue (over)/under M#"
          --PENTA.pk_jobrevenue.f_contract(j.job_id,15, P_IN_DATE,P_IN_DATE)-PENTA.pk_jobrevenue.f_earned (j.job_id,P_IN_DATE,SYSDATE) "Revenue (over)/under M#"
          --case when PENTA.pk_jobrevenue.f_contract(j.job_id,15)=0 then 0 else
          ,round(abs(PENTA.pk_jobrevenue.f_billed (j.job_id,P_IN_DATE,P_IN_DATE) / NULLIF( PENTA.pk_jobrevenue.f_contract(j.job_id,15,P_IN_DATE,P_IN_DATE),0)) * 100,0) "% M# Spent"
          ,NULL /*j.PCT_WORK_COMPLETE*/   "% Work Complete" --will become calculated
          ,TRUNC(P_IN_DATE - PENTA.pk_jobActuals.f_lastEntryDate(j.job_id, '%', '%',P_IN_DATE,P_IN_DATE)) "Last Cost (Days)"
          ,CASE WHEN PENTA.pk_jobrevenue.f_contract(j.job_id,15, P_IN_DATE,P_IN_DATE) >= 20000 and PENTA.pk_jobrevenue.f_contract(j.job_id,15, P_IN_DATE,P_IN_DATE) <= 200000 THEN
                PENTA.pk_jobrevenue.f_contract(j.job_id,15,P_IN_DATE,P_IN_DATE) * 0.85
              WHEN PENTA.pk_jobrevenue.f_contract(j.job_id,15, P_IN_DATE,P_IN_DATE) < 20000 then 
                PENTA.pk_jobrevenue.f_contract(j.job_id,15,P_IN_DATE,P_IN_DATE) 
              ELSE
                PENTA.pk_jobrevenue.f_contract(j.job_id,15,P_IN_DATE,P_IN_DATE) * 0.9 
              END "Lower Threshold"
          ,CASE WHEN PENTA.pk_jobrevenue.f_contract(j.job_id,15, P_IN_DATE,P_IN_DATE) >= 20000 and PENTA.pk_jobrevenue.f_contract(j.job_id,15, P_IN_DATE,P_IN_DATE) <= 200000 THEN
                PENTA.pk_jobrevenue.f_contract(j.job_id,15,P_IN_DATE,P_IN_DATE) * 1.15
              WHEN PENTA.pk_jobrevenue.f_contract(j.job_id,15, P_IN_DATE,P_IN_DATE) < 20000 then 
                PENTA.pk_jobrevenue.f_contract(j.job_id,15,P_IN_DATE,P_IN_DATE) 
              ELSE
                PENTA.pk_jobrevenue.f_contract(j.job_id,15,P_IN_DATE,P_IN_DATE) * 1.1 
                END "Upper Threshold"
          ,j.INVOICE_JOB_ID --NEW
          ,j.CUSTOMER_PO_NUMBER --NEw
          ,PENTA.pk_jobrevenue.f_contract(j.job_id,15, P_IN_DATE,P_IN_DATE) - PENTA.pk_jobrevenue.f_contract(j.job_id,1, P_IN_DATE,P_IN_DATE) CHANGE_ORDER_VALUE
          --,f_getCOValue(j.job_id,  P_IN_DATE) CHANGE_ORDER_VALUE --NEW
          ,PENTA.pk_jobestimates.f_cost(j.job_id,'%','%',15,P_IN_DATE,SYSDATE) "ESTIMATED_COST_JTD" 
          ,PENTA.pk_jobactuals.f_costToDate(j.job_id,'%','%',P_IN_DATE,P_IN_DATE)"COST_JTD" --NEW
          , j.CUS_ID
          , (SELECT NAME FROM PENTA.CUSTOMER C where C.CUS_ID = j.CUS_ID) 
          , f_getUDFValue('CCC_STATUS', j.udf_row_id, P_IN_DATE) CCC_STATUS
          , f_getUDFDate('CCC_STATUS', j.udf_row_id, P_IN_DATE) CCC_STATUS_ED
          , f_getUDFValue('FAC_STATUS',j.udf_row_id, P_IN_DATE) FAC_STATUS
          , f_getUDFDate('FAC_STATUS', j.udf_row_id, P_IN_DATE)FAC_STATUS_ED
          , CASE WHEN j.CUS_ID = 'E-CIT-270' THEN 'ESA'
            WHEN j.CUS_ID = 'E-CIT-248' THEN 'TSESA'
            WHEN j.CUS_ID = 'E-CIT-275' THEN 'COE-SA'
            WHEN j.CUS_ID not in  ('E-CIT-270','E-CIT-248','E-CIT-275') AND COALESCE(j.LAB_RATE_SCHD_NUM, j.CT_MKUP_SCHD_NUM ,j.EQ_RATE_SCHD_NUM,j.INV_MKUP_SCHD_NUM) is not null then '3rd Party Cost Plus'
            ELSE '3rd Party Lump Sum' END
      from penta.job_udf j
        where 
              j.job_stat_cd <> 'C' 
              and length(j.job_id) = 6 
              and j.pmgr_emp_id is not null
              and j.cus_id <> 'ETECH OH'
              --and substr(j.job_id,0,2) >= '18'--Debug Only
      group by 
      COALESCE(j.LAB_RATE_SCHD_NUM, j.CT_MKUP_SCHD_NUM ,j.EQ_RATE_SCHD_NUM,j.INV_MKUP_SCHD_NUM)
      , j.pmgr_emp_id
      , j.job_id
      , j.Name
      , j.INVOICE_JOB_ID
      , j.CUSTOMER_PO_NUMBER
      , j.CHANGE_ORDER_VALUE
      , j.PCT_WORK_COMPLETE
      , j.CUS_ID 
      , j.CCC_STATUS
      , j.CCC_STATUS_ED
      , J.FAC_STATUS
      , J.FAC_STATUS_ED
      , j.udf_row_id);
      
        commit;
  END P_LOAD_EPC_JOB_VARIANCE;
  
  /*------------------------------------------------------------------------------------------------------------------*/
  PROCEDURE LOCK_EPC_JOB_VARIANCE_RPT(p_in_locked IN varchar2) as
  begin
    UPDATE EPC_CUSTOM.EPC_JOB_VARIANCE_LOCKED SET LOCKED = p_in_locked;
    commit;
  end LOCK_EPC_JOB_VARIANCE_RPT;

  --FUNCTION P_PROCESS_INTR_BATCH (p_in_intr_rqst_id in varchar2, p_in_batch_type in varchar2, p_uid in varchar2, p_pwd in varchar2) return varchar2
  
  FUNCTION num_business_days(start_date IN DATE, end_date IN DATE)
    RETURN NUMBER IS
    busdays NUMBER := 0;
    stDate DATE;
    enDate DATE;
    
    BEGIN
    
    stDate := TRUNC(start_date);
    enDate := TRUNC(end_date);
    
    if enDate >= stDate
    then
    -- Get the absolute date range
    busdays := enDate - stDate
    -- Now subtract the weekends
    -- this statement rounds the range to whole weeks (using
    -- TRUNC and determines the number of days in the range.
    -- then it divides by 7 to get the number of weeks, and
    -- multiplies by 2 to get the number of weekend days.
    - ((TRUNC(enDate,'D')-TRUNC(stDate,'D'))/7)*2
    -- Add one to make the range inclusive
    + 1;
    
    /* Adjust for ending date on a saturday */
    IF TO_CHAR(enDate,'D') = '7' THEN
    busdays := busdays - 1;
    END IF;
    
    /* Adjust for starting date on a sunday */
    IF TO_CHAR(stDate,'D') = '1' THEN
    busdays := busdays - 1;
    END IF;
    else
    busdays := 0;
    END IF;
    
    RETURN(busdays);
    END;
END PKG_APEX_DASHBOARD;

/
