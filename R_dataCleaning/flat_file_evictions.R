if (!require("dplyr")) install.packages("dplyr")
if (!require("ggplot2")) install.packages("ggplot2")
if (!require("fastDummies")) install.packages("fastDummies")
if (!require("tidyr")) install.packages("tidyr")
if (!require("DBI")) install.packages("DBI")
if (!require("stringr")) install.packages("stringr")
if (!require("dplyr")) install.packages("dplyr")
if (!require("rstudioapi")) install.packages("rstudioapi")

library(dplyr)
library(ggplot2)
library(fastDummies)
library(tidyr)
library(DBI)
library(stringr)
library(dplyr)
library(rstudioapi)

# extra functions from data_cleaning_evictions.R
source("S:/R/custom_functions/data_cleaning_evictions.R") 

setwd(dirname(getActiveDocumentContext()$path))

createJudgmentDummies <- function() {
  getJudgments() %>% 
    group_by(case_code) %>% 
    summarize(judgment = paste(case_type, collapse = "; ")) %>%
    mutate(Judgment_General = ifelse(judgment == "Judgment - General" | grepl("Judgment - General;", judgment) | grepl("; Judgment - General", judgment), 1, 0),
           Judgment_Dismissal = ifelse(judgment == "Judgment - General Dismissal" | grepl("Dismissal", judgment), 1, 0),
           Judgment_Creates_Lien = ifelse(judgment == "Judgment - General Creates Lien" | grepl("Creates Lien", judgment), 1, 0)) %>% 
    return()
}
addMoratoriumVars <- function() {
  getCaseOverviews() %>% 
    mutate(date2 = as.Date(getCaseOverviews()$date, "%m/%d/%Y"),
           Oregon_Moratorium = if_else(date2 >= as.Date('2020-3-22'), 1, 0),
           Multnomah_Moratorium = if_else(date2 >= as.Date('2020-3-17') & location == "Multnomah", 1, 0)) %>% 
    return()
}
getPlaintifNames <- function() {
  getCaseParties() %>% 
    filter(party_side == "Plaintiff") %>% 
    group_by(case_code) %>% 
    summarize(plaintiff_name = paste(name, collapse = "; ")) %>% 
    return()
}
getLawyersByParty <- function() {
  getCaseParties() %>%
    rename(party_name = name) %>% 
    select(case_code, party_name, party_side) %>% 
    right_join(getLawyers() %>% 
                 rename(lawyerName = name) %>%
                 select(case_code, party_name, lawyerName, status), by = c('case_code', 'party_name')) %>% 
    return()
}
getDefendantLawyers <- function() {
  getLawyersByParty() %>% 
    filter(party_side == "Defendant") %>% 
    group_by(case_code) %>% 
    summarize(party = paste(unique(party_name), collapse = "; "), 
              tenant_lawyer = paste(unique(lawyerName), collapse = "; ")) %>%
    return()
}
getPlaintiffLawyer <- function() {
  getLawyersByParty() %>% 
    filter(party_side == "Plaintiff") %>% 
    group_by(case_code) %>% 
    summarize(party = paste(unique(party_name), collapse = "; "), 
              landlord_lawyer = paste(unique(lawyerName), collapse = "; ")) %>% 
    return()
}
makeFTAvars <- function() {
  #makes Failure to Appear variable
  getEvents() %>% 
    filter(result == "FTA - Default" | result == "Failure to Appear") %>% 
    distinct(case_code) %>% 
    mutate(FTA = 1) %>% 
    return()
}
makeFlatFile <- function() {
  # makes final flat_file output
  addMoratoriumVars() %>% 
    select(case_code, style, date, Oregon_Moratorium, Multnomah_Moratorium, status, location) %>% 
    full_join(getPlaintifNames() %>% select(case_code, plaintiff_name), by = 'case_code') %>% 
    full_join(getDefendantInfo() %>% select(case_code, defendant_names, defendant_addr), by = 'case_code') %>% 
    full_join(createJudgmentDummies() %>% select(case_code, judgment, Judgment_General, 
                                       Judgment_Creates_Lien, 
                                       Judgment_Dismissal), by = 'case_code') %>% 
    full_join(getDefendantLawyers() %>% select(case_code, tenant_lawyer), by = 'case_code') %>% 
    full_join(getPlaintiffLawyer() %>% select(case_code, landlord_lawyer), by = 'case_code') %>% 
    full_join(makeFTAvars(), by = 'case_code') %>%
    mutate(landlord_has_lawyer = ifelse(is.na(landlord_lawyer), 0, 1),
           tenant_has_lawyer = ifelse(is.na(tenant_lawyer), 0, 1),
           FTA = ifelse(is.na(FTA), 0, 1),
           date = as.Date(date, "%m/%d/%Y"),
           month = as.Date(cut(date, breaks = "month")),
           no_judgment = ifelse(status == "Closed" & judgment == "NULL", 1, 0),
           zip = word(defendant_addr, -1)) %>% 
    rename(case_name = style) %>% 
    return()
}
saveTablesRDS <- function() {
  saveRDS(makeFlatFile(), "flat_file.rds", sep = ""))
  saveRDS(getCaseOverviews(), "case_overviews.rds", sep = ""))
  saveRDS(getCaseParties(), "case_parties.rds", sep = ""))
  saveRDS(getEvents(), "events.rds", sep = ""))
  saveRDS(getJudgments(), "judgments.rds", sep = ""))
  saveRDS(getLawyers(), "lawyers.rds", sep = ""))
  saveRDS(getFiles(), "files.rds", sep = ""))
}

saveTablesCSV <- function(){
  write.csv(makeFlatFile(), "flat_file.csv", sep = ""))
  write.csv(getCaseOverviews(), "case_overviews.csv", sep = ""))
  write.csv(getCaseParties(), "case_parties.csv", sep = ""))
  write.csv(getEvents(), "events.csv", sep = ""))
  write.csv(getJudgments(), "judgments.csv", sep = ""))
  write.csv(getLawyers(), "lawyers.csv", sep = ""))
  write.csv(getFiles(), "files.csv", sep = ""))
}

# set save directory
setwd(getSrcDirectory()[1])
dir.create(paste("full_scrape", today, sep = "_"))
setwd(paste("full_scrape", today, sep = "_"))

# Execute
saveTablesRDS()
saveTablesCSV()



