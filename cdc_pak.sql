CREATE OR REPLACE PACKAGE cdc_pak
AS
procedure audit_entry(p_error IN varchar2, 
                                        p_msg IN varchar2, 
                                        p_pgm IN varchar2);

procedure load_states;

procedure load_counties;

procedure load_ethnic_codes;

procedure load_mortality;

procedure load_census_geos;

v_err_num           number;
v_err_msg           varchar2(250 char);

END cdc_pak;
/
CREATE OR REPLACE PACKAGE BODY cdc_pak
AS
/********************************************************
** utility procedure to store exceptions in error_log table
**
*********************************************************/
PROCEDURE audit_entry(p_error IN varchar2, 
                                            p_msg IN varchar2, 
                                            p_pgm IN varchar2)
IS
BEGIN
    INSERT INTO error_log(progname,
                                              progtime,
                                              errcode,
                                              errmesg)
      VALUES(p_pgm,
                sysdate,
                p_error,
                p_msg);
                
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
      v_err_num := sqlcode;
      v_err_msg := substr(sqlerrm(v_err_num), 1, 250);
      
      INSERT INTO error_log(progname,
                              progtime,
                              errcode,
                              errmesg)
      VALUES('audit_entry',
                sysdate,
                v_err_num,
                v_err_msg);
    
END audit_entry;

/******************************************************
** load states from cdc load file
**
******************************************************/
PROCEDURE load_states
IS
BEGIN

    EXECUTE IMMEDIATE 'ALTER TABLE cdc_counties DISABLE CONSTRAINT cdc_counties_FK1';
    EXECUTE IMMEDIATE 'ALTER TABLE cdc_regionsdivisions DISABLE CONSTRAINT cdc_statefips_FK';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE cdc_states';
    
    INSERT INTO cdc_states(statefips,
                                                        statecode,
                                                        statename)
    SELECT DISTINCT state_code,
                TRIM(substr(county_name, instr(county_name,',')+1,length(county_name))),
                state_name
    FROM ext_cdc_ethnic_deaths_load;
    
    COMMIT;

    EXECUTE IMMEDIATE 'ALTER TABLE cdc_counties ENABLE CONSTRAINT cdc_counties_FK1';
    EXECUTE IMMEDIATE 'ALTER TABLE cdc_regionsdivisions ENABLE CONSTRAINT cdc_statefips_FK';

EXCEPTION
    WHEN OTHERS THEN
      v_err_num := sqlcode;
      v_err_msg := substr(sqlerrm(v_err_num), 1, 250);
      
      audit_entry(v_err_num, v_err_msg, 'cn_load_states');

END load_states;

/******************************************************
** load counties from cdc load file
**
******************************************************/
PROCEDURE load_counties
IS
BEGIN

    EXECUTE IMMEDIATE 'ALTER TABLE cdc_mortality DISABLE CONSTRAINT cdc_mortality_FK1';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE cdc_counties';
    
    INSERT INTO cdc_counties(countyfips,
                                                        countyname,
                                                        statefips)
    SELECT DISTINCT county_code, 
                CASE WHEN INSTR(county_name, 'County') > 0 THEN
                        TRIM(SUBSTR(COUNTY_NAME,1, INSTR(COUNTY_NAME, 'County')-1))
                        WHEN INSTR(county_name, 'Parish') > 0 THEN
                        TRIM(SUBSTR(county_name,1, INSTR(county_name, 'Parish')-1))
                ELSE TRIM(Substr(county_name,1, INSTR(county_name, ',')-1)) END,
                state_code
    FROM ext_cdc_ethnic_deaths_load;
        
    COMMIT;

    EXECUTE IMMEDIATE 'ALTER TABLE cdc_mortality ENABLE CONSTRAINT cdc_mortality_FK1';
    
EXCEPTION
    WHEN OTHERS THEN
      v_err_num := sqlcode;
      v_err_msg := substr(sqlerrm(v_err_num), 1, 250);
      
      audit_entry(v_err_num, v_err_msg, 'cn_load_counties');

END load_counties;

