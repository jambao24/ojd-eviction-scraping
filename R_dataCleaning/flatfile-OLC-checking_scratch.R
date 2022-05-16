# James Bao
# 2022 May 13
# scratch R code for analyzing and interpreting weekly scrape data

library(readxl)
library(sqldf)
library(plyr)

# for Goal 1, we want cols B (case_code), M, N, O, R, S
# for Goal 2, we want cols B (case_code). L, Q, V, U
# for Goal 3, we want cols B (case_code), H
FF_0506 <- read.csv("G:/Shared drives/ojdevictions/ScrapeData/full_scrape_20220506/flat_file.csv")
FF_0506_1 = FF_0506[,-1]
FF_0506_1 <- subset(FF_0506_1, select = -c(case_name:status))
FF_0506_1 <- subset(FF_0506_1, select = -c(plaintiff_name:Agent))
FF_0506_1 <- subset(FF_0506_1, select = -c(tenant_lawyer:landlord_lawyer))
FF_0506_1 <- subset(FF_0506_1, select = -c(landlord_has_lawyer:zip))
#View(FF_0506_1)

FF_0506_2 = FF_0506[,-1]
FF_0506_2 <- subset(FF_0506_2, select = -c(case_name:defendant_addr))
FF_0506_2 <- subset(FF_0506_2, select = -c(Judgment_General:tenant_lawyer))
FF_0506_2 <- subset(FF_0506_2, select = -c(FTA:FTAFirst))
FF_0506_2 <- subset(FF_0506_2, select = -c(FTAFirstXJudgmentGeneral:zip))
#View(FF_0506_2)

FF_0506_3 = FF_0506[,-1]
FF_0506_3 <- subset(FF_0506_3, select = -c(case_name:status))
FF_0506_3 <- subset(FF_0506_3, select = -c(plaintiff_name:zip))
#View(FF_0506_3)

# for Goal 3, we want col C (case_code), F (decision), G (judgment date)
judgments_0506 <- read.csv("G:/Shared drives/ojdevictions/ScrapeData/full_scrape_20220506/judgments.csv")
# https://www.youtube.com/watch?v=6inAoQddaj0
# convert date column to Date data type
judgments_0506$date <- as.Date(judgments_0506$date, format = '%m/%d/%Y')
# remove unwanted rows
judgments_0506 = judgments_0506[,-1]
judgments_0506 = judgments_0506[,-1]
judgments_0506 = judgments_0506[,-2]
judgments_0506 = judgments_0506[,-2]
judgments_0506 = judgments_0506[,-5]
#View(judgments_0506)
# filter for rows that contain judgment dates within the current week (2022-05-01 through 2022-05-07)
judgments_0506_curr = judgments_0506[judgments_0506$date > "2022-04-30" & judgments_0506$date < "2022-05-08" & judgments_0506$date <> null, ]
judgments_0506_curr <- judgments_0506_curr[complete.cases(judgments_0506_curr),]

# for Goal 1, we want cols A (case_code), H, AA, AE
# for Goal 2, we want cols A (case_code), W, V
OLC_updated <- read_excel("G:/Shared drives/ojdevictions/OLCData/OLC-FEDs 2021 v.9 (Apr 7, 2022) - MJ.xlsx")
#View(OLC_updated)
OLC_updated_1 <- subset(OLC_updated, select = -c(Parties:County))
# want to get rid of cols 'Date filed', 'FA Date'
OLC_updated_1 = OLC_updated_1[,-2]
OLC_updated_1 = OLC_updated_1[,-2]
OLC_updated_1 <- subset(OLC_updated_1, select = -c(Pending:Outcome2))
OLC_updated_1 <- subset(OLC_updated_1, select = -c(Default:SA))
OLC_updated_1 <- subset(OLC_updated_1, select = -c(SA_shortmove:Notes))
#View(OLC_updated_1)
OLC_updated_2 <- subset(OLC_updated, select = -c(Parties:Represented))
OLC_updated_2 <- subset(OLC_updated_2, select = -c(SB278_setover:Notes))
#View(OLC_updated_2)



# https://rforjournalists.com/2018/04/10/sql-joins-merges-r/


part1_join <- merge(FF_0506_1, OLC_updated_1, by.x = "case_code", by.y = "Case #")
part2_join <- merge(FF_0506_2, OLC_updated_2, by.x = "case_code", by.y = "Case #")
part3_join <- merge(FF_0506_3, judgments_0506, by = "case_code")

# number of rows in part1_join
nrow(part1_join)

# count number of 'created_lien' that are coded incorrectly in the FF
part1_join_JCL_check <- sqldf("select * from part1_join 
                                                where 
                                                [Judgment_Creates_Lien] = '1' AND [Judgment_General] <> '1' 
                                                AND 
                                                [Judgment_Creates_Lien] = '1' AND [Judgment_Dismissal] <> '1'")
nrow(part1_join_JCL_check)


# filter FF data frame for judgments that aren't coded incorrectly
part1_join_filter <- sqldf('select * from part1_join except select * from part1_join_JCL_check')
nrow(part1_join_filter)


# filter FF data frame for judgments that aren't coded incorrectly and
# already have a first appearance
part1_join_FA_held <- sqldf("select * from part1_join_filter 
                                                where 
                                                [FA Held] = 'Y'")
nrow(part1_join_FA_held)

# filter through correct eviction rulings
part1_join_evict_match <- sqldf("select * from part1_join_filter 
                                                where 
                                                [Judgment_General] = '1'
                                                and
                                                [Outcome3] = 'Tenant Default' 
                                                or 
                                                [Outcome3] = 'Judgment for Landlord' 
                                                or 
                                                [Outcome3] = 'Stipulated Agreement' and [SA_noncomp] = '1' 
                                ")
nrow(part1_join_evict_match)
# fitter through eviction rulings per FF but not OLC
part1_join_evict_not_match_1 <- sqldf("select * from part1_join_filter 
                                                where 
                                                [Judgment_General] = '1'
                                                and
                                                [Outcome3] <> 'Tenant Default' 
                                                and 
                                                [Outcome3] <> 'Judgment for Landlord' 
                                                and not
                                                [Outcome3] = 'Stipulated Agreement' and [SA_noncomp] = '1' 
                                ")
nrow(part1_join_evict_not_match_1)
# fitter through eviction rulings per OLC but not FF
part1_join_evict_not_match_2 <- sqldf("select * from part1_join_filter 
                                                where 
                                                [Judgment_General] <> '1'
                                                and
                                                [Outcome3] = 'Tenant Default' 
                                                or 
                                                [Outcome3] = 'Judgment for Landlord' 
                                                or 
                                                [Outcome3] = 'Stipulated Agreement' and [SA_noncomp] = '1' 
                                ")
nrow(part1_join_evict_not_match_2)


# filter through correct dismissal rulings
part1_join_dismiss_match <- sqldf("select * from part1_join_filter 
                                               pgAdmin where 
                                                [Judgment_Dismissal] = '1'
                                                and
                                                [Outcome3] = 'Dismissed' 
                                ")
nrow(part1_join_dismiss_match)
# filter through dismissal rulings per FF but not OLC
part1_join_dismiss_not_match_1 <- sqldf("select * from part1_join_filter 
                                                where 
                                                [Judgment_Dismissal] = '1'
                                                and
                                                [Outcome3] <> 'Dismissed' 
                                ")
nrow(part1_join_dismiss_not_match_1)
# filter through dismissal rulings per OLC but not FF
part1_join_dismiss_not_match_2 <- sqldf("select * from part1_join_filter 
                                                where 
                                                [Judgment_Dismissal] <> '1'
                                                and
                                                [Outcome3] = 'Dismissed' 
                                ")
nrow(part1_join_dismiss_not_match_2)

# filter through correct FTA rulings
part1_join_FTA_match <- sqldf("select * from part1_join_filter 
                                                where 
                                                [FTADefault] = '1'
                                                and
                                                [Outcome3] = 'Tenant Default' 
                                ")
nrow(part1_join_FTA_match)
# filter through FTA rulings per FF but not OLC
part1_join_FTA_not_match_1 <- sqldf("select * from part1_join_filter 
                                                where 
                                                [FTADefault] = '1'
                                                and
                                                [Outcome3] <> 'Tenant Default' 
                                ")
nrow(part1_join_FTA_not_match_1)
# filter through FTA rulings per OLC but not FF
part1_join_FTA_not_match_2 <- sqldf("select * from part1_join_filter 
                                                where 
                                                [FTADefault] <> '1'
                                                and
                                                [Outcome3] = 'Tenant Default' 
                                ")
nrow(part1_join_FTA_not_match_2)

# filter through correct FTA rulings with FTA
part1_join_FTA_match0 <- sqldf("select * from part1_join_filter 
                                                where 
                                                [FTA] = '1'
                                                and
                                                [Outcome3] = 'Tenant Default' 
                                ")
nrow(part1_join_FTA_match0)
# filter through FTA rulings per FF but not OLC
part1_join_FTA_not_match0_1 <- sqldf("select * from part1_join_filter 
                                                where 
                                                [FTA] = '1'
                                                and
                                                [Outcome3] <> 'Tenant Default' 
                                ")
nrow(part1_join_FTA_not_match0_1)
# filter through FTA rulings per OLC but not FF
part1_join_FTA_not_match0_2 <- sqldf("select * from part1_join_filter 
                                                where 
                                                [FTA] <> '1'
                                                and
                                                [Outcome3] = 'Tenant Default' 
                                ")
nrow(part1_join_FTA_not_match0_2)




part2_join_lawyer_rep_match <- sqldf("select * from part2_join 
                                                where 
                                                [landlord_has_lawyer] = [LL_rep]
                                                AND 
                                                [tenant_has_lawyer] = [Ten_rep]")
nrow(part2_join_lawyer_rep_match)
nrow(part2_join)



# determine how many eviction rulings occurred this week in each county
# for this we merge the judgments_0506_curr dataframe with the part1_join_evict_match dataframe (confirmed evictions)
this_week_evict_1 <- merge(judgments_0506_curr, part1_join_evict_match, by.x = "case_code", by.y = "case_code")
this_week_evict_2 <- merge(judgments_0506_curr, part1_join_evict_not_match_1, by.x = "case_code", by.y = "case_code")
this_week_evict_3 <- merge(judgments_0506_curr, part1_join_evict_not_match_2, by.x = "case_code", by.y = "case_code")
this_week_evict_all <- rbind(this_week_evict_1, this_week_evict_2, this_week_evict_3)

table <- subset(FF_0506, select = location)
distinct(table[c("location")])

table(this_week_evict_1$location)
table(this_week_evict_all$location)
