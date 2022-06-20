# James Bao
# 2022 Jun 15 version
# scratch R code for analyzing and interpreting weekly scrape data

library(readxl)
library(sqldf)
library(plyr)


# for Goal 1, we want cols B (case_code), M, N, O, R, S
# for Goal 2, we want cols B (case_code). L, Q, V, U
# for Goal 3, we want cols B (case_code), H
FF_0610 <- read.csv("G:/Shared drives/ojdevictions/ScrapeData/full_scrape_20220610/flat_file.csv")
# 06/15 update for comparison with updated OLC file- we want to filter FF cases by date
FF_0610_1 = FF_0610[,-1]
#FF_0610_1 <- subset(FF_0610_1, select = -c(case_name:status))
FF_0610_1 <- subset(FF_0610_1, select = -c(case_name))
FF_0610_1 <- subset(FF_0610_1, select = -c(Oregon_Moratorium:status))
FF_0610_1 <- subset(FF_0610_1, select = -c(plaintiff_name:Agent))
FF_0610_1 <- subset(FF_0610_1, select = -c(tenant_lawyer:landlord_lawyer))
FF_0610_1 <- subset(FF_0610_1, select = -c(landlord_has_lawyer:zip))

# convert date column to Date data type
FF_0610_1$date <- as.Date(FF_0610_1$date)
# filter for only cases with date set before 2022-05-15
FF_0610_1_OLC = FF_0610_1[FF_0610_1$date < "2022-05-15", ]
#View(FF_0610_1)

FF_0610_2 = FF_0610[,-1]
FF_0610_2 <- subset(FF_0610_2, select = -c(case_name:defendant_addr))
FF_0610_2 <- subset(FF_0610_2, select = -c(Judgment_General:tenant_lawyer))
FF_0610_2 <- subset(FF_0610_2, select = -c(FTA:FTAFirst))
FF_0610_2 <- subset(FF_0610_2, select = -c(FTAFirstXJudgmentGeneral:zip))
#View(FF_0610_2)

FF_0610_3 = FF_0610[,-1]
FF_0610_3 <- subset(FF_0610_3, select = -c(case_name:status))
FF_0610_3 <- subset(FF_0610_3, select = -c(plaintiff_name:zip))
#View(FF_0610_3)

# for Goal 3, we want col C (case_code), F (decision), G (judgment date)
judgments_0610 <- read.csv("G:/Shared drives/ojdevictions/ScrapeData/full_scrape_20220610/judgments.csv")
# https://www.youtube.com/watch?v=6inAoQddaj0
# convert date column to Date data type
judgments_0610$date <- as.Date(judgments_0610$date, format = '%m/%d/%Y')
# remove unwanted rows
judgments_0610 = judgments_0610[,-1]
judgments_0610 = judgments_0610[,-1]
judgments_0610 = judgments_0610[,-2]
judgments_0610 = judgments_0610[,-2]
judgments_0610 = judgments_0610[,-5]
#View(judgments_0610)
# filter for rows that contain judgment dates within the current week 
judgments_0610_curr = judgments_0610[judgments_0610$date > "2022-06-04" & judgments_0610$date < "2022-06-12", ]
judgments_0610_curr <- judgments_0610_curr[complete.cases(judgments_0610_curr),]

# for Goal 1, we want cols A (case_code), H, AA, AE
# for Goal 2, we want cols A (case_code), W, V
#OLC_updated <- read_excel("G:/Shared drives/ojdevictions/OLCData/OLC-FEDs 2021 v.9 (Apr 7, 2022) - MJ.xlsx")
OLC_updated <- read_excel("G:/Shared drives/ojdevictions/OLCData/OLC-FEDs 2021-22 v.11 (June 14, 2022) - MJ.xlsx")
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


part1_join_OLC <- merge(FF_0610_1_OLC, OLC_updated_1, by.x = "case_code", by.y = "Case #")
part1_join <- merge(FF_0610_1, OLC_updated_1, by.x = "case_code", by.y = "Case #")
part2_join <- merge(FF_0610_2, OLC_updated_2, by.x = "case_code", by.y = "Case #")
part3_join <- merge(FF_0610_3, judgments_0610, by = "case_code")