/******************************************************
** load ethnic_codes from cdc load file
**
******************************************************/
PROCEDURE load_ethnic_codes
IS
BEGIN
    
    EXECUTE IMMEDIATE 'ALTER TABLE cdc_mortality DISABLE CONSTRAINT cdc_mortality_FK2';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE cdc_ethnic_codes'; 
    
    INSERT INTO cdc_ethnic_codes(ethniccode,
                                                            ethniclabel)
    SELECT DISTINCT
                CASE WHEN hispanic_origin_code = '2135-2' THEN '2135-2'
                    ELSE race_code END,
                CASE WHEN hispanic_origin_code = '2135-2' THEN 'Hispanic'
                    ELSE race END
    FROM ext_cdc_ethnic_deaths_load;

    COMMIT;
    
    EXECUTE IMMEDIATE 'ALTER TABLE cdc_mortality ENABLE CONSTRAINT cdc_mortality_FK2';

EXCEPTION
    WHEN OTHERS THEN
      v_err_num := sqlcode;
      v_err_msg := substr(sqlerrm(v_err_num), 1, 250);

      audit_entry(v_err_num, v_err_msg, 'cn_load_ethnic_codes');
        
END load_ethnic_codes;

/******************************************************
** load deaths from cdc load file
**
******************************************************/
PROCEDURE load_mortality
IS
BEGIN

    EXECUTE IMMEDIATE 'TRUNCATE TABLE cdc_mortality'; 
        
    INSERT INTO cdc_mortality(countyfips,
                                                        gendercode,
                                                        ethniccode,
                                                        reportyear,
                                                        deaths,
                                                        population)
    SELECT county_code,
                gender_code,
                CASE WHEN hispanic_origin_code = '2135-2' THEN '2135-2'
                    ELSE race_code END,
                report_year,
                sum(deaths),
                sum(population)
    FROM ext_cdc_ethnic_deaths_load
    GROUP BY county_code,
                        gender_code,
                        CASE WHEN hispanic_origin_code = '2135-2' THEN '2135-2'
                            ELSE race_code END,
                        report_year;
                        
    COMMIT;
            
EXCEPTION
    WHEN OTHERS THEN
      v_err_num := sqlcode;
      v_err_msg := substr(sqlerrm(v_err_num), 1, 250);

      audit_entry(v_err_num, v_err_msg, 'cn_load_mortality');
      
END load_mortality;

/******************************************************
** load census bureau geo data 
**
******************************************************/
PROCEDURE load_census_geos
IS
BEGIN
-- load region information

    EXECUTE IMMEDIATE 'ALTER TABLE cdc_regionsdivisions DISABLE CONSTRAINT cdc_region_FK';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE cdc_regions';
    
    INSERT INTO cdc_regions(regionid,
                                                regionname)
    SELECT regionid,
                regionname
    FROM ext_census_state_geo_codes_load;
    
    COMMIT;

    EXECUTE IMMEDIATE 'ALTER TABLE cdc_regionsdivisions ENABLE CONSTRAINT cdc_region_FK';
    
-- load division information

    EXECUTE IMMEDIATE 'ALTER TABLE cdc_regionsdivisions DISABLE CONSTRAINT cdc_division_FK';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE cdc_divisions';
    
    INSERT INTO cdc_divisions(divisionid,
                                                     divisionname)
    SELECT divisionid,
                divisionname
    FROM ext_census_state_geo_codes_load;
    
    COMMIT;

    EXECUTE IMMEDIATE 'ALTER TABLE cdc_regionsdivisions ENABLE CONSTRAINT cdc_division_FK';
    
-- load region division combo table

    EXECUTE IMMEDIATE 'TRUNCATE TABLE cdc_regionsdivisions';
    
    INSERT INTO cdc_regionsdivisions(regionid,
                                                                divisionid,
                                                                statefips)
    SELECT regionid,
                divisionid,
                statefips
    FROM ext_census_state_geo_codes_load;
    
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
      v_err_num := sqlcode;
      v_err_msg := substr(sqlerrm(v_err_num), 1, 250);
      
      audit_entry(v_err_num, v_err_msg, 'cn_load_census_geos');

END load_census_geos;

END cdc_pak;
/
