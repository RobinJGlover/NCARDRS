select
  distinct 
  -- Mother Fields --------
  md.NHSNumberMother,
  md.PersonBirthDateMother,
  case
    when md.EthnicCategoryMother in ('X', 'Z', '99') then null
    else md.EthnicCategoryMother
  end EthnicCategoryMother,
  md.postcode,
  -------------------------
  -- Preg Fields ----------
  pb.AntenatalAppDate,
  case 
    when pb.OrgSiteIDBooking in ('ZZ999','ZZ203') then null
    else pb.OrgSiteIDBooking
  end as OrgSiteIDBooking,
  pb.EDDAgreed,
  case 
    when pb.EDDMethodAgreed = '01' then 'Last Menstrual Period (LMP) Date as stated by the mother'
    when pb.EDDMethodAgreed = '02' then 'Last Menstrual Period Date (LMP) confirmed by Ultrasound Scan In Pregnancy'
    when pb.EDDMethodAgreed = '03' then 'Ultrasound Scan in Pregnancy dating measurements'
    when pb.EDDMethodAgreed = '04' then 'Clinical assessment'
    else pb.EDDMethodAgreed
  end as EDDMethodAgreed,
  bd.GestationLengthBirth,
  ds.NoFetusesDatingUltrasound,
  ds.LocalFetalID,
  ds.FetalOrder,
  ld.BirthsPerLabandDel,
  pb.PreviousLiveBirths,
  pb.PreviousStillbirths,
  pb.PreviousLossesLessThan24Weeks,
  case
    when pb.FolicAcidSupplement = '01' then 'Has been taking prior to becoming pregnant'
    when pb.FolicAcidSupplement = '02' then 'Started taking once pregnancy confirmed'
    when pb.FolicAcidSupplement = '03' then 'Not taking folic acid supplement'
    when pb.FolicAcidSupplement = 'ZZ' then null
    else pb.FolicAcidSupplement
  end as FolicAcidSupplement,
  -------------------------
  -- Baby Fields ----------
  bd.NHSNumberBaby,
  bd.PersonBirthDateBaby,
  -- TODO: DOB range using Discharge dates or EDD
  bd.BirthOrderMaternitySUS,
  case when bd.PersonPhenSex = 'X' then null else bd.PersonPhenSex end PersonPhenSex,
  -------------------------
  -- Outcome --------------
  case
    when bd.PregOutcome = '01' then 'Livebirth'
    when bd.PregOutcome in ('02','03','04') then 'Stillbirth'
    when bd.PregOutcome = '04' then 'Termination >= 24 weeks'
    when bd.PregOutcome = 98 then null
    else bd.PregOutcome
  end PregOutcome,
  case
    when pb.DischReason = '01' then 'Discharge following delivery'
    when pb.DischReason = '02' then 'Transfer to other Health Care Provider'
    when pb.DischReason = '03' then 'Miscarriage'
    when pb.DischReason = '04' then 'Termination of Pregnancy < 24weeks'
    when pb.DischReason = '05' then 'Termination of Pregnancy >= 24weeks'
    when pb.DischReason = '06' then 'No further contact from mother'
    when pb.DischReason = '07' then 'Maternal death'
    else pb.DischReason
  end DischReason,
  case
    when ld.DischMethCodeMothPostDelHospProvSpell in (1,2,3,4,8,9) then null
    when ld.DischMethCodeMothPostDelHospProvSpell = 5 then 'Stillbirth'
    else ld.DischMethCodeMothPostDelHospProvSpell
  end DischMethCodeMothPostDelHospProvSpell,
  bd.OrgSiteIDActualDelivery,
  bd.SettingPlaceBirth,
  case
    when bd.DeliveryMethodCode = 0 then 'Spontaneous Vertex'
    when bd.DeliveryMethodCode = 1 then 'Spontaneous Other Cephalic'
    when bd.DeliveryMethodCode = 2 then 'Low forceps, not breech'
    when bd.DeliveryMethodCode = 3 then 'Other Forceps, not breech'
    when bd.DeliveryMethodCode = 4 then 'Ventouse, Vacuum extraction'
    when bd.DeliveryMethodCode = 5 then 'Breech'
    when bd.DeliveryMethodCode = 6 then 'Breech Extraction'
    when bd.DeliveryMethodCode = 7 then 'Elective caesarean section'
    when bd.DeliveryMethodCode = 8 then 'Emergency caesarean section'
    when bd.DeliveryMethodCode = 9 then 'Other'
    else bd.DeliveryMethodCode
  end as DeliveryMethodCode,
  bd.EthnicCategoryBaby
  -------------------------
from
  mat_pre_clear.msd401babydemographics bd
  left join mat_pre_clear.msd101pregnancybooking pb on bd.UniqPregID = pb.UniqPregID
  left join mat_pre_clear.msd103datingscan ds on bd.UniqPregID = ds.UniqPregID
  left join mat_pre_clear.msd001motherdemog md on pb.Person_ID_Mother = md.Person_ID_Mother
  left join mat_pre_clear.msd301labourdelivery ld on bd.UniqPregID = ld.UniqPregID
order by
  1