# number of rows in part1_join
#nrow(part1_join)

# count number of 'created_lien' that are coded incorrectly in the FF
part1_join_JCL_check <- sqldf("select * from part1_join 
                                                where 
                                                [Judgment_Creates_Lien] = '1' AND [Judgment_General] <> '1' 
                                                AND 
                                                [Judgment_Creates_Lien] = '1' AND [Judgment_Dismissal] <> '1'")
#nrow(part1_join_JCL_check)


# filter FF data frame for judgments that aren't coded incorrectly
part1_join_filter <- sqldf('select * from part1_join except select * from part1_join_JCL_check')
#nrow(part1_join_filter)


# filter FF data frame for judgments that aren't coded incorrectly and
# already have a first appearance
part1_join_FA_held <- sqldf("select * from part1_join_filter 
                                                where 
                                                [FA Held] = 'Y'")
#nrow(part1_join_FA_held)

# filter through correct eviction rulings
part1_join_evict_match <- sqldf("select * from part1_join_FA_held 
                                                where 
                                                [Judgment_General] = '1'
                                                and
                                                ([Outcome3] = 'Tenant Default' 
                                                or 
                                                [Outcome3] = 'Judgment for Landlord' 
                                                or 
                                                [Outcome3] = 'Stipulated Agreement' and [SA_noncomp] = '1')
                                ")
#nrow(part1_join_evict_match)
# filter through eviction rulings per FF but not OLC
part1_join_evict_not_match_1 <- sqldf("select * from part1_join_FA_held 
                                                where 
                                                [Judgment_General] = '1'
                                                and not
                                                ([Outcome3] = 'Tenant Default' 
                                                or 
                                                [Outcome3] = 'Judgment for Landlord' 
                                                or
                                                [Outcome3] = 'Stipulated Agreement' and [SA_noncomp] = '1') 
                                ")
#nrow(part1_join_evict_not_match_1)
# filter through eviction rulings per OLC but not FF
part1_join_evict_not_match_2 <- sqldf("select * from part1_join_FA_held 
                                                where 
                                                ([Judgment_General] <> '1' or [Judgment_General] is null)
                                                and
                                                ([Outcome3] = 'Tenant Default' 
                                                or 
                                                [Outcome3] = 'Judgment for Landlord' 
                                                or 
                                                [Outcome3] = 'Stipulated Agreement' and [SA_noncomp] = '1')
                                ")
#nrow(part1_join_evict_not_match_2)

# filter through OLC eviction rulings
part1_join_evict_all <- sqldf("select * from part1_join_FA_held 
                                                where 
                                                ([Outcome3] = 'Tenant Default' 
                                                or 
                                                [Outcome3] = 'Judgment for Landlord' 
                                                or 
                                                [Outcome3] = 'Stipulated Agreement' and [SA_noncomp] = '1')
                                                or
                                                [Judgment_General] = '1'
                                                
                                ")
#nrow(part1_join_evict_all)




# SQL queries part1_join_OLC (cases before May 15 that can be expected to be found in the most recent OLC)

# count number of 'created_lien' that are coded incorrectly in the FF
part1_join_OLC_JCL_check <- sqldf("select * from part1_join_OLC 
                                                where 
                                                [Judgment_Creates_Lien] = '1' AND [Judgment_General] <> '1' 
                                                AND 
                                                [Judgment_Creates_Lien] = '1' AND [Judgment_Dismissal] <> '1'")
#nrow(part1_join_OLC_JCL_check)


# filter FF data frame for judgments that aren't coded incorrectly
part1_join_OLC_filter <- sqldf('select * from part1_join_OLC except select * from part1_join_OLC_JCL_check')
#nrow(part1_join_OLC_filter)


# filter FF data frame for judgments that aren't coded incorrectly and
# already have a first appearance (06/19 update- this doesn't seem to filter out all the FA Held N/A's)
part1_join_OLC_FA_held <- sqldf("select * from part1_join_OLC_filter 
                                                where 
                                                [FA Held] = 'Y'")
#nrow(part1_join_OLC_FA_held)

# filter through correct eviction rulings
part1_join_OLC_evict_match <- sqldf("select * from part1_join_OLC_FA_held 
                                                where 
                                                [Judgment_General] = '1'
                                                and
                                                ([Outcome3] = 'Tenant Default' 
                                                or 
                                                [Outcome3] = 'Judgment for Landlord' 
                                                or 
                                                [Outcome3] = 'Stipulated Agreement' and [SA_noncomp] = '1')
                                ")
#nrow(part1_join_OLC_evict_match)
# filter through eviction rulings per FF but not OLC
part1_join_OLC_evict_not_match_1 <- sqldf("select * from part1_join_OLC_FA_held 
                                                where 
                                                [Judgment_General] = '1'
                                                and not
                                                ([Outcome3] = 'Tenant Default' 
                                                or 
                                                [Outcome3] = 'Judgment for Landlord' 
                                                or
                                                [Outcome3] = 'Stipulated Agreement' and [SA_noncomp] = '1') 
                                ")
#nrow(part1_join_OLC_evict_not_match_1)
# filter through eviction rulings per OLC but not FF
part1_join_OLC_evict_not_match_2 <- sqldf("select * from part1_join_OLC_FA_held 
                                                where 
                                                ([Judgment_General] <> '1' or [Judgment_General] is null)
                                                and
                                                ([Outcome3] = 'Tenant Default' 
                                                or 
                                                [Outcome3] = 'Judgment for Landlord' 
                                                or 
                                                [Outcome3] = 'Stipulated Agreement' and [SA_noncomp] = '1')
                                ")
#nrow(part1_join_OLC_evict_not_match_2)

# filter through OLC eviction rulings
part1_join_OLC_evict_all <- sqldf("select * from part1_join_OLC_FA_held 
                                                where 
                                                ([Outcome3] = 'Tenant Default' 
                                                or 
                                                [Outcome3] = 'Judgment for Landlord' 
                                                or 
                                                [Outcome3] = 'Stipulated Agreement' and [SA_noncomp] = '1')
                                                or
                                                [Judgment_General] = '1'
                                                
                                ")
#nrow(part1_join_OLC_evict_all)


# filter through correct dismissal rulings
part1_join_OLC_dismiss_match <- sqldf("select * from part1_join_OLC_FA_held 
                                               pgAdmin where 
                                                [Judgment_Dismissal] = '1'
                                                and
                                                [Outcome3] = 'Dismissed' 
                                ")
#nrow(part1_join_OLC_dismiss_match)
# filter through dismissal rulings per FF but not OLC
part1_join_OLC_dismiss_not_match_1 <- sqldf("select * from part1_join_OLC_FA_held
                                                where 
                                                [Judgment_Dismissal] = '1'
                                                and
                                                ([Outcome3] <> 'Dismissed' or [Outcome3] is null)
                                ")
#nrow(part1_join_OLC_dismiss_not_match_1)
# filter through dismissal rulings per OLC but not FF
part1_join_OLC_dismiss_not_match_2 <- sqldf("select * from part1_join_OLC_FA_held 
                                                where 
                                                ([Judgment_Dismissal] <> '1' or [Judgment_Dismissal] is null)
                                                and
                                                [Outcome3] = 'Dismissed' 
                                ")
#nrow(part1_join_OLC_dismiss_not_match_2)

# filter through OLC dismissal rulings
part1_join_OLC_dismiss_all <- sqldf("select * from part1_join_OLC_FA_held 
                                                where 
                                                [Outcome3] = 'Dismissed'
                                                or
                                                [Judgment_Dismissal] = '1'
                                                
                                ")
#nrow(part1_join_OLC_dismiss_all)



# filter through correct FTA rulings [FTADefault]
part1_join_OLC_FTA1_match <- sqldf("select * from part1_join_OLC_FA_held 
                                                where 
                                                [FTADefault] = '1'
                                                and
                                                [Outcome3] = 'Tenant Default' 
                                ")
#nrow(part1_join_OLC_FTA1_match)
# filter through FTA rulings per FF but not OLC
part1_join_OLC_FTA1_not_match_1 <- sqldf("select * from part1_join_OLC_FA_held 
                                                where 
                                                [FTADefault] = '1'
                                                and
                                                ([Outcome3] <> 'Tenant Default' or [Outcome3] is null) 
                                ")
#nrow(part1_join_OLC_FTA1_not_match_1)
# filter through FTA rulings per OLC but not FF
part1_join_OLC_FTA1_not_match_2 <- sqldf("select * from part1_join_OLC_FA_held 
                                                where 
                                                ([FTADefault] <> '1' or [FTADefault] is null)
                                                and
                                                [Outcome3] = 'Tenant Default' 
                                ")
#nrow(part1_join_OLC_FTA1_not_match_2)


# filter through correct FTA rulings [FTA]
part1_join_OLC_FTA2_match <- sqldf("select * from part1_join_OLC_FA_held 
                                                where 
                                                [FTA] = '1'
                                                and
                                                [Outcome3] = 'Tenant Default' 
                                ")
#nrow(part1_join_OLC_FTA2_match)
# filter through FTA rulings per FF but not OLC
part1_join_OLC_FTA2_not_match_1 <- sqldf("select * from part1_join_OLC_FA_held 
                                                where 
                                                [FTA] = '1'
                                                and
                                                ([Outcome3] <> 'Tenant Default' or [Outcome3] is null) 
                                ")
#nrow(part1_join_OLC_FTA2_not_match_1)
# filter through FTA rulings per OLC but not FF
part1_join_OLC_FTA2_not_match_2 <- sqldf("select * from part1_join_OLC_FA_held
                                                where 
                                                ([FTA] <> '1' or [FTA] is null)
                                                and
                                                [Outcome3] = 'Tenant Default' 
                                ")
#nrow(part1_join_OLC_FTA2_not_match_2)

# analyze all FTA rulings
part1_join_OLC_FTA_match <- rbind(part1_join_OLC_FTA1_match, part1_join_OLC_FTA2_match)
part1_join_OLC_FTA_match <- unique(part1_join_OLC_FTA_match[order(part1_join_OLC_FTA_match$case_code),])
part1_join_OLC_FTA_not_match_1 <- sqldf("select * from part1_join_OLC_FA_held
                                                where 
                                                ([FTA] = '1' or [FTADefault] = '1')
                                                and
                                                ([Outcome3] <> 'Tenant Default' or [Outcome3] is null) 
                                    ")
part1_join_OLC_FTA_not_match_2 <- sqldf("select * from part1_join_OLC_FA_held
                                                where 
                                                ([FTA] <> '1' or [FTA] is null) and ([FTADefault] <> '1' or [FTADefault] is null)
                                                and
                                                [Outcome3] = 'Tenant Default' 
                                    ")
part1_join_OLC_FTA_all <- sqldf("select * from part1_join_OLC_FA_held 
                                                where 
                                                [FTADefault] = '1' or [FTA] = '1'
                                                or
                                                [Outcome3] = 'Tenant Default' 
                            ")


# filter FF data frame for judgments that aren't true positive evict or true positive dismissal
part1_join_OLC_query <- sqldf("select * from part1_join_OLC_FA_held except select * from part1_join_OLC_evict_match")
part1_join_OLC_incorrect_all <- sqldf("select * from part1_join_OLC_query except select * from part1_join_OLC_dismiss_match")

# filter FF data frame for judgments that don't have a final ruling
part1_join_OLC_incorrect_NAs_only <- sqldf("select * from part1_join_OLC_incorrect_all 
                                           where
                                           [Judgment_General] is null
                                           or
                                           [Judgment_Creates_Lien] is null
                                           or
                                           [JUdgment_Dismissal] is null
                                     ")
# filter FF data frame for judgments that have a final ruling
part1_join_OLC_incorrect_finals_only <- sqldf("select * from part1_join_OLC_incorrect_all except select * from part1_join_OLC_incorrect_NAs_only")


#** Each case that is completed (has a final judgment, no longer pending) should have EITHER judgment_evict or dismissal ??? CHECK THIS? 
#  then Lien or FTA is a subcategory
#   Can be an eviction WITH FTA, eviction WITH LIEN, or dismissal WITH LIEN
#   can there be a dismissal with FTA? ??? if the FTA is the LANDLORD not the tenant! this is not captured in the FF

# When the cases are not correct- what are they coded as? 
#   We have a count of false negatives and false positives - how to work back from FF coding to figure out why they are not correct??? what is NA? why are some cases coming up as NA? - what is going on in FF coding that leads to so many NAs?
#  -if we removed all the NAs, what is the accuracy of the FF vs. OLC? 
#  -how many incorrect FF coding are with a Stipulated Agreement? - in total and for each outcome? 
  



part2_join_lawyer_rep_match <- sqldf("select * from part2_join 
                                                where 
                                                [landlord_has_lawyer] = [LL_rep]
                                                AND 
                                                [tenant_has_lawyer] = [Ten_rep]")
#nrow(part2_join_lawyer_rep_match)
#nrow(part2_join)

# filter FF data frame for cases where lawyer rep data does not match OLC
part2_join_mismatch <- sqldf('select * from part2_join except select * from part2_join_lawyer_rep_match')
part2_join_mismatch_both <- sqldf("select * from part2_join_mismatch 
                                                where 
                                                [landlord_has_lawyer] <> [LL_rep]
                                                AND 
                                                [tenant_has_lawyer] <> [Ten_rep]")
part2_join_mismatch_remaining <- sqldf('select * from part2_join_mismatch except select * from part2_join_mismatch_both')
part2_join_mismatch_ldlrd <- sqldf('select * from part2_join_mismatch_remaining
                                                where [landlord_has_lawyer] <> [LL_rep]')
part2_join_mismatch_tnt <- sqldf('select * from part2_join_mismatch_remaining
                                                where [tenant_has_lawyer] <> [Ten_rep]')
#nrow(part2_join_mismatch)
#nrow(part2_join_mismatch_both)
#nrow(part2_join_mismatch_ldlrd)
#nrow(part2_join_mismatch_tnt)




# determine how many eviction rulings occurred this week in each county
# for this we merge the judgments_0610_curr dataframe with the part1_join_evict_match dataframe (confirmed evictions)
# IMPORTANT: we need to make sure the part1_join_evict_match type dataframes include cases that received a judgment
# during the current week! this means we need to select all cases in the flatfile! not just the ones that had a ruling
# before 2022-05-15...
this_week_evict_1 <- merge(judgments_0610_curr, part1_join_evict_match, by.x = "case_code", by.y = "case_code")
this_week_evict_2 <- merge(judgments_0610_curr, part1_join_evict_not_match_1, by.x = "case_code", by.y = "case_code")
this_week_evict_3 <- merge(judgments_0610_curr, part1_join_evict_not_match_2, by.x = "case_code", by.y = "case_code")
this_week_evict_all <- rbind(this_week_evict_1, this_week_evict_2, this_week_evict_3)

# generate list of how many values are in each this_week_evict table
temp1 <- data.frame(table(this_week_evict_1$location))
temp2 <- data.frame(table(this_week_evict_all$location))

# create template CSV file for tabulating weekly eviction counts
CountyDataACS <- readRDS("CountyDataACS.rds")
CountyWeekEvict_base <- subset(CountyDataACS, select = -c(AIAN :pOwner))
colnames(CountyWeekEvict_base)[colnames(CountyWeekEvict_base) == "summary_est"] <- "Count"
CountyWeekEvict_base$Count <- 0
CountyWeekEvict_base$Count_full <- 0

# create CSV file for this week's scrape
CountyWeekEvict_curr <- CountyWeekEvict_base

# iterate through the lists of how many values are in each this_week_evict table
for (i in 1:nrow(CountyWeekEvict_curr)) {
  # both evict_1 (FF and OLC match) and evict_all (all eviction records) have same # of rows
  for (j in 1:nrow(temp1)) {
    # copy County # of evicts (FF and OLC match)
    if (temp1$Var1[j] == CountyWeekEvict_curr$NAME[i]) {
      CountyWeekEvict_curr$Count[i] <- temp1$Freq[j]
    }
    # copy County # of evicts (all eviction records)
    if (temp2$Var1[j] == CountyWeekEvict_curr$NAME[i]) {
      CountyWeekEvict_curr$Count_full[i] <- temp2$Freq[j]
    }
  }
}
CountyWeekEvict_curr$Count[nrow(CountyWeekEvict_curr)] <- sum(temp1$Freq)
CountyWeekEvict_curr$Count_full[nrow(CountyWeekEvict_curr)] <- sum(temp2$Freq)
write.table(CountyWeekEvict_curr, file="G:/Shared drives/ojdevictions/FF_vs_OLC_accuracy/CountyWeeklyEvict_0610.csv", row.names=F, sep=",")


#write.table(CountyWeekEvict_base, file="G:/Shared drives/ojdevictions/FF_vs_OLC_accuracy/CountyWeeklyEvict_template.csv", row.names=F, sep=",")

if (!file.exists("0610_Excel")) {
  dir.create(file.path("G:/Shared drives/ojdevictions/FF_vs_OLC_accuracy/0610_Excel"))
}

write.table(part1_join_OLC_evict_match, file="G:/Shared drives/ojdevictions/FF_vs_OLC_accuracy/0610_Excel/0610_eviction_true_pos.csv", row.names=F, sep=",")
#write.table(part1_join_OLC_evict_not_match_1, file="G:/Shared drives/ojdevictions/FF_vs_OLC_accuracy/0610_Excel/0610_eviction_false_pos.csv", row.names=F, sep=",")
#write.table(part1_join_OLC_evict_not_match_2, file="G:/Shared drives/ojdevictions/FF_vs_OLC_accuracy/0610_Excel/0610_eviction_false_neg.csv", row.names=F, sep=",")
write.table(part1_join_OLC_dismiss_match, file="G:/Shared drives/ojdevictions/FF_vs_OLC_accuracy/0610_Excel/0610_dismissal_true_pos.csv", row.names=F, sep=",")
#write.table(part1_join_OLC_dismiss_not_match_1, file="G:/Shared drives/ojdevictions/FF_vs_OLC_accuracy/0610_Excel/0610_dismissal_false_pos.csv", row.names=F, sep=",")
#write.table(part1_join_OLC_dismiss_not_match_2, file="G:/Shared drives/ojdevictions/FF_vs_OLC_accuracy/0610_Excel/0610_dismissal_false_neg.csv", row.names=F, sep=",")
write.table(part1_join_OLC_incorrect_finals_only, file="G:/Shared drives/ojdevictions/FF_vs_OLC_accuracy/0610_Excel/0610_incorrect_final_rulings.csv", row.names=F, sep=",")
#write.table(part1_join_OLC_FTA_not_match_1, file="G:/Shared drives/ojdevictions/FF_vs_OLC_accuracy/0610_Excel/0610_FTA_false_pos.csv", row.names=F, sep=",")
#write.table(part1_join_OLC_FTA_not_match_2, file="G:/Shared drives/ojdevictions/FF_vs_OLC_accuracy/0610_Excel/0610_FTA_false_neg.csv", row.names=F, sep=",")

table(this_week_evict_1$location)
table(this_week_evict_all$location)


# https://www.statology.org/r-concatenate-strings/
#concatenate the three strings into one string
#d <- paste(a, b, c)


# https://stackoverflow.com/questions/23474239/writing-multiple-lines-to-a-txt-file-using-r
#Line1 = "Line One of Text File"
#Line2 = "The Second Line of the Text File"
#
#FileName = "TextFile.txt"
#
#fileConn<-file(FileName)
#writeLines(c(Line1, Line2), fileConn)
#close(fileConn)


Line0 <- paste("Summary (new version with May 2022 OLC)")
Line1 <- paste("Total # of cases in record: ", nrow(part1_join_OLC))
Line2 <- paste("# of cases w/ incorrect lien format in FF: ", nrow(part1_join_OLC_JCL_check))
Line3 <- paste("# of cases w/ correct lien format in FF: ", nrow(part1_join_OLC_filter))
Line4 <- paste("# of cases w/ a FA held: ", nrow(part1_join_OLC_FA_held))

Line5 <- paste("Eviction Cases")
Line6 <- paste("# of FA cases with matching eviction records: ", nrow(part1_join_OLC_evict_match))
Line7 <- paste("# of FA cases with eviction record false positives: ", nrow(part1_join_OLC_evict_not_match_1))
Line8 <- paste("# of FA cases with eviction record false negatives: ", nrow(part1_join_OLC_evict_not_match_2))
Line9 <- paste("Total # of FA cases with eviction records: ", nrow(part1_join_OLC_evict_all))

Line10 <- paste("Dismissal Cases")
Line11 <- paste("# of FA cases with matching dismissal records: ", nrow(part1_join_OLC_dismiss_match))
Line12 <- paste("# of FA cases with dismissal record false positives: ", nrow(part1_join_OLC_dismiss_not_match_1))
Line13 <- paste("# of FA cases with dismissal record false negatives: ", nrow(part1_join_OLC_dismiss_not_match_2))
Line14 <- paste("Total # of FA cases with dismissal records: ", nrow(part1_join_OLC_dismiss_all))

Line15 <- paste("FTA Cases")
Line16 <- paste("# of FA cases with matching FTA records: ", nrow(part1_join_OLC_FTA_match))
Line17 <- paste("# of FA cases with FTA record false positives: ", nrow(part1_join_OLC_FTA_not_match_1))
Line18 <- paste("# of FA cases with FTA record false negatives: ", nrow(part1_join_OLC_FTA_not_match_2))
Line19 <- paste("Total # of FA cases with FTA records: ", nrow(part1_join_OLC_FTA_all))

Line20 <- paste("Lawyer Representation")
Line21 <- paste("Total # of judgment cases in record: ", nrow(part2_join)) 
Line22 <- paste("Total # of cases with matching lawyer rep data: ", nrow(part2_join_lawyer_rep_match))
Line23 <- paste("Total # of cases with mismatched lawyer rep data for both: ", nrow(part2_join_mismatch_both))
Line24 <- paste("Total # of cases with mismatched lawyer rep data for landlord only: ", nrow(part2_join_mismatch_ldlrd))
Line25 <- paste("Total # of cases with mismatched lawyer rep data for tenant only: ", nrow(part2_join_mismatch_tnt))

Line26 <- paste("May 2022 OLC Updated Analysis")
Line27 <- paste("# of FA cases- Eviction True Positives: ", nrow(part1_join_OLC_evict_match))
Line28 <- paste("# of FA cases- Dismissal True Positives: ", nrow(part1_join_OLC_dismissal_match))
Line29 <- paste("# of FA cases- No Ruling Yet in FF: ", nrow(part1_join_OLC_incorrect_finals_only))

FileName = "G:/Shared drives/ojdevictions/FF_vs_OLC_accuracy/Weekly_Scrape_Accuracy/summary_0610_new.txt"

fileConn<-file(FileName)
writeLines(c(Line0, Line1, Line2, Line3, Line4, Line5, Line6, Line7, Line8, Line9, Line10, Line11, Line12, Line13, Line14, Line15, Line16, Line17, Line18, Line19, Line20, Line21, Line22, Line23, Line24, Line25), fileConn)
close(fileConn)