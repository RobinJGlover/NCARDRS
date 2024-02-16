rationalise_data <- function(data) {
  data %>% mutate(
    PersonBirthDateMother = rationalise_maternal_birth_date(data),
    EthnicCategoryMother = rationalise_ethnic_category_mother(data),
    BookingPostcode = rationalise_booking_postcode(data),
    DeliveryPostcode = rationalise_delivery_postcode(data),
    EDDAgreed = rationalise_edd(data),
    NumFetusesEarly = rationalise_fetuses_early(data),
    NumFetusesDelivery = rationalise_fetuses_delivery(data),
  ) %>% filter(row_number() == 1)
}

rationalise_maternal_birth_date <- function(data) {
  unique_values <- data %>% pull(PersonBirthDateMother) %>% unique
  if(length(unique_values) == 1) {
    return(unique_values[1])
  } else {
    return(max(unique_values))
  }
}

rationalise_ethnic_category_mother <- function(data) {
  unique_values <- data %>% pull(EthnicCategoryMother) %>% unique(.) %>% remove_na_from_vector(.) %>% sort()
  if(length(unique_values) <= 1) {
    return(unique_values[1])
  } else {
    # TODO remove vague ethnicities where more specific available
    print(unique_values)
    return(sprintf("Conflicting values: %s", paste(unique_values,collapse=", ")))
  }
}

rationalise_booking_postcode <- function(data) {
  # TODO make the earliest md submission for pregnancy psotcode -> booking postcode
  return(data$postcode[1])
}

rationalise_delivery_postcode <- function(data) {
  # TODO make the latest md submission for pregnancy -> delivery postcode
  return(data$postcode[1])
}

rationalise_edd <- function(data) {
  return(data$EDDAgreed[1])
}

rationalise_fetuses_early <- function(data) {
  return(1)
}

rationalise_fetuses_delivery <- function(data) {
  return(1)
}
