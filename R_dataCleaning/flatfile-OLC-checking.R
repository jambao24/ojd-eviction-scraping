# James Bao
# 2022 May 31 version
# scratch R code for analyzing and interpreting weekly scrape data

library(readxl)
library(sqldf)
library(plyr)


# for Goal 1, we want cols B (case_code), M, N, O, R, S
# for Goal 2, we want cols B (case_code). L, Q, V, U
# for Goal 3, we want cols B (case_code), H
FF_0603 <- read.csv("G:/Shared drives/ojdevictions/ScrapeData/full_scrape_20220603/flat_file.csv")
FF_0603_1 = FF_0603[,-1]
FF_0603_1 <- subset(FF_0603_1, select = -c(case_name:status))
FF_0603_1 <- subset(FF_0603_1, select = -c(plaintiff_name:Agent))
FF_0603_1 <- subset(FF_0603_1, select = -c(tenant_lawyer:landlord_lawyer))
FF_0603_1 <- subset(FF_0603_1, select = -c(landlord_has_lawyer:zip))
#View(FF_0603_1)

FF_0603_2 = FF_0603[,-1]
FF_0603_2 <- subset(FF_0603_2, select = -c(case_name:defendant_addr))
FF_0603_2 <- subset(FF_0603_2, select = -c(Judgment_General:tenant_lawyer))
FF_0603_2 <- subset(FF_0603_2, select = -c(FTA:FTAFirst))
FF_0603_2 <- subset(FF_0603_2, select = -c(FTAFirstXJudgmentGeneral:zip))
#View(FF_0603_2)

FF_0603_3 = FF_0603[,-1]
FF_0603_3 <- subset(FF_0603_3, select = -c(case_name:status))
FF_0603_3 <- subset(FF_0603_3, select = -c(plaintiff_name:zip))
#View(FF_0603_3)

# for Goal 3, we want col C (case_code), F (decision), G (judgment date)
judgments_0603 <- read.csv("G:/Shared drives/ojdevictions/ScrapeData/full_scrape_20220603/judgments.csv")
# https://www.youtube.com/watch?v=6inAoQddaj0
# convert date column to Date data type
judgments_0603$date <- as.Date(judgments_0603$date, format = '%m/%d/%Y')
# remove unwanted rows
judgments_0603 = judgments_0603[,-1]
judgments_0603 = judgments_0603[,-1]
judgments_0603 = judgments_0603[,-2]
judgments_0603 = judgments_0603[,-2]
judgments_0603 = judgments_0603[,-5]
#View(judgments_0603)
# filter for rows that contain judgment dates within the current week 
judgments_0603_curr = judgments_0603[judgments_0603$date > "2022-05-28" & judgments_0603$date < "2022-06-05", ]
judgments_0603_curr <- judgments_0603_curr[complete.cases(judgments_0603_curr),]

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


part1_join <- merge(FF_0603_1, OLC_updated_1, by.x = "case_code", by.y = "Case #")
part2_join <- merge(FF_0603_2, OLC_updated_2, by.x = "case_code", by.y = "Case #")
part3_join <- merge(FF_0603_3, judgments_0603, by = "case_code")

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


