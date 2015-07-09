# --------------------------------------------------------------
# CMS HCC Model V22 for Continuing Community Enrollees
#Assumes that these data frames have been imported into the R environment
#PERSON File Input
# 1. HICNO (or other person identification variable. Character or numeric type and unique to an individual
# 2. SEX -one character, 1=male; 2=female 
# 3. DOB - date of birth
# 4. MCAID -numeric, =1 if number of State Part B BUYIN (MEDICAID)Months of base year >0, =0 otherwise 
# 5. NEMCAID -numeric, =1 if a new enrollee and number of State Part B BUYIN (MEDICAID) months of payment year >0; =0 otherwise 
# 6. OREC - -one character, original reason for entitlement with the following values: 0 - OLD AGE (OASI), 1 - DISABILITY (DIB), 2 - ESRD, 3 - BOTH DIB AND ESRD
#DIAG File Input
# 1. HICNO (or other person identification variable that must be the same as in PERSON file) - person identifier of character or numeric type and unique to an individual 
# 2. DIAG - ICD-9-CM diagnosis code, 5 character field, no periods, left justified. The user may include all diagnoses or limit the codes to those used by the
# 	model. Codes should be to the greatest level of available specificity. Diagnoses should be included only from providers and physician specialties as
#	provided in prior notices.
# --------------------------------------------------------------
# Calculated fields
# Assume DOB is in yyyy-mm-dd format, calculate age from today
#Evaluate CMS-HCC risk adjustment score
icd9RiskAdjCMSHCC <- function(DIAG, PERSON, cmshcc_list) {
  PERSON$AGE <- as.numeric(round(difftime(Sys.Date(), as.Date(PERSON$DOB, "%Y-%m-%d", tz = "UTC"), units = "weeks")/52.25))
  PERSON$DISABL <- (PERSON$AGE < 65) & (PERSON$OREC != 0)
  PERSON$ORIGDS <- (PERSON$AGE >= 65) & (PERSON$OREC %in% c(1,3))
  breaks <- c(0, 35, 45, 55, 60, 65, 70, 75, 80, 85, 90, 95, 120)
  PERSON$AGE_BAND <- cut(x = PERSON$AGE, breaks = breaks, include.lowest = TRUE, right = FALSE)
  female_age_factors <- c(0.201, 0.211, 0.270, 0.334, 0.402, 0.295, 0.357, 0.448, 0.553, 0.694, 0.835, 0.861)
  male_age_factors <- c(0.124, 0.127, 0.186, 0.275, 0.319, 0.295, 0.365, 0.454, 0.557, 0.700, 0.869, 1.054)
  PERSON$AGEGENDER_SCORE <- (PERSON$SEX == 1) * male_age_factors[PERSON$AGE_BAND] + (PERSON$SEX == 2) * female_age_factors[PERSON$AGE_BAND]
  PERSON$MCAID_FEMALE_AGED <- (PERSON$MCAID == 1) & (PERSON$SEX == 2) & (PERSON$DISABL == 0)
  PERSON$MCAID_FEMALE_DISABL <- (PERSON$MCAID == 1) & (PERSON$SEX == 2) & (PERSON$DISABL == 1)
  PERSON$MCAID_MALE_AGED <- (PERSON$MCAID == 1) & (PERSON$SEX == 1) & (PERSON$DISABL == 0)
  PERSON$MCAID_MALE_DISABL <- (PERSON$MCAID == 1) & (PERSON$SEX == 2) & (PERSON$DISABL == 1)
  PERSON$ORIGDS_FEMALE <- (PERSON$ORIGDS == 1) & (PERSON$SEX == 2)
  PERSON$ORIGDS_MALE <- (PERSON$ORIGDS == 1) & (PERSON$SEX == 1)
  demointeraction_factors <- c(0.155, 0.087, 0.181, 0.088, 0.245, 0.167)
  PERSON$DEMOINTERACTION_SCORE <- as.matrix(PERSON[,c("MCAID_FEMALE_AGED", "MCAID_FEMALE_DISABL", "MCAID_MALE_AGED", "MCAID_MALE_DISABL", "ORIGDS_FEMALE", "ORIGDS_MALE")]) %*% demointeraction_factors
  #Evaluate using icd9 package by Jack Wasey
  PERSON <- cbind(PERSON, as.data.frame(icd9Comorbid(icd9df = DIAG, icd9Mapping = cmshcc_list, visitId = "HICNO")))
  #Apply Hierarchies
  PERSON$HCC12 <- PERSON$HCC12 & (!PERSON$HCC8) & (!PERSON$HCC9) & (!PERSON$HCC10) & (!PERSON$HCC11)
  PERSON$HCC11 <- PERSON$HCC11 & (!PERSON$HCC8) & (!PERSON$HCC9) & (!PERSON$HCC10)
  PERSON$HCC10 <- PERSON$HCC10 & (!PERSON$HCC8) & (!PERSON$HCC9)
  PERSON$HCC9 <- PERSON$HCC9 & (!PERSON$HCC8)
  PERSON$HCC19 <- PERSON$HCC19 & (!PERSON$HCC17) & (!PERSON$HCC18)
  PERSON$HCC18 <- PERSON$HCC18 & (!PERSON$HCC19)
  PERSON$HCC29 <- PERSON$HCC29 & (!PERSON$HCC27) & (!PERSON$HCC28)
  PERSON$HCC28 <- PERSON$HCC28 & (!PERSON$HCC27)
  PERSON$HCC80 <- PERSON$HCC80 & (!PERSON$HCC27) & (!PERSON$HCC166)
  PERSON$HCC48 <- PERSON$HCC48 & (!PERSON$HCC46)
  PERSON$HCC55 <- PERSON$HCC55 & (!PERSON$HCC54)
  PERSON$HCC58 <- PERSON$HCC58 & (!PERSON$HCC57)
  PERSON$HCC169 <- PERSON$HCC169 & (!PERSON$HCC72) & (!PERSON$HCC71) & (!PERSON$HCC70)
  PERSON$HCC104 <- PERSON$HCC104 & (!PERSON$HCC71) & (!PERSON$HCC70) & (!PERSON$HCC103)
  PERSON$HCC103 <- PERSON$HCC103 & (!PERSON$HCC70)
  PERSON$HCC72 <- PERSON$HCC72 & (!PERSON$HCC71) & (!PERSON$HCC70)
  PERSON$HCC71 <- PERSON$HCC71 & (!PERSON$HCC70)
  PERSON$HCC84 <- PERSON$HCC84 & (!PERSON$HCC83) & (!PERSON$HCC82)
  PERSON$HCC83 <- PERSON$HCC83 & (!PERSON$HCC82)
  PERSON$HCC88 <- PERSON$HCC88 & (!PERSON$HCC87) & (!PERSON$HCC86)
  PERSON$HCC87 <- PERSON$HCC87 & (!PERSON$HCC86)
  PERSON$HCC100 <- PERSON$HCC100 & (!PERSON$HCC99)
  PERSON$HCC108 <- PERSON$HCC108 & (!PERSON$HCC107) & (!PERSON$HCC106)
  PERSON$HCC161 <- PERSON$HCC161 & (!PERSON$HCC106)
  PERSON$HCC189 <- PERSON$HCC189 & (!PERSON$HCC106)
  PERSON$HCC107 <- PERSON$HCC107 & (!PERSON$HCC106)
  PERSON$HCC112 <- PERSON$HCC112 & (!PERSON$HCC111) & (!PERSON$HCC110)
  PERSON$HCC111 <- PERSON$HCC111 & (!PERSON$HCC110)
  PERSON$HCC115 <- PERSON$HCC115 & (!PERSON$HCC114)
  PERSON$HCC137 <- PERSON$HCC137 & (!PERSON$HCC136) & (!PERSON$HCC135) & (!PERSON$HCC134)
  PERSON$HCC136 <- PERSON$HCC136 & (!PERSON$HCC135) & (!PERSON$HCC134)
  PERSON$HCC135 <- PERSON$HCC135 & (!PERSON$HCC134)
  PERSON$HCC161 <- PERSON$HCC161 & (!PERSON$HCC158) & (!PERSON$HCC157)
  PERSON$HCC158 <- PERSON$HCC158 & (!PERSON$HCC157)
  PERSON$HCC167 <- PERSON$HCC167 & (!PERSON$HCC166)
  #Generate Disease Scores
  disease_factors <- c(.482, .548, .451, 2.546, 0.997, 0.689, 0.325, 0.158, 0.378, 0.378, 0.121, 0.731, 0.374, 0.251, 0.947)
  disease_factors <- c(disease_factors, c(0.409, 0.257, 0.318, 0.293, 0.310, 0.510, 0.383, 1.165, 0.534, 0.258, 0.431, 0.431, 0.503, 0.339, 1.265))
  disease_factors <- c(disease_factors, c(1.078, 0.522, 0.982, 0.046, 0.418, 0.579, 0.570, 0.708, 0.291, 0.585, 1.558, 0.822, 0.338, 0.377, 0.282, 0.264, 0.145, 0.302, 0.347))
  disease_factors <- c(disease_factors, c(0.325, 0.596, 0.406, 1.449, 0.42, 0.306, 0.427, 0.355, 0.281, 0.689, 0.205, 0.208, 0.343, 0.488, 0.488, 0.230, 0.230, 2.551, 1.371))
  disease_factors <- c(disease_factors, c(0.549, 0.422, 0.585, 0.167, 0.509, 0.458, 0.272, 0.580, 0.913, 0.667, 0.798))
  PERSON$DISEASE_SCORE <- as.matrix(PERSON[, names(cmshcc_list)]) %*% disease_factors
  #Condition Category Groupings
  PERSON$CANCER <- PERSON$HCC8 | PERSON$HCC9 | PERSON$HCC10 | PERSON$HCC11 | PERSON$HCC12
  PERSON$IMMUNE <- PERSON$HCC47
  PERSON$CHF <- PERSON$HCC85
  PERSON$COPD <- PERSON$HCC110 | PERSON$HCC111
  PERSON$RENAL <- PERSON$HCC134 | PERSON$HCC135 | PERSON$HCC136 | PERSON$HCC137
  PERSON$CARD_RESP_FAIL <- PERSON$HCC82 | PERSON$HCC83 | PERSON$HCC84
  PERSON$DIABETES <- PERSON$HCC17 | PERSON$HCC18 | PERSON$HCC19
  PERSON$SEPSIS <- PERSON$HCC2
  #Disease x Disease Interaction Terms
  PERSON$CANCER_IMMUNE <- PERSON$CANCER & PERSON$IMMUNE
  PERSON$CHF_COPD <- PERSON$CHF & PERSON$COPD
  PERSON$CHF_RENAL <- PERSON$CHF & PERSON$RENAL
  PERSON$COPD_CARD_RESP_FAIL <- PERSON$COPD & PERSON$CARD_RESP_FAIL
  PERSON$DIABETES_CHF <- PERSON$DIABETES & PERSON$CHF
  PERSON$SEPSIS_CARD_RESP_FAIL <- PERSON$SEPSIS & PERSON$CARD_RESP_FAIL
  interaction_terms <- c("CANCER_IMMUNE", "CHF_COPD", "CHF_RENAL", "COPD_CARD_RESP_FAIL", "DIABETES_CHF", "SEPSIS_CARD_RESP_FAIL")
  interaction_factors <- c(0.971, 0.265, 0.325, 0.467, 0.187, 0.219)
  PERSON$DISEASE_INTERACTION <- as.matrix(PERSON[, interaction_terms]) %*% interaction_factors
  #Disability x Disease Interaction Terms
  PERSON$DISABL_HCC6 <- PERSON$DISABL & PERSON$HCC6
  PERSON$DISABL_HCC34 <- PERSON$DISABL & PERSON$HCC34
  PERSON$DISABL_HCC46 <- PERSON$DISABL & PERSON$HCC46
  PERSON$DISABL_HCC54 <- PERSON$DISABL & PERSON$HCC54
  PERSON$DISABL_HCC110 <- PERSON$DISABL & PERSON$HCC110
  PERSON$DISABL_HCC176 <- PERSON$DISABL & PERSON$HCC176
  disabl_int_terms <- c("DISABL_HCC6", "DISABL_HCC34", "DISABL_HCC46", "DISABL_HCC54", "DISABL_HCC110", "DISABL_HCC176")
  disabl_int_factors <- c(0.462, 0.562, 1.381, 0.339, 2.476, 0.516)
  PERSON$DISABL_INTERACTION <- as.matrix(PERSON[, disabl_int_terms]) %*% disabl_int_factors
  #Total Risk Adjustment Scores
  PERSON$TOTAL <- PERSON$AGEGENDER_SCORE + PERSON$DEMOINTERACTION_SCORE + PERSON$DISEASE_SCORE + PERSON$DISEASE_INTERACTION + PERSON$DISABL_INTERACTION
  return(PERSON$TOTAL)
}
randomDate <- function(size = 100, start_time = "1930/01/01", end_time = "2010/12/31") {
  start_time <- as.POSIXct(as.Date(start_time))
  end_time <- as.POSIXct(as.Date(end_time))
  date_time <- as.numeric(difftime(end_time, start_time, unit = "sec"))
  end_value <- sort(runif(size, 0, date_time))
  random_time <- start_time + end_value
  return(random_time)
}
generateTestPERSON <- function(size = 100, seed = 2, start_time = "1930/01/01", end_time = "2010/12/31") {
  set.seed(seed)
  HICNO <- 1:size
  SEX <- sample(x = c(1, 2), size, replace = TRUE)
  DOB <- randomDate(size, start_time, end_time)
  MCAID <- sample(x = c(0, 1), size, replace = TRUE)
  NMCAID <- sample(x = c(0, 1), size, replace = TRUE)
  OREC <- sample(x = 0:3, size, replace = TRUE)
  PERSON <- data.frame(HICNO = HICNO, SEX = SEX, DOB = DOB, MCAID = MCAID, NMCAID = NMCAID, OREC = OREC, stringsAsFactors = FALSE)
  return(PERSON)
}
generateTestDIAG <- function(size = 100, seed = 2, max_dx = 10, cmshcc_map) {
  set.seed(seed)
  num_dx <- sample(x = 1:max_dx, size, replace = TRUE)
  tot_dx <- sum(num_dx)
  dxs <- sample(cmshcc_map$icd9, tot_dx, replace = TRUE)
  HICNO <-rep(x = 1:size, times = num_dx)
  DIAG <- data.frame(HICNO = HICNO, DIAGS = dxs, stringsAsFactors = FALSE)
  return(DIAG)
}
#Load icd9HCC mapping
loadicd9HCC <- function() {
  cmshcc_map <- read.csv(file.choose(), header=FALSE, sep="", stringsAsFactors=FALSE)
  names(cmshcc_map) <- c("icd9", "hcc")
  #Generate list of HCC mapping
  hccs <- sort(unique(cmshcc_map$hcc))
  cmshcc_list <- list()
  for(i in 1:length(hccs)) {
    label <- paste0("HCC", hccs[i])
    cmshcc_list[[label]] <- subset(cmshcc_map, hcc == hccs[i])$icd9
  }
  cmshcc_list
	set.seed(seed)
	num_dx <- sample(x = 1:max_dx, size, replace = TRUE)
	tot_dx <- sum(num_dx)
	dxs <- sample(icd9Dict, tot_dx, replace = TRUE)
	HICNO <-rep(x = 1:size, times = num_dx)
	DIAG <- data.frame(HICNO = HICNO, DIAGS = dxs, stringsAsFactors = FALSE)
	return(DIAG)
}
#Load icd9HCC mapping
loadicd9HCC <- function() {
	cmshcc_map <- read.csv(file.choose(), header=FALSE, sep="", stringsAsFactors=FALSE)
	names(cmshcc_map) <- c("icd9", "hcc")
	#Generate list of HCC mapping
	hccs <- sort(unique(cmshcc_map$hcc))
	cmshcc_list <- list()
	for(i in 1:length(hccs)) {
		label <- paste0("HCC", hccs[i])
		cmshcc_list[[label]] <- subset(cmshcc_map, hcc == hccs[i])$icd9
	}
	cmshcc_list
}