library(dplyr)
library(lubridate)

rm(list=ls()) 
cat("\014")  

setwd("C:/Users/rogl2/OneDrive - NHS/Dev/R/MSDS/Preprocess Data")

source("util.r")
source("rationalise_fields.R")


data <- read.csv('export - 20240214.csv', na="null")

data <- data %>% mutate(
  PersonBirthDateMother = ymd(PersonBirthDateMother)
)

output <- NA

unique_pregnancies <- data %>% pull(UniqPregID) %>% unique

# TODO loop by mother and uniq preg id instead of just mother in case multiple of same pt pregnancies in batch

for(i in 1:length(unique_pregnancies)) {
  data_for_pt  <- data %>% filter(UniqPregID == unique_pregnancies[i])
  if(nrow(data_for_pt) == 1) {
    rationalised_row <- data_for_pt
  } else {
    rationalised_row <- rationalise_data(data_for_pt)
  }
  
  if(length(output)==1) {
    output = rationalised_row
  } else {
    output = rbind(output, rationalised_row)
  }
}

ordered_output <- output %>% mutate(
  DischargeDateMotherHosp = NA,
) %>%
  select(
    # Administrative
    UniqPregID,
    # Mother
    NHSNumberMother,
    PersonBirthDateMother,
    EthnicCategoryMother,
    # Pregnancy
    BookingPostcode, 
    DeliveryPostcode,
    AntenatalAppDate,
    ReasonLateBooking,
    OrgSiteIDBooking,
    EDDAgreed,
    NumFetusesEarly,
    NumFetusesDelivery,
    PreviousLiveBirths, # find max
    PreviousStillbirths, # find max
    PreviousLossesLessThan24Weeks, # find max
    FolicAcidSupplement, # find most favourable answer
    # Baby
    NHSNumberBaby,
    PersonBirthDateBaby1 = PersonBirthDateBaby, # Figure out range from vcarious rules
    PersonBirthDateBaby2 = PersonBirthDateBaby,
    DischargeDateBabyHosp,
    dischargedatematservice,
    DischReason,
    DischMethCodeMothPostDelHospProvSpell,
    DischargeDateMotherHosp,
    PersonPhenSex, # Figure out how to handle conflicts
    PregOutcome, # Mangle the various fields together to get this
    OrgSiteIDActualDelivery, # Find latest provider for this..?
    DeliveryMethodCode,
    BirthWeight = birthweight,
    # Event Only
    PregFirstConDate,
    LeadAnteProvider,
    OrgIDProvOrigin,
    OrgIDRecv,
    LastMenstrualPeriodDate,
    EDDMethodAgreed,
    ActivityOfferDateUltrasound,
    OfferStatusDatingUltrasound,
    ProcedureDateDatingUltrasound,
    OrgIDDatingUltrasound,
    BirthOrderMaternitySUS,
    SettingPlaceBirth,
    PersonBirthTimeBaby,
    PersonDeathDateBaby,
    PersonDeathTimeBaby,
    DischargeDateBabyHosp,
    ovsvischcat,
    NeonatalTransferStartDate,
    NeonatalTransferStartTime,
    OrgSiteIDAdmittingNeonatal,
    NeoCritCareInd
  )

View(ordered_output)

