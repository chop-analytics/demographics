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
std_demo_sql <- c("with COHORT as
                  (
                  select
                  cohort.PAT_KEY,
                  cohort.VISIT_KEY,
                  cohort.metric_to_analyze as metric
                  from table_to_analyze cohort
                  ),

                  DEMOS as
                  (
                  SELECT
                  COHORT.PAT_KEY,
                  census.FIPS,
                  CASE WHEN COUNT(DISTINCT DICT1.DICT_NM) > 1 THEN 'Multi-racial' ELSE MAX(DICT1.DICT_NM) END AS RACE,
				          case when ETHNICITY <> 'Hispanic or Latino' then
					              case when RACE = 'White' then 'Non-Hispanic White'
						            case when RACE = 'Black' then 'Non-Hispanic Black'
							          case when RACE = 'Refused' then 'Refused'
						            else 'Other' end
					           else 'Hispanic or Latino' end as RACE,
                  case when pat.LANG is null then 'ENGLISH' else LANG end as PRIMARY_LANG
                  FROM table_to_analyze cohort
                  LEFT JOIN CDWUAT..PATIENT_GEOGRAPHICAL_SPATIAL_INFO map on cohort.PAT_KEY = map.PAT_KEY
                  and map.SEQ_NUM = 0
                  LEFT JOIN CDWUAT..CENSUS_TRACT census on map.CENSUS_TRACT_KEY = census.CENSUS_TRACT_KEY
                  LEFT JOIN CDWUAT..PATIENT PAT                   ON COHORT.PAT_KEY = PAT.PAT_KEY
                  LEFT JOIN CDWUAT..PATIENT_RACE_ETHNICITY RACE   ON PAT.PAT_KEY = RACE.PAT_KEY AND RACE.RACE_IND = 1
                  LEFT JOIN CDWUAT..CDW_DICTIONARY DICT1          ON RACE.DICT_RACE_ETHNIC_KEY = DICT1.DICT_KEY
                  GROUP BY
                  COHORT.PAT_KEY,
                  census.FIPS,
                  pat.LANG,
                  PAT.ETHNIC_GRP
                  ),

                  PAYER as
                  (
                  select
                  cohort.visit_key,
                  case when rpt_grp_10 is null or rpt_grp_10 not in ('GOVERNMENT', 'COMMERCIAL') then 'OTHER' else rpt_grp_10 end as payer_type
                  from table_to_analyze cohort
                  left join CDWUAT..HOSPITAL_ACCOUNT acct on cohort.visit_key=acct.pri_visit_key
                  left join CDWUAT..payor on payor.payor_key=acct.pri_payor_key
                  )

                  select
                  cohort.PAT_KEY,
                  cohort.VISIT_KEY,
                  cohort.METRIC,
                  demos.RACE,
                  demos.PRIMARY_LANG,
                  --demos.FIPS,
                  payer.PAYER_TYPE
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
