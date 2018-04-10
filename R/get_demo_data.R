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

get_demo_data <- function(table, metric, qmr_con, datamart){

# SQL Query goes here
std_demo_sql <-
c("with cohort as
  (
  select
  cohort.pat_key,
  cohort.visit_key,
  cohort.metric_to_analyze as metric
  from table_to_analyze cohort
  ),

  demos as
  (
  select
  cohort.pat_key,
  census.fips,
  case when count(distinct race_dict.dict_nm) > 1 then 'Multi-Racial' else max(race_dict.dict_nm) end as race_raw,
  case when ethnic_grp <> 'Hispanic or Latino' then
  case when race_raw = 'White' then 'Non-Hispanic White'
  when race_raw = 'Black or African American' then 'Non-Hispanic Black'
  when race_raw = 'Multi-Racial' then 'Multi-Racial'
  when race_raw = 'Refused' then 'Refused'
  else 'Other' end
  else 'Hispanic or Latino' end as race,
  case when pat.lang is null then 'English' else lang end as primary_lang
  from table_to_analyze cohort
  left join cdwuat..patient_geographical_spatial_info map on cohort.pat_key = map.pat_key
  and map.seq_num = 0
  left join cdwuat..census_tract census on map.census_tract_key = census.census_tract_key
  left join cdwuat..patient pat                   on cohort.pat_key = pat.pat_key
  left join cdwuat..patient_race_ethnicity race   on pat.pat_key = race.pat_key and race.race_ind = 1
  left join cdwuat..cdw_dictionary race_dict      on race.dict_race_ethnic_key = race_dict.dict_key
  group by
  cohort.pat_key,
  census.fips,
  pat.lang,
  pat.ethnic_grp
  ),

  payer as
  (
  select
  cohort.visit_key,
  case when rpt_grp_10 is null or rpt_grp_10 not in ('Government', 'Commercial') then 'Other' else rpt_grp_10 end as payer_type
  from table_to_analyze cohort
  left join cdwuat..hospital_account acct on cohort.visit_key=acct.pri_visit_key
  left join cdwuat..payor on payor.payor_key=acct.pri_payor_key
  )

  select
  cohort.pat_key,
  cohort.visit_key,
  cohort.metric,
  demos.race,
  demos.primary_lang,
  --demos.fips,
  payer.payer_type
  from cohort cohort
  left join demos on cohort.pat_key = demos.pat_key
  left join payer on cohort.visit_key = payer.visit_key
  group by
  cohort.visit_key,
  cohort.pat_key,
  cohort.metric,
  demos.race,
  demos.primary_lang,
  payer.payer_type
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