{
  mockData = F
  target_rows = 16
  
  ETHNICITIES <- c('A','B','C','D','E','F','G','H','J','K','L','M','N','P','R','S')
  FOLIC_ACID <- c('Has been taking prior to becoming pregnant', 'Started taking once pregnancy confirmed', 'Not taking folic acid supplement','Not Stated (Person asked but declined to provide a response)')
  REASON_LATE_BOOKING <- c('Mother unaware of pregnancy',
                           'Maternal choice',
                           'Concealed pregnancy',
                           'Transferred in from other maternity provider',
                           'Service capacity',
                           'Awaiting availability of interpreter',
                           'Did not attend one or more antenatal booking appointments',
                           'Recently moved to area - no previous antenatal booking appointment'
  )
  
  US_STATUS <- c ('Offered and undecided',
                  'Offered and declined',
                  'Offered and accepted',
                  'Not offered',
                  'Not eligible - for stage in pregnancy'
  )
  
  SETTING_PLACE_BIRTH <- c(
    'NHS Obstetric unit (including theatre)',
    'NHS Alongside midwifery unit',
    'NHS Freestanding midwifery unit (FMU)',
    'Home (NHS care)',
    'Home (private care)',
    'Private hospital',
    'Maternity assessment or triage unit/ area',
    'NHS ward/health care setting without delivery facilities',
    'In transit (with NHS ambulance services)',
    'In transit (with private ambulance services)',
    'In transit (without healthcare services present)',
    'Non-domestic and non-health care setting',
    'Other (not listed)',
    'Not known (not recorded)'
  )
  
  
  # ==================================================
  if (mockData) {
    mock_data <- ordered_output
    
    mock_data[1,] = NA
    for(i in 1:(target_rows-1)) {
      mock_data <- rbind(mock_data, NA)
    }
    
    mock_data <- mock_data %>% mutate(
      PersonBirthDateMother = as.Date(PersonBirthDateMother),
      AntenatalAppDate = as.Date(AntenatalAppDate),
      EDDAgreed = as.Date(EDDAgreed),
      PersonBirthDateBaby1 = as.Date(PersonBirthDateBaby1),
      PersonBirthDateBaby2 = as.Date(PersonBirthDateBaby2),
      PregFirstConDate = as.Date(PregFirstConDate),
      LastMenstrualPeriodDate = as.Date(LastMenstrualPeriodDate),
      ActivityOfferDateUltrasound = as.Date(ActivityOfferDateUltrasound),
      ProcedureDateDatingUltrasound = as.Date(ProcedureDateDatingUltrasound),
      PersonBirthTimeBaby = format(now(), '%H:%M'),
      DischargeDateBabyHosp = as.Date(DischargeDateBabyHosp),
      DischargeDateMotherHosp = as.Date(DischargeDateMotherHosp)
    )
    
    for(i in 1:nrow(mock_data)) {
      mock_data$NHSNumberMother[i] = runif(1,min=8000000000,max=8999999999)
      mock_data$PersonBirthDateMother[i] = dmy('1-1-1985') + days(floor(runif(1,min=100,max=1000)))
      mock_data$EthnicCategoryMother[i] = sample(ETHNICITIES,1)
      
      mock_data$BookingPostcode[i] = 'M1 3BN'
      mock_data$DeliveryPostcode[i] = 'M1 3BN'
      
      conception = dmy('1-1-2022') + days(floor(runif(1,min=0,max=365)))
      
      mock_data$AntenatalAppDate[i] = as.Date(conception + days(floor(runif(1,min=8*7,max=10*7))))
      mock_data$ReasonLateBooking[i] = sample(REASON_LATE_BOOKING,1)
      mock_data$OrgSiteIDBooking[i] = 'REP01'
      mock_data$EDDAgreed[i] = conception + weeks(40)
      mock_data$NumFetusesEarly[i] = mock_data$NumFetusesDelivery[i] = 1
      mock_data$PreviousLiveBirths[i] = mock_data$PreviousStillbirths[i] = mock_data$PreviousLossesLessThan24Weeks[i] = 1
      mock_data$FolicAcidSupplement[i] = sample(FOLIC_ACID,1)
      
      mock_data$NHSNumberBaby[i] = runif(1,min=9000000000,max=9999999999)
      mock_data$PersonBirthDateBaby1[i] = mock_data$PersonBirthDateBaby2[i] = mock_data$EDDAgreed[i] + days(floor(runif(1,min=-56,max=14)))
      mock_data$PersonPhenSex[i] = sample(c('1','2'),1)
      mock_data$PregOutcome[i] = sample(c('Livebirth'), 1)
      mock_data$OrgSiteIDActualDelivery[i] = 'REP01'
      mock_data$DeliveryMethodCode[i] = sample(c('Spontaneous Vertex','Spontaneous Other Cephalic','Low forceps, not breech'),1)
      mock_data$BirthWeight[i] = sample(2200:3200, 1)
      
      
      mock_data$PregFirstConDate[i] = mock_data$AntenatalAppDate[i] - days(sample(1:14,1))
      mock_data$LeadAnteProvider[i] = mock_data$OrgIDProvOrigin[i] = mock_data$OrgIDRecv[i] = mock_data$OrgIDDatingUltrasound[i] = 'REP01'
      mock_data$LastMenstrualPeriodDate[i] = conception
      mock_data$EDDMethodAgreed[i] = sample(c('Last Menstrual Period (LMP) Date as stated by the mother','Last Menstrual Period Date (LMP) confirmed by Ultrasound Scan In Pregnancy'),1)
      mock_data$ActivityOfferDateUltrasound[i] = mock_data$AntenatalAppDate[i]
      mock_data$OfferStatusDatingUltrasound[i] = sample(US_STATUS, 1)
      mock_data$ProcedureDateDatingUltrasound[i] = mock_data$ActivityOfferDateUltrasound[i] + days(7)
      mock_data$SettingPlaceBirth[i] = sample(SETTING_PLACE_BIRTH,1)
      mock_data$PersonBirthTimeBaby[i] = format(now() + minutes(sample(1:1439,1)), '%H:%M')
      mock_data$BirthOrderMaternitySUS[i] = 1
      
      
      mock_data$DischargeDateMotherHosp [i] = mock_data$PersonBirthDateBaby1[i] + days(1)
      mock_data$DischargeDateBabyHosp[i] = mock_data$PersonBirthDateBaby1[i] + days(1)
      
      mock_data$submission_provider[i] = paste(sample(c("REP01","RMC01","R0A05","R0A07"), 2), collapse=", ")
      mock_data$submission_month[i] = paste(format(mock_data$AntenatalAppDate[i], '%Y-%m'),format(mock_data$AntenatalAppDate[i] + weeks(9), '%Y-%m'), sep=", ")
      mock_data$submission_lpi_mother[i] = sprintf("X%s, Y%s, Z%s", substr(mock_data$NHSNumberMother[i],1,5),substr(mock_data$NHSNumberMother[i],2,6),substr(mock_data$NHSNumberMother[i],3,7))
      mock_data$submission_lpi_baby[i] = sprintf(", Q%s, R%s", substr(mock_data$NHSNumberBaby[i],1,5),substr(mock_data$NHSNumberBaby[i],2,6),substr(mock_data$NHSNumberBaby[i],3,7))
    }
    
    
    
    file_name <- paste0('MOCK_DATA_',format(now(), '%Y%m%d_%H%M'),'.csv')
    
    
    View(mock_data)
    write.csv(mock_data, file=file_name)
    shell.exec(getwd())
  }}


# ==================================================
# Event layout suggestion:

# Timeline MSDS
# TRust A C00001 1/1/2023
# TRust B W00001 2/2/2023


# X
# Y 
# Z