# filter through correct dismissal rulings
part1_join_dismiss_match <- sqldf("select * from part1_join_FA_held 
                                               pgAdmin where 
                                                [Judgment_Dismissal] = '1'
                                                and
                                                [Outcome3] = 'Dismissed' 
                                ")
#nrow(part1_join_dismiss_match)
# filter through dismissal rulings per FF but not OLC
part1_join_dismiss_not_match_1 <- sqldf("select * from part1_join_FA_held
                                                where 
                                                [Judgment_Dismissal] = '1'
                                                and
                                                ([Outcome3] <> 'Dismissed' or [Outcome3] is null)
                                ")
#nrow(part1_join_dismiss_not_match_1)
# filter through dismissal rulings per OLC but not FF
part1_join_dismiss_not_match_2 <- sqldf("select * from part1_join_FA_held 
                                                where 
                                                ([Judgment_Dismissal] <> '1' or [Judgment_Dismissal] is null)
                                                and
                                                [Outcome3] = 'Dismissed' 
                                ")
#nrow(part1_join_dismiss_not_match_2)

# filter through OLC dismissal rulings
part1_join_dismiss_all <- sqldf("select * from part1_join_FA_held 
                                                where 
                                                [Outcome3] = 'Dismissed'
                                                or
                                                [Judgment_Dismissal] = '1'
                                                
                                ")
#nrow(part1_join_dismiss_all)



# filter through correct FTA rulings [FTADefault]
part1_join_FTA1_match <- sqldf("select * from part1_join_FA_held 
                                                where 
                                                [FTADefault] = '1'
                                                and
                                                [Outcome3] = 'Tenant Default' 
                                ")
#nrow(part1_join_FTA1_match)
# filter through FTA rulings per FF but not OLC
part1_join_FTA1_not_match_1 <- sqldf("select * from part1_join_FA_held 
                                                where 
                                                [FTADefault] = '1'
                                                and
                                                ([Outcome3] <> 'Tenant Default' or [Outcome3] is null) 
                                ")
#nrow(part1_join_FTA1_not_match_1)
# filter through FTA rulings per OLC but not FF
part1_join_FTA1_not_match_2 <- sqldf("select * from part1_join_FA_held 
                                                where 
                                                ([FTADefault] <> '1' or [FTADefault] is null)
                                                and
                                                [Outcome3] = 'Tenant Default' 
                                ")
#nrow(part1_join_FTA1_not_match_2)


# filter through correct FTA rulings [FTA]
part1_join_FTA2_match <- sqldf("select * from part1_join_FA_held 
                                                where 
                                                [FTA] = '1'
                                                and
                                                [Outcome3] = 'Tenant Default' 
                                ")
#nrow(part1_join_FTA2_match)
# filter through FTA rulings per FF but not OLC
part1_join_FTA2_not_match_1 <- sqldf("select * from part1_join_FA_held 
                                                where 
                                                [FTA] = '1'
                                                and
                                                ([Outcome3] <> 'Tenant Default' or [Outcome3] is null) 
                                ")
#nrow(part1_join_FTA2_not_match_1)
# filter through FTA rulings per OLC but not FF
part1_join_FTA2_not_match_2 <- sqldf("select * from part1_join_FA_held
                                                where 
                                                ([FTA] <> '1' or [FTA] is null)
                                                and
                                                [Outcome3] = 'Tenant Default' 
                                ")
#nrow(part1_join_FTA2_not_match_2)

# analyze all FTA rulings
part1_join_FTA_match <- rbind(part1_join_FTA1_match, part1_join_FTA2_match)
part1_join_FTA_match <- unique(part1_join_FTA_match[order(part1_join_FTA_match$case_code),])
part1_join_FTA_not_match_1 <- sqldf("select * from part1_join_FA_held
                                                where 
                                                ([FTA] = '1' or [FTADefault] = '1')
                                                and
                                                ([Outcome3] <> 'Tenant Default' or [Outcome3] is null) 
                                    ")
part1_join_FTA_not_match_2 <- sqldf("select * from part1_join_FA_held
                                                where 
                                                ([FTA] <> '1' or [FTA] is null) and ([FTADefault] <> '1' or [FTADefault] is null)
                                                and
                                                [Outcome3] = 'Tenant Default' 
                                    ")
part1_join_FTA_all <- sqldf("select * from part1_join_FA_held 
                                                where 
                                                [FTADefault] = '1' or [FTA] = '1'
                                                or
                                                [Outcome3] = 'Tenant Default' 
                            ")



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
# for this we merge the judgments_0603_curr dataframe with the part1_join_evict_match dataframe (confirmed evictions)
this_week_evict_1 <- merge(judgments_0603_curr, part1_join_evict_match, by.x = "case_code", by.y = "case_code")
this_week_evict_2 <- merge(judgments_0603_curr, part1_join_evict_not_match_1, by.x = "case_code", by.y = "case_code")
this_week_evict_3 <- merge(judgments_0603_curr, part1_join_evict_not_match_2, by.x = "case_code", by.y = "case_code")
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
write.table(CountyWeekEvict_curr, file="G:/Shared drives/ojdevictions/FF_vs_OLC_accuracy/CountyWeeklyEvict_0603.csv", row.names=F, sep=",")


#write.table(CountyWeekEvict_base, file="G:/Shared drives/ojdevictions/FF_vs_OLC_accuracy/CountyWeeklyEvict_template.csv", row.names=F, sep=",")

if (!file.exists("0603_Excel")) {
  dir.create(file.path("G:/Shared drives/ojdevictions/FF_vs_OLC_accuracy/0603_Excel"))
}


write.table(part1_join_evict_not_match_1, file="G:/Shared drives/ojdevictions/FF_vs_OLC_accuracy/0603_Excel/0603_eviction_false_pos.csv", row.names=F, sep=",")
write.table(part1_join_evict_not_match_2, file="G:/Shared drives/ojdevictions/FF_vs_OLC_accuracy/0603_Excel/0603_eviction_false_neg.csv", row.names=F, sep=",")
write.table(part1_join_dismiss_not_match_1, file="G:/Shared drives/ojdevictions/FF_vs_OLC_accuracy/0603_Excel/0603_dismissal_false_pos.csv", row.names=F, sep=",")
write.table(part1_join_dismiss_not_match_2, file="G:/Shared drives/ojdevictions/FF_vs_OLC_accuracy/0603_Excel/0603_dismissal_false_neg.csv", row.names=F, sep=",")
write.table(part1_join_FTA_not_match_1, file="G:/Shared drives/ojdevictions/FF_vs_OLC_accuracy/0603_Excel/0603_FTA_false_pos.csv", row.names=F, sep=",")
write.table(part1_join_FTA_not_match_2, file="G:/Shared drives/ojdevictions/FF_vs_OLC_accuracy/0603_Excel/0603_FTA_false_neg.csv", row.names=F, sep=",")

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


Line0 <- paste("Summary")
Line1 <- paste("Total # of cases in record: ", nrow(part1_join))
Line2 <- paste("# of cases w/ incorrect lien format in FF: ", nrow(part1_join_JCL_check))
Line3 <- paste("# of cases w/ correct lien format in FF: ", nrow(part1_join_filter))
Line4 <- paste("# of cases w/ a FA held: ", nrow(part1_join_FA_held))

Line5 <- paste("Eviction Cases")
Line6 <- paste("# of FA cases with matching eviction records: ", nrow(part1_join_evict_match))
Line7 <- paste("# of FA cases with eviction record false positives: ", nrow(part1_join_evict_not_match_1))
Line8 <- paste("# of FA cases with eviction record false negatives: ", nrow(part1_join_evict_not_match_2))
Line9 <- paste("Total # of FA cases with eviction records: ", nrow(part1_join_evict_all))

Line10 <- paste("Dismissal Cases")
Line11 <- paste("# of FA cases with matching dismissal records: ", nrow(part1_join_dismiss_match))
Line12 <- paste("# of FA cases with dismissal record false positives: ", nrow(part1_join_dismiss_not_match_1))
Line13 <- paste("# of FA cases with dismissal record false negatives: ", nrow(part1_join_dismiss_not_match_2))
Line14 <- paste("Total # of FA cases with dismissal records: ", nrow(part1_join_dismiss_all))

Line15 <- paste("FTA Cases")
Line16 <- paste("# of FA cases with matching FTA records: ", nrow(part1_join_FTA_match))
Line17 <- paste("# of FA cases with FTA record false positives: ", nrow(part1_join_FTA_not_match_1))
Line18 <- paste("# of FA cases with FTA record false negatives: ", nrow(part1_join_FTA_not_match_2))
Line19 <- paste("Total # of FA cases with FTA records: ", nrow(part1_join_FTA_all))

Line20 <- paste("Lawyer Representation")
Line21 <- paste("Total # of judgment cases in record: ", nrow(part2_join)) 
Line22 <- paste("Total # of cases with matching lawyer rep data: ", nrow(part2_join_lawyer_rep_match))
Line23 <- paste("Total # of cases with mismatched lawyer rep data for both: ", nrow(part2_join_mismatch_both))
Line24 <- paste("Total # of cases with mismatched lawyer rep data for landlord only: ", nrow(part2_join_mismatch_ldlrd))
Line25 <- paste("Total # of cases with mismatched lawyer rep data for tenant only: ", nrow(part2_join_mismatch_tnt))

FileName = "G:/Shared drives/ojdevictions/FF_vs_OLC_accuracy/Weekly_Scrape_Accuracy/summary_0603.txt"

fileConn<-file(FileName)
writeLines(c(Line0, Line1, Line2, Line3, Line4, Line5, Line6, Line7, Line8, Line9, Line10, Line11, Line12, Line13, Line14, Line15, Line16, Line17, Line18, Line19, Line20, Line21, Line22, Line23, Line24, Line25), fileConn)
close(fileConn)