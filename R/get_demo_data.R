#' Get demographic data
#'
#' Helper function to add demographic data to input dataset (from either datamart or writing R dataframe to QMR_DEV)
#'
#' @param table Either datamart name or R dataframe
#' @param metric Metric to be stratified
#' @param qmr_con QMR_DEV connection name
#' @param datamart Logical indicating if table argument is a datamart.
#'
#' @import stringr
#' @import odbc
#'
#' @export

get_demo_data <- function(table, metric, qmr_con, datamart){

# SQL Query goes here
std_demo_sql <-
c("with COHORT as
(
  select
  cohort.PAT_KEY,
  cohort.VISIT_KEY,
  cohort.metric_to_analyze as metric
  from table_to_analyze cohort
  join CDWUAT..VISIT on cohort.VISIT_KEY = visit.VISIT_KEY
),

  demos as
  (
  select
  cohort.PAT_KEY,
  census.FIPS,
  case when count(distinct race_dict.DICT_NM) > 1 then 'Multi-Racial' else max(race_dict.DICT_NM) end as RACE_RAW,
  case when upper(ETHNIC_GRP) <> 'HISPANIC OR LATINO' then
  case when upper(RACE_RAW) = 'WHITE' then 'NON-HISPANIC WHITE'
  when upper(RACE_RAW) = 'BLACK OR AFRICAN AMERICAN' then 'NON-HISPANIC BLACK'
  when upper(RACE_RAW) = 'REFUSED' then 'REFUSED'
  else 'OTHER' end
  else 'HISPANIC OR LATINO' end as RACE,
  case when pat.LANG is null or pat.LANG = 'ENGLISH' then 'ENGLISH' else 'NON-ENGLISH' end as PRIMARY_LANG
  from table_to_analyze cohort
  left join CDWUAT..PATIENT_GEOGRAPHICAL_SPATIAL_INFO map on cohort.pat_key = map.pat_key
  and map.SEQ_NUM = 0
  left join CDWUAT..CENSUS_TRACT CENSUS on map.census_tract_key = census.census_tract_key
  left join CDWUAT..PATIENT pat on cohort.pat_key = pat.pat_key
  left join CDWUAT..PATIENT_RACE_ETHNICITY race on pat.pat_key = race.pat_key and race.race_ind = 1
  left join CDWUAT..CDW_DICTIONARY race_dict on race.dict_race_ethnic_key = race_dict.dict_key
  group by
  cohort.PAT_KEY,
  census.FIPS,
  pat.LANG,
  pat.ETHNIC_GRP
  ),

  payer as
  (
  select
  cohort.VISIT_KEY,
  case when RPT_GRP_10 is null or upper(RPT_GRP_10) not in ('GOVERNMENT', 'COMMERCIAL') then 'OTHER' else RPT_GRP_10 end as PAYER_TYPE
  from table_to_analyze cohort
  left join CDWUAT..HOSPITAL_ACCOUNT ACCT on cohort.VISIT_KEY = ACCT.PRI_VISIT_KEY
  left join CDWUAT..VISIT on cohort.VISIT_KEY = visit.VISIT_KEY
  left join CDWUAT..PAYOR on
  case when ACCT.PRI_PAYOR_KEY is not null then ACCT.PRI_PAYOR_KEY = PAYOR.PAYOR_KEY
  else visit.PAYOR_KEY = payor.PAYOR_KEY end
  )

  select
  cohort.PAT_KEY,
  cohort.VISIT_KEY,
  cohort.metric,
  demos.race,
  demos.primary_lang,
  --demos.fips,
  payer.payer_type
  from COHORT cohort
  left join DEMOS on cohort.PAT_KEY = demos.PAT_KEY
  left join PAYER on cohort.VISIT_KEY = payer.VISIT_KEY
  ;"
)

  if (datamart) {
    # replace table/metric in std sql code, remember ocqi_uat..
    sql <-
      std_demo_sql %>%
      str_replace_all("table_to_analyze", paste0("ocqi_uat..", table)) %>%
      str_replace_all("metric_to_analyze", metric)
    # then run the edited query and assign it to demo data set
  }
  else {
    # write the data frame to qmr_dev: dbwritetable

    # add a step here like:
    # table %>% select(VISIT_KEY, PAT_KEY, !! PRIMARY_KEY, !! METRIC_NAME)
    dbWriteTable(qmr_con, "DEMO_DATA", get(table), overwrite = TRUE)

    sql <-
      std_demo_sql %>%
      str_replace_all("table_to_analyze", paste0("qmr_dev.", Sys.getenv("USERNAME"), ".DEMO_DATA")) %>%
      str_replace_all("metric_to_analyze", metric)
    # then do the same stuff as above, but refer to qmr_dev.. instead of ocqi_uat..
  }

  writeClipboard(sql)
  print("SQL Query was copied to clipboard. Paste into Aginity to run.")

  demo_data <- dbGetQuery(qmr_con, sql)

  #if(!datamart) {
  #  dbRemoveTable(qmr_con, "DEMO_DATA")
  #}

  demo_data

}
