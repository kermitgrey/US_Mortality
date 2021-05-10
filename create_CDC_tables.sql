
DROP TABLE cdc_mortality;
DROP TABLE cdc_ethnic_codes;
DROP TABLE cdc_counties;
DROP TABLE cdc_regionsdivisions;
DROP TABLE cdc_states;
DROP TABLE cdc_regions;
DROP TABLE cdc_divisions;


CREATE TABLE cdc_ethnic_codes(
ethniccode             varchar2(10 char),
ethniclabel            varchar2(50 char),
CONSTRAINT cdc_ethnic_codes_PK PRIMARY KEY(ethniccode)
);

CREATE TABLE cdc_states(
statefips		varchar2(2 char),
statecode		varchar2(2 char),
statename		varchar2(50 char),
CONSTRAINT cdc_states_PK PRIMARY KEY(statefips)
);

CREATE TABLE cdc_counties(
countyfips		varchar2(5 char),
countyname		varchar2(100 char),
statefips		varchar2(2 char),
CONSTRAINT cdc_counties_PK PRIMARY KEY(countyfips),
CONSTRAINT cdc_counties_FK1 FOREIGN KEY (statefips) 
	REFERENCES cdc_states(statefips)
);

CREATE TABLE cdc_mortality(
countyfips                varchar2(5 char),
gendercode               varchar2( 1 char),
ethniccode               varchar2(10 char),
reportyear               varchar2(4 char),
deaths                    number,
population		  number,
CONSTRAINT cdc_mortality_PK PRIMARY KEY(countyfips, gendercode, ethniccode, reportyear),
CONSTRAINT cdc_mortality_FK1 FOREIGN KEY (countyfips) 
	REFERENCES cdc_counties(countyfips),
CONSTRAINT cdc_mortality_FK2 FOREIGN KEY (ethniccode) 
REFERENCES cdc_ethnic_codes(ethniccode)
);

CREATE TABLE cdc_regions(
regionid          	NUMBER NOT NULL,
regionname      	VARCHAR2(50 CHAR) NOT NULL,
constraint cdc_regions_PK Primary Key(regionid)
);

CREATE TABLE cdc_divisions(
divisionid                  NUMBER NOT NULL,
divisionname            VARCHAR2(50 CHAR) NOT NULL,
CONSTRAINT cdc_divisions_PK Primary Key(divisionid)
);

CREATE TABLE cdc_regionsdivisions(
regionid               	NUMBER NOT NULL,
divisionid                NUMBER NOT NULL,
statefips                VARCHAR2(2 CHAR) NOT NULL,
CONSTRAINT cdc_regdiv_PK Primary Key (regionid, divisionid, statefips),
CONSTRAINT cdc_region_FK Foreign Key(regionid) 
    REFERENCES cdc_regions(regionid),
CONSTRAINT cdc_division_FK Foreign Key(divisionid) 
    REFERENCES cdc_divisions(divisionid),
CONSTRAINT cdc_statefips_FK FOREIGN KEY(statefips) 
    REFERENCES cdc_states(statefips)
);

DROP TABLE ext_cdc_ethnic_deaths_load;


CREATE TABLE ext_cdc_ethnic_deaths_load(
notes                          varchar2(500 char),
state_name                     varchar2(100 char),
state_code                     varchar2(2 char),
county_name                    varchar2(100 char),
county_code                    varchar2(5 char),
gender                         varchar2(30 char),
gender_code                    varchar2(1 char),
race                           varchar2(100 char),
race_code                      varchar2(10 char),
hispanic_origin                varchar2(30 char),
hispanic_origin_code           varchar2(10 char),
deaths                         number,
population                     number,
crude_rate                     number(12,1),
report_year                    varchar2(4 char)
)
    ORGANIZATION EXTERNAL
    (
        TYPE ORACLE_LOADER
        DEFAULT DIRECTORY ext_data_dir
        ACCESS PARAMETERS
        (
            records delimited by '\r\n'
	    skip 1
	    load when (state_name != BLANKS)
            readsize 2777834
            badfile ext_bad_dir:'deaths.bad'
            logfile ext_log_dir: 'deaths.log'
            fields terminated by '|' LRTRIM
            missing field values are null
            reject rows with all null fields
            (
		notes,
		state_name,
		state_code,
		county_name,
		county_code,
		gender,
		gender_code,
		race,
		race_code,
		hispanic_origin,
		hispanic_origin_code,
		deaths,
		population,
		crude_rate,
		report_year
	    )
	)
	LOCATION('cdcdeathsout.csv')
)
 PARALLEL 5
 REJECT LIMIT UNLIMITED;
