# US_Mortality
United States Deaths
<h3> U.S. Mortality (2015 - 2019)</h3>

<p> The Centers for Disease Control and Prevention (CDC) provides the Multiple Causes of Death data set containing mortality and population counts for all U.S. counties. That data set, encompassing years 1999-2019, is made available to the public via the CDC Wonder information platform, an integrated information and communication system for public health.</p>

<p>The data from CDC Wonder will be used to perform an analysis of data for the period 2015 through 2019.
   The data used for the analysis includes the following:
</p>
    <ul>
    <li> Census Bureau Region, Division, and FIPS codes for states, 
         (state-geocodes-v2019.xlsx)</li>
    <li> CDC annual mortality statistics encompassing all causes of deaths, 
         years 2015-2019 </li>
    </ul>

<p> NOTE: This repo does not replicate the files extracted from CDC Wonder.  Please visit 
    https://wonder.cdc.gov/ for access to the actual data.
</p>

<p> The processing steps for the Census Bureau data is documented separately in the covid19_review repo.
    Please reference the python file labeled "generateCensusRegions.py".  Additionally, all CDC files
    were transformed using Excel; that process is not part of this repo.</p>

<p> These files are subsequently loaded into an Oracle database for analysis.</p>

<h4> Oracle Database </h4>    
    
<p> The following files contain all the code necessary to create the schema objects that support the
    analysis as well as the code to process the data. </p>
    <ul>
    <ol>
        <li> create_CDC_tables.sql: This creates all the internal tables used to contain 
             the data created by the database package.  It also provides the external table
             definition that provides direct query access to the data.</li>
        <li> cdc_pak.sql: This generates a database package that contains all the
             code needed to process the data and load it into the database.</li>
    </ol>
    </ul>
<p> This code makes use of Oracle's external table functionality that enables read-only access to 
    the external data files extracted from CDC Wonder.  Please reference the Oracle Database    
    Administrator's Guide for specifics on needed setup steps prior to using the external tables
    functionality.</p
