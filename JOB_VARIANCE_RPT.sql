--------------------------------------------------------
--  DDL for Table EPC_JOB_VARIANCE
--------------------------------------------------------

  CREATE TABLE "EPC_CUSTOM"."EPC_JOB_VARIANCE" 
   (	"AS_OF_DATE" DATE, 
	"PM_PC" VARCHAR2(125 BYTE), 
	"JOB_ID" VARCHAR2(12 BYTE), 
	"NAME" VARCHAR2(500 BYTE), 
	"BILLED" NUMBER, 
	"TOTAL_APPROVED_CONTRACT" NUMBER, 
	"REVENUE_OVER_UNDERBILLED" NUMBER, 
	"PCT_M_SPENT" NUMBER, 
	"PCT_WORK_COMPLETED" NUMBER(*,4), 
	"FORECAST_TOTAL_REV" NUMBER, 
	"FORECAST_UNBILLABLE_COST" NUMBER, 
	"LAST_COST_DAYS" NUMBER, 
	"LOWER_THRESHOLD" NUMBER, 
	"UPPER_THRESHOLD" NUMBER, 
	"STATUS_EXPLANATION" VARCHAR2(2000 BYTE), 
	"ROW_NUM" NUMBER, 
	"ACTION_ITEMS" VARCHAR2(2000 BYTE), 
	"INVOICE_JOB_ID" VARCHAR2(125 BYTE), 
	"CUSTOMER_PO_NUMBER" VARCHAR2(125 BYTE), 
	"CHANGE_ORDER_VALUE" NUMBER, 
	"ESTIMATED_COST_JTD" NUMBER, 
	"COST_JTD" NUMBER, 
	"EARNED_REVENUE_JTD" NUMBER, 
	"INVOICE_STATUS" VARCHAR2(50 BYTE), 
	"CUS_ID" VARCHAR2(20 BYTE), 
	"CUS_NAME" VARCHAR2(100 BYTE), 
	"CCC_STATUS" VARCHAR2(50 BYTE), 
	"CCC_DATE" DATE, 
	"FAC_STATUS" VARCHAR2(50 BYTE), 
	"FAC_DATE" DATE, 
	"ESTIMATE_VALUE" NUMBER, 
	"CONTRACT_TYPE" VARCHAR2(50 BYTE)
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "PENTA_DATA"   NO INMEMORY ;
--------------------------------------------------------
--  DDL for Index EPC_JOB_VARIANCE_PK
--------------------------------------------------------

  CREATE UNIQUE INDEX "EPC_CUSTOM"."EPC_JOB_VARIANCE_PK" ON "EPC_CUSTOM"."EPC_JOB_VARIANCE" ("ROW_NUM") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "PENTA_DATA" ;
--------------------------------------------------------
--  DDL for Trigger EPC_JOB_VARIANCE_ROW_NUM
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TRIGGER "EPC_CUSTOM"."EPC_JOB_VARIANCE_ROW_NUM" 
BEFORE INSERT ON EPC_JOB_VARIANCE 
FOR EACH ROW
BEGIN
  if inserting then
      if :NEW."ROW_NUM" is null then
         select EPC_JOB_VARIANCE_SEQ.nextval into :NEW."ROW_NUM" from dual;
      end if;
   end if;
END;
/
ALTER TRIGGER "EPC_CUSTOM"."EPC_JOB_VARIANCE_ROW_NUM" ENABLE;
--------------------------------------------------------
--  Constraints for Table EPC_JOB_VARIANCE
--------------------------------------------------------

  ALTER TABLE "EPC_CUSTOM"."EPC_JOB_VARIANCE" ADD CONSTRAINT "EPC_JOB_VARIANCE_PK" PRIMARY KEY ("ROW_NUM")
  USING INDEX PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "PENTA_DATA"  ENABLE;
  ALTER TABLE "EPC_CUSTOM"."EPC_JOB_VARIANCE" MODIFY ("ROW_NUM" NOT NULL ENABLE);