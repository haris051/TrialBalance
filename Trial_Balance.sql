drop procedure if Exists PROC_TRIAL_BALANCE;
DELIMITER $$
CREATE PROCEDURE `PROC_TRIAL_BALANCE`(P_ACCOUNT_ID TEXT,
				      P_ACCOUNT_TYPE TEXT, 
				      P_ENTRY_DATE_FROM TEXT,
				      P_ENTRY_DATE_TO TEXT,
				      P_START INT,
				      P_LENGTH INT,
				      P_COMPANY_ID INT,
				      P_YEAR TEXT )
BEGIN


    IF P_ACCOUNT_ID = "" THEN
		SET P_ACCOUNT_ID = '-1';
    END IF;
    
	IF P_ACCOUNT_TYPE = "" THEN
		SET P_ACCOUNT_TYPE = '-1';
    END IF;
	
	IF P_COMPANY_ID = "" Then 
		SET P_COMPANY_ID = "-1";
	END if;
    
        
	
	 SET @QRY = CONCAT('
				Select 
						
						I.ACC_ID,
						I.Description as "DESCRIPTION",
						Round(cast(SUM(I.Debit) as Decimal(22,2)),2) as "DEBIT",
						Round(cast(SUM(I.Credit) as Decimal(22,2)),2) as "CREDIT",	
						I.AccountId as "ID"
				from(
                      select 
								A.AccountId,
                                case when A.NegativeCredit <> 0 then A.NegativeCredit else A.Debit end as Debit,
                                case when A.NegativeDebit <> 0 then A.NegativeDebit else A.Credit end as Credit,
                                A.ACC_ID,
                                A.Description
					  from 
                            (
						select 
								
								B.AccountId,
								Case when (D.Account_Id = "3" OR D.Account_Id = "2" OR D.Account_Id = "5") And (B.Balance >0) then B.Balance else 0 end as Debit,
								Case when (D.Account_Id = "1" OR D.Account_Id = "4" OR D.Account_Id = "6") And (B.Balance >0) then B.Balance else 0 end as Credit,
                                Case when (D.Account_Id = "3" OR D.Account_Id = "2" OR D.Account_Id = "5") and (B.Balance < 0) then B.Balance * -1 else 0 end as NegativeDebit,
								Case when (D.Account_Id = "1" OR D.Account_Id = "4" OR D.Account_Id = "6") and (B.Balance < 0) then B.Balance * -1 else 0 end as NegativeCredit,
								C.ACC_ID,
								C.Description
						from (	
								select 
										SUM(A.Balance) as Balance,
										A.AccountId 
								from 
										daily_account_balance A 
								where 
										case when "',P_ENTRY_DATE_TO,'" <> -1 then A.ENTRYDATE <= DATE("',P_ENTRY_DATE_TO,'") else true end									
								group by 
										A.AccountId
							 )B
						inner join 
									Accounts_Id C 
						ON 
									C.id = B.AccountId
						inner join
									Account_Type D 
						ON	
									D.id = C.Account_Type_Id
						where 
									case when ',P_COMPANY_ID,' <> -1 then C.Company_Id =',P_COMPANY_ID,' else true end
						AND 
									case when \'',P_ACCOUNT_ID,'\' <> -1 then C.id in (',P_ACCOUNT_ID,') else true end
						AND 
									case when \'',P_ACCOUNT_TYPE,'\' <> -1 then D.id in (',P_ACCOUNT_TYPE,') else true end
                         ) as A 
					) I 
				group by 
						I.AccountId,
						I.ACC_ID,
						I.Description
				with ROLLUP having I.AccountId is null OR I.Description is not null LIMIT ',P_START,',',P_LENGTH,';');
				
		
			PREPARE STMP FROM @QRY;
			EXECUTE STMP ;
			DEALLOCATE PREPARE STMP;




END $$
DELIMITER ;
